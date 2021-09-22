local t = require('luatest')
local g = t.group('fragments')

local helper = require('test.helper')

local errors = require('errors')

local fragments = require('graphqlapi.fragments')

g.after_each(function()
    fragments.stop()
end)

g.test_apply_fragment = function()
    local fragment = {}
    local ok, err = fragments.apply_fragment(fragment)
    t.assert_equals(ok, nil)
    t.assert_equals(err.err, 'attempt to call a nil value')

    fragment = { fragment = nil }
    ok, err = fragments.apply_fragment(fragment)
    t.assert_equals(ok, nil)
    t.assert_equals(err.err, 'attempt to call a nil value')

    fragment = { fragment = function() return 1+nil end }
    ok, err = fragments.apply_fragment(fragment)
    t.assert_equals(ok, nil)
    t.assert_str_contains(err.err, 'attempt to perform arithmetic on a nil value')

    fragment = { fragment = function() return true end }
    local res = fragments.apply_fragment(fragment)
    t.assert_equals(res, true)

    local my_error = errors.new_class('My error')

    fragment = { fragment = function() return nil, my_error:new("space 'absent_space' doesn't exists") end }
    ok, err = fragments.apply_fragment(fragment)
    t.assert_equals(ok, nil)
    t.assert_str_contains(err.err, "space 'absent_space' doesn't exists")
    t.assert_equals(err.file, nil)
    t.assert_equals(err.stack, nil)
end

g.test_load_fragment = function()
    package.path = helper.project_root.. '/test/fragments/suite1/?.lua;' .. package.path

    -- check non-existent file
    local ok, err = fragments.load_fragment('test/fragments/suite1/empty1.lua')
    t.assert_equals(ok, nil)
    t.assert_equals(err,
        'cannot open '..(package.searchroot())..'/test/fragments/suite1/empty1.lua: No such file or directory')

    -- check empty file
    ok, err = fragments.load_fragment('test/fragments/suite1/empty.lua')
    t.assert_equals(ok, nil)
    t.assert_str_contains(err.err, 'fragment must be a table')

    -- check file with syntax error
    ok, err = fragments.load_fragment('test/fragments/suite1/syntax_error.lua')
    t.assert_equals(ok, nil)
    t.assert_str_contains(err, 'unexpected symbol near \'111\'')

    -- check file with missing fragment
    ok, err = fragments.load_fragment('test/fragments/suite1/missing_fragment.lua')
    t.assert_equals(ok, nil)
    t.assert_str_contains(err.err, 'fragment must contain \'fragment\' function')

    -- check file with invalid spaces
    ok, err = fragments.load_fragment('test/fragments/suite1/invalid_spaces.lua')
    t.assert_equals(ok, nil)
    t.assert_str_contains(err.err, 'fragment.spaces must be a table')

    -- check file with invalid space in spaces array
    ok, err = fragments.load_fragment('test/fragments/suite1/invalid_space.lua')
    t.assert_equals(ok, nil)
    t.assert_str_contains(err.err, 'fragment.spaces item \'1\' must be a string')

    -- check file with missing spaces
    local fragment = fragments.load_fragment('test/fragments/suite1/missing_spaces.lua')
    t.assert_equals(type(fragment.fragment), 'function')

    -- check file with valid fragment
    fragment = fragments.load_fragment('test/fragments/suite1/valid_fragment.lua')
    t.assert_items_equals(fragment.spaces, {'fragment'})
    t.assert_equals(type(fragment.fragment), 'function')
    t.assert_equals(type(fragment.f), 'function')
end

g.test_init_stop = function()
    package.path = helper.project_root.. '/test/fragments/suite1/?.lua;' .. package.path
    fragments.init('test/fragments/suite1')
    t.assert_items_equals(fragments.list_fragments(), {
        'test.fragments.suite1.missing_spaces',
        'test.fragments.suite1.valid_fragment',
        'test.fragments.suite1.spaces.spaces',
    })
    t.assert_items_equals(fragments.list_loaded(), {'module'})

    fragments.stop()
    t.assert_items_equals(fragments.list_fragments(), {})
    t.assert_equals(package.loaded['module'], nil)
end

g.test_remove_fragment = function()
    package.path = helper.project_root.. '/test/fragments/suite1/?.lua;' .. package.path
    fragments.init('test/fragments/suite1/')
    t.assert_items_equals(fragments.list_fragments(), {
        'test.fragments.suite1.missing_spaces',
        'test.fragments.suite1.valid_fragment',
        'test.fragments.suite1.spaces.spaces',
    })
    t.assert_items_equals(fragments.list_loaded(), {'module'})

    fragments.remove_fragment('test/fragments/suite1/valid_fragment.lua')
    t.assert_items_equals(fragments.list_fragments(), {
        'test.fragments.suite1.missing_spaces',
        'test.fragments.suite1.spaces.spaces',
    })

    fragments.stop()

    fragments.init('./test/fragments/suite1/')
    t.assert_items_equals(fragments.list_fragments(), {
        'test.fragments.suite1.missing_spaces',
        'test.fragments.suite1.valid_fragment',
        'test.fragments.suite1.spaces.spaces',
    })
    t.assert_items_equals(fragments.list_loaded(), {'module'})

    fragments.remove_fragment('test.fragments.suite1.valid_fragment')
    t.assert_items_equals(fragments.list_fragments(), {
        'test.fragments.suite1.missing_spaces',
        'test.fragments.suite1.spaces.spaces',
    })
end

g.test_remove_fragment_by_space_name = function ()
    package.path = helper.project_root.. '/test/fragments/suite1/?.lua;' .. package.path
    fragments.init('test/fragments/suite1/')
    t.assert_items_equals(fragments.list_fragments(), {
        'test.fragments.suite1.missing_spaces',
        'test.fragments.suite1.valid_fragment',
        'test.fragments.suite1.spaces.spaces',
    })
    t.assert_items_equals(fragments.list_loaded(), {'module'})

    fragments.remove_fragment_by_space_name('fragment')

    t.assert_items_equals(fragments.list_fragments(), {
        'test.fragments.suite1.missing_spaces',
        'test.fragments.suite1.spaces.spaces',
    })
end

g.test_update_space_fragments = function()
    _G._test_fragment = 0
    package.path = helper.project_root.. '/test/fragments/suite1/?.lua;' .. package.path
    fragments.init('test/fragments/suite1')
    t.assert_items_equals(fragments.list_fragments(), {
        'test.fragments.suite1.missing_spaces',
        'test.fragments.suite1.valid_fragment',
        'test.fragments.suite1.spaces.spaces',
    })
    t.assert_equals(_G._test_fragment, 1)
    fragments.update_space_fragments('fragment')
    t.assert_equals(_G._test_fragment, 2)
end

g.test_get_func = function()
    package.path = helper.project_root.. '/test/fragments/suite1/?.lua;' .. package.path
    local fragment = fragments.load_fragment('test/fragments/suite1/valid_fragment.lua')
    fragments.apply_fragment(fragment)

    local mod_path = ('test/fragments/suite1'):gsub('/', '%.'):lstrip('.')
    local mod_name = 'valid_fragment'
    local fun_name = 'f'
    local fun = fragments.get_func(mod_path, mod_name, fun_name)
    t.assert_items_equals(fun(), {module = 'fragment function'})
    fragments.stop()

    fragments.init('test/fragments/suite1/')
    fun = fragments.get_func(mod_path, mod_name, fun_name)
    t.assert_items_equals(fun(), {module = 'fragment function'})

    fun = fragments.get_func()
    t.assert_equals(fun, nil)
end
