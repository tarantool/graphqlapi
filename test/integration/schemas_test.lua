local fio = require('fio')
local t = require('luatest')
local g = t.group('schemas')

local helper = require('test.helper')

local schemas = require('graphqlapi.schemas')

g.before_all(function()
    local cluster_config = table.deepcopy(helper.cluster_config)
    g.cluster = helper.Cluster:new(cluster_config)
    g.cluster:start()
    helper.retrying({}, function()
        t.assert_equals(helper.list_cluster_issues(g.cluster.main_server), {})
    end)
end)

g.after_all(function()
    g.cluster:stop()
    fio.rmtree(g.cluster.datadir)
    g.cluster = nil
end)

g.test_default_schema = function()
    local router = g.cluster:server('router')
    local res, ide = router.net_box:eval([[
        schemas = require('graphqlapi.schemas')
        graphqlide = require('graphqlide')
        schemas.set_invalid()
        return schemas.is_invalid(), graphqlide.get_endpoints()
    ]])
    t.assert_equals(res, true)
    t.assert_items_equals(ide, {schema = {default = false, path = "admin/graphql"}})

    res, ide = router.net_box:eval([[
        schemas.reset_invalid()
        return schemas.is_invalid(), graphqlide.get_endpoints()
    ]])
    t.assert_equals(res, false)
    t.assert_items_equals(ide, {schema = {default = false, path = "admin/graphql"}})

    res = router.net_box:eval([[ return schemas.schemas_list()]])
    t.assert_items_equals(res, {'Default'})

    res, ide = router.net_box:eval([[
        schemas.remove_schema()
        return schemas.schemas_list(), graphqlide.get_endpoints()
    ]])
    t.assert_items_equals(res, {})
    t.assert_items_equals(ide, {})
end

g.test_custom_schema = function()
    local router = g.cluster:server('router')

    local res, ide = router.net_box:eval([[
        schemas = require('graphqlapi.schemas')
        graphqlide = require('graphqlide')
        schemas.set_invalid('schema')
        return schemas.is_invalid('schema'), graphqlide.get_endpoints()
    ]])
    t.assert_equals(res, true)
    t.assert_items_equals(ide, {schema = {default = false, path = "admin/graphql"}})

    res, ide = router.net_box:eval([[
        schemas.reset_invalid('schema')
        return schemas.is_invalid('schema'), graphqlide.get_endpoints()
    ]])
    t.assert_equals(res, false)
    t.assert_items_equals(ide, {schema = {default = false, path = "admin/graphql"}})

    res = router.net_box:eval([[ return schemas.schemas_list()]])
    t.assert_items_equals(res, {'schema'})

    res, ide = router.net_box:eval([[
        schemas.remove_schema('schema')
        return schemas.schemas_list(), graphqlide.get_endpoints()
    ]])
    t.assert_items_equals(res, {})
    t.assert_items_equals(ide, {})
end

g.test_multiple_schemas = function()
    local router = g.cluster:server('router')

    local res, ide = router.net_box:eval([[
        schemas = require('graphqlapi.schemas')
        graphqlide = require('graphqlide')
        schemas.set_invalid()
        return schemas.is_invalid(), graphqlide.get_endpoints()
    ]])
    t.assert_equals(res, true)
    t.assert_items_equals(ide, {schema = {default = false, path = "admin/graphql"}})

    res, ide = router.net_box:eval([[
        schemas.set_invalid('schema')
        return schemas.is_invalid('schema'), graphqlide.get_endpoints()
    ]])
    t.assert_equals(res, true)
    t.assert_items_equals(ide,
        {
            Default = {default = false, path = "admin/graphql"},
            schema = {default = false, path = "admin/graphql"}
        }
    )

    res, ide = router.net_box:eval([[
        schemas.reset_invalid()
        return schemas.is_invalid(), graphqlide.get_endpoints()
    ]])

    t.assert_equals(res, false)
    t.assert_items_equals(ide,
        {
            Default = {default = false, path = "admin/graphql"},
            schema = {default = false, path = "admin/graphql"}
        }
    )

    res, ide = router.net_box:eval([[
        schemas.reset_invalid('schema')
        return schemas.is_invalid('schema'), graphqlide.get_endpoints()
    ]])

    t.assert_equals(res, false)
    t.assert_items_equals(ide,
        {
            Default = {default = false, path = "admin/graphql"},
            schema = {default = false, path = "admin/graphql"}
        }
    )

    res = router.net_box:eval([[return schemas.schemas_list()]])
    t.assert_items_equals(res, {'schema', 'Default'})

    res, ide = router.net_box:eval([[
        schemas.set_invalid('schema', true)
        return schemas.is_invalid('schema'), graphqlide.get_endpoints()
    ]])
    t.assert_equals(res, true)
    t.assert_items_equals(ide, {Default = {default = false, path = "admin/graphql"}})

    res, ide = router.net_box:eval([[
        schemas.remove_all()
        return schemas.schemas_list(), graphqlide.get_endpoints()
    ]])
    t.assert_items_equals(res, {})
    t.assert_items_equals(ide, {})
end

g.test_graphql_cache = function()
    local test_query_ast = {'test_value'}

    -- test cache_get on non existent schema
    t.assert_equals(schemas.cache_get('non_existent_schema1', 'test_query'), nil)

    -- test cache_set on non existent schema
    t.assert_equals(schemas.cache_set('non_existent_schema2', 'test_query'), nil)

    schemas.set_invalid('some_schema')
    t.assert_equals(schemas.cache_get('some_schema', 'test_query'), nil)
    schemas.cache_set('some_schema', 'test_query', test_query_ast)
    t.assert_items_equals(schemas.cache_get('some_schema', 'test_query'), test_query_ast)

    for i = 1, 501 do
        schemas.cache_set('some_schema', 'test_query'..tostring(i), {i})
    end

    for i = 2, 501 do
        t.assert_items_equals(schemas.cache_get('some_schema', 'test_query'..tostring(i)), {i})
    end

    schemas.remove_all()

    t.assert_items_equals(schemas.schemas_list(), {})
end
