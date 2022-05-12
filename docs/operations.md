# Submodule **operations** Lua API

- [Submodule **operations** Lua API](#submodule-operations-lua-api)
  - [Lua API](#lua-api)
    - [stop()](#stop)
    - [remove_all()](#remove_all)
    - [get_queries()](#get_queries)
    - [get_mutations()](#get_mutations)
    - [add_queries_prefix()](#add_queries_prefix)
    - [is_queries_prefix_exists()](#is_queries_prefix_exists)
    - [remove_queries_prefix()](#remove_queries_prefix)
    - [add_mutations_prefix()](#add_mutations_prefix)
    - [is_mutations_prefix_exists()](#is_mutations_prefix_exists)
    - [remove_mutations_prefix()](#remove_mutations_prefix)
    - [add_query()](#add_query)
    - [is_query_exists()](#is_query_exists)
    - [remove_query()](#remove_query)
    - [queries_list()](#queries_list)
    - [add_mutation()](#add_mutation)
    - [is_mutation_exists()](#is_mutation_exists)
    - [remove_mutation()](#remove_mutation)
    - [mutations_list()](#mutations_list)
    - [add_space_query()](#add_space_query)
    - [remove_space_query()](#remove_space_query)
    - [add_space_mutation()](#add_space_mutation)
    - [remove_space_mutation()](#remove_space_mutation)
    - [remove_operations_by_space_name()](#remove_operations_by_space_name)
    - [on_resolve()](#on_resolve)
    - [remove_on_resolve_triggers()](#remove_on_resolve_triggers)
    - [is_schema_empty()](#is_schema_empty)
    - [get_operation_fields()](#get_operation_fields)

Submodule `operations.lua` - is a part of GraphQL API module provided functions to add/remove queries, mutations and it's prefixes as well as subsidiary functions to deal with GraphQL operations.

## Lua API

### stop()

`operations.stop()` - method to deinit `operations` submodule, it removes all queries, mutations and cleanup all internal module variables including trigger functions that controls any space format changes. This behavior is needed to make possible hot-reload of all GraphQL API operations.

### remove_all()

`operations.remove_all()` - method to remove all queries, mutations and cleanup all internal module variables. Unlike `stop()` `remove_all()` doesn't remove space trigger function.

### get_queries()

`operations.get_queries()` - function to get all GraphQL API schema registered queries,

returns:

- `queries` (`table`) - map with all registered queries. If query is prefixed it will be returned in the following format: "prefix.query_name".

### get_mutations()

`operations.get_mutations()` - function to get all GraphQL API schema registered mutations,

returns:

- `mutations` (`table`) - map with all GraphQL API schema registered mutations. If mutation is prefixed it will be returned in the following format: "prefix.mutation_name".

### add_queries_prefix()

`operations.add_queries_prefix(opts)` - method to add queries prefix to the desired schema,

where:

- `opts` (`table`) - mandatory, options to create queries prefix:
  - `prefix` (`string`) - mandatory, queries prefix name compliant with [#2.1.9 GraphQL specification](http://spec.graphql.org/draft/#sec-Names);
  - `type_name` (`string`) - optional, custom prefix object type name. By default, if `type_name` is not provided created prefix will have the following type name:  [defaults.QUERIES_PREFIX](defaults.md#queries_prefix)..opts.prefix and if `type_name` is is provided then opts.type_name will be used for prefix object type name;
  - `schema` (`string`) - optional, schema name, if nil - then default schema is used [Default schema](defaults.md#default_schema_name);
  - `doc` (`string`) - any arbitrary text that describes prefixed set of GraphQL queries.

Example:

```lua
    require('graphqlapi.operations').add_queries_prefix({
      prefix = 'queries_prefix',
      type_name = 'API_QUERIES_PREFIX',
      schema = 'Default',
      docs = 'Set of queries',
    })
```

### is_queries_prefix_exists()

`operations.is_queries_prefix_exists(opts)` - method to check is queries prefix already exists in the desired schema,

where:

- `opts` (`table`) - mandatory, options to check queries prefix:
  - `prefix` (`string`) - mandatory, queries prefix name compliant with [#2.1.9 GraphQL specification](http://spec.graphql.org/draft/#sec-Names);
  - `schema` (`string`) - optional, schema name, if nil - then default schema is used [Default schema](defaults.md#default_schema_name),

returns:

`[1]` (`boolean`) - `true` if requested queries prefix already exists in desired schema, `false` if not.

### remove_queries_prefix()

`operations.remove_queries_prefix(opts)` - method to remove queries prefix and all the underlying queries to keep schema consistent,

where:

- `opts` (`string`) - mandatory, queries prefix options:
  - `prefix` (`string`) - mandatory, queries prefix name compliant with [#2.1.9 GraphQL specification](http://spec.graphql.org/draft/#sec-Names);
  - `schema` (`string`) - optional, schema name, if nil - then default schema is used [Default schema](defaults.md#default_schema_name).


Example:

```lua
    require('graphqlapi.operations').remove_queries_prefix('queries_prefix')
```

### add_mutations_prefix()

`operations.add_mutations_prefix(opts)` - method to add mutations prefix to the desired schema,

where:

- `opts` (`table`) - mandatory, options to create mutations prefix:
  - `prefix` (`string`) - mandatory, mutations prefix name compliant with [#2.1.9 GraphQL specification](http://spec.graphql.org/draft/#sec-Names);
  - `type_name` (`string`) - optional, custom mutations prefix object type name. By default, if `type_name` is not provided created prefix will have the following type name:  [defaults.QUERIES_PREFIX](defaults.md#mutations_prefix)..opts.prefix and if `type_name` is is provided then opts.type_name will be used for prefix object type name;
  - `schema` (`string`) - optional, schema name, if nil - then default schema is used [Default schema](defaults.md#default_schema_name);
  - `doc` (`string`) - any arbitrary text that describes prefixed set of GraphQL queries.

Example:

```lua
    require('graphqlapi.operations').add_mutations_prefix({
      prefix = 'mutations_prefix',
      type_name = 'MUTATIONS_API_PREFIX',
      schema = 'Default',
      docs = 'Set of mutations',
    })
```

### is_mutations_prefix_exists()

`operations.is_mutations_prefix_exists(opts)` - method to check is mutations prefix already exists in the desired schema,

where:

- `opts` (`table`) - mandatory, options to check mutations prefix:
  - `prefix` (`string`) - mandatory, mutations prefix name compliant with [#2.1.9 GraphQL specification](http://spec.graphql.org/draft/#sec-Names);
  - `schema` (`string`) - optional, schema name, if nil - then default schema is used [Default schema](defaults.md#default_schema_name),

returns:

`[1]` (`boolean`) - `true` if requested mutations prefix already exists in the desired schema, `false` if not.

### remove_mutations_prefix()

`operations.remove_mutations_prefix(opts)` - method to remove mutations prefix and all the underlying queries to keep schema consistent,

where:

- `opts` (`string`) - mandatory, mutations prefix options:
  - `prefix` (`string`) - mandatory, mutations prefix name compliant with [#2.1.9 GraphQL specification](http://spec.graphql.org/draft/#sec-Names);
  - `schema` (`string`) - optional, schema name, if nil - then default schema is used [Default schema](defaults.md#default_schema_name).


Example:

```lua
    require('graphqlapi.operations').remove_mutations_prefix('mutations_prefix')
```

### add_query()

`operations.add_query(opts)` - method to add GraphQL query,

where:

- `opts` (`table`) - mandatory, query options:
  - `schema` (`string`) - optional, schema name, if nil - then default schema is used [Default schema](defaults.md#default_schema_name).
  - `prefix` (`string`) - optional, queries prefix name compliant with [#2.1.9 GraphQL specification](http://spec.graphql.org/draft/#sec-Names). Queries prefix must be created before using it;
  - `name` (`string`) - mandatory, query name compliant with [#2.1.9 GraphQL specification](http://spec.graphql.org/draft/#sec-Names);
  - `doc` (`string`) - optional, any arbitrary text that describes query;
  - `args` (`table`) - optional, table of query arguments - map of GraphQL scalars or inputObjects compliant with [#2.6 GraphQL specification](http://spec.graphql.org/draft/#sec-Language.Arguments);
  - `kind` (`table|string`) - mandatory, list of GraphQL scalars or GraphQL object compliant with [#2.6 GraphQL specification](http://spec.graphql.org/draft/#sec-Language.Arguments) or string;
  - `callback` (`string`) - mandatory, path and name of function to be called to execute GraphQL query.

Example:

```lua
  require('operations').add_query({
        schema = `Default`,
        prefix = 'entities',
        name = 'entity',
        doc = 'Get entity object',
        args = {
            entity_id = types.string.nonNull,
            id = types.int,
            user = types()['user_entity_input']
        },
        kind = types.list(types.entity),
        callback = 'fragments.entity.entity_get',
    })
```

### is_query_exists()

`operations.is_query_exists(opts)` - method to check if query already exists in the desired schema,

where:

- `opts` (`table`) - mandatory, options to check query:
  - `name` (`string`) - mandatory, query name compliant with [#2.1.9 GraphQL specification](http://spec.graphql.org/draft/#sec-Names);
  - `prefix` (`string`) - mandatory, query prefix name compliant with [#2.1.9 GraphQL specification](http://spec.graphql.org/draft/#sec-Names);
  - `schema` (`string`) - optional, schema name, if nil - then default schema is used [Default schema](defaults.md#default_schema_name),

returns:

`[1]` (`boolean`) - `true` if requested query already exists in the desired schema, `false` if not.

### remove_query()

`operations.remove_query(opts)` - method is used to remove GraphQL query from the desired schema,

where:

- `opts` (`table`) - mandatory, options to check query:
  - `name` (`string`) - mandatory, query name compliant with [#2.1.9 GraphQL specification](http://spec.graphql.org/draft/#sec-Names);
  - `prefix` (`string`) - mandatory, query prefix name compliant with [#2.1.9 GraphQL specification](http://spec.graphql.org/draft/#sec-Names);
  - `schema` (`string`) - optional, schema name, if nil - then default schema is used [Default schema](defaults.md#default_schema_name).

Example:

```lua
  require('operations').remove_query({
    name = 'entity',
    prefix = 'entities',
    schema = `Default`,
  })
```

### queries_list()

`operations.queries_list(schema_name)` - method is used to get list of registered queries,

where:

- `schema_name` (`string`) - optional, schema name, if nil - then default schema is used [Default schema](defaults.md#default_schema_name),

returns:

- `queries` (`table`) - list of queries. If query has a prefix `queries_list()` returns it in the following format: 'entities.entity'.

### add_mutation()

`operations.add_mutation(opts)` - method to add GraphQL mutation,

where:

- `opts` (`table`) - mandatory, mutation options:
  - `schema` (`string`) - optional, schema name, if nil - then default schema is used [Default schema](defaults.md#default_schema_name);
  - `prefix` (`string`) - optional, mutations prefix name compliant with [#2.1.9 GraphQL specification](http://spec.graphql.org/draft/#sec-Names). Mutations prefix must be created before using it;
  - `name` (`string`) - mandatory, mutation name compliant with [#2.1.9 GraphQL specification](http://spec.graphql.org/draft/#sec-Names);
  - `doc` (`string`) - optional, any arbitrary text that describes mutation;
  - `args` (`table`) - optional, table of mutation arguments - list of GraphQL scalars compliant with [#2.6 GraphQL specification](http://spec.graphql.org/draft/#sec-Language.Arguments);
  - `kind` (`table|string`) - mandatory, list of GraphQL scalars compliant with [#2.6 GraphQL specification](http://spec.graphql.org/draft/#sec-Language.Arguments) or string;
  - `callback` (`string`) - mandatory, path and name of function to be called to execute GraphQL mutation.

Example:

```lua
  require('operations').add_mutation({
        schema = `Default`,
        prefix = 'entities',
        name = 'entity',
        doc = 'Update entity object',
        args = {
            entity_id = types.string.nonNull,
            entity = types.string.nonNull,
        },
        kind = types.list(types.entity),
        callback = 'fragments.entity.entity_update',
    })
```

### is_mutation_exists()

`operations.is_mutation_exists(opts)` - method to check if mutation already exists in the desired schema,

where:

- `opts` (`table`) - mandatory, options to check mutation:
  - `name` (`string`) - mandatory, mutation name compliant with [#2.1.9 GraphQL specification](http://spec.graphql.org/draft/#sec-Names);
  - `prefix` (`string`) - mandatory, mutation prefix name compliant with [#2.1.9 GraphQL specification](http://spec.graphql.org/draft/#sec-Names);
  - `schema` (`string`) - optional, schema name, if nil - then default schema is used [Default schema](defaults.md#default_schema_name),

returns:

`[1]` (`boolean`) - `true` if requested mutation already exists in the desired schema, `false` if not.

### remove_mutation()

`operations.remove_mutation(name, prefix)` - method is used to remove GraphQL mutation,

where:

- `opts` (`table`) - mandatory, options to remove mutation:
  - `name` (`string`) - mandatory, mutation name compliant with [#2.1.9 GraphQL specification](http://spec.graphql.org/draft/#sec-Names);
  - `prefix` (`string`) - mandatory, mutation prefix name compliant with [#2.1.9 GraphQL specification](http://spec.graphql.org/draft/#sec-Names);
  - `schema` (`string`) - optional, schema name, if nil - then default schema is used [Default schema](defaults.md#default_schema_name).

Example:

```lua
  require('operations').remove_mutation({
    name = 'entity',
    prefix = 'entities',
    schema = `Default`,
  })
```

### mutations_list()

`operations.mutations_list(schema_name)` - method is used to get list of registered queries,

where:

- `schema_name` (`string`) - optional, schema name, if nil - then default schema is used [Default schema](defaults.md#default_schema_name),

returns:

- `queries` (`table`) - list of queries. If mutation has a prefix `mutations_list()` returns it in the following format: 'entities.entity'.

### add_space_query()

`operations.add_space_query(opts)` - method to add GraphQL space object type and space query based on provided space format. Query and related space GraphQL type (representation) can be flexibly configured by add_space_query() options,

where:

- `opts` (`table`) - mandatory, GraphQL space query options:
  - `schema` (`string`) - optional, schema name, if nil - then default schema is used [Default schema](defaults.md#default_schema_name);
  - `type_name` (`string`) - optional, GraphQL type name related to specified space, if not provided space query related GraphQL type will be named exactly equal to space name with postfix '_space';
  - `description` (`string`) - optional, any arbitrary text that describes space GraphQL type;
  - `space` (`string`) - mandatory, name of existing space;
  - `fields` (`string`) - optional, table with list of space GraphQL type. It's possible to add any additional fields to query results that can be returned by callback function, as well as remove any unneeded space fields from query result. For example, if space has `bucket_id` field and request must not return this field then that field may be removed by the following trick:

  ```lua
    ...
    fields = { bucket_id = box.NULL }
    ...
  ```

  - `prefix` (`string`) - optional, queries prefix name compliant with [#2.1.9 GraphQL specification](http://spec.graphql.org/draft/#sec-Names). Queries prefix must be created before using it;
  - `name` (`string`) - optional, query name compliant with [#2.1.9 GraphQL specification](http://spec.graphql.org/draft/#sec-Names). if not provided will be named exactly equal to space name;
  - `doc` (`string`) - optional, any arbitrary text that describes query;
  - `args` (`table`) - optional, table of query arguments - list of GraphQL scalars compliant with [#2.6 GraphQL specification](http://spec.graphql.org/draft/#sec-Language.Arguments);
  - `kind` (`table`) - optional, by default kind will be an GraphQL object with space fields but if kind is not nil then it will used as result in this particular query;
  - `list` (`boolean`) - optional, flag to set kind as list of datasets or single dataset;
  - `callback` (`string`) - mandatory, path and name of function to be called to execute GraphQL query.

Example:

```lua
    local space = box.schema.space.create('entity', { 
        if_not_exists = true,
        format = {
          { name = 'bucket_id', type = 'unsigned', is_nullable = false },
          { name = 'entity_id', type = 'string', is_nullable = false },
          { name = 'entity', type = 'string', is_nullable = true },
        }
    })
    require('operations').add_space_query({
        schema = 'Default',
        type_name = 'entity_query_type',
        description = '"entity" query GraphQL type',
        space = 'entity',
        fields = {
            bucket_id = box.NULL
        },
        prefix = 'entities',
        name = 'entity query',
        doc = '"entity" GraphQL query',
        args = {
            entity_id = types.string.nonNull,
        },
        list = true,
        callback = 'fragments.entity_get',
    })
```

### remove_space_query()

`operations.remove_space_query(opts)` - method to remove GraphQL space object type and space query,

where:

- `opts` (`table`) - mandatory, GraphQL space query options:
  - `schema` (`string`) - optional, schema name, if nil - then default schema is used [Default schema](defaults.md#default_schema_name);
  - `prefix` (`string`) - optional, queries prefix name compliant with [#2.1.9 GraphQL specification](http://spec.graphql.org/draft/#sec-Names);
  - `space` (`string`) - mandatory, name of space;
  - `name` (`string`) - optional, query name compliant with [#2.1.9 GraphQL specification](http://spec.graphql.org/draft/#sec-Names).

### add_space_mutation()

`operations.add_space_mutation(opts)` - method to add GraphQL space object type and space mutation based on provided space format. Mutation and related space GraphQL type (representation) can be flexibly configured by add_space_mutation() options,

where:

- `opts` (`table`) - mandatory, GraphQL space mutation which has the following parameters:
  - `schema` (`string`) - optional, schema name, if nil - then default schema is used [Default schema](defaults.md#default_schema_name);
  - `type_name` (`string`) - optional, GraphQL type name related to specified space, if not provided space mutation related GraphQL type will be named exactly equal to space name;
  - `description` (`string`) - optional, any arbitrary text that describes space GraphQL type;
  - `space` (`string`) - mandatory, name of existing space;
  - `fields` (`string`) - optional, table with list of space GraphQL type fields. It's possible to add any additional fields to mutation results that can be returned by callback function, as well as remove any unneeded space fields from mutation result. For example, if space has `bucket_id` field and request must not return this field then that field may be removed by the following trick:

  ```lua
    ...
    fields = { bucket_id = box.NULL }
    ...
  ```

  - `prefix` (`string`) - optional, mutations prefix name compliant with [#2.1.9 GraphQL specification](http://spec.graphql.org/draft/#sec-Names). Mutations prefix must be created before using it;
  - `name` (`string`) - optional, mutation name compliant with [#2.1.9 GraphQL specification](http://spec.graphql.org/draft/#sec-Names). if not provided will be named exactly equal to space name;
  - `doc` (`string`) - optional, any arbitrary text that describes mutation;
  - `args` (`table`) - optional, table of mutation arguments - list of GraphQL scalars compliant with [#2.6 GraphQL specification](http://spec.graphql.org/draft/#sec-Language.Arguments);
  - `kind` (`boolean`) - optional, flag to set kind as list of datasets or single dataset;
  - `callback` (`string`) - mandatory, path and name of function to be called to execute GraphQL mutation.

Example:

```lua
    local space = box.schema.space.create('entity', { 
        if_not_exists = true,
        format = {
          { name = 'bucket_id', type = 'unsigned', is_nullable = false },
          { name = 'entity_id', type = 'string', is_nullable = false },
          { name = 'entity', type = 'string', is_nullable = true },
        }
    })
    require('operations').add_space_mutation({
        schema = 'Default',
        type_name = 'entity_mutation_type',
        description = '"entity" mutation GraphQL type',
        space = 'entity',
        fields = {
            bucket_id = box.NULL
        },
        prefix = 'entities',
        name = 'entity mutation',
        doc = '"entity" GraphQL mutation',
        args = {
            entity_id = types.string.nonNull,
        },
        kind = true,
        callback = 'fragments.entity_update',
    })
```

### remove_space_mutation()

`operations.remove_space_mutation(opts)` - method to remove GraphQL space object type and space mutation,

where:

- `opts` (`table`) - mandatory, GraphQL space mutation options:
  - `schema` (`string`) - optional, schema name, if nil - then default schema is used [Default schema](defaults.md#default_schema_name);
  - `prefix` (`string`) - optional, mutations prefix name compliant with [#2.1.9 GraphQL specification](http://spec.graphql.org/draft/#sec-Names);
  - `space` (`string`) - mandatory, name of space;
  - `name` (`string`) - optional, mutation name compliant with [#2.1.9 GraphQL specification](http://spec.graphql.org/draft/#sec-Names).


### remove_operations_by_space_name()

`operations.remove_operations_by_space_name(space_name)` - function to remove GraphQL queries and mutations related to the space previously added by `add_space_query()` and `add_space_mutation()`,

where:

- `space_name` (`string`) - mandatory, name of existing space.

### on_resolve()

`operations.on_resolve(trigger_new, trigger_old)` - method to set or remove special triggers that will be called on every GraphQL resolve. Trigger can help to solve the following cases:

- log requests and it's arguments;
- make some custom filtration of quests and its arguments;
- deny of executing some requests if it's needed,

where:

- `trigger_new` (`function`) - optional, new function to be added to triggers chain set;
- `trigger_old` (`function`) - optional, old function to be added to triggers chain set.

Note: As both two arguments `on_resolve()` is optional, but one of them must be present to apply any changes (see examples below).

Trigger function `trigger(operation_type, operation_schema, operation_prefix, operation_name, object, arguments, info)` has the following arguments:

- `operation_type` (`string`) - can contain the following values: `query` or `mutation`
- `operation_schema` (`string`) - schema name executed query or mutation belongs to;
- `operation_prefix` (`string`) - prefix name of query or mutation;
- `operation_name` (`string`) - query or mutation name;
- `object` (`table`) - GraphQL object;
- `arguments` (`table`) - a set of request arguments;
- `info` (`table`) - a set of additional request info:
  - `defaultValues` (`table`) - arguments default values;
  - `directives` (`table`) - directives;
  - `directivesDefaultValues` (`table`) - directivesdefault values,

and may return two values:

- `ok` (`boolean`) - trigger status can return:
  - nil or true - request will continue to execute as usual;
  - false - request execution will be interrupted and will be return an error (second return value);
- `err` (`any`) - an error object or any type that can be encoded to json to be able to return in http response.

Example:

```lua
    local json_options = {
      encode_use_tostring = true,
      encode_deep_as_nil = true,
      encode_max_depth = 10,
      encode_invalid_as_nil = true,
    }

    local function log_request(operation_type, operation_schema, operation_prefix, operation_name, ...)
    local _, arguments, info = ...

    -- user will be nil if no cartridge auth is enabled
    local user = cartridge.http_get_username()

    log.info("\nGraphQL request by username: %s =>\n"..
              "\toperation: %s\n"..
              "\tschema: %s\n"..
              "\tprefix: %s\n"..
              "\toperation name: %s\n"..
              "\targuments: %s\n"..
              "\targuments defaults: %s\n"..
              "\tdirectives: %s\n"..
              "\tdirectives defaults: %s",
          tostring(user or 'unknown'),
          operation_type,
          tostring(operation_schema),
          tostring(operation_prefix),
          operation_name,
          json.encode(arguments, json_options),
          json.encode(info.defaultValues, json_options),
          json.encode(info.directives, json_options),
          json.encode(info.directivesDefaultValues, json_options)
      )
    end

    local function deny_mutations(operation_type, operation_name)
        if operation_type:upper() == 'MUTATION' then
          log.info("GraphQL %s: %s", operation_type, operation_name)
          return false, errors.new('GraphQLAPIError', "Mutations temporarily prohibited")
        end
    end

    -- set triggers
    operations.on_resolve(log_request) -- start logging GraphQL requests
    operations.on_resolve(deny_mutations) -- deny GraphQL mutation requests

    -- remove one of the triggers
    operations.on_resolve(nil, deny_mutations) -- remove deny GraphQL mutation requests trigger
```

### remove_on_resolve_triggers()

`operations.remove_on_resolve_triggers()` - method to remove all GraphQL API triggers at once.

### is_schema_empty()

`operations.is_schema_empty(schema_name)` - method is used to check if schema contains at least one of: query, mutation, queries_prefix, mutations_prefix,

where:

- `schema_name` (`string`) - optional, schema name, if nil - then default schema is used [Default schema](defaults.md#default_schema_name),

returns:

- `is_schema_empty` (`boolean`) - If `true` - schema is empty and if `false` - schema contains at least one of: query, mutation, queries_prefix, mutations_prefix.

### get_operation_fields()

`operations.get_operation_fields(info, filter_func)` - method is used to extract query or mutation operation requested fields. This method can be used for different purposes in callback functions to get the list of field names that was requested by caller,

where:

- `info` (`table`) - mandatory, it's actually the third argument of a callback function;
- `filter_func` (`function`) - optional, function with custom filter which is called on each found field_name during iteration over selection set. `filter_func` has the following declaration: `cursor_filter(field_name, filter)`, where:
  - `field_name` (`string`) - name of found field name;
  - `filter` (`any`) - result of previous call of `filter_func` (initially filter is `nil`);
  
  `filter_func` must return `filter` or `nil`,

`get_operation_fields()` returns:

- `[1]` (`table`) - mandatory, array of operation requested fields or {} if no any;
- `[2]` (`any`) - final state of `filter` or nil if `filter_func` was not provided.

Example:

```lua
  -- GraphQL query
  local query = '{ entity { result, cursor } }'

  -- query callback function
  local function callback(_, arguments, info)
      local function cursor_filter(field_name, filter)
          if field_name == 'cursor' then
              return true
          end
          return filter
      end

      -- `fields` will contain an array with names of requested fields: { "result", "cursor" }
      -- `filter` will be true, because 
      local fields, filter = operations.get_operation_fields(info, cursor_filter)

      ...

      return ...
  end
```
