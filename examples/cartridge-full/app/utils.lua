local vshard = require('vshard')

local function get_by_primary_key(space_name, key)

    local res, unflatten, err
    res, err = crud.get( space_name, key,
        { bucket_id = vshard.router.bucket_id_mpcrc32({key}), }
    )

    if res== nil then
        return nil, err
    end

    unflatten, err = crud.unflatten_rows(res.rows, res.metadata)

    if unflatten ~= nil then
        unflatten = unflatten[1]
    end

    return unflatten, err
end

local function get_by_field(space_name, field_name, key)
    local res, unflatten, err
    res, err = crud.select(
        space_name,
        { { '==', field_name, key }, },
        { force_map_call = true, first = 1, }
    )

    if res== nil then
        return nil, err
    end

    unflatten, err = crud.unflatten_rows(res.rows, res.metadata)

    if unflatten ~= nil then
        unflatten = unflatten[1]
    end

    return unflatten, err
end

local function get_all(space_name)
    local res, unflatten, err
    res, err = crud.select(
        space_name,
        { force_map_call = true, }
    )

    if res == nil then
        return nil, err
    end

    unflatten, err = crud.unflatten_rows(res.rows, res.metadata)

    return unflatten, err
end

local function get_all_by_field(space_name, field_name, key)
    local res, unflatten, err
    res, err = crud.select(
        space_name,
        { { '==', field_name, key }, },
        { force_map_call = true, }
    )

    if res == nil then
        return nil, err
    end

    unflatten, err = crud.unflatten_rows(res.rows, res.metadata)

    return unflatten, err
end

return {
    get_by_primary_key = get_by_primary_key,
    get_by_field = get_by_field,
    get_all = get_all,
    get_all_by_field = get_all_by_field,
}
