local t = require('luatest')
local g = t.group('helpers')

require('test.helper')

local fiber = require('fiber')

local defaults = require('graphqlapi.defaults')
local helpers = require('graphqlapi.helpers')

g.test_shared = function()
    helpers.add_shared('schema', 'query', 'request', 'test')
    t.assert_equals(helpers.is_shared('schema', 'query', 'request', 'test'), false)
    helpers.add_shared('schema', 'query', 'request', 'test1')
    t.assert_equals(helpers.is_shared('schema', 'query', 'request', 'test'), true)
    helpers.remove_shared('schema', 'query', 'request', 'test1')
    t.assert_equals(helpers.is_shared('schema', 'query', 'request', 'test'), false)
    helpers.add_shared('schema', 'query', 'request', 'test1')
    helpers.clean_shared('schema', 'query')
    t.assert_equals(helpers.is_shared('schema', 'query', 'request', 'test'), false)
    t.assert_equals(helpers.is_shared('schema', 'query', 'request', 'test1'), false)
    helpers.add_shared('schema', 'query', 'request', 'test')
    t.assert_equals(helpers.is_shared('schema', 'query', 'request', 'test'), false)
    helpers.clean_shared('schema')
end

g.test_on_stop_trigger = function()
    local fired = false
    local stop_handler = function()
        fired = true
    end

    helpers.on_stop(stop_handler)
    helpers.stop()
    helpers.stop()
    t.assert_equals(fired, true)

    fired = false
    helpers.on_stop(stop_handler)
    helpers.on_stop(nil, stop_handler)
    helpers.stop()
    helpers.stop()
    t.assert_equals(fired, false)

    fired = false
    local bad_stop_handler = function()
        fired = true
        error()
    end
    helpers.on_stop(bad_stop_handler)
    helpers.stop()
    helpers.stop()
    t.assert_equals(fired, true)
end

g.test_on_update_schema_trigger = function()
    local fired = false
    local update_schema_handler = function()
        fired = true
    end
    helpers.on_update_schema(update_schema_handler)
    helpers.update_schema()
    helpers.update_schema()
    t.assert_equals(fired, true)

    fired = false
    helpers.on_update_schema(update_schema_handler)
    helpers.on_update_schema(nil, update_schema_handler)
    helpers.update_schema()
    helpers.update_schema()
    t.assert_equals(fired, false)


    fired = false
    local bad_update_schema_handler = function()
        fired = true
        error()
    end
    helpers.on_update_schema(bad_update_schema_handler)
    helpers.update_schema()
    helpers.update_schema()
    t.assert_equals(fired, true)

    helpers.stop()
end

g.test_on_update_config_trigger = function()
    local fired = false
    local update_config_handler = function()
        fired = true
    end
    helpers.on_update_config(update_config_handler)

    local fiber_name
    for _, f in pairs(fiber.info()) do
        if f.name == 'gql_config' then
            fiber_name = f.name
        end
    end

    t.assert_equals(fiber_name, 'gql_config')

    helpers.update_config()
    fiber.yield()
    helpers.update_config()
    fiber.yield()
    t.assert_equals(fired, true)

    fired = false
    helpers.on_update_config(update_config_handler)
    helpers.on_update_config(nil, update_config_handler)
    helpers.update_config()
    fiber.yield()
    helpers.update_config()
    fiber.yield()
    t.assert_equals(fired, false)

    fired = false
    local bad_update_config_handler = function()
        fired = true
        error()
    end
    helpers.on_update_config(bad_update_config_handler)
    helpers.update_config()
    fiber.yield()
    helpers.update_config()
    fiber.yield()
    t.assert_equals(fired, true)

    helpers.stop()

    helpers.on_update_config(update_config_handler)
    for _ = 1, defaults.CONFIG_UPDATE_CHANNEL_CAPACITY+2 do
        helpers.update_config()
    end
    fiber.yield()
    helpers.stop()
end
