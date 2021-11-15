local t = require('luatest')
local g = t.group('utils')

local helper = require('test.helper')

local defaults = require('graphqlapi.defaults')
local utils = require('graphqlapi.utils')

g.test_value_in = function()
    t.assert_equals(utils.value_in(nil, {}), false)
    t.assert_equals(utils.value_in(1, {2, 3, 4}), false)
    t.assert_equals(utils.value_in('1', {1, 2}), false)
    t.assert_equals(utils.value_in('1', {'2', '1'}), true)
end

g.test_diff_maps = function()
    local res = utils.diff_maps({['a'] = true, ['c'] = true}, {['a'] = true, ['b'] = true}, {'a', 'd'})
    t.assert_items_equals(res, {'a', 'd', 'b'})
    res = utils.diff_maps({}, {['a'] = true, ['b'] = true}, {'a', 'd'})
    t.assert_items_equals(res, {'a', 'd', 'b'})
end

g.test_diff_arrays = function()
    local res = utils.diff_arrays({}, {})
    t.assert_items_equals(res, {})
    res = utils.diff_arrays({'entity1'}, {})
    t.assert_items_equals(res, {})
    res = utils.diff_arrays({}, {'entity1'})
    t.assert_items_equals(res, {})
    res = utils.diff_arrays({'entity1'}, {'entity2'})
    t.assert_items_equals(res, {})
    res = utils.diff_arrays({'entity1'}, {'entity1'})
    t.assert_items_equals(res, {'entity1'})
end

g.test_merge_maps = function()
    local res = utils.merge_maps({}, {})
    t.assert_items_equals(res, {})

    res = utils.merge_maps({a = 'a', b = 'b'}, {})
    t.assert_items_equals(res, {a = 'a', b = 'b'})

    res = utils.merge_maps({}, {a = 'a', b = 'b'})
    t.assert_items_equals(res, {a = 'a', b = 'b'})

    res = utils.merge_maps({a = 'a', b = 'b'}, {})
    t.assert_items_equals(res, {a = 'a', b = 'b'})

    res = utils.merge_maps({a = 'a', b = 'b'}, {c = 'c', d = 'd'})
    t.assert_items_equals(res, {a = 'a', b = 'b', c = 'c', d = 'd'})

    res = utils.merge_maps({a = 'a', b = 'b1', c = 'c2'}, {b = 'b2', c = 'c1', d = 'd'})
    t.assert_items_equals(res, {a = 'a', b = 'b2', c = 'c1', d = 'd'})

    res = utils.merge_maps(
        {},
        {['space1'] = {name = 'space1', schema = 'default', prefix = 'spaces'},}
    )
    t.assert_items_equals(res, {
        space1 = {name = "space1", prefix = "spaces", schema = "default"},
    })

    res = utils.merge_maps(
        {['space1'] = {name = 'space1', schema = 'default', prefix = 'spaces'},},
        {['space1'] = {name = 'space1', schema = 'default', prefix = 'spaces'},}
    )
    t.assert_items_equals(res, {
        space1 = {name = "space1", prefix = "spaces", schema = "default"},
    })

    res = utils.merge_maps(
        {['space1'] = {name = 'space1', schema = 'default', prefix = 'spaces'},},
        {['space2'] = {name = 'space2', schema = 'default', prefix = 'spaces'},}
    )
    t.assert_items_equals(res, {
        space1 = {name = "space1", prefix = "spaces", schema = "default"},
        space2 = {name = "space2", prefix = "spaces", schema = "default"},
    })

    res = utils.merge_maps(
        {
            ['space1'] = {name = 'space1', schema = 'default', prefix = 'spaces'},
            ['space2'] = {name = 'space2', schema = 'default', prefix = 'spaces'},
        },
        {
            ['space2'] = {name = 'space2', schema = 'default', prefix = 'spaces'},
            ['space1'] = {name = 'space1', schema = 'default', prefix = 'spaces'},
        }
    )
    t.assert_items_equals(res, {
        space1 = {name = "space1", prefix = "spaces", schema = "default"},
        space2 = {name = "space2", prefix = "spaces", schema = "default"},
    })
end

g.test_merge_arrays = function()
    local res = utils.merge_arrays({}, {})
    t.assert_items_equals(res, {})

    res = utils.merge_arrays({1}, {})
    t.assert_items_equals(res, {1})

    res = utils.merge_arrays({}, {1})
    t.assert_items_equals(res, {1})

    res = utils.merge_arrays({1}, {1})
    t.assert_items_equals(res, {1})

    res = utils.merge_arrays({1, 9, 3, 4, 5}, {6, 3, 5, 9, 10})
    t.assert_items_equals(res, {1, 9, 3, 4, 5, 6, 10})
end

g.test_concat_arrays = function()
    local res = utils.concat_arrays()
    t.assert_items_equals(res, {})

    res = utils.concat_arrays(nil, {{arr1 = 'val1'}})
    t.assert_items_equals(res, {{arr1 = 'val1'}})

    res = utils.concat_arrays({}, {})
    t.assert_items_equals(res, {})

    res = utils.concat_arrays({{arr1 = 'val1'}})
    t.assert_items_equals(res, {{arr1 = 'val1'}})

    res = utils.concat_arrays({{arr1 = 'val1'}}, {{arr2 = 'val2'}})
    t.assert_items_equals(res, {{arr1 = 'val1'}, {arr2 = 'val2'}})
end

g.test_is_string_array = function()
    t.assert_equals(utils.is_string_array(nil), false)
    t.assert_equals(utils.is_string_array('a'), false)
    t.assert_equals(utils.is_string_array({1, 'a'}), false)
    t.assert_equals(utils.is_string_array({'a', {'b'}}), false)
    t.assert_equals(utils.is_string_array({'a', 'b'}), true)
end

g.test_dedup_array = function ()
    t.assert_equals(utils.dedup_array(nil), {})
    t.assert_equals(utils.dedup_array({}), {})
    t.assert_equals(utils.dedup_array({'1'}), {'1'})
    t.assert_equals(utils.dedup_array({'1', '2'}), {'1', '2'})
    t.assert_equals(utils.dedup_array({'1', '2', '1'}), {'2', '1'})
    t.assert_equals(utils.dedup_array({'1', '2', '1', '2'}), {'1', '2'})
    t.assert_equals(utils.dedup_array({'1', '2', '1', '2', '1'}), {'2', '1'})
end

g.test_is_map = function()
    t.assert_equals(utils.is_map(nil), false)
    t.assert_equals(utils.is_map({'1'}), false)
    t.assert_equals(utils.is_map({'1', '2', '3'}), false)
    t.assert_equals(utils.is_map({['1'] = 1, ['2'] = 2, 3}), false)
    t.assert_equals(utils.is_map({0, ['1'] = 1, ['2'] = 2}), false)
    t.assert_equals(utils.is_map({['1'] = 1, ['2'] = 2, ['3'] = 3}), true)
    t.assert_equals(utils.is_map({['1'] = {1}, ['2'] = {2}, ['3'] = {3}}), true)
end

g.test_coerce_schema = function()
    t.assert_equals(utils.coerce_schema(nil), defaults.DEFAULT_SCHEMA_NAME)
    t.assert_equals(utils.coerce_schema('spaces'), 'spaces')
end

g.test_map_by_field = function()
    t.assert_items_equals(utils.map_by_field(), {})

    local test_arr = {
        {
            a = 'a1',
        },
        {
            a = 'a2'
        },
        {
            b = 'b'
        }
    }

    local test_result = {
        a1 = {
            a = 'a1',
        },
        a2 = {
            a = 'a2'
        },
    }
    t.assert_items_equals(utils.map_by_field(test_arr, 'a'), test_result)
end

g.test_encode_decode_cursor = function()
    local res, err
    local row = { 1, 'entity_id', 'entity', 'property', 'feature', }
    local pk_row1 = { box.NULL, 'entity_id', box.NULL, box.NULL, box.NULL, }
    local pk_row2 = { box.NULL, 'entity_id', box.NULL, box.NULL, 'feature', }
    local space_name = 'entity'
    local index_name = 'primary'

    res = utils.encode_cursor(row, space_name)
    t.assert_equals(res, nil)

    local space = helper.create_space()

    res = utils.encode_cursor(nil, space_name)
    t.assert_equals(res, nil)
    res = utils.encode_cursor(row, space_name)
    t.assert_equals(res, nil)

    helper.create_index(space.name, 'primary', true, {{field = 2, type = 'string',},})
    local encoded = utils.encode_cursor(row, 'entity')
    t.assert_items_equals(utils.decode_cursor(encoded), pk_row1)

    helper.drop_index(space.name, index_name)

    helper.create_index(space.name, 'primary', true, {
        {field = 2, type = 'string',},
        {field = 5, type = 'string',},
    })

    encoded = utils.encode_cursor(row, 'entity')
    t.assert_items_equals(utils.decode_cursor(encoded), pk_row2)

    helper.drop_index(space.name, index_name)

    space:drop()

    res, err = utils.decode_cursor()
    t.assert_equals(res, nil)
    t.assert_equals(err, 'Failed to decode cursor: "nil"')

    res, err = utils.decode_cursor('')
    t.assert_equals(res, nil)
    t.assert_equals(err, 'Failed to decode cursor: ""')

    res, err = utils.decode_cursor(1)
    t.assert_equals(res, nil)
    t.assert_equals(err, 'Failed to decode cursor: "1"')
end

g.test_capitalize = function()
    local res = utils.capitalize('abcdefghijklmnopqrstuvwxyz', false)
    t.assert_equals(res, 'abcdefghijklmnopqrstuvwxyz')
    res = utils.capitalize('abcdefghijklmnopqrstuvwxyz', true)
    t.assert_equals(res, 'ABCDEFGHIJKLMNOPQRSTUVWXYZ')
end

g.test_is_box_null = function()
    t.assert_equals(utils.is_box_null(nil), false)
    t.assert_equals(utils.is_box_null('aaa'), false)
    t.assert_equals(utils.is_box_null(box.NULL), true)
end

g.test_compat = function()
    local function map_n(tbl)
        local counter = 0
        for _, _ in pairs(tbl) do
            counter = counter + 1
        end
        return counter
    end

    local cache = {}

    local compat = utils.to_compat(cache, nil)
    t.assert_equals(compat, nil)
    t.assert_equals(utils.from_compat(cache, nil), nil)

    local test_names = {
        {'s1-master', 's1_master', 1},
        {'_bucket', '_bucket', 1},
        {
            'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^&*()-=`\\/?<>,.',
            'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ____________________',
            2,
        },
    }

    for _, test_name in pairs(test_names) do
        compat = utils.to_compat(cache, test_name[1])
        t.assert_equals(compat, test_name[2])
        t.assert_equals(utils.from_compat(cache, compat), test_name[1])
        t.assert_equals(map_n(cache), test_name[3])
    end
end

g.test_get_tnt_version = function()
    local version = rawget(_G, '_TARANTOOL')

    local versions = {
        { '2.8.1-0-ge2a1ec0c2', { major = 2, minor = 8, patch = 1, enterprise = false }},
        { '2.8.1-0-ge2a1ec0c2-r405', { major = 2, minor = 8, patch = 1, enterprise = true }},
        { '2.10.0-beta1-0-g7da4b1438', { major = 2, minor = 10, patch = 0, enterprise = false }},
        { '2.10.0-beta1-0-g7da4b1438-r427', { major = 2, minor = 10, patch = 0, enterprise = true }},
    }

    for _, ver in ipairs(versions) do
        rawset(_G, '_TARANTOOL', ver[1])
        t.assert_items_equals(utils.get_tnt_version(), ver[2])
    end

    rawset(_G, '_TARANTOOL', version)
end
