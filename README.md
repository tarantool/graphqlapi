# Tarantool GraphQL API module

- [Tarantool GraphQL API module](#tarantool-graphql-api-module)
  - [General description](#general-description)
  - [Install pre-built rock](#install-pre-built-rock)
  - [Lua API](#lua-api)
  - [Simple start](#simple-start)
  - [Examples](#examples)

## General description

Module based on:

- [Tarantool 2.8.4+](https://www.tarantool.io/en/download/)
- [Tarantool Cartridge 2.7.4+](https://github.com/tarantool/cartridge)
- [Tarantool Graphql 0.1.4+](https://github.com/tarantool/graphql)
- [Tarantool DDL 1.6.0+](https://github.com/tarantool/ddl)
- [Tarantool VShard 0.1.19+](https://github.com/tarantool/vshard)
- [Tarantool Checks 3.1.0+](https://github.com/tarantool/checks)
- [Tarantool Errors 2.2.1+](https://github.com/tarantool/errors)
- [Tarantool GraphQLIDE 0.0.20+](https://github.com/tarantool/graphqlide)

**CAUTION:** Since this module is under heavy development it is not recommended to use on production environments and also API and functionality in future releases may be changed without backward compatibility!

## Install pre-built rock

Simply run from the root of Tarantool App root the following:

```bash
    cd <tarantool-application-dir>
    tarantoolctl rocks install graphqlapi
```

## Lua API

GraphQL API module has a several submodules. Each of submodule has an API that described in the following docs:

- [graphqlapi](./docs/graphqlapi.md)
- [graphqlapi.cluster](./docs/cluster.md)
- [graphqlapi.defaults](./docs/defaults.md)
- [graphqlapi.fragments](./docs/fragments.md)
- [graphqlapi.helpers](./docs/helpers.md)
- [graphqlapi.middleware](./docs/middleware.md)
- [graphqlapi.operations](./docs/operations.md)
- [graphqlapi.schemas](./docs/schemas.md)
- [graphqlapi.types](./docs/types.md)

## Simple start

1. Install the following modules to your app:

```bash
    cd <tarantool-application-dir>
    
    # install GraphQL IDE
    tarantoolctl rocks install graphqlide

    # install GraphQL API
    tarantoolctl rocks install graphqlapi

    # install GraphQL API Helpers (available only for Tarantool Enterprise SDK users)
    tarantoolctl rocks install graphqlapi-helpers
```

1. Add dependent roles to router custom role:

```lua
    ...
    dependencies = {
        ...
        'cartridge.roles.graphqlide',
        'cartridge.roles.graphqlapi',
    },
    ...
```

3. Add helpers to init() router custom role:

```lua
local function init(opts) -- luacheck: no unused args
    -- if opts.is_master then
    -- end

    spaces.init({ schema = 'Spaces' })
    data.init({ schema = 'Data' })

    return true
end
```

4. Add custom fragments (if need some) to `./fragments` dir.

## Examples

For simple example of using this module refer to: [GraphQL API simple example](./examples/cartridge-simple)

For fully featured example of using this module refer to: [GraphQL API full featured example](./examples/cartridge-full)
