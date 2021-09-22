local log = require('log')
local utils = require('migrator.utils')

return {
    up = function()
        local space = box.schema.space.create('owner', { if_not_exists = true })

        space:format({
            { name = 'bucket_id', type = 'unsigned', is_nullable = false, comment = 'bucket_id', },
            { name = 'owner_id', type = 'unsigned', is_nullable = false, comment = 'owner ID' },
            { name = 'owner_username', type = 'string', is_nullable = false, comment = 'owner username' },
            { name = 'owner_name', type = 'string', is_nullable = true, comment = 'owner name' },
            { name = 'owner_surname', type = 'string', is_nullable = true, comment = 'owner name' },
            { name = 'owner_age', type = 'unsigned', is_nullable = false, comment = 'owner age' },
        })

        space:create_index('primary', {
            parts = { 'owner_id' },
            unique = true,
            if_not_exists = true,
        })

        space:create_index('secondary', {
            parts = { 'owner_username' },
            unique = true,
            if_not_exists = true,
        })

        space:create_index('bucket_id', {
            parts = { 'bucket_id' },
            unique = false,
            if_not_exists = true,
        })

        utils.register_sharding_key(space.name, {'owner_id'})
        log.info('Space "owner" created')
    end
}
