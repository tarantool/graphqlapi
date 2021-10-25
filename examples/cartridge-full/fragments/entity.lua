local checks = require('checks')
local types = require('graphqlapi.types')
local operations = require('graphqlapi.operations')
local utils = require('app.utils')

local space_name = 'entity'

local function entity_get_by_id(_, args, _)
    checks('?', { entity_id = 'number' }, '?')
    return utils.get_by_primary_key(space_name, args.entity_id)
end

local function entity_get_by_name(_, args, _)
    checks('?', { entity_name = 'string' }, '?')
    return utils.get_by_field(space_name, 'entity_name', args.entity_name)
end

local function entity_get_all(_, _, _)
    return utils.get_all(space_name)
end

local function fragment()
    operations.remove_query({
        name = 'entity_get_by_id'
    })
    operations.add_space_query({
        space = space_name,
        name = 'entity_get_by_id',
        args = {
            entity_id = types.int.nonNull,
        },
        fields = {
            bucket_id = box.NULL,
        },
        callback = 'fragments.entity.entity_get_by_id'
    })
    operations.remove_query({
        name = 'entity_get_by_name'
    })
    operations.add_space_query({
        space = space_name,
        name = 'entity_get_by_name',
        args = {
            entity_name = types.string.nonNull,
        },
        fields = {
            bucket_id = box.NULL,
        },
        callback = 'fragments.entity.entity_get_by_name'
    })
    operations.remove_query({
        name = 'entity_get_all'
    })
    operations.add_space_query({
        space = space_name,
        type_name = space_name..'_full',
        name = 'entity_get_all',
        list = true,
        callback = 'fragments.entity.entity_get_all'
    })
end

return {
    spaces = { space_name },
    fragment = fragment,
    entity_get_by_id = entity_get_by_id,
    entity_get_by_name = entity_get_by_name,
    entity_get_all = entity_get_all,
}
