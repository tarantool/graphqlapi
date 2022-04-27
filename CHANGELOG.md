# Changelog

## Unreleased

- `Fix is_array() not working properly`
- `Accept a cdata number as value of a Float variable and forbid NaN and Inf`
- `Fix coerce scalar list variables`
- `Fix returning gapped arrays`

## 0.0.8

- `update examples dependencies: graphqlide@0.0.18 ->  graphqlide@0.0.19, graphqlapi@0.0.7 -> graphqlapi@0.0.8, graphqlapi-helpers@0.0.7 -> graphqlapi-helpers@0.0.8`

## 0.0.7

- `add utils.cache_get() and utils.cache_set() methods`
- `add caching of graphql requests`
- `add arguments check helpers`
- `replace checks module to internal check helpers to increase performance`
- `add specifiedByURL for custom GraphQL scalars`
- `add propagation of defaultValues and directivesDefaultValues to callback`
- `update luatest@0.5.6 to luatest@0.5.7`
- `make requirements compatible with Cartridge 2.6.0+`
- `speedup CI`

## 0.0.6

- `fix coercing default values on schema generation`

## 0.0.5

- `rename errors class in cluster submodule`
- `rename specifiedByUrl to specifiedBy`
- `use vanilla graphql lib`
- `fixed not injecting module version in release workflow`
- `remove empty schema if it doesn't contain operations or prefixes`
- `actualize examples`

## 0.0.4

- `fix utils.to_compat() and utils.from_compat() incorrect logic`
- `add status field to cluster.get_replicaset_instances() and cluster.get_instances()`
- `add utils.get_tnt_version() function`
- `fix arguments description introspection propagation`

## 0.0.3

- `change paths after move repo to github/tarantool`
- `update examples dependencies after move repo to github/tarantool`

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
- `update examples dependency cartridge@2.7.2 to cartridge@2.7.3`

## 0.0.1

Initial Release.
