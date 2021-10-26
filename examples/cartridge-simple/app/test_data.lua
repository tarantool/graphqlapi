local cluster = require('graphqlapi.cluster')
local log = require('log')

local function value_in(val, arr)
    for i, elem in ipairs(arr) do
        if val == elem then
            return true, i
        end
    end
    return false
end

local function register_sharding_key(space_name, key)
    if value_in('bucket_id', key) then
        log.error("Wrong sharding key: 'bucket_id' is used as input of sharding function for space '"
            .. space_name .. "'")
    end

    if box.space._ddl_sharding_key == nil then
        local sharding_space = box.schema.space.create('_ddl_sharding_key', {
            format = {
                {name = 'space_name', type = 'string', is_nullable = false},
                {name = 'sharding_key', type = 'array', is_nullable = false}
            },
            if_not_exists = true,
        })
        sharding_space:create_index(
            'space_name', {
                type = 'TREE',
                unique = true,
                parts = {{'space_name', 'string', is_nullable = false}},
                if_not_exists = true,
            }
        )
    end
    box.space._ddl_sharding_key:replace{space_name, key}
end

local function fill()
    if box.space['customer'] == nil then
        local space = box.schema.space.create('customer', { if_not_exists = true })

        space:format({
            { name = 'customer_id', type = 'unsigned', is_nullable = false },
            { name = 'bucket_id', type = 'unsigned', is_nullable = false },
            { name = 'fullname', type = 'string', is_nullable = false},
        })

        space:create_index('customer_id', {
            unique = true,
            parts = {'customer_id'},
            if_not_exists = true
        })

        space:create_index('bucket_id', {
            unique = false,
            parts = {'bucket_id'},
            if_not_exists = true
        })

        space:create_index('fullname', {
            unique = true,
            parts = {'fullname'},
            if_not_exists = true
        })

        register_sharding_key('customer', {'customer_id'})
    end

    if box.space['customer'] ~= nil then
        for id = 1, 250 do
            local bucket_id = cluster.sharding_function('customer', {id})
            crud.replace('customer', {id, bucket_id, 'Test Customer '..tostring(id)})
        end
    end
end

return {
    fill = fill,
}
