local t = require('luatest')
local g = t.group('schemas')

require('test.helper')
local schemas = require('graphqlapi.schemas')

g.test_default_schema = function()
    schemas.set_invalid()
    t.assert_equals(schemas.is_invalid(), true)
    schemas.reset_invalid()
    t.assert_equals(schemas.is_invalid(), false)
    t.assert_items_equals(schemas.schemas_list(), {'Default'})
    schemas.remove_schema()
    t.assert_items_equals(schemas.schemas_list(), {})
end

g.test_custom_schema = function()
    schemas.set_invalid('schema')
    t.assert_equals(schemas.is_invalid('schema'), true)
    schemas.reset_invalid('schema')
    t.assert_equals(schemas.is_invalid('schema'), false)
    t.assert_items_equals(schemas.schemas_list(), {'schema'})
    schemas.remove_schema('schema')
    t.assert_items_equals(schemas.schemas_list(), {})
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
    t.assert_items_equals(schemas.schemas_list(), {'schema', 'Default'})
    schemas.remove_all()
    t.assert_items_equals(schemas.schemas_list(), {})
end

g.test_graphql_cache = function()
    local test_query_ast = {'test_value'}
    t.assert_equals(schemas.cache_get('non_existent_schema', 'test_query'), nil)
    schemas.cache_set('some_schema', 'test_query', test_query_ast)

    t.assert_items_equals(schemas.cache_get('some_schema', 'test_query'), test_query_ast)
    schemas.set_invalid('some_schema')
    t.assert_equals(schemas.cache_get('some_schema', 'test_query'), nil)
    schemas.remove_all()

    t.assert_items_equals(schemas.schemas_list(), {})
end
