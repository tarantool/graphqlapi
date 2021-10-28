# Submodule **schemas** Lua API

- [Submodule **schemas** Lua API](#submodule-schemas-lua-api)
  - [Lua API](#lua-api)
    - [set_invalid()](#set_invalid)
    - [reset_invalid()](#reset_invalid)
    - [is_invalid()](#is_invalid)
    - [remove_schema()](#remove_schema)
    - [remove_all()](#remove_all)
    - [schemas_list()](#schemas_list)

Submodule `schemas.lua` is a part of GraphQL API module that provides common API for managing internal GraphQL schemas registry. Each GraphQL schema often a large tree of objects in special format. For performance purposes each schema have a cache, but if something is added or removed to the schema cache must be invalidated and on next request to this schema cache must be rebuilt.

## Lua API

### set_invalid()

`schemas.set_invalid(schema)` - method is used to invalidate schema and also this method add the desired schema to [GraphQLIDE](https://github.com/tarantool/graphqlide) schemas registry,

where:

- `schema` (`string`) - optional, schema name, if nil - then default schema is used [Default schema](defaults.md#default_schema_name).

### reset_invalid()

`schemas.reset_invalid(schema)` - method is used to reset schema invalidation,

where:

- `schema` (`string`) - optional, schema name, if nil - then default schema is used [Default schema](defaults.md#default_schema_name).

### is_invalid()

`schemas.is_invalid(schema)` - method is used to check schema invalidation state,

where:

- `schema` (`string`) - optional, schema name, if nil - then default schema is used [Default schema](defaults.md#default_schema_name).

### remove_schema()

`schemas.remove_schema(schema)` - method is used to remove schema from schemas registry and also this method removes the desired schema from [GraphQLIDE](https://github.com/tarantool/graphqlide) schemas registry,

where:

- `schema` (`string`) - optional, schema name, if nil - then default schema is used [Default schema](defaults.md#default_schema_name).

### remove_all()

`schemas.remove_all()` - method is used to remove all schemas from schemas registry and also this method removes all schemas from [GraphQLIDE](https://github.com/tarantool/graphqlide) schemas registry.


### schemas_list()

`schemas.remove_all()` - method is used to get list of Graphql schemas from schemas registry,

returns:

`[1]` (`table`) - array of strings with schemas names or {} if no any schemas is registered in schemas registry.
