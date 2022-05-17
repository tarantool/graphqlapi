local argparse = require('cartridge.argparse')
local cartridge = require('cartridge')
local ddl = require('ddl')
local errors = require('errors')
local membership = require('membership')
local pool = require('cartridge.pool')
local vshard = require('vshard')

local utils = require('graphqlapi.utils')

local _replicas = {}

local e_cluster_api = errors.new_class('cluster API error', { capture_stack = false })

local function get_alias_by_uuid(conn)
    utils.is_table(1, conn, false)
    for _, server in pairs(cartridge.admin_get_servers()) do
        if server.uuid == conn.peer_uuid then
            return server.alias
        end
    end
end

local function get_servers()
    local servers = {}
    local connect_errors
    for _, server in pairs(cartridge.admin_get_servers()) do
        local conn, err = pool.connect(server.uri)
        local alias = server.alias or 'unknown'
        if conn then
            table.insert(servers, { alias = alias, conn = conn })
        else
            connect_errors = connect_errors or {}
            table.insert(connect_errors,  e_cluster_api:new('instance \'%s\' error: %s', alias, err))
        end
    end
    return servers, connect_errors
end

local function get_masters()
    local servers = {}
    local connect_errors
    for _, replicaset in pairs(cartridge.admin_get_replicasets()) do
        local conn, err = pool.connect(replicaset.active_master.uri)
        local alias = replicaset.active_master.alias or 'unknown'
        if conn then
            table.insert(servers, { alias = alias, conn = conn })
        else
            connect_errors = connect_errors or {}
            table.insert(connect_errors,  e_cluster_api:new('instance \'%s\' error: %s', alias, err))
        end
    end
    return servers, connect_errors
end

local function get_candidates(role)
    utils.is_string(1, role, true)
    local servers = {}
    local connect_errors
    for _, uri in ipairs(cartridge.rpc_get_candidates(role)) do
        local conn, err = pool.connect(uri)
        local alias = get_alias_by_uuid(conn)
        if not conn then
            connect_errors = connect_errors or {}
            table.insert(connect_errors,  e_cluster_api:new('instance \'%s\' error: %s', alias, err))
        else
            table.insert(servers, { alias = alias, conn = conn })
        end
    end
    return servers, connect_errors
end

local function get_storages_instances(mode, prefer_replica, balance)
    utils.is_string(1, mode, true)
    utils.is_boolean(2, prefer_replica, true)
    utils.is_boolean(3, balance, true)

    local servers = {}
    if mode ~= 'read' and mode ~= 'write' then
        mode = 'write'
    end
    prefer_replica = prefer_replica or false
    balance = balance or false

    for uuid, replicaset in pairs(vshard.router.routeall()) do
        local conn
        if mode == 'write' or #replicaset.replicas == 1 then
            conn = replicaset.master.conn
            _replicas[uuid] = conn.peer_uuid
        else
            if prefer_replica == false and balance == false then
                conn =  replicaset.master.next_by_priority.conn
                _replicas[uuid] = conn.peer_uuid
            elseif prefer_replica == false and balance == true then
                local prev_uuid = _replicas[uuid] or replicaset.priority_list[1].uuid
                if replicaset.replicas[prev_uuid].next_by_priority then
                    conn = replicaset.replicas[prev_uuid].next_by_priority.conn
                else
                    conn = replicaset.replicas[replicaset.priority_list[1].uuid].conn
                end
                _replicas[uuid] = conn.peer_uuid
            elseif prefer_replica == true and balance == false then
                conn = replicaset.master.next_by_priority.conn
                _replicas[uuid] = conn.peer_uuid
            else
                local prev_uuid = _replicas[uuid] or replicaset.priority_list[1].uuid
                if replicaset.replicas[prev_uuid].next_by_priority then
                    conn = replicaset.replicas[prev_uuid].next_by_priority.conn
                else
                    conn = replicaset.replicas[replicaset.priority_list[1].uuid].conn
                end
                if conn.peer_uuid == replicaset.master.uuid then
                    conn = replicaset.master.next_by_priority.conn
                end
                _replicas[uuid] = conn.peer_uuid
            end
        end
        -- local replicaset_uuid = uuid or '00000000-0000-0000-0000-000000000000'
        local alias = get_alias_by_uuid(conn)
        table.insert(servers, { alias = alias, conn = conn })
    end
    return servers
end

local function get_self_alias()
    local parse = argparse.parse()
    return parse.instance_name or parse.alias or box.info.uuid
end

local function get_self_uri()
    return membership.myself().uri
end

local function get_replicasets()
    local replicasets = {}

    local config = cartridge.config_get_readonly()
    if config ~= nil and type(config.topology) == 'table' then
        for _, replicaset in pairs(config.topology.replicasets or {}) do
            table.insert(replicasets, replicaset.alias)
        end
    end
    return replicasets
end

local function get_replicaset_instances(replicaset)
    local instances = {}
    for _, server in ipairs(cartridge.admin_get_servers() or {}) do
        if server.replicaset.alias == replicaset then
            table.insert(instances, { alias = server.alias, uri = server.uri, status = server.status })
        end
    end
    return instances
end

local function get_instances()
    local instances = {}
    for _, server in ipairs(cartridge.admin_get_servers() or {}) do
        table.insert(instances, { alias = server.alias, uri = server.uri, status = server.status })
    end
    return instances
end

local function get_servers_by_list(instances)
    local servers = {}
    local connect_errors
    for _, server in pairs(cartridge.admin_get_servers()) do
        if utils.value_in(instances, server.alias) then
            local conn, err = pool.connect(server.uri)
            local replicaset_uuid = server.replicaset.uuid or '00000000-0000-0000-0000-000000000000'
            local alias = server.alias or 'unknown'
            if conn then
                table.insert(servers, { replicaset_uuid = replicaset_uuid, alias = alias, conn = conn, })
            else
                connect_errors = connect_errors or {}
                table.insert(connect_errors,  e_cluster_api:new('instance \'%s\' error: %s', alias, err))
            end
        end
    end
    return servers, connect_errors
end

local function get_existing_spaces()
    local spaces = {}
    local schema = ddl.get_schema()
    for space in pairs(schema.spaces) do
        spaces[space]=space
    end
    return spaces
end

local function is_space_exists(space_name)
    return ddl.get_schema().spaces[space_name] ~= nil
end

local function get_schema()
    return ddl.get_schema()
end

local function check_schema(schema)
    return ddl.check_schema(schema)
end

local function set_schema(schema)
    return ddl.set_schema(schema)
end

local function bucket_id(space_name, sharding_key)
    return ddl.bucket_id(space_name, sharding_key)
end

return {
    -- Cluster API
    get_servers = get_servers,
    get_masters = get_masters,
    get_candidates = get_candidates,
    get_storages_instances = get_storages_instances,
    get_self_alias = get_self_alias,
    get_self_uri = get_self_uri,
    get_replicasets = get_replicasets,
    get_replicaset_instances = get_replicaset_instances,
    get_instances = get_instances,
    get_servers_by_list = get_servers_by_list,

    -- Schema API
    get_existing_spaces = get_existing_spaces,
    is_space_exists = is_space_exists,
    get_schema = get_schema,
    check_schema = check_schema,
    set_schema = set_schema,
    bucket_id = bucket_id,
}
