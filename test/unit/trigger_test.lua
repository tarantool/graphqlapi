local t = require('luatest')
local g = t.group('trigger')

local test_helper = require('test.helper')

local fiber = require('fiber')

local helpers = require('graphqlapi.helpers')
local trigger = require('graphqlapi.trigger')

local triggers_number = function()
    return #box.space._space:on_replace()
end

g.test_init_stop = function()
    trigger.init()
    t.assert_equals(triggers_number(), 1)
    trigger.init()
    t.assert_equals(triggers_number(), 1)
    trigger.stop()
    t.assert_equals(triggers_number(), 0)
    trigger.stop()
    t.assert_equals(triggers_number(), 0)

    local custom_trigger = function()
    end

    box.space._space:on_replace(custom_trigger)
    t.assert_equals(triggers_number(), 1)
    trigger.init()
    t.assert_equals(triggers_number(), 2)
    trigger.stop()
    t.assert_equals(triggers_number(), 1)
    t.assert_equals(box.space._space:on_replace()[1], custom_trigger)
    box.space._space:on_replace(nil, custom_trigger)
    t.assert_equals(triggers_number(), 0)
end

g.test_space_trigger = function()
    trigger.init()
    local space = test_helper.create_space()
    t.assert_equals(triggers_number(), 1)

    local fiber_name
    for _, f in pairs(fiber.info()) do
        if f.name == 'gql_schema' then
            fiber_name = f.name
        end
    end

    t.assert_equals(fiber_name, 'gql_schema')

    space:drop()
    trigger.stop()
end

g.test_updater_init = function()
    trigger.init()

    local space = test_helper.create_space()

    local fiber_name
    for _, f in pairs(fiber.info()) do
        if f.name == 'gql_schema' then
            fiber_name = f.name
        end
    end

    t.assert_equals(fiber_name, 'gql_schema')

    space:drop()
    trigger.stop()
end

g.test_trigger_exception = function()
    trigger.init()
    local temp = helpers.update_schema
    helpers.update_schema = nil

    local space = test_helper.create_space()

    local fiber_name
    for _, f in pairs(fiber.info()) do
        if f.name == 'gql_schema' then
            fiber_name = f.name
        end
    end

    t.assert_equals(fiber_name, 'gql_schema')

    space:drop()
    trigger.stop()
    helpers.update_schema = temp
end
