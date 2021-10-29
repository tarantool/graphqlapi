# Changelog

## 0.0.2

- `automatically add/remove schemas to graphqlide registry`
- `rename remove_query_prefix() to remove_queries_prefix()`
- `rename remove_mutation_prefix() to remove_mutations_prefix()`
- `fix specifiedByUrl directive and specifiedByUrl field not propagated to introspection`
- `improve tests of embedded graphql module`
- `update luatest@0.5.5 to luatest@0.5.6`
- `improve cartridge full example (update dependencies, simplify code)`
- `fix default Tarantool Cartridge authorization doesn't work`
- `more accurate cast of Tarantool object names to GraphQL names allowed characters`
- `make arguments/directives arguments defaults to be propagated more carefully during request execution`
- `rename 'cartridge-example' to 'cartridge-full'`
- `add simple Cartridge App example`
- `remove double error logging if fragments dir is not found`
- `rename fragments.list_fragments to fragments.fragments_list`
- `rename fragments.list_loaded to fragments.loaded_list`
- `rename schemas.list_schemas to schemas.schemas_list`
- `rename operations.list_queries to operations.queries_list`
- `rename operations.mutations_list to operation.mutations_list`
- `rename types.list_types to types.types_list`
- `map lua 'integer' to GraphQL 'Long' type`
- `updated description of all APIs`

## 0.0.1

Initial Release.
