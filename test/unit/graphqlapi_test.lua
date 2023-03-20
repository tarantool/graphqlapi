local json = require('json')
local net_box = require('net.box')
local t = require('luatest')
local g = t.group('graphqlapi')

local helper = require('test.helper')

local HOST = 'localhost'
local PORT = 15999
local ENDPOINT = 'admin/graphql'
local url = 'http://'..HOST..':'..tostring(PORT)..'/'..ENDPOINT

local errors = require('errors')
local http = require('http.server')
local http_client = require('http.client').new()
local graphqlapi = require('graphqlapi')
local operations = require('graphqlapi.operations')
local schemas = require('graphqlapi.schemas')
local types = require('graphqlapi.types')

local httpd

local function stop()
    graphqlapi.stop()
    if httpd then
        httpd:stop()
        httpd = nil
    end
end

g.after_each(stop)

local function call_execute_graphql(req, variables, schema_name)
    return net_box.self:call('execute_graphql', { req, variables, schema_name })
end

g.test_init_stop = function()
    -- test both HTTP and IPROTO
    package.path = helper.project_root.. '/test/fragments/suite1/?.lua;' .. package.path
    httpd = http.new(HOST, PORT,{ log_requests = false })
    httpd:start()
    graphqlapi.init(httpd, nil, nil, 'test/fragments/suite1', { enable_iproto = true })
    t.assert_equals(graphqlapi.get_fragments_dir(), 'test/fragments/suite1')
    t.assert_equals(graphqlapi.get_endpoint(), 'admin/graphql')
    stop()

    -- test incorrect HTTP arguments
    local custom_middleware = {
        authorize_request = function(req) -- luacheck: no unused args
            return false
        end,
        render_response = function(resp)
            return resp
        end,
        request_wrapper = function(handler)
            return handler
        end,
    }

    t.assert_error_msg_contains(
        '"http_middleware" or/and "endpoint" arguments must not be provided if "httpd" is not',
        graphqlapi.init,
        nil, custom_middleware, nil, 'test/fragments/suite1', { enable_iproto = true }
    )

    t.assert_error_msg_contains(
        'Neither GraphQL-over-HTTP nor GraphQL-over-IPROTO interfaces are requested to be initialized',
        graphqlapi.init,
        nil, nil, nil, 'test/fragments/suite1'
    )
end

g.test_set_get_fragments_dir = function()
    package.path = helper.project_root.. '/test/fragments/suite1/?.lua;' .. package.path
    httpd = http.new(HOST, PORT,{ log_requests = false })
    httpd:start()
    graphqlapi.init(httpd, nil, nil, 'test/fragments/suite1')
    graphqlapi.set_fragments_dir('test/fragments/suite1')
    t.assert_equals(graphqlapi.get_fragments_dir(), 'test/fragments/suite1')
end

g.test_set_get_endpoint = function()
    package.path = helper.project_root.. '/test/fragments/suite1/?.lua;' .. package.path
    httpd = http.new(HOST, PORT,{ log_requests = false })
    httpd:start()
    graphqlapi.init(httpd, nil, nil, 'test/fragments/suite1')
    graphqlapi.set_endpoint(ENDPOINT)
    t.assert_equals(graphqlapi.get_endpoint(), 'admin/graphql')
    graphqlapi.set_endpoint(ENDPOINT..'/')
    t.assert_equals(graphqlapi.get_endpoint(), 'admin/graphql')
end

g.test_reload = function()
    package.path = helper.project_root.. '/test/fragments/suite1/?.lua;' .. package.path
    httpd = http.new(HOST, PORT,{ log_requests = false })
    httpd:start()
    graphqlapi.init(httpd, nil, nil, 'test/fragments/suite1')
    local check = function()
        operations.add_query({
            name = 'test_data',
            doc = 'Get test_data',

            kind = types.object({
                name = 'some_data1',
                fields = {
                    some_data1 = types.string
                }
            }),
            callback = 'test.unit.graphqlapi_test.stub_data'
        })

        local query = [[
            {
                "query":"{ test_data {some_data1}}",
                "variables":null
            }
        ]]

        local response = http_client:post(url, query)
        t.assert_items_equals(json.decode(response.body), { data = { test_data = {some_data1 = 'some_data1'} }})
        t.assert_equals(response.status, 200)
    end

    check()
    graphqlapi.reload()
    t.assert_equals(rawget(_G, '__GRAPHQLAPI_MODELS_DIR'), 'test/fragments/suite1')
    check()
end

g.test_custom_middleware = function()
    local custom_middleware = {
        authorize_request = function(req) -- luacheck: no unused args
            return false
        end,
        render_response = function(resp)
            return resp
        end,
        request_wrapper = function(handler)
            return handler
        end,
    }
    package.path = helper.project_root.. '/test/fragments/suite1/?.lua;' .. package.path
    httpd = http.new(HOST, PORT,{ log_requests = false })
    httpd:start()
    graphqlapi.init(httpd, custom_middleware, nil, 'test/fragments/suite1')

    t.assert_equals(graphqlapi.get_middleware().authorize_request(), false)

    local query = [[
        {
            "query":"
                query {
                    space_info(name: []) {
                        name
                    }
                }",
            "variables":null
        }
    ]]

    local response = http_client:post(url, query)
    t.assert_equals(response.body, "{\"errors\":[{\"message\":\"Unauthorized\"}]}")
    t.assert_equals(response.status, 401)

    stop()

    httpd = http.new(HOST, PORT,{ log_requests = false })
    httpd:start()
    graphqlapi.init(httpd, nil, nil, 'test/fragments/suite1')

    graphqlapi.set_middleware(custom_middleware)

    response = http_client:post(url, query)
    t.assert_equals(response.body, "{\"errors\":[{\"message\":\"Unauthorized\"}]}")
    t.assert_equals(response.status, 401)
end

g.test_invalid_requests = function()
    package.path = helper.project_root.. '/test/fragments/suite1/?.lua;' .. package.path
    httpd = http.new(HOST, PORT,{ log_requests = false })
    httpd:start()
    graphqlapi.init(httpd, nil, nil, 'test/fragments/suite1')
    -- check empty graphql query
    local query = ''
    local response = http_client:post(url, query)
    t.assert_equals(response.body, "{\"errors\":[{\"message\":\"Expected a non-empty request body\"}]}")
    t.assert_equals(response.status, 400)

    -- check empty string graphql query
    query = '""'
    response = http_client:post(url, query)
    t.assert_equals(response.body, "{\"errors\":[{\"message\":\"Body should be a valid JSON\"}]}")
    t.assert_equals(response.status, 400)

    -- check empty field graphql query
    query = '{"field":{}}'
    response = http_client:post(url, query)
    t.assert_equals(response.body, "{\"errors\":[{\"message\":\"Body should have 'query' field\"}]}")
    t.assert_equals(response.status, 400)

    -- check incorrect operation name query
    query = [[
        {
            "operationName": true,
            "query":"query MyQuery {space_info(name: [qqqq]) {name}}",
            "variables":null
        }
    ]]
    response = http_client:post(url, query)
    t.assert_equals(response.body, "{\"errors\":[{\"message\":\"'operationName' should be string\"}]}")
    t.assert_equals(response.status, 400)

    -- check incorrect variable query
    query = [[
        {
            "query":"query {space_info(name: [qqqq]) {name}}",
            "variables":"variable"
        }
    ]]
    response = http_client:post(url, query)
    t.assert_equals(response.body, "{\"errors\":[{\"message\":\"'variables' should be a dictionary\"}]}")
    t.assert_equals(response.status, 400)

    -- check incorrect syntax query
    query = [[
        {
            "operationName": "MyQuery",
            "query":"query MyQuery {space_info(name:) {name}}",
            "variables":null
        }
    ]]
    response = http_client:post(url, query)
    t.assert_equals(
        response.body,
        "{\"errors\":[{\"message\":\"1.32: syntax error, unexpected )\"}]}"
    )
    t.assert_equals(response.status, 400)
end

g.test_execute_graphql_data_and_or_errors = function()
    package.path = helper.project_root.. '/test/fragments/suite1/?.lua;' .. package.path
    httpd = http.new(HOST, PORT,{ log_requests = false })
    httpd:start()
    graphqlapi.init(httpd, nil, nil, 'test/fragments/suite1')
    -- test return data without errors
    do
        operations.add_query({
            name = 'test_data',
            doc = 'Get test_data',

            kind = types.object({
                name = 'some_data1',
                fields = {
                    some_data1 = types.string
                }
            }),
            callback = 'test.unit.graphqlapi_test.stub_data'
        })

        local query = [[
            {
                "query":"{ test_data {some_data1}}",
                "variables":null
            }
        ]]

        local response = http_client:post(url, query)
        t.assert_items_equals(json.decode(response.body), { data = { test_data = {some_data1 = 'some_data1'} }})
        t.assert_equals(response.status, 200)
        http_client:post(url, query)
    end

    -- test return data and errors
    do
        operations.add_query({
            name = 'test_and_errors',
            doc = 'Get test_and_errors',

            kind = types.object({
                name = 'some_data2',
                fields = {
                    some_data2 = types.string
                }
            }),
            callback = 'test.unit.graphqlapi_test.stub_data_errors'
        })

        local query = [[
            {
                "query":"{ test_and_errors {some_data2}}",
                "variables":null
            }
        ]]

        local response = http_client:post(url, query)
        t.assert_equals(json.decode(response.body).errors[1].message, "Some error #1")
        t.assert_equals(json.decode(response.body).errors[2].message, "Some error #2")
        t.assert_equals(json.decode(response.body).errors[3].message, "Some error #3")
        t.assert_items_equals(json.decode(response.body).data, { test_and_errors = {some_data2 = 'some_data2'} })
        t.assert_equals(response.status, 200)
    end

    -- test return only simple string error
    do
        operations.add_query({
            name = 'test_errors_string',
            doc = 'Get test_errors_string',

            kind = types.object({
                name = 'some_data3',
                fields = {
                    some_data3 = types.string
                }
            }),
            callback = 'test.unit.graphqlapi_test.stub_error_string'
        })

        local query = [[
            {
                "query":"{ test_errors_string {some_data3}}",
                "variables":null
            }
        ]]

        local response = http_client:post(url, query)
        t.assert_equals(json.decode(response.body).errors[1].message, 'Simple string error')
        t.assert_equals(response.status, 200)
    end

    -- test return only simple error
    do
        operations.add_query({
            name = 'test_errors_error',
            doc = 'Get test_errors_error',

            kind = types.object({
                name = 'some_data4',
                fields = {
                    some_data4 = types.string
                }
            }),
            callback = 'test.unit.graphqlapi_test.stub_error_error'
        })

        local query = [[
            {
                "query":"{ test_errors_error {some_data4}}",
                "variables":null
            }
        ]]

        local response = http_client:post(url, query)
        t.assert_equals(json.decode(response.body).errors[1].message, 'Simple error()')
        t.assert_equals(response.status, 200)
    end

    -- test return only array of errors
    do
        operations.add_query({
            name = 'test_errors_array',
            doc = 'Get test_errors_error',

            kind = types.object({
                name = 'some_data5',
                fields = {
                    some_data5 = types.string
                }
            }),
            callback = 'test.unit.graphqlapi_test.stub_errors_array'
        })

        local query = [[
            {
                "query":"{ test_errors_array {some_data5}}",
                "variables":null
            }
        ]]

        local response = http_client:post(url, query)
        t.assert_equals(json.decode(response.body).errors[1].message, "Some error #1")
        t.assert_equals(json.decode(response.body).errors[2].message, "Some error #2")
        t.assert_equals(json.decode(response.body).errors[3].message, "Some error #3")
        t.assert_equals(response.status, 200)
    end
end

g.test_invalid_requests_iproto = function()
    package.path = helper.project_root.. '/test/fragments/suite1/?.lua;' .. package.path
    graphqlapi.init(nil, nil, nil, 'test/fragments/suite1', { enable_iproto = true })
    -- check nil graphql request
    local response, err = call_execute_graphql()
    t.assert_equals(response, nil)
    t.assert_equals(err[1].str, 'GraphQL over IPROTO parsing failed: Expected a non-empty request map')

    -- check incorrect graphql request type
    local request = ''
    response, err = call_execute_graphql(request)
    t.assert_equals(response, nil)
    t.assert_equals(err[1].str, 'GraphQL over IPROTO parsing failed: Expected a non-empty request map')

    -- check incorrect graphql query type
    request = { query = 1 }
    response, err = call_execute_graphql(request)
    t.assert_equals(response, nil)
    t.assert_equals(err[1].str, 'GraphQL over IPROTO parsing failed: Expected a non-empty "query" string')

    -- check empty graphql query
    request = { query = '' }
    response, err = call_execute_graphql(request)
    t.assert_equals(response, nil)
    t.assert_equals(err[1].str, 'GraphQL over IPROTO parsing failed: Expected a non-empty "query" string')

    -- check incorrect graphql operationName type
    request = {
        query = 'query MyQuery {space_info(name: [qqqq]) {name}}',
        operationName = 1,
    }
    response, err = call_execute_graphql(request)
    t.assert_equals(response, nil)
    t.assert_equals(err[1].str, 'GraphQL over IPROTO parsing failed: Expected a non-empty "operationName" string')

    -- check incorrect operation name query
    request = {
        operationName = true,
        query = 'query MyQuery {space_info(name: [qqqq]) {name}}',
    }

    response, err = call_execute_graphql(request)
    t.assert_equals(response, nil)
    t.assert_equals(err[1].str, 'GraphQL over IPROTO parsing failed: Expected a non-empty "operationName" string')

    -- check incorrect variables type
    request = {
            query = 'query {space_info(name: [qqqq]) {name}}',
            variables = 'variable',
    }

    response, err = call_execute_graphql(request)
    t.assert_equals(response, nil)
    t.assert_equals(err[1].str, 'GraphQL over IPROTO parsing failed: Expected "variables" should be a dictionary')

    -- check incorrect schema_name type
    request = {
            query = 'query {space_info(name: [qqqq]) {name}}',
            schema = 1,
    }

    response, err = call_execute_graphql(request)
    t.assert_equals(response, nil)
    t.assert_equals(err[1].str, 'GraphQL over IPROTO parsing failed: Expected a non-empty "schema" string')

    -- check empty schema_name
    request = {
        query = 'query {space_info(name: [qqqq]) {name}}',
        schema = '',
    }

    response, err = call_execute_graphql(request)
    t.assert_equals(response, nil)
    t.assert_equals(err[1].str, 'GraphQL over IPROTO parsing failed: Expected a non-empty "schema" string')


    -- check incorrect syntax query
    request = {
        query = 'query":"query MyQuery {space_info(name:) {name}}',
        operationName = 'MyQuery',
    }

    response, err = call_execute_graphql(request)
    t.assert_equals(response, nil)
    t.assert_equals(
        err[1].str,
        'GraphQL over IPROTO parsing failed: 1.6-8: syntax error, unexpected STRING, expecting ( or @ or {'
    )
end

g.test_graphql_iproto = function()
    package.path = helper.project_root.. '/test/fragments/suite1/?.lua;' .. package.path
    graphqlapi.init(nil, nil, nil, 'test/fragments/suite1', { enable_iproto = true })
    -- test return data without errors
    do
        operations.add_query({
            name = 'test_data',
            doc = 'Get test_data',

            kind = types.object({
                name = 'some_data1',
                fields = {
                    some_data1 = types.string
                }
            }),
            callback = 'test.unit.graphqlapi_test.stub_data'
        })

        local query = '{ test_data {some_data1}}'
        local response, err = call_execute_graphql({ query = query })
        t.assert_equals(err, nil)
        t.assert_items_equals(response, { test_data = {some_data1 = 'some_data1'} })
    end

    -- test return data and errors
    do
        operations.add_query({
            name = 'test_and_errors',
            doc = 'Get test_and_errors',

            kind = types.object({
                name = 'some_data2',
                fields = {
                    some_data2 = types.string
                }
            }),
            callback = 'test.unit.graphqlapi_test.stub_data_errors'
        })

        local query = '{ test_and_errors {some_data2}}'
        local response, err = call_execute_graphql({ query = query })
        t.assert_equals(err[1].str, "GraphQL request error: Some error #1")
        t.assert_equals(err[2].str, "GraphQL request error: Some error #2")
        t.assert_equals(err[3].str, "GraphQL request error: Some error #3")
        t.assert_items_equals(response, { test_and_errors = {some_data2 = 'some_data2'} })
    end

    -- test return only simple string error
    do
        operations.add_query({
            name = 'test_errors_string',
            doc = 'Get test_errors_string',

            kind = types.object({
                name = 'some_data3',
                fields = {
                    some_data3 = types.string
                }
            }),
            callback = 'test.unit.graphqlapi_test.stub_error_string'
        })

        local query = '{ test_errors_string {some_data3}}'
        local response, err = call_execute_graphql({ query = query })
        t.assert_equals(response, nil)
        t.assert_equals(err[1].str, 'GraphQL over IPROTO execution failed: Simple string error')
    end

    -- test return only simple error
    do
        operations.add_query({
            name = 'test_errors_error',
            doc = 'Get test_errors_error',

            kind = types.object({
                name = 'some_data4',
                fields = {
                    some_data4 = types.string
                }
            }),
            callback = 'test.unit.graphqlapi_test.stub_error_error'
        })

        local query = '{ test_errors_error {some_data4}}'
        local response, err = call_execute_graphql({ query = query })
        t.assert_equals(response, nil)
        t.assert_equals(err[1].str, 'GraphQL over IPROTO execution failed: Simple error()')
    end

    -- test return only array of errors
    do
        operations.add_query({
            name = 'test_errors_array',
            doc = 'Get test_errors_error',
            schema = 'test_schema',
            kind = types.object({
                name = 'some_data5',
                fields = {
                    some_data5 = types.string
                }
            }),
            callback = 'test.unit.graphqlapi_test.stub_errors_array'
        })

        local query = '{ test_errors_array {some_data5}}'
        local response, err = call_execute_graphql({ query = query, schema = 'test_schema' })
        t.assert_equals(response, nil)
        t.assert_equals(err[1].str, "GraphQL request error: Some error #1")
        t.assert_equals(err[2].str, "GraphQL request error: Some error #2")
        t.assert_equals(err[3].str, "GraphQL request error: Some error #3")
    end
end

g.test_schema_caching = function()
    package.path = helper.project_root.. '/test/fragments/suite1/?.lua;' .. package.path
    httpd = http.new(HOST, PORT,{ log_requests = false })
    httpd:start()
    graphqlapi.init(httpd, nil, nil, 'test/fragments/suite1')
    -- test return data without errors
    do
        operations.add_query({
            name = 'test_data',
            doc = 'Get test_data',

            kind = types.object({
                name = 'some_data1',
                fields = {
                    some_data1 = types.string
                }
            }),
            callback = 'test.unit.graphqlapi_test.stub_data'
        })

        local query = [[
            {
                "query":"{ test_data {some_data1}}",
                "variables":null
            }
        ]]

        t.assert_equals(schemas.is_invalid(), true)

        local response = http_client:post(url, query)
        t.assert_items_equals(json.decode(response.body), { data = { test_data = {some_data1 = 'some_data1'} }})
        t.assert_equals(response.status, 200)
        t.assert_equals(schemas.is_invalid(), false)
        http_client:post(url, query)
        t.assert_equals(schemas.is_invalid(), false)
    end
end

g.test_version = function()
    t.assert_type(require('graphqlapi')._VERSION, 'string')
end

local function stub_data()
    return {some_data1 = 'some_data1'}
end

local function stub_data_errors()
    local request_error = errors.new_class('GraphQL request error')
    local err = {}
    for i = 1, 3, 1 do
        local _err = request_error:new('Some error #'..tostring(i))
        table.insert(err, _err)
    end
    return {some_data2 = 'some_data2'}, err
end

local function stub_error_string()
    return nil, 'Simple string error'
end

local function stub_error_error()
    error('Simple error()', 0)
end

local function stub_errors_array()
    local request_error = errors.new_class('GraphQL request error')
    local err = {}
    for i = 1, 3, 1 do
        local _err = request_error:new('Some error #'..tostring(i))
        table.insert(err, _err)
    end
    return nil, err
end

return {
    stub_data = stub_data,
    stub_data_errors = stub_data_errors,
    stub_error_string = stub_error_string,
    stub_error_error = stub_error_error,
    stub_errors_array = stub_errors_array,
}

