local checks = require('checks')
local utils = require('graphqlapi.utils')

local _schema_invalid = {}

local function is_invalid(schema)
    checks('?string')
    schema = utils.coerce_schema(schema)
    return _schema_invalid[schema] or false
end

local function reset_invalid(schema)
    checks('?string')
    schema = utils.coerce_schema(schema)
    _schema_invalid[schema] = false
end

local function set_invalid(schema)
    checks('?string')
    schema = utils.coerce_schema(schema)
    _schema_invalid[schema] = true
end

local function remove_schema(schema)
    checks('?string')
    schema = utils.coerce_schema(schema)
    _schema_invalid[schema] = nil
end

local function remove_all()
    _schema_invalid = {}
end

local function list_schemas()
    local schemas = {}
    for schema_name in pairs(_schema_invalid) do
        table.insert(schemas, schema_name)
    end
    return schemas
end

return {
    set_invalid = set_invalid,
    reset_invalid = reset_invalid,
    is_invalid = is_invalid,
    remove_schema = remove_schema,
    remove_all = remove_all,
    list_schemas = list_schemas,
}
