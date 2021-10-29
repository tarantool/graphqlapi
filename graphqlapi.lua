local log = require('log')
local json = require('json')
local fio = require('fio')
local checks = require('checks')
local errors = require('errors')

local VERSION = '0.0.2-1'

for _, module in ipairs({
    'graphqlapi.cluster',
    'graphqlapi.defaults',
    'graphqlapi.fragments',
    'graphqlapi.funcall',
    'graphqlapi.graphql.execute',
    'graphqlapi.graphql.introspection',
    'graphqlapi.graphql.parse',
    'graphqlapi.graphql.query_util',
    'graphqlapi.graphql.rules',
    'graphqlapi.graphql.schema',
    'graphqlapi.graphql.types',
    'graphqlapi.graphql.util',
    'graphqlapi.graphql.validate_variables',
    'graphqlapi.graphql.validate',
    'graphqlapi.helpers.data',
    'graphqlapi.helpers.data_api',
    'graphqlapi.helpers.schema',
    'graphqlapi.helpers.service',
    'graphqlapi.helpers.service_api',
    'graphqlapi.helpers.spaces',
    'graphqlapi.helpers.spaces_api',
    'graphqlapi.helpers',
    'graphqlapi.middleware',
    'graphqlapi.operations',
    'graphqlapi.schemas',
    'graphqlapi.trigger',
    'graphqlapi.types',
    'graphqlapi.utils',
}) do
    package.loaded[module] = nil
end

local execute = require('graphqlapi.graphql.execute')
local parse = require('graphqlapi.graphql.parse')
local schema = require('graphqlapi.graphql.schema')
local validate = require('graphqlapi.graphql.validate')

local defaults = require('graphqlapi.defaults')
local helpers = require('graphqlapi.helpers')
local fragments = require('graphqlapi.fragments')
local middleware = require('graphqlapi.middleware')
local operations = require('graphqlapi.operations')
local schemas = require('graphqlapi.schemas')
local trigger = require('graphqlapi.trigger')
local types = require('graphqlapi.types')

local _http_middleware = {}
local _endpoint = nil
local _graphql_schema = {}
local _httpd = nil
local _fragments_dir = nil

local e_graphql_internal = errors.new_class('GraphQL internal error')
local e_graphql_parse = errors.new_class('GraphQL parsing failed')
local e_graphql_validate = errors.new_class('GraphQL validation failed')
local e_graphql_execute = errors.new_class('GraphQL execution failed')

local function get_schema(schema_name)
    checks('?string')

    if schemas.is_invalid(schema_name) == true then
        _graphql_schema[schema_name] = nil
        schemas.reset_invalid(schema_name)
    end

    if _graphql_schema[schema_name] ~= nil then
        return _graphql_schema[schema_name]
    end

    local queries = {}
    for name, fun in pairs(operations.get_queries(schema_name)) do
        queries[name] = fun
    end

    local mutations = {}
    for name, fun in pairs(operations.get_mutations(schema_name)) do
        mutations[name] = fun
    end

    local directives = {
        types.include,
        types.skip,
        types.specifiedByUrl,
    }

    for _, directive in pairs(types.get_directives(schema_name) or {}) do
        table.insert(directives, directive)
    end

    if types(schema_name).Query ~= nil then
        types(schema_name).Query = nil
    end

    local root = {
        query = types.object({name = 'Query', fields=queries, schema = schema_name, }),
        directives = directives,
    }

    if types(schema_name).Mutation ~= nil then
        types(schema_name).Mutation = nil
    end

    if next(mutations) then
        root.mutation = types.object({name = 'Mutation', fields=mutations, schema = schema_name, })
    end

    _graphql_schema[schema_name] = schema.create(root, schema_name)

    return _graphql_schema[schema_name]
end

local function http_finalize(obj, status)
    checks('table', '?number')
    return _http_middleware.render_response({
        status = status or 200,
        headers = {['content-type'] = "application/json; charset=utf-8"},
        body = json.encode(obj),
    })
end

local function to_graphql_error(err)
    if type(err) == 'string' then
        err = { err = err}
    end
    if type(err.err) ~= 'string' then
        err.err = json.encode(err.err)
    end

    log.error('%s', err)

    local extensions
    if err.class_name ~= nil or err.stack ~= nil then
        extensions = err.graphql_extensions or {}
        extensions['io.tarantool.errors.class_name'] = err.class_name
        extensions['io.tarantool.errors.stack'] = err.stack
    end

    return {
        message = err.err,
        extensions = extensions,
    }
end

local function _execute_graphql(req)
    if not _http_middleware.authorize_request(req) then
        return http_finalize({
            errors = {{message = "Unauthorized"}},
        }, 401)
    end

    local body = req:read_cached()

    local schema_name = defaults.DEFAULT_SCHEMA_NAME

    if req.headers.schema ~= nil and type(req.headers.schema) == 'string' then
        schema_name = req.headers.schema
    end

    if body == nil or body == '' then
        return http_finalize({
            errors = {{message = "Expected a non-empty request body"}},
        }, 400)
    end

    local parsed = json.decode(body)
    if parsed == nil or type(parsed) ~= 'table' then
        return http_finalize({
            errors = {{message = "Body should be a valid JSON"}},
        }, 400)
    end

    if parsed.query == nil or type(parsed.query) ~= 'string' then
        return http_finalize({
            errors = {{message = "Body should have 'query' field"}},
        }, 400)
    end

    if parsed.operationName ~= nil and type(parsed.operationName) ~= 'string' then
        return http_finalize({
            errors = {{message = "'operationName' should be string"}},
        }, 400)
    end

    if parsed.variables ~= nil and type(parsed.variables) ~= "table" then
        return http_finalize({
            errors = {{message = "'variables' should be a dictionary"}},
        }, 400)
    end

    local operationName = nil

    if parsed.operationName ~= nil then
        operationName = parsed.operationName
    end

    local variables = nil
    if parsed.variables ~= nil then
        variables = parsed.variables
    end
    local query = parsed.query

    local ast, err = e_graphql_parse:pcall(parse.parse, query)

    if not ast then
        log.error('%s', err)
        return http_finalize({
            errors = {{message = err.err}},
        }, 400)
    end

    local schema_obj = get_schema(schema_name)

    err = select(2,e_graphql_validate:pcall(validate.validate, schema_obj, ast))

    if err then
        log.error('%s', err)
        return http_finalize({
            errors = {{message = err.err}},
        }, 400)
    end

    local rootValue = {}
    local data
    data, err = e_graphql_execute:pcall(execute.execute,
        schema_obj, ast, rootValue, variables, operationName
    )

    if err ~= nil then
        if errors.is_error_object(err) or type(err) == 'string' then
            err = {to_graphql_error(err)}
        elseif type(err) == 'table' then
            local _errors = {}
            for _, _err_arr in ipairs(err) do
                if errors.is_error_object(_err_arr) then
                    table.insert(_errors, to_graphql_error(_err_arr))
                elseif type(_err_arr) == 'string' then
                    table.insert(_errors, to_graphql_error(_err_arr))
                else
                    for _, _err in ipairs(_err_arr) do
                        table.insert(_errors, to_graphql_error(_err))
                    end
                end
            end
            err = _errors
        end
    end

    return http_finalize({
        data = data,
        errors = err,
    }, 200)
end

local function execute_graphql(req)
    local resp, err = e_graphql_internal:pcall(_execute_graphql, req)
    if resp == nil then
        log.error('%s', err)
        return {
            status = 500,
            body = tostring(err),
        }
    end
    return resp
end

local function delete_route(httpd, name)
    if httpd then
        local route = httpd.iroutes[name]
        if route then
            httpd.iroutes[name] = nil
            table.remove(httpd.routes, route)
        end

        for n, r in ipairs(httpd.routes) do
            if r.name then
                httpd.iroutes[r.name] = n
            end
        end
    end
end

local function remove_side_slashes(path)
    if path:startswith('/') then
        path = path:sub(2)
    end
    if path:endswith('/') then
        path = path:sub(1, -2)
    end
    return path
end

local function set_endpoint(endpoint, opts)
    checks('string', '?table')
    delete_route(_httpd, _endpoint)
    _endpoint = remove_side_slashes(endpoint)
    rawset(_G, '__GRAPHQLAPI_ENDPOINT', _endpoint)
    opts = opts or {}
    opts.path = _endpoint
    opts.name = _endpoint
    opts.method = opts.method or 'POST'
    opts.public = opts.public or false
    _httpd:route(opts, _http_middleware.request_wrapper(execute_graphql))
end

local function get_endpoint()
    return _endpoint
end

local function _set_middleware(http_middleware)
    if http_middleware == nil then
        _http_middleware = middleware
        return
    end

    local m = {}
    if http_middleware.render_response == nil  then
        m.render_response = _http_middleware.render_response or middleware.render_response
    else
        m.render_response = http_middleware.render_response
    end

    if http_middleware.authorize_request == nil then
        m.authorize_request = _http_middleware.authorize_request or middleware.authorize_request
    else
        m.authorize_request = http_middleware.authorize_request
    end

    if http_middleware.request_wrapper == nil then
        m.request_wrapper = _http_middleware.request_wrapper or middleware.request_wrapper
    else
        m.request_wrapper = http_middleware.request_wrapper
    end

    _http_middleware = m
end

local function set_middleware(http_middleware)
    _set_middleware(http_middleware)
    set_endpoint(_endpoint)
end

local function get_middleware()
    return _http_middleware
end

local function _init()
    if fio.path.is_dir(fio.pathjoin(package.searchroot(), _fragments_dir)) then
        fragments.init(_fragments_dir)
        return true
    else
        _fragments_dir = nil
        local err = string.format('Path is not valid: %s', tostring(_fragments_dir))
        log.error('%s', err)
        return nil, err
    end
end

local function init(httpd, http_middleware, endpoint, fragments_dir, opts)
    checks('table', '?table', '?string', '?string', '?table')

    endpoint = endpoint or rawget(_G, '__GRAPHQLAPI_ENDPOINT')
    endpoint = endpoint or defaults.DEFAULT_ENDPOINT
    fragments_dir = fragments_dir or rawget(_G, '__GRAPHQLAPI_MODELS_DIR')
    _fragments_dir = fragments_dir or defaults.DEFAULT_FRAGMENTS_DIR
    rawset(_G, '__GRAPHQLAPI_MODELS_DIR', _fragments_dir)

    _httpd = httpd
    _set_middleware(http_middleware)
    set_endpoint(endpoint, opts)

    _init()

    trigger.init()
end

local function stop()
    delete_route(_httpd, _endpoint)

    trigger.stop()
    helpers.stop()
    fragments.stop()
    types.remove_all()
    operations.stop()
    _http_middleware = {}
    _endpoint = nil
    _graphql_schema = {}
    _httpd = nil
    _fragments_dir = nil
end

local function reload()
    operations.remove_on_resolve_triggers()
    operations.remove_all()
    types.remove_all()
    fragments.stop()
    helpers.stop()
    _graphql_schema = {}

    _init()
    return true
end

local function set_fragments_dir(fragments_dir)
    checks('string')
    if fio.path.is_dir(fio.pathjoin(package.searchroot(), fragments_dir)) then
        _fragments_dir = fragments_dir
        rawset(_G, '__GRAPHQLAPI_MODELS_DIR', fragments_dir)
        reload()
    end
end

local function get_fragments_dir()
    return _fragments_dir
end

return {
    -- Common methods
    init = init,
    stop = stop,
    reload = reload,
    set_fragments_dir = set_fragments_dir,
    get_fragments_dir = get_fragments_dir,
    set_endpoint = set_endpoint,
    get_endpoint = get_endpoint,
    set_middleware = set_middleware,
    get_middleware = get_middleware,

    -- version
    VERSION = VERSION,
}
