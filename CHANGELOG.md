# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/)
and this project adheres to [Semantic
Versioning](http://semver.org/spec/v2.0.0.html) except to the first release.

## [Unreleased]

### Added

### Changed

### Fixed

## [0.0.15] - 2026-09-11

This release fixes Tarantool Enterprise detection under cartridge.

### Fixed

- `utils.get_tnt_version()` aborting with `variable 'tarantool' is not
  declared` in Cartridge applications, which broke Tarantool Enterprise
  detection (#61).

## [0.0.14] - 2026-09-11

This release fixes Tarantool Enterprise detection and flaky tests.

### Fixed

- Detect Tarantool Enterprise by tarantool.package in utils.get_tnt_version()
  (#58).
- Flaky `cluster.test_get_instances` and `cluster.test_get_replicaset_instances`
  tests by waiting until all instances report `healthy` status before running
  assertions.

## [0.0.13] - 2026-03-19

This release removes support for the ddl enterprise edition.

### Removed

- Support for ddl-ee (reverted the previously added support) (#55).

## [0.0.12] - 2024-06-18

This release adds support for the ddl enterprise edition.

### Added

- Support for ddl-ee.

## [0.0.11] - 2024-04-11

This release allows using ddl 1.7.0 and newer.

### Changed

- Allow working with ddl 1.7.0 and newer (#53).

## [0.0.10] - 2023-03-21

This release changes versioning support.

### Changed

- Change versioning support (#51).

## [0.0.9] - 2022-05-26

This release adds GraphQL over IPROTO support and fixes a number of scalar,
variable and array handling issues.

### Added

- GraphQL over IPROTO support (#37).
- `bucket_id` wrapper (#39).
- `operations.get_operation_fields()` to extract operation requested fields
  (#42).
- `utils.find()` helper (#42).
- `cluster.get_candidates()` method (#46, #47).

### Changed

- Rename `schemas.schemas_list()` to `schemas.list()` (#40).
- Use the cmake build type instead of the builtin one (#44).
- Update dependencies to latest (#35).
- Update examples dependencies: graphqlide@0.0.19 -> graphqlide@0.0.21,
  graphqlapi@0.0.8 -> graphqlapi@0.0.9, graphqlapi-helpers@0.0.8 ->
  graphqlapi-helpers@0.0.9 (#50).

### Fixed

- `is_array()` not working properly (#26, #27).
- Accept a cdata number as a value of a Float variable and forbid NaN and Inf
  (#28).
- Coerce scalar list variables (#30).
- Returning gapped arrays (#31).
- Silently cast huge cdata numbers to null (#32).
- Arguments and variables nullability validation (#33).
- Map (custom scalar type) - prevent dual `json.encode` in some cases (#34).
- Schema caching not working (#38).
- GraphQLIDE endpoints not registered in some cases (#41).

### Removed

- Sharding functions helpers (ddl 1.6+ now fully supports custom sharding
  functions) (#35).

## [0.0.8] - 2022-02-07

This release updates example dependencies.

### Changed

- Update examples dependencies: graphqlide@0.0.18 -> graphqlide@0.0.19,
  graphqlapi@0.0.7 -> graphqlapi@0.0.8, graphqlapi-helpers@0.0.7 ->
  graphqlapi-helpers@0.0.8 (#25).

## [0.0.7] - 2022-01-30

This release adds request caching and internal argument checks, and improves
custom scalar support.

### Added

- `utils.cache_get()` and `utils.cache_set()` methods (#17).
- Caching of GraphQL requests (#17).
- Arguments check helpers (#17).
- `specifiedByURL` for custom GraphQL scalars (#20).
- Propagation of `defaultValues` and `directivesDefaultValues` to callback
  (#21).

### Changed

- Replace the checks module with internal check helpers to increase performance
  (#17).
- Update luatest@0.5.6 to luatest@0.5.7 (#22).
- Make requirements compatible with Cartridge 2.6.0+ (#22).
- Speed up CI (#22).

## [0.0.6] - 2022-01-11

This release fixes coercion of default values during schema generation.

### Fixed

- Coercing default values on schema generation (#14).

## [0.0.5] - 2022-01-11

This release switches to the vanilla graphql library and renames a number of
API fields.

### Changed

- Rename errors class in the cluster submodule.
- Rename `specifiedByUrl` to `specifiedBy`.
- Use the vanilla graphql library (#9).
- Remove empty schema if it doesn't contain operations or prefixes (#11).
- Actualize examples (#12).

### Fixed

- Not injecting module version in the release workflow (#10).

## [0.0.4] - 2021-11-16

This release fixes compatibility helpers and argument description
introspection.

### Added

- `status` field to `cluster.get_replicaset_instances()` and
  `cluster.get_instances()`.
- `utils.get_tnt_version()` function.

### Fixed

- `utils.to_compat()` and `utils.from_compat()` incorrect logic.
- Arguments description introspection propagation.

## [0.0.3] - 2021-11-02

This release updates paths and example dependencies after the repository move
to the tarantool org.

### Changed

- Paths after moving the repo to github/tarantool (#3).
- Examples dependencies after moving the repo to github/tarantool (#3).

## [0.0.2] - 2021-10-29

This release improves the embedded GraphQL module, renames a number of APIs,
and fixes Cartridge authorization.

### Added

- Automatically add/remove schemas to the GraphQLIDE registry.
- Simple Cartridge App example.

### Changed

- Rename `remove_query_prefix()` to `remove_queries_prefix()`.
- Rename `remove_mutation_prefix()` to `remove_mutations_prefix()`.
- Improve tests of the embedded graphql module.
- Update luatest@0.5.5 to luatest@0.5.6.
- Improve the cartridge full example (update dependencies, simplify code).
- More accurate cast of Tarantool object names to GraphQL names allowed
  characters.
- Make arguments/directives arguments defaults to be propagated more carefully
  during request execution.
- Rename 'cartridge-example' to 'cartridge-full'.
- Rename `fragments.list_fragments` to `fragments.fragments_list`.
- Rename `fragments.list_loaded` to `fragments.loaded_list`.
- Rename `schemas.list_schemas` to `schemas.list`.
- Rename `operations.list_queries` to `operations.queries_list`.
- Rename `operations.mutations_list` to `operation.mutations_list`.
- Rename `types.list_types` to `types.types_list`.
- Map Lua `integer` to the GraphQL `Long` type.
- Update description of all APIs.
- Update examples dependency cartridge@2.7.2 to cartridge@2.7.3.

### Fixed

- `specifiedByUrl` directive and `specifiedByUrl` field not propagated to
  introspection.
- Default Tarantool Cartridge authorization not working.
- Double error logging if the fragments dir is not found.

## [0.0.1] - 2021-09-22

Initial Release.
