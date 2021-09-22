# Tarantool GraphQL API module

- [Tarantool GraphQL API module](#tarantool-graphql-api-module)
  - [General description](#general-description)
  - [Install pre-built rock](#install-pre-built-rock)
  - [Lua API](#lua-api)
  - [Example](#example)

## General description

Module based on:

- [Tarantool 2.x.x](https://www.tarantool.io/en/download/)
- [Tarantool Cartridge 2.6.0+](https://github.com/tarantool/cartridge) (optional)
- [Tarantool Graphql 0.1.1+](https://github.com/tarantool/graphql)
- [Tarantool DDL 1.4.0+](https://github.com/tarantool/ddl)
- [Tarantool VShard 0.1.18](https://github.com/tarantool/vshard)
- [Tarantool Checks 1.1.0+](https://github.com/tarantool/checks)
- [Tarantool Errors 2.1.3+](https://github.com/tarantool/errors)

**CAUTION:** Since this module is under heavy development it is not recommended to use on production environments and also API and functionality in future releases may be changed without backward compatibility!

## Install pre-built rock

Simply run from the root of Tarantool App root the following:

```sh
    cd <tarantool-application-dir>
    tarantoolctl rocks install https://github.com/no1seman/graphqlapi/releases/download/0.0.1/graphqlapi-0.0.1-1.all.rock
```

## Lua API

This module has a several submodules:

- [graphqlapi](./docs/graphqlapi.md)
- [graphqlapi.cluster](./docs/cluster.md)
- [graphqlapi.defaults](./docs/defaults.md)
- [graphqlapi.fragments](./docs/fragments.md)
- [graphqlapi.helpers](./docs/helpers.md)
- [graphqlapi.middleware](./docs/middleware.md)
- [graphqlapi.operations](./docs/operations.md)
- [graphqlapi.schemas](./docs/schemas.md)
- [graphqlapi.types](./docs/types.md)

## Example

For fully featured example of using this module refer to: [GraphQL API Example](./examples/cartridge-example)

To run example:

```sh
  cd ./examples/cartridge-example/
  ./deps.sh
  ./scripts/start.sh
  ./scripts/bootstrap.sh
  ./scripts/fill.sh
```

Then follow: `http://localhost:8081`
