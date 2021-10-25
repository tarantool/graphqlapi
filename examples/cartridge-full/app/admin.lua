local cartridge = require('cartridge')
local cli_admin = require('cartridge-cli-extensions.admin')
local migrator = require("migrator")
local vshard = require('vshard')
local yaml = require('yaml')

local function bucket_id(key)
    return vshard.router.bucket_id_mpcrc32(key)
end

-- register admin functions to use it with "cartridge admin"
local function init()
    cli_admin.init()

    local fill = {
        usage = 'Load data',
        args = {},
        call = function(_)
            -- fill entities
            local entity = {
                { bucket_id(1), 1, 'SSD', 3, 'Solid State Drive', },
                { bucket_id(2), 2, 'CPU', 2, 'Central Processor Unit', },
                { bucket_id(3), 3, 'RAM', 1, 'Random Access Memory', },
                { bucket_id(4), 4, 'eMMC', 3, 'embedded Multimedia Memory Card', },
            }

            local entity_counter = 0
            for _, _entity in ipairs(entity) do
                local result, err = crud.replace( 'entity', _entity)
                if not result then
                    return nil, 'Failed to load "entity" space data: '..tostring(err)
                end
                entity_counter = entity_counter + 1
            end

            -- fill owners
            local owner = {
                { bucket_id(1), 1, 'in-memory', 'In', 'Memory', 20, },
                { bucket_id(2), 2, 'rapid', 'Low', 'Latency', 25, },
                { bucket_id(3), 3, 'unbreakable', 'Un', 'Breakable', 30, },
            }

            local owner_counter = 0
            for _, _owner in ipairs(owner) do
                local result, err = crud.replace('owner', _owner)
                if not result then
                    return nil, 'Failed to load "owner" space data: '..tostring(err)
                end
                owner_counter = owner_counter + 1
            end

            return {
                string.format(
                    'Load data: OK\n"owner" space tuples loaded: %d\n"entity" space tuples loaded: %d',
                    owner_counter,
                    entity_counter
                )
            }
        end,
    }

    local migrations = {
        usage = 'Fire migrations',
        args = {},
        call = function(_)
            local ok, res = pcall(migrator.up)
            if ok then
                return { 'Applied migrations:\n'..yaml.encode(res), }
            else
                return nil, 'Migrations failed:\n'..yaml.encode(res)
            end
        end,
    }

    local reload = {
        usage = 'Reload GraphQLAPI fragments',
        args = {},
        call = function(_)
            local graphqlapi = cartridge.service_get('graphqlapi')
            if graphqlapi ~= nil and graphqlapi.reload() == true then
                return { 'GraphQL API fragments reloaded', }
            end
            return nil, 'GraphQL API fragments reload failed'
        end,
    }

    local ok, err = cli_admin.register('fill', fill.usage, fill.args, fill.call)
    assert(ok, err)
    ok, err = cli_admin.register('migrations', migrations.usage, migrations.args, migrations.call)
    assert(ok, err)
    ok, err = cli_admin.register('reload', reload.usage, reload.args, reload.call)
    assert(ok, err)
end

return {
    init = init,
}
