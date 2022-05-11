local defaults = require('graphqlapi.defaults')
local list = require('graphqlapi.list')
local utils = require('graphqlapi.utils')
local graphqlide_ok, graphqlide = pcall(require, 'graphqlide')

local _schema_invalid = {}
local _graphql_cache = {}
local _graphql_cache_lists = {}

local function cache_reset(schema, cache_size)
    schema = utils.coerce_schema(schema)
    cache_size = cache_size or defaults.GRAPHQL_QUERY_CACHE_SIZE

    _graphql_cache[schema] = {}
    _graphql_cache_lists[schema] = list.new(cache_size)
end

local function cache_set(schema, request_hash, request_ast)
    utils.is_string(1, schema, true)
    utils.is_string(2, request_hash, false)
    utils.is_table(3, request_ast, true)

    schema = utils.coerce_schema(schema)
    if _graphql_cache[schema] == nil then return end

    if _graphql_cache_lists[schema]:is_full() then
        local removed = _graphql_cache_lists[schema]:pop()
        if removed ~= nil then
            _graphql_cache[schema][removed] = nil
        end
    end

    local item = _graphql_cache_lists[schema]:push(request_hash)

    _graphql_cache[schema][request_hash] = {
        request_ast = request_ast,
        item = item
    }
end

local function cache_get(schema, request_hash)
    utils.is_string(1, schema, true)
    utils.is_string(2, request_hash, false)

    schema = utils.coerce_schema(schema)
    if _graphql_cache[schema] == nil then return end

    local request = _graphql_cache[schema][request_hash]
    if request ~= nil then
        _graphql_cache_lists[schema]:pop(request.item) -- remove item
        request.item = _graphql_cache_lists[schema]:push(request_hash) -- push item
        return request.request_ast
    end
end

local function is_invalid(schema)
    utils.is_string(1, schema, true)
    schema = utils.coerce_schema(schema)
    return _schema_invalid[schema] or false
end

local function reset_invalid(schema)
    utils.is_string(1, schema, true)
    schema = utils.coerce_schema(schema)
    _schema_invalid[schema] = false
end

local function set_invalid(schema, remove)
    utils.is_string(1, schema, true)
    utils.is_boolean(2, remove, true)

    schema = utils.coerce_schema(schema)

    if graphqlide_ok == true then
        if remove then
            graphqlide.remove_endpoint(schema)
        else
            local endpoints = graphqlide.get_endpoints()
            local endpoint = rawget(_G, '__GRAPHQLAPI_ENDPOINT')
            if endpoints ~= nil and type(endpoints) == 'table' and
                endpoints[schema] == nil and endpoint ~= nil then
                graphqlide.set_endpoint({name = schema, path = endpoint})
            end
        end
    end

    _schema_invalid[schema] = true
    cache_reset(schema)
end

local function remove_schema(schema)
    utils.is_string(1, schema, true)

    schema = utils.coerce_schema(schema)
    if graphqlide_ok == true then graphqlide.remove_endpoint(schema) end

    _schema_invalid[schema] = nil
    cache_reset(schema)
end

local function list()
    local schemas = {}
    for schema_name in pairs(_schema_invalid) do
        table.insert(schemas, schema_name)
    end
    return schemas
end

local function remove_all()
    for _, schema in ipairs(list()) do
        cache_reset(schema)
    end

    _schema_invalid = {}

    if graphqlide_ok == true then
        local endpoints = graphqlide.get_endpoints()
        for endpoint in pairs(endpoints) do
            graphqlide.remove_endpoint(endpoint)
        end
    end
end

return {
    set_invalid = set_invalid,
    reset_invalid = reset_invalid,
    is_invalid = is_invalid,
    remove_schema = remove_schema,
    remove_all = remove_all,
    list = list,
    cache_set = cache_set,
    cache_get = cache_get,
}
