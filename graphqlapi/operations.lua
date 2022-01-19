local cluster = require('graphqlapi.cluster')
local defaults = require('graphqlapi.defaults')
local funcall = require('graphqlapi.funcall')
local schemas = require('graphqlapi.schemas')
local types = require('graphqlapi.types')
local utils = require('graphqlapi.utils')

local _queries = {}
local _mutations = {}
local _on_resolve_triggers = {}
local _space_query = {}
local _space_mutation = {}

local function funcall_wrap(fun_name, operation_type, operation_schema, operation_prefix, operation_name)
    utils.is_string(1, fun_name, false)
    utils.is_string(2, operation_type, false)
    utils.is_string(3, operation_schema, true)
    utils.is_string(4, operation_prefix, true)
    utils.is_string(5, operation_name, false)

    return function(...)
        for trigger, _ in pairs(_on_resolve_triggers) do
            local ok, err = trigger(operation_type, operation_schema, operation_prefix, operation_name, ...)
            if ok == false then return nil, err end
        end

        local res, err = funcall.call(fun_name, ...)

        if res == nil and err ~= nil then
            error(err, 0)
        end

        return res, err
    end
end

local function is_schema_empty(schema)
    schema = utils.coerce_schema(schema)

    local all_operations = utils.count_map(_queries[schema])
    all_operations = all_operations + utils.count_map(_mutations[schema])
    if all_operations == 0 then
        return true
    end
    return false
end

local function add_queries_prefix(opts)
    utils.is_table(1, opts, false)
    utils.is_string('1.prefix', opts.prefix, false)
    utils.is_string('1.type_name', opts.type_name, true)
    utils.is_string('1.schema', opts.schema, true)
    utils.is_string('1.doc', opts.doc, true)

    opts.schema = utils.coerce_schema(opts.schema)
    _queries[opts.schema] = _queries[opts.schema] or {}

    opts.type_name = opts.type_name or defaults.QUERIES_PREFIX..opts.prefix

    if _queries[opts.schema][opts.prefix] ~= nil then
        error('query or prefix with name "'..tostring(opts.prefix)..
              '" already exists in schema: "'..opts.schema..'"', 0)
    end

    local kind = types.object({
        name = opts.type_name,
        schema = opts.schema,
        fields = {},
        description = opts.doc,
    })

    local obj = {
        kind = kind,
        arguments = {},
        resolve = function()
            return {}
        end,
        description = opts.doc,
    }
    _queries[opts.schema][opts.prefix] = obj
    schemas.set_invalid(opts.schema)
    return obj
end

local function is_query_prefix(query)
    if query and
       type(query) == 'table' and
       query.kind and
       type(query.kind) == 'table' and
       query.kind.__type == 'Object' and
       query.kind.name:sub(1, #defaults.QUERIES_PREFIX) == defaults.QUERIES_PREFIX and
       query.kind.fields and
       type(query.kind.fields) == 'table' then
        return true
    else
        return false
    end
end

local function is_queries_prefix_exists(opts)
    utils.is_table(1, opts, false)
    utils.is_string('1.prefix', opts.prefix, false)
    utils.is_string('1.schema', opts.schema, true)

    opts.schema = utils.coerce_schema(opts.schema)

    for query in pairs(_queries[opts.schema] or {}) do
        if query == opts.prefix and is_query_prefix(_queries[opts.schema][query]) then
            return true
        end
    end
    return false
end

local function remove_queries_prefix(opts)
    utils.is_table(1, opts, false)
    utils.is_string('1.prefix', opts.prefix, false)
    utils.is_string('1.schema', opts.schema, true)

    opts.schema = utils.coerce_schema(opts.schema)
    _queries[opts.schema] = _queries[opts.schema] or {}
    -- Remove all queries with removed prefix
    local prefix = _queries[opts.schema][opts.prefix]
    if type(prefix) == 'table' and type(prefix.kind) == 'table' and type(prefix.kind.name) == 'string' then
        types(opts.schema)[prefix.kind.name] = nil
    end
    _queries[opts.schema][opts.prefix] = nil
    -- Cleanup _space_query with removed prefix
    for space in pairs(_space_query) do
        local space_queries = table.copy(_space_query[space])
        for index, query in pairs(space_queries or {}) do
            if query.schema == opts.schema and
                query.prefix == opts.prefix then
                table.remove(_space_query[space], index)
            end
        end
    end

    schemas.set_invalid(opts.schema, is_schema_empty(opts.schema))
end

local function add_mutations_prefix(opts)
    utils.is_table(1, opts, false)
    utils.is_string('1.prefix', opts.prefix, false)
    utils.is_string('1.type_name', opts.type_name, true)
    utils.is_string('1.schema', opts.schema, true)
    utils.is_string('1.doc', opts.doc, true)

    opts.schema = utils.coerce_schema(opts.schema)
    _mutations[opts.schema] = _mutations[opts.schema] or {}

    opts.type_name = opts.type_name or defaults.MUTATIONS_PREFIX..opts.prefix

    if _mutations[opts.schema][opts.prefix] ~= nil then
        error('mutation or prefix with name "'..tostring(opts.prefix)..
              '" already exists in schema: "'..opts.schema..'"', 0)
    end

    local kind = types.object({
        name = opts.type_name,
        schema = opts.schema,
        fields = {},
        description = opts.doc,
    })

    local obj = {
        kind = kind,
        arguments = {},
        resolve = function()
            return {}
        end,
        description = opts.doc,
    }
    _mutations[opts.schema][opts.prefix] = obj
    schemas.set_invalid(opts.schema)
    return obj
end

local function is_mutation_prefix(mutation)
    if mutation and
       type(mutation) and
       mutation.kind and
       type(mutation.kind) == 'table' and
       mutation.kind.__type == 'Object' and
       mutation.kind.name:sub(1, #defaults.MUTATIONS_PREFIX) == defaults.MUTATIONS_PREFIX and
       mutation.kind and
       mutation.kind.fields and
       type (mutation.kind.fields) then
        return true
    else
        return false
    end
end

local function is_mutations_prefix_exists(opts)
    utils.is_table(1, opts, false)
    utils.is_string('1.prefix', opts.prefix, false)
    utils.is_string('1.schema', opts.schema, true)

    opts.schema = utils.coerce_schema(opts.schema)

    for mutation in pairs(_mutations[opts.schema] or {}) do
        if mutation == opts.prefix and is_mutation_prefix(_mutations[opts.schema][mutation]) then
            return true
        end
    end
    return false
end

local function remove_mutations_prefix(opts)
    utils.is_table(1, opts, false)
    utils.is_string('1.prefix', opts.prefix, false)
    utils.is_string('1.schema', opts.schema, true)

    opts.schema = utils.coerce_schema(opts.schema)
    _mutations[opts.schema] = _mutations[opts.schema] or {}
    -- Remove all mutations with removed prefix
    local prefix = _mutations[opts.schema][opts.prefix]
    if type(prefix) == 'table' and type(prefix.kind) == 'table' and type(prefix.kind.name) == 'string' then
        types(opts.schema)[prefix.kind.name] = nil
    end
    _mutations[opts.schema][opts.prefix] = nil
    -- Cleanup _space_mutation with removed prefix
    for space in pairs(_space_mutation) do
        local space_mutations = table.copy(_space_mutation[space])
        for index, mutation in pairs(space_mutations or {}) do
            if mutation.schema == opts.schema and
                mutation.prefix == opts.prefix then
                table.remove(_space_mutation[space], index)
            end
        end
    end
    schemas.set_invalid(opts.schema, is_schema_empty(opts.schema))
end

local function add_query(opts)
    utils.is_table(1, opts, false)
    utils.is_string('1.schema', opts.schema, true)
    utils.is_string('1.prefix', opts.prefix, true)
    utils.is_string('1.name', opts.name, false)
    utils.is_string('1.doc', opts.doc, true)
    utils.is_table('1.args', opts.args, true)
    utils.is_table('1.interfaces', opts.interfaces, true)
    utils.is_table_or_string('1.kind', opts.kind, false)
    utils.is_string('1.callback', opts.callback, false)

    opts.schema = utils.coerce_schema(opts.schema)
    _queries[opts.schema] = _queries[opts.schema] or {}

    if opts.prefix ~= nil then
        local obj = _queries[opts.schema][opts.prefix]
        if obj == nil then
            error('No such query prefix "' .. opts.prefix..'"', 0)
        end

        if obj.kind.fields[opts.name] ~= nil then
            error('query "'..tostring(opts.name)..'" already exists in prefix "'..
                  tostring(opts.prefix)..'" in schema: "'..opts.schema..'"', 0)
        end

        local oldkind = obj.kind
        oldkind.fields[opts.name] = {
            kind = opts.kind,
            arguments = opts.args,
            interfaces = opts.interfaces,
            resolve = funcall_wrap(
                opts.callback,
                'query',
                opts.schema,
                opts.prefix,
                opts.name
            ),
            description = opts.doc,
        }

        if types(opts.schema)[oldkind.name] ~= nil then
            types(opts.schema)[oldkind.name] = nil
        end

        obj.kind = types.object{
            name = oldkind.name,
            schema = opts.schema,
            fields = oldkind.fields,
            description = oldkind.description,
        }
    else
        if _queries[opts.schema][opts.name] then
            error('query "'..tostring(opts.name)..'" already exists in schema: "'..opts.schema..'"', 0)
        end

        _queries[opts.schema][opts.name] = {
            kind = opts.kind,
            arguments = opts.args,
            interfaces = opts.interfaces,
            resolve = funcall_wrap(
                opts.callback,
                'query',
                opts.schema,
                opts.prefix,
                opts.name
            ),
            description = opts.doc,
        }
    end
    schemas.set_invalid(opts.schema)
end

local function is_query_exists(opts)
    utils.is_table(1, opts, false)
    utils.is_string('1.name', opts.name, false)
    utils.is_string('1.schema', opts.schema, true)
    utils.is_string('1.prefix', opts.prefix, true)

    opts.schema = utils.coerce_schema(opts.schema)
    _queries[opts.schema] = _queries[opts.schema] or {}

    if opts.prefix == nil then
        return _queries[opts.schema] ~= nil
    else
        return _queries[opts.schema][opts.prefix] ~= nil
    end
end

local function remove_query(opts)
    utils.is_table(1, opts, false)
    utils.is_string('1.name', opts.name, false)
    utils.is_string('1.schema', opts.schema, true)
    utils.is_string('1.prefix', opts.prefix, true)

    opts.schema = utils.coerce_schema(opts.schema)
    _queries[opts.schema] = _queries[opts.schema] or {}

    if opts.prefix == nil then
        _queries[opts.schema][opts.name] = nil
    else
        if _queries[opts.schema][opts.prefix] and
           _queries[opts.schema][opts.prefix].kind and
           _queries[opts.schema][opts.prefix].kind.fields then
            _queries[opts.schema][opts.prefix].kind.fields[opts.name] = nil
        end
    end

    for space in pairs(_space_query) do
        local space_queries = table.copy(_space_query[space])
        for index, query in pairs(space_queries or {}) do
            if query.schema == opts.schema and
               query.prefix == opts.prefix and
               query.name == opts.name then
                table.remove(_space_query[space], index)
            end
        end
    end

    schemas.set_invalid(opts.schema, is_schema_empty(opts.schema))
end

local function queries_list(schema_name)
    utils.is_string(1, schema_name, true)

    local queries = {}

    schema_name = utils.coerce_schema(schema_name)
    _queries[schema_name] = _queries[schema_name] or {}

    for query in pairs(_queries[schema_name]) do
        if is_query_prefix(_queries[schema_name][query]) then
            for prefixed_query in pairs(_queries[schema_name][query].kind.fields or {}) do
                table.insert(queries, tostring(query)..'.'..tostring(prefixed_query))
            end
        else
            table.insert(queries, query)
        end
    end
    return queries
end

local function add_mutation(opts)
    utils.is_table(1, opts, false)
    utils.is_string('1.schema', opts.schema, true)
    utils.is_string('1.prefix', opts.prefix, true)
    utils.is_string('1.name', opts.name, false)
    utils.is_string('1.doc', opts.doc, true)
    utils.is_table('1.args', opts.args, true)
    utils.is_table_or_string('1.kind', opts.kind, true)
    utils.is_string('1.callback', opts.callback, false)

    opts.schema = utils.coerce_schema(opts.schema)
    _mutations[opts.schema] = _mutations[opts.schema] or {}

    if opts.prefix then
        local obj = _mutations[opts.schema][opts.prefix]
        if obj == nil then
            error('No such mutation prefix "' .. opts.prefix..'"', 0)
        end

        if obj.kind.fields[opts.name] ~= nil then
            error('mutation "'..tostring(opts.name)..'" already exists in prefix "'..
                  tostring(opts.prefix)..'" in schema: "'..opts.schema..'"', 0)
        end

        local oldkind = obj.kind
        oldkind.fields[opts.name] = {
            kind = opts.kind,
            arguments = opts.args,
            resolve = funcall_wrap(
                opts.callback,
                'mutation',
                opts.schema,
                opts.prefix,
                opts.name
            ),
            description = opts.doc
        }

        if types(opts.schema)[oldkind.name] ~= nil then
            types(opts.schema)[oldkind.name] = nil
        end

        obj.kind = types.object{
            name = oldkind.name,
            schema = opts.schema,
            fields = oldkind.fields,
            description = oldkind.description,
        }
    else
        if _mutations[opts.schema][opts.name] then
            error('mutation "'..tostring(opts.name)..'" already exists in schema: "'..opts.schema..'"', 0)
        end

        _mutations[opts.schema][opts.name] = {
            kind = opts.kind,
            arguments = opts.args,
            resolve = funcall_wrap(
                opts.callback,
                'mutation',
                opts.schema,
                opts.prefix,
                opts.name
            ),
            description = opts.doc,
        }
    end
    schemas.set_invalid(opts.schema)
end

local function is_mutation_exists(opts)
    utils.is_table(1, opts, false)
    utils.is_string('1.name', opts.name, false)
    utils.is_string('1.schema', opts.schema, true)
    utils.is_string('1.prefix', opts.prefix, true)

    opts.schema = utils.coerce_schema(opts.schema)
    _mutations[opts.schema] = _mutations[opts.schema] or {}

    if opts.prefix == nil then
        return _mutations[opts.schema] ~= nil
    else
        return _mutations[opts.schema][opts.prefix] ~= nil
    end
end

local function remove_mutation(opts)
    utils.is_table(1, opts, false)
    utils.is_string('1.name', opts.name, false)
    utils.is_string('1.schema', opts.schema, true)
    utils.is_string('1.prefix', opts.prefix, true)

    opts.schema = utils.coerce_schema(opts.schema)
    _mutations[opts.schema] = _mutations[opts.schema] or {}

    if opts.prefix == nil then
        _mutations[opts.schema][opts.name] = nil
    else
        if _mutations[opts.schema][opts.prefix] and
           _mutations[opts.schema][opts.prefix].kind and
           _mutations[opts.schema][opts.prefix].kind.fields then
            _mutations[opts.schema][opts.prefix].kind.fields[opts.name] = nil
        end
    end

    for space in pairs(_space_mutation) do
        local space_mutations = table.copy(_space_mutation[space])
        for index, mutation in pairs(space_mutations or {}) do
            if mutation.schema == opts.schema and
               mutation.prefix == opts.prefix and
               mutation.name == opts.name then
                table.remove(_space_mutation[space], index)
            end
        end
    end

    schemas.set_invalid(opts.schema, is_schema_empty(opts.schema))
end

local function mutations_list(schema_name)
    utils.is_string(1, schema_name, true)

    local mutations = {}
    schema_name = utils.coerce_schema(schema_name)
    _mutations[schema_name] = _mutations[schema_name] or {}

    for mutation in pairs(_mutations[schema_name]) do
        if is_mutation_prefix(_mutations[schema_name][mutation]) then
            for prefixed_mutation in pairs(_mutations[schema_name][mutation].kind.fields or {}) do
                table.insert(mutations, tostring(mutation)..'.'..tostring(prefixed_mutation))
            end
        else
            table.insert(mutations, mutation)
        end
    end
    return mutations
end

local function add_space_query(opts)
    utils.is_table(1, opts, false)
    utils.is_string('1.schema', opts.schema, true)
    utils.is_string('1.type_name', opts.type_name, true)
    utils.is_string('1.description', opts.description, true)
    utils.is_string('1.space', opts.space, false)
    utils.is_table('1.fields', opts.fields, true)
    utils.is_string('1.prefix', opts.prefix, true)
    utils.is_string('1.name', opts.name, true)
    utils.is_string('1.doc', opts.doc, true)
    utils.is_table('1.args', opts.args, true)
    utils.is_table_or_string('1.kind', opts.kind, true)
    utils.is_boolean('1.list', opts.list, true)
    utils.is_string('1.callback', opts.callback, false)

    opts.schema = utils.coerce_schema(opts.schema)
    _queries[opts.schema] = _queries[opts.schema] or {}

    if not cluster.is_space_exists(opts.space) then
        error(string.format("space '%s' doesn't exists", opts.space), 0)
    end

    local kind, type_name

    if type(opts.kind) == 'string' or (type(opts.kind) == 'table' and opts.kind.__type) then
        kind = opts.kind
    else
        type_name = opts.type_name or opts.space..'_space'

        if not types(opts.schema)[type_name] then
            types.add_space_object({
                schema = opts.schema,
                name = type_name,
                description = opts.description,
                space = opts.space,
                fields = opts.fields
            })
        end
        if opts.list then
            kind = types.list(types(opts.schema)[type_name])
        else
            kind = types(opts.schema)[type_name]
        end
    end

    local name = opts.name or opts.space

    add_query({
        schema = opts.schema,
        prefix = opts.prefix,
        name = name,
        doc = opts.doc,
        args = opts.args,
        kind = opts.kind or kind,
        callback = opts.callback,
    })

    _space_query[opts.space] = utils.merge_arrays(
        _space_query[opts.space] or {},
        {
            {
                name = name,
                schema = opts.schema,
                prefix = opts.prefix,
                type_name = type_name,
            }
        }
    )
end

local function remove_space_query(opts)
    utils.is_table(1, opts, false)
    utils.is_string('1.schema', opts.schema, true)
    utils.is_string('1.prefix', opts.prefix, true)
    utils.is_string('1.space', opts.space, false)
    utils.is_string('1.name', opts.name, true)

    if opts.name == nil then
        local removed_types = {}
        local space_queries = table.copy(_space_query[opts.space])
        for index, query in pairs(space_queries or {}) do
            query.schema = utils.coerce_schema(query.schema)
            removed_types[query.schema] = removed_types[query.schema] or {}
            if query.type_name ~=nil then
                local recursively_removed = types.remove_recursive(query.type_name, query.schema)
                removed_types[query.schema] = utils.merge_arrays(
                    removed_types[query.schema],
                    recursively_removed
                )
            end

            _queries[query.schema] = _queries[query.schema] or {}
            if query.prefix == nil then
                _queries[query.schema][query.name] = nil
            else
                if _queries[query.schema][query.prefix] and
                   _queries[query.schema][query.prefix].kind and
                   _queries[query.schema][query.prefix].kind.fields then
                    _queries[query.schema][query.prefix].kind.fields[query.name] = nil
                end
            end
            table.remove(_space_query[opts.space], index)
            schemas.set_invalid(opts.schema, is_schema_empty(opts.schema))
        end
    else
        opts.schema = utils.coerce_schema(opts.schema)
        remove_query({
            name = opts.name,
            schema = opts.schema,
            prefix = opts.prefix,
        })
    end
end

local function add_space_mutation(opts)
    utils.is_table(1, opts, false)
    utils.is_string('1.schema', opts.schema, true)
    utils.is_string('1.type_name', opts.type_name, true)
    utils.is_string('1.description', opts.description, true)
    utils.is_string('1.space', opts.space, false)
    utils.is_table('1.fields', opts.fields, true)
    utils.is_string('1.prefix', opts.prefix, true)
    utils.is_string('1.name', opts.name, true)
    utils.is_string('1.doc', opts.doc, true)
    utils.is_table('1.args', opts.args, true)
    utils.is_table('1.args_ext', opts.args_ext, true)
    utils.is_table_or_string('1.kind', opts.kind, true)
    utils.is_boolean('1.list', opts.list, true)
    utils.is_string('1.callback', opts.callback, false)

    opts.schema = utils.coerce_schema(opts.schema)
    _mutations[opts.schema] = _mutations[opts.schema] or {}

    if not cluster.is_space_exists(opts.space) then
        error(string.format("space '%s' doesn't exists", opts.space), 0)
    end

    local kind, type_name, args

    if type(opts.kind) == 'string' or (type(opts.kind) == 'table' and opts.kind.__type) then
        kind = opts.kind
    else
        type_name = opts.type_name or opts.space..'_space'

        if not types(opts.schema)[type_name] then
            types.add_space_object({
                schema = opts.schema,
                name = type_name,
                description = opts.description,
                space = opts.space,
                fields = opts.fields
            })
        end
        if opts.list then
            kind = types.list(types(opts.schema)[type_name])
        else
            kind = types(opts.schema)[type_name]
        end
    end

    if opts.args then
        args = opts.args
    else
        args = utils.merge_maps(types.space_fields(opts.space, true), opts.args_ext)
    end

    local name = opts.name or opts.space

    add_mutation({
        schema = opts.schema,
        prefix = opts.prefix,
        name = name,
        doc = opts.doc,
        args = args,
        kind = opts.kind or kind,
        callback = opts.callback,
    })

    _space_mutation[opts.space] = utils.merge_arrays(
        _space_mutation[opts.space] or {},
        {
            {
                name = name,
                schema = opts.schema,
                prefix = opts.prefix,
                type_name = type_name,
            }
        }
    )
end

local function remove_space_mutation(opts)
    utils.is_table(1, opts, false)
    utils.is_string('1.schema', opts.schema, true)
    utils.is_string('1.prefix', opts.prefix, true)
    utils.is_string('1.space', opts.space, false)
    utils.is_string('1.name', opts.name, true)

    if opts.name == nil then
        local removed_types = {}
        local space_queries = table.copy(_space_mutation[opts.space])
        for index, mutation in pairs(space_queries or {}) do
            mutation.schema = utils.coerce_schema(mutation.schema)
            removed_types[mutation.schema] = removed_types[mutation.schema] or {}
            if mutation.type_name ~= nil then
                local recursively_removed = types.remove_recursive(mutation.type_name, mutation.schema)
                removed_types[mutation.schema] = utils.merge_arrays(
                    removed_types[mutation.schema],
                    recursively_removed
                )
            end

            _mutations[mutation.schema] = _mutations[mutation.schema] or {}
            if mutation.prefix == nil then
                _mutations[mutation.schema][mutation.name] = nil
            else
                if _mutations[mutation.schema][mutation.prefix] and
                   _mutations[mutation.schema][mutation.prefix].kind and
                   _mutations[mutation.schema][mutation.prefix].kind.fields then
                    _mutations[mutation.schema][mutation.prefix].kind.fields[mutation.name] = nil
                end
            end
            table.remove(_space_mutation[opts.space], index)
            schemas.set_invalid(opts.schema, is_schema_empty(opts.schema))
        end
    else
        opts.schema = utils.coerce_schema(opts.schema)
        remove_mutation({
            name = opts.name,
            schema = opts.schema,
            prefix = opts.prefix,
        })
    end
end

local function remove_on_resolve_triggers()
    _on_resolve_triggers = {}
end

local function remove_all(opts)
    utils.is_table(1, opts, true)
    if opts ~= nil then
        utils.is_string('1.schema', opts.schema, true)
    end

    if opts ~= nil then
        opts.schema = utils.coerce_schema(opts.schema)
        _queries[opts.schema] = nil

        for space in pairs(_space_query) do
            local space_queries = table.copy(_space_query[space])
            for index, query in pairs(space_queries or {}) do
                if query.schema == opts.schema then
                    table.remove(_space_query[space], index)
                end
            end
        end

        _mutations[opts.schema] = nil

        for space in pairs(_space_mutation) do
            local space_mutations = table.copy(_space_mutation[space])
            for index, mutation in pairs(space_mutations or {}) do
                if mutation.schema == opts.schema then
                    table.remove(_space_mutation[space], index)
                end
            end
        end

    else
        _queries = {}
        _mutations = {}
        _space_query = {}
        _space_mutation = {}
    end
end

local function stop()
    _queries = {}
    _mutations = {}
    _space_query = {}
    _space_mutation = {}
    remove_on_resolve_triggers()
    schemas.remove_all()
end

local function remove_operations_by_space_name(space_name)
    utils.is_string(1, space_name, false)

    -- Cleanup queries related to space
    for _, query in pairs(_space_query[space_name] or {}) do
        query.schema = utils.coerce_schema(query.schema)
        _queries[query.schema] = _queries[query.schema] or {}

        if query.prefix == nil then
            _queries[query.schema][query.name] = nil
        else
            if _queries[query.schema][query.prefix] and
               _queries[query.schema][query.prefix].kind and
               _queries[query.schema][query.prefix].kind.fields then
                _queries[query.schema][query.prefix].kind.fields[query.name] = nil
            end
        end

        schemas.set_invalid(query.schema, is_schema_empty(query.schema))
    end

    _space_query[space_name] = nil

    -- Cleanup mutations related to space
    for _, mutation in pairs(_space_mutation[space_name] or {}) do
        mutation.schema = utils.coerce_schema(mutation.schema)
        _mutations[mutation.schema] = _mutations[mutation.schema] or {}

        if mutation.prefix == nil then
            _mutations[mutation.schema][mutation.name] = nil
        else
            if _mutations[mutation.schema] and
               _mutations[mutation.schema][mutation.prefix].kind and
               _mutations[mutation.schema][mutation.prefix].kind.fields then
                _mutations[mutation.schema][mutation.prefix].kind.fields[mutation.name] = nil
            end
        end

        schemas.set_invalid(mutation.schema, is_schema_empty(mutation.schema))
    end
    _space_mutation[space_name] = nil
end

local function on_resolve(trigger_new, trigger_old)
    utils.is_function(1, trigger_new, true)
    utils.is_function(2, trigger_old, true)
    if trigger_old ~= nil then
        _on_resolve_triggers[trigger_old] = nil
    end
    if trigger_new ~= nil then
        _on_resolve_triggers[trigger_new] = true
    end
    return trigger_new
end

local function get_queries(schema_name)
    utils.is_string(1, schema_name, true)

    schema_name = utils.coerce_schema(schema_name)
    return _queries[schema_name] or {}
end

local function get_mutations(schema_name)
    utils.is_string(1, schema_name, true)

    schema_name = utils.coerce_schema(schema_name)
    return _mutations[schema_name] or {}
end

return {
    stop = stop,
    remove_all = remove_all,
    get_queries = get_queries,
    get_mutations = get_mutations,
    is_schema_empty = is_schema_empty,

    -- Queries prefixes API
    add_queries_prefix = add_queries_prefix,
    is_queries_prefix_exists = is_queries_prefix_exists,
    remove_queries_prefix = remove_queries_prefix,

    -- Mutations prefixes API
    add_mutations_prefix = add_mutations_prefix,
    is_mutations_prefix_exists = is_mutations_prefix_exists,
    remove_mutations_prefix = remove_mutations_prefix,

    -- Queries API
    add_query = add_query,
    is_query_exists = is_query_exists,
    remove_query = remove_query,
    queries_list = queries_list,

    -- Mutations API
    add_mutation = add_mutation,
    is_mutation_exists = is_mutation_exists,
    remove_mutation = remove_mutation,
    mutations_list = mutations_list,

    -- Spaces queries and mutations API
    add_space_query = add_space_query,
    remove_space_query = remove_space_query,
    add_space_mutation = add_space_mutation,
    remove_space_mutation = remove_space_mutation,
    remove_operations_by_space_name = remove_operations_by_space_name,

    -- Resolve triggers
    on_resolve = on_resolve,
    remove_on_resolve_triggers = remove_on_resolve_triggers,
}
