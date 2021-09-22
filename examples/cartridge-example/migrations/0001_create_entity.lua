local log = require('log')
local utils = require('migrator.utils')

return {
    up = function()
        local space = box.schema.space.create('entity', { if_not_exists = true })

        space:format({
            { name = 'bucket_id', type = 'unsigned', is_nullable = false, comment = 'bucket_id', },
            { name = 'entity_id', type = 'unsigned', is_nullable = false, comment = 'entity ID' },
            { name = 'entity_name', type = 'string', is_nullable = false, comment = 'entity name' },
            { name = 'entity_owner_id', type = 'unsigned', is_nullable = false, comment = 'entity owner ID' },
            { name = 'entity_description', type = 'string', is_nullable = true, comment = 'entity description' },
        })

        space:create_index('primary', {
            parts = { 'entity_id' },
            unique = true,
            if_not_exists = true,
        })

        space:create_index('secondary', {
            parts = { 'entity_name' },
            unique = false,
            if_not_exists = true,
        })

        space:create_index('bucket_id', {
            parts = { 'bucket_id' },
            unique = false,
            if_not_exists = true,
        })

        utils.register_sharding_key(space.name, {'entity_id'})
        log.info('Space "entity" created')
    end
}
