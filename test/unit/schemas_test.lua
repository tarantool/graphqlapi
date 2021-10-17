local t = require('luatest')
local g = t.group('schemas')

require('test.helper')
local schemas = require('graphqlapi.schemas')

g.test_default_schema = function()
    schemas.set_invalid()
    t.assert_equals(schemas.is_invalid(), true)
    schemas.reset_invalid()
    t.assert_equals(schemas.is_invalid(), false)
    t.assert_items_equals(schemas.list_schemas(), {'Default'})
    schemas.remove_schema()
    t.assert_items_equals(schemas.list_schemas(), {})
end

g.test_custom_schema = function()
    schemas.set_invalid('schema')
    t.assert_equals(schemas.is_invalid('schema'), true)
    schemas.reset_invalid('schema')
    t.assert_equals(schemas.is_invalid('schema'), false)
    t.assert_items_equals(schemas.list_schemas(), {'schema'})
    schemas.remove_schema('schema')
    t.assert_items_equals(schemas.list_schemas(), {})
end

g.test_multiple_schemas = function()
    schemas.set_invalid()
    t.assert_equals(schemas.is_invalid(), true)
    schemas.set_invalid('schema')
    t.assert_equals(schemas.is_invalid('schema'), true)
    schemas.reset_invalid()
    t.assert_equals(schemas.is_invalid(), false)
    schemas.reset_invalid('schema')
    t.assert_equals(schemas.is_invalid('schema'), false)
    t.assert_items_equals(schemas.list_schemas(), {'schema', 'Default'})
    schemas.remove_all()
    t.assert_items_equals(schemas.list_schemas(), {})
end
