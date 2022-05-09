local errors = require('errors')
local json = require('json')
local log = require('log')

local graphql_types = require('graphqlapi.graphql.types')
local cluster = require('graphqlapi.cluster')
local defaults = require('graphqlapi.defaults')
local schemas = require('graphqlapi.schemas')
local utils = require('graphqlapi.utils')

local types = {
    -- base graphql types
    bare = graphql_types.bare,
    boolean = graphql_types.boolean,
    directive = graphql_types.directive,
    float = graphql_types.float,
    id = graphql_types.id,
    include = graphql_types.include,
    int = graphql_types.int,
    list = graphql_types.list,
    long = graphql_types.long,
    nonNull = graphql_types.nonNull,
    nullable = graphql_types.nullable,
    scalar = graphql_types.scalar,
    skip = graphql_types.skip,
    specifiedBy = graphql_types.specifiedBy,
    string = graphql_types.string,
}

local _space_type = {}
local _directives = {}

local e_graphqlapi = errors.new_class('GraphQL API error', { capture_stack = false, })
local e_max_depth = errors.new_class('Recursive remove', { capture_stack = true, })

types.enum = function(config)
    config.schema = utils.coerce_schema(config.schema)

    if graphql_types.get_env(config.schema)[config.name] then
        error('enum "'..tostring(config.name)..'" already exists in schema: "'..config.schema..'"', 0)
    end

    local instance = graphql_types.enum(config)
    schemas.set_invalid(config.schema)
    return instance
end

types.inputObject = function(config)
    config.schema = utils.coerce_schema(config.schema)

    if graphql_types.get_env(config.schema)[config.name] then
        error('inputObject "'..tostring(config.name)..'" already exists in schema: "'..config.schema..'"', 0)
    end

    local instance = graphql_types.inputObject(config)
    schemas.set_invalid(config.schema)
    return instance
end

types.interface = function(config)
    config.schema = utils.coerce_schema(config.schema)

    if graphql_types.get_env(config.schema)[config.name] then
        error('interface "'..tostring(config.name)..'" already exists in schema: "'..config.schema..'"', 0)
    end

    local instance = graphql_types.interface(config)
    schemas.set_invalid(config.schema)
    return instance
end

types.object = function(config)
    config.schema = utils.coerce_schema(config.schema)

    if graphql_types.get_env(config.schema)[config.name] then
        error('object "'..tostring(config.name)..'" already exists in schema: "'..config.schema..'"', 0)
    end

    local instance = graphql_types.object(config)
    schemas.set_invalid(config.schema)
    return instance
end

types.union = function(config)
    config.schema = utils.coerce_schema(config.schema)

    if graphql_types.get_env(config.schema)[config.name] then
        error('union "'..tostring(config.name)..'" already exists in schema: "'..config.schema..'"', 0)
    end

    local instance = graphql_types.union(config)
    schemas.set_invalid(config.schema)
    return instance
end

local function parseNullLiteral(_)
    return box.NULL
end

local scalar_kind_to_parse = {
    boolean = types.boolean.parseLiteral,
    float = types.float.parseLiteral,
    int = types.long.parseLiteral,
    long = types.long.parseLiteral,
    null = parseNullLiteral,
    string = types.string.parseLiteral,
    uuid = types.id.parseLiteral,
}

types.any = types.scalar({
    name = 'Any',
    description = 'The `Any` scalar type to represent any type except array or map',
    specifiedByURL = 'https://github.com/tarantool/graphqlapi/wiki/Any',
    serialize = function(value)
        if type(value) == 'table' then
            error(type(value)..' is not a scalar kind', 0)
        end
        return value
    end,
    parseValue = function(value)
        if type(value) == 'table' then
            error(type(value)..' is not a scalar kind', 0)
        end
        return value
    end,
    parseLiteral = function(node)
        if scalar_kind_to_parse[node.kind] then
            return scalar_kind_to_parse[node.kind](node)
        end
    end,
    isValueOfTheType = function(value)
        return type(value) ~= 'table'
    end,
})

types.map = types.scalar{
    name = 'Map',
    description = 'Type to process any data in JSON format',
    specifiedByURL = 'https://github.com/tarantool/graphqlapi/wiki/Map',
    serialize = function(value)
        if type(value) ~= 'string' then
            return json.encode(value)
        else
            -- in some cases need to prevent dual json.encode
            return value
        end
    end,
    parseValue = function(value)
        if type(value) == 'string' then
            return json.decode(value)
        end
        if value == nil then
            return value
        end
    end,
    parseLiteral = function(node)
        if node.kind == 'string' then
            return json.decode(node.value)
        end
        if node.value == nil then
            return node.value
        end
    end,
    isValueOfTheType = function(value)
        return type(value) == 'string' or value == nil
    end,
}

types.mapper = setmetatable({
    ['any'] = { ['type'] = types.any, name = 'Any', },
    ['array'] = { ['type'] = types.list(types.any), name = 'List', },
    ['boolean'] = { ['type'] = types.boolean, name = 'Boolean', },
    ['decimal'] = { ['type'] = types.long, name = 'Long', },
    ['double'] = { ['type'] = types.float, name = 'Float', },
    ['integer'] = { ['type'] = types.long, name = 'Long', },
    ['map'] = { ['type'] = types.map, name = 'Map', },
    ['number'] = { ['type'] = types.float, name = 'Float', },
    ['scalar'] = { ['type'] = types.any, name = 'Any', },
    ['string'] = { ['type'] = types.string, name = 'String', },
    ['unsigned'] = { ['type'] = types.long, name = 'Long',},
    ['uuid'] = { ['type'] = types.id, name = 'ID', },
}, {
    __index = function(self)
        return self['any']
    end
})

local default_scalars = {
    'Any',
    'Boolean',
    'Double',
    'Float',
    'ID',
    'Int',
    'Long',
    'Map',
    'String',
}

types.space_fields = function(space, required)
    local schema = cluster.get_schema()

    if not schema.spaces[space] then return nil end
    local fields = {}
    for _, field in ipairs(schema.spaces[space].format) do
        if field[defaults.DEFAULT_DESCRIPTION_KEY] ~= nil and field[defaults.DEFAULT_DESCRIPTION_KEY] ~= '' then
            if required and not field.is_nullable then
                fields[field.name] = {
                    kind = types.nonNull(types.mapper[field.type].type),
                    description = field[defaults.DEFAULT_DESCRIPTION_KEY],
                }
            else
                fields[field.name] = {
                    kind = types.mapper[field.type].type,
                    description = field[defaults.DEFAULT_DESCRIPTION_KEY],
                }
            end
        else
            if required and not field.is_nullable then
                fields[field.name] = types.nonNull(types.mapper[field.type].type)
            else
                fields[field.name] = types.mapper[field.type].type
            end
        end
    end
    return fields
end

types.remove = function (type_name, schema)
    utils.is_string(1, type_name, false)
    utils.is_string(2, schema, true)

    schema = utils.coerce_schema(schema)
    graphql_types.get_env(schema)[type_name] = nil

    for space in pairs(_space_type or {}) do
        local space_types = table.copy(_space_type[space])
        for index, _type in pairs(space_types or {}) do
            if _type.schema == schema and _type.type_name == type_name then
                table.remove(_space_type[space], index)
            end
        end
    end

    schemas.set_invalid(schema)
    return type_name
end

local function add_non_leaf_type(type_list, type_name)
    if type_name ~= nil and not utils.value_in(type_name, default_scalars) then
        table.insert(type_list, type_name)
    end
end

types.get_non_leaf_types = function(t, type_list, depth, skip)
    if not t or type(t) ~= 'table' then return {} end
    local root = false
    if depth == nil then
        depth = 1
    else
        depth = depth + 1
    end
    if type_list == nil then
        type_list = {}
        root = true
    end
    if depth > defaults.REMOVE_RECURSIVE_MAX_DEPTH then
        local err = e_max_depth:new('Too high nest level')
        log.error('%s', err)
        return type_list, err
    end
    -- if node is a custom Scalar add it to list of non-leafs only if its not a root
    if t.__type == 'Scalar' then
        if not root then
            add_non_leaf_type(type_list, t.name)
        end
    -- if node is NonNull then process node's child
    elseif t.__type == 'NonNull' then
        types.get_non_leaf_types(t.ofType or {}, type_list, depth)
    -- if node is List then process node's children
    elseif t.__type == 'List' then
        types.get_non_leaf_types(t.ofType or {}, type_list, depth)
    -- if node is Enum then simply add to list of non-leafs
    elseif t.__type == 'Enum' then
        if not root and t.name ~= nil then
            table.insert(type_list, t.name)
        end
    -- if node is Object process its kind, fields, arguments and interfaces
    elseif t.__type == 'Object' then
        -- if Object is query prefix simply run over all its fields
        if t.name and t.name:sub(1, #defaults.QUERIES_PREFIX) == defaults.QUERIES_PREFIX then
            if not root and t.name ~= nil and not skip then
                table.insert(type_list, t.name)
            end
            for _, f in pairs(t.fields or {}) do
                types.get_non_leaf_types(f.kind or {}, type_list, depth)
                for _, a in pairs(f.arguments or {}) do
                    if a.kind ~= nil then a = a.kind end
                    add_non_leaf_type(type_list, a.name)
                    types.get_non_leaf_types(a, type_list, depth)
                end
            end
        -- if Object is mutation prefix simply run over all its fields
        elseif t.name and t.name:sub(1, #defaults.MUTATIONS_PREFIX) == defaults.MUTATIONS_PREFIX then
            if not root and t.name ~= nil and not skip then
                table.insert(type_list, t.name)
            end
            for _, f in pairs(t.fields or {}) do
                types.get_non_leaf_types(f.kind or {}, type_list, depth)
                for _, a in pairs(f.arguments or {}) do
                    if a.kind ~= nil then a = a.kind end
                    add_non_leaf_type(type_list, a.name)
                    types.get_non_leaf_types(a, type_list, depth)
                end
            end
        -- process ordinary Object
        else
            if not root and t.name then
                table.insert(type_list, t.name)
            end
            for _, f in pairs(t.fields or {}) do
                types.get_non_leaf_types(f.kind or {}, type_list, depth)
                for _, a in pairs(f.arguments or {}) do
                    if a.kind ~= nil then a = a.kind end
                    add_non_leaf_type(type_list, a.name)
                    types.get_non_leaf_types(a, type_list, depth)
                end
            end
            for _, i in pairs(t.interfaces or {}) do
                if i.kind ~= nil then i = i.kind end
                add_non_leaf_type(type_list, i.name)
                types.get_non_leaf_types(i, type_list, depth)
            end
        end
    -- if node is inputObject process its kind, fields, arguments and interfaces
    elseif t.__type == 'InputObject' then
        if not root and t.name then
            table.insert(type_list, t.name)
        end
        for _, f in pairs(t.fields or {}) do
            types.get_non_leaf_types(f.kind or {}, type_list, depth)
        end
    -- if node is Interface process its kind, fields, arguments and interfaces
    elseif t.__type == 'Interface' then
        if not root and t.name then
            table.insert(type_list, t.name)
        end
        for _, f in pairs(t.fields or {}) do
            types.get_non_leaf_types(f.kind or {}, type_list, depth)
        end
    -- if node is Union process its children
    elseif t.__type == 'Union' then
        if not root and t.name then
            table.insert(type_list, t.name)
        end
        for _, v in pairs(t.types or {}) do
            types.get_non_leaf_types(v, type_list, depth)
        end
    -- if root t is query or mutation prefix itself process all items
    elseif t.kind and t.resolve and root then
        types.get_non_leaf_types(t.kind, type_list, depth, true)
        for _, a in pairs(t.arguments or {}) do
            if a.kind ~= nil then a = a.kind end
            add_non_leaf_type(type_list, a.name)
            types.get_non_leaf_types(a, type_list, depth)
        end
    -- if root t is schema queries or mutations process all prefixes
    elseif root then
        for _, v in pairs(t or {}) do
            types.get_non_leaf_types(v.kind, type_list, depth)
            for _, a in pairs(v.arguments or {}) do
                if a.kind ~= nil then a = a.kind end
                add_non_leaf_type(type_list, a.name)
                types.get_non_leaf_types(a, type_list, depth)
            end
        end
    end
    if root then
        return utils.dedup_array(type_list)
    end
end

types.remove_recursive = function (type_name, schema)
    utils.is_string(1, type_name, false)
    utils.is_string(2, schema, true)
    schema = utils.coerce_schema(schema)

    local removed_types = {}
    types.remove(type_name, schema)
    table.insert(removed_types, type_name)
    for k,v in pairs(types(schema)) do
        if utils.value_in(type_name, types.get_non_leaf_types(v)) then
            types.remove(k, schema)
            table.insert(removed_types, k)
        end
    end

    return removed_types
end

-- schema:
-- 1: nil - remove in all schemas
-- 2: box.NULL - remove in default
-- 3: 'string' - remove in provided schema

types.remove_types_by_space_name = function(space_name, schema)
    utils.is_string(1, space_name, false)
    utils.is_string(2, schema, true)
    if utils.is_box_null(schema) then
        schema = utils.coerce_schema(schema)
    end

    local removed_types = {}

    if _space_type[space_name] ~= nil then
        local space_type = table.copy(_space_type[space_name])
        for _, _type in pairs(space_type or {}) do
            _type.schema = utils.coerce_schema(_type.schema)
            if schema == nil or schema == _type.schema then
                removed_types[_type.schema] = removed_types[_type.schema] or {}
                local recursively_removed = types.remove_recursive(_type.type_name, _type.schema)
                removed_types[_type.schema] = utils.merge_arrays(
                    removed_types[_type.schema],
                    recursively_removed
                )

                schemas.set_invalid(_type.schema)
            end
        end
        if schema == nil then
            _space_type[space_name] = nil
        end
    end

    return removed_types
end

types.remove_all = function(schema)
    utils.is_string(1, schema, true)

    if utils.is_box_null(schema) then
        schema = utils.coerce_schema(schema)
    end
    if schema ~= nil then
        schema = utils.coerce_schema(schema)
        for type_name in pairs(graphql_types.get_env(schema)) do
            types.remove(type_name, schema)
        end

        for directive_name in pairs(_directives[schema] or {}) do
            types.remove_directive(directive_name, schema)
        end

        schemas.remove_schema(schema)
    else
        for _, _schema in pairs(schemas.schemas_list()) do
            for type_name in pairs(graphql_types.get_env(_schema)) do
                types.remove(type_name, _schema)
            end
        end
        _directives = {}
        _space_type = {}
        schemas.remove_all()
    end
end

types.add_space_object = function(opts)
    utils.is_table(1, opts, false)
    utils.is_string('1.schema', opts.schema, true)
    utils.is_string('1.name', opts.name, true)
    utils.is_string('1.description', opts.description, true)
    utils.is_string('1.space', opts.space, false)
    utils.is_table('1.fields', opts.fields, true)
    utils.is_table('1.interfaces', opts.interfaces, true)

    opts.schema = utils.coerce_schema(opts.schema)

    if not cluster.is_space_exists(opts.space) then
        return nil, nil, e_graphqlapi:new(string.format("space '%s' doesn't exists", opts.space))
    end

    local type_name = opts.name or opts.space..'_space'

    types.object({
        schema = opts.schema,
        name = type_name,
        description = opts.description,
        fields = opts.fields and
            utils.merge_maps(types.space_fields(opts.space, false), opts.fields) or
            types.space_fields(opts.space, false),
        interfaces = opts.interfaces,
    })

    _space_type[opts.space] = utils.merge_arrays(
        _space_type[opts.space] or {},
        {
            {
                type_name = type_name,
                schema = opts.schema,
            }
        }
    )

    return graphql_types.get_env(opts.schema)[type_name]
end

types.add_space_input_object = function(opts)
    utils.is_table(1, opts, false)
    utils.is_string('1.schema', opts.schema, true)
    utils.is_string('1.name', opts.name, true)
    utils.is_string('1.description', opts.description, true)
    utils.is_string('1.space', opts.space, false)
    utils.is_table('1.fields', opts.fields, true)

    opts.schema = utils.coerce_schema(opts.schema)

    if not cluster.is_space_exists(opts.space) then
        return nil, nil, e_graphqlapi:new(string.format("space '%s' doesn't exists", opts.space))
    end

    local type_name = opts.name or opts.space..'_space_input'

    types.inputObject({
        schema = opts.schema,
        name = type_name,
        description = opts.description,
        fields = opts.fields and utils.merge_maps(types.space_fields(opts.space, true), opts.fields) or
        types.space_fields(opts.space, true),
    })

    _space_type[opts.space] = utils.merge_arrays(
        _space_type[opts.space] or {},
        {
            {
                type_name = type_name,
                schema = opts.schema,
            }
        }
    )
    return graphql_types.get_env(opts.schema)[type_name]
end

types.types_list = function(schema)
    utils.is_string(1, schema, true)

    schema = utils.coerce_schema(schema)
    local type_list = {}
    for _type in pairs(graphql_types.get_env(schema)) do
        table.insert(type_list, _type)
    end
    return type_list
end

types.add_directive = function(opts)
    utils.is_table(1, opts, false)
    utils.is_string('1.schema', opts.schema, true)
    utils.is_string('1.name', opts.name, true)
    utils.is_string('1.description', opts.description, true)
    utils.is_table('1.args', opts.args, true)
    utils.is_boolean('1.onQuery', opts.onQuery, true)
    utils.is_boolean('1.onMutation', opts.onMutation, true)
    utils.is_boolean('1.onField', opts.onField, true)
    utils.is_boolean('1.onFragmentDefinition', opts.onFragmentDefinition, true)
    utils.is_boolean('1.onFragmentSpread', opts.onFragmentSpread, true)
    utils.is_boolean('1.onInlineFragment', opts.onInlineFragment, true)
    utils.is_boolean('1.onVariableDefinition', opts.onVariableDefinition, true)
    utils.is_boolean('1.onSchema', opts.onSchema, true)
    utils.is_boolean('1.onScalar', opts.onScalar, true)
    utils.is_boolean('1.onObject', opts.onObject, true)
    utils.is_boolean('1.onFieldDefinition', opts.onFieldDefinition, true)
    utils.is_boolean('1.onArgumentDefinition', opts.onArgumentDefinition, true)
    utils.is_boolean('1.onInterface', opts.onInterface, true)
    utils.is_boolean('1.onUnion', opts.onUnion, true)
    utils.is_boolean('1.onEnum', opts.onEnum, true)
    utils.is_boolean('1.onEnumValue', opts.onEnumValue, true)
    utils.is_boolean('1.onInputObject', opts.onInputObject, true)
    utils.is_boolean('1.onInputFieldDefinition', opts.onInputFieldDefinition, true)
    utils.is_boolean('1.isRepeatable', opts.isRepeatable, true)

    opts.schema = utils.coerce_schema(opts.schema)

    _directives[opts.schema] = _directives[opts.schema] or {}

    if _directives[opts.schema][opts.name] ~= nil then
        error('directive "'..tostring(opts.name)..'" already exists in schema: "'..opts.schema..'"', 0)
    end

    _directives[opts.schema][opts.name] = types.directive({
        name = opts.name,
        description = opts.description,
        arguments = opts.args,
        onQuery = opts.onQuery,
        onMutation = opts.onMutation,
        onField = opts.onField,
        onFragmentDefinition = opts.onFragmentDefinition,
        onFragmentSpread = opts.onFragmentSpread,
        onInlineFragment = opts.onInlineFragment,
        onVariableDefinition = opts.onVariableDefinition,
        onSchema = opts.onSchema,
        onScalar = opts.onScalar,
        onObject = opts.onObject,
        onFieldDefinition = opts.onFieldDefinition,
        onArgumentDefinition = opts.onArgumentDefinition,
        onInterface = opts.onInterface,
        onUnion = opts.onUnion,
        onEnum = opts.onEnum,
        onEnumValue = opts.onEnumValue,
        onInputObject = opts.onInputObject,
        onInputFieldDefinition = opts.onInputFieldDefinition,
        isRepeatable = opts.isRepeatable,
    })

    schemas.set_invalid(opts.schema)

    return _directives[opts.schema][opts.name]
end

types.get_directives = function(schema)
    schema = utils.coerce_schema(schema)
    return _directives[schema] or {}
end

types.is_directive_exists = function(name, schema)
    utils.is_string(1, name, false)
    utils.is_string(2, schema, true)

    schema = utils.coerce_schema(schema)
    _directives[schema] = _directives[schema] or {}
    return _directives[schema][name] ~= nil
end

types.directives_list = function(schema)
    utils.is_string(1, schema, true)
    schema = utils.coerce_schema(schema)
    local directives_list = {}
    for directive in pairs(_directives[schema] or {}) do
        table.insert(directives_list, directive)
    end
    return directives_list
end

types.remove_directive = function(name, schema)
    utils.is_string(1, name, false)
    utils.is_string(2, schema, true)
    schema = utils.coerce_schema(schema)
    _directives[schema] = _directives[schema] or {}
    _directives[schema][name] = nil
end

return setmetatable(types, {
    __call = function(_, schema)
        schema = utils.coerce_schema(schema)
        return graphql_types.get_env(schema)
    end
})
