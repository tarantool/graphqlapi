local fio = require('fio')
local t = require('luatest')
local g = t.group('cluster')

local helper = require('test.helper')
local cluster = require('graphqlapi.cluster')

g.before_each(function()
    local cluster_config = table.deepcopy(helper.cluster_config)
    g.cluster = helper.Cluster:new(cluster_config)
    g.cluster:start()
end)

g.after_each(function()
    g.cluster:stop()
    fio.rmtree(g.cluster.datadir)
    g.cluster = nil
end)

local function check_instance(servers, instance_name)
    local function find_by_alias(_servers, alias)
        for _, server in pairs(_servers) do
            if server.alias == alias then
                return server
            end
        end
    end

    local _instance = find_by_alias(servers, instance_name)
    local instance = g.cluster:server(instance_name)
    t.assert_equals(_instance.replicaset_uuid, instance.replicaset_uuid)
    t.assert_equals(
        tostring(_instance.conn.host)..':'..
        tostring(_instance.conn.port), instance.net_box_uri)
end

g.test_get_servers = function()
    local router = g.cluster:server('router')
    local servers = router.net_box:eval("return require('graphqlapi.cluster').get_servers()")

    t.assert_equals(#servers, #g.cluster.servers)
    for _, server in pairs(servers) do
        local instance = g.cluster:server(server.alias)
        t.assert_equals(server.replicaset_uuid, instance.replicaset_uuid)
        t.assert_equals(tostring(server.conn.host)..':'..tostring(server.conn.port), instance.net_box_uri)
    end

    g.cluster:server('storage-1-master'):stop()
    local _, errors = router.net_box:eval("return require('graphqlapi.cluster').get_servers()")
    t.assert_str_contains(errors[1].str, 'instance \'storage-1-master\' error')
end

g.test_get_masters = function()
    local router = g.cluster:server('router')
    local servers = router.net_box:eval("return require('graphqlapi.cluster').get_masters()")

    t.assert_equals(#servers, 3)

    check_instance(servers, 'router')
    check_instance(servers, 'storage-1-master')
    check_instance(servers, 'storage-2-master')
end

g.test_get_storages_instances = function()
    local router = g.cluster:server('router')
    local servers = router.net_box:eval("return require('graphqlapi.cluster').get_storages_instances('write')")
    t.assert_equals(#servers, 2)

    check_instance(servers, 'storage-1-master')
    check_instance(servers, 'storage-2-master')

    servers = router.net_box:eval("return require('graphqlapi.cluster').get_storages_instances('read')")
    t.assert_equals(#servers, 2)

    check_instance(servers, 'storage-1-replica')
    check_instance(servers, 'storage-2-replica')

    servers = router.net_box:eval("return require('graphqlapi.cluster').get_storages_instances('read', false, true)")
    t.assert_equals(#servers, 2)

    servers = router.net_box:eval("return require('graphqlapi.cluster').get_storages_instances('read', false, true)")
    t.assert_equals(#servers, 2)

    servers = router.net_box:eval("return require('graphqlapi.cluster').get_storages_instances('read', true, false)")
    t.assert_equals(#servers, 2)

    servers = router.net_box:eval("return require('graphqlapi.cluster').get_storages_instances('read', true, true)")
    t.assert_equals(#servers, 2)
end

g.test_get_self_alias = function()
    local router = g.cluster:server('router')
    local alias = router.net_box:eval("return require('graphqlapi.cluster').get_self_alias()")
    t.assert_equals(alias, 'router')
    t.assert_equals(box.info.uuid, cluster.get_self_alias())
end

g.test_get_self_uri = function()
    local router = g.cluster:server('router')
    local uri = router.net_box:eval("return require('graphqlapi.cluster').get_self_uri()")
    t.assert_equals(uri, 'localhost:13301')
end

g.test_get_replicasets = function()
    local router = g.cluster:server('router')
    local replicasets = router.net_box:eval("return require('graphqlapi.cluster').get_replicasets()")
    t.assert_items_equals(replicasets, {'storage-1','api','storage-2'})
    replicasets = cluster.get_replicasets()
    t.assert_items_equals(replicasets, {})
end

g.test_get_replicaset_instances = function()
    local router = g.cluster:server('router')
    local instances = router.net_box:eval(
        "return require('graphqlapi.cluster').get_replicaset_instances('storage-1')")
    t.assert_items_equals(instances, {
        {alias = "storage-1-replica", status = "healthy", uri = "localhost:13303"},
        {alias = "storage-1-master", status = "healthy", uri = "localhost:13302"},
    })
    instances = cluster.get_replicaset_instances()
    t.assert_items_equals(instances, {})
end

g.test_get_instances = function()
    local router = g.cluster:server('router')
    local instances = router.net_box:eval("return require('graphqlapi.cluster').get_instances()")
    t.assert_items_equals(instances, {
        { alias = 'storage-1-replica', status = "healthy", uri = 'localhost:13303', },
        { alias = 'router', status = "healthy", uri = 'localhost:13301', },
        { alias = 'storage-2-replica', status = "healthy", uri = 'localhost:13305', },
        { alias = 'storage-2-master', status = "healthy", uri = 'localhost:13304', },
        { alias = 'storage-1-master', status = "healthy", uri = 'localhost:13302', },
    })
    instances = cluster.get_instances()
    t.assert_items_equals(instances, {})
end

g.test_get_servers_by_list = function()
    local router = g.cluster:server('router')
    local servers = router.net_box:eval([[
        local servers_list = {
            'router',
            'storage-1-master',
            'storage-1-replica',
            'storage-2-master',
            'storage-2-replica',
        }
        return require('graphqlapi.cluster').get_servers_by_list(servers_list)
    ]])

    t.assert_equals(#servers, #g.cluster.servers)
    for _, server in pairs(servers) do
        local instance = g.cluster:server(server.alias)
        t.assert_equals(server.replicaset_uuid, instance.replicaset_uuid)
        t.assert_equals(tostring(server.conn.host)..':'..tostring(server.conn.port), instance.net_box_uri)
    end

    g.cluster:server('storage-1-master'):stop()
    local _, errors = router.net_box:eval([[
        local servers_list = {
            'router',
            'storage-1-master',
            'storage-1-replica',
            'storage-2-master',
            'storage-2-replica',
        }
        return require('graphqlapi.cluster').get_servers_by_list(servers_list)
    ]])
    t.assert_str_contains(errors[1].str, 'instance \'storage-1-master\' error')
end
