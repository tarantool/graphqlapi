local checks = require('checks')
local types = require('graphqlapi.types')
local operations = require('graphqlapi.operations')
local utils = require('app.utils')

local space_name = 'owner'

local function owner_get_by_id(_, args, _)
    checks('?', { owner_id = 'number' }, '?')
    return utils.get_by_primary_key(space_name, args.owner_id)
end

local function owner_get_by_username(_, args, _)
    checks('?', { owner_username = 'string' }, '?')
    local res, err = utils.get_by_field(space_name, 'owner_username', args.owner_username)
    if res and type(res) == 'table' and next(res) then
        res.entities = utils.get_all_by_field('entity', 'entity_owner_id', res.owner_id)
    end
    return res, err
end

local function owner_get_all(_, _, _)
    return utils.get_all(space_name)
end

local function fragment()
    operations.remove_query({
        name = 'owner_get_by_id'
    })
    operations.add_space_query({
        space = space_name,
        name = 'owner_get_by_id',
        args = {
            owner_id = types.int.nonNull,
        },
        fields = {
            bucket_id = box.NULL,
        },
        callback = "fragments.owner.owner_get_by_id"
    })
    operations.remove_query({
        name = 'owner_get_by_username'
    })
    operations.add_space_query({
        space = space_name,
        type_name = 'owner_with_entities',
        name = 'owner_get_by_username',
        args = {
            owner_username = types.string.nonNull,
        },
        fields = {
            bucket_id = box.NULL,
            entities = types.list(types()['entity_space'])
        },
        callback = "fragments.owner.owner_get_by_username"
    })
    operations.remove_query({
        name = 'owner_get_all'
    })
    operations.add_space_query({
        space = space_name,
        type_name = space_name..'_full',
        name = 'owner_get_all',
        list = true,
        callback = "fragments.owner.owner_get_all"
    })
end

return {
    spaces = { space_name },
    fragment = fragment,
    owner_get_by_id = owner_get_by_id,
    owner_get_by_username = owner_get_by_username,
    owner_get_all = owner_get_all,
}
