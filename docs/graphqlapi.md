# Module **graphqlapi** Lua API

- [Module **graphqlapi** Lua API](#module-graphqlapi-lua-api)
  - [Lua API](#lua-api)
    - [init()](#init)
    - [stop()](#stop)
    - [reload()](#reload)
    - [set_fragments_dir()](#set_fragments_dir)
    - [get_fragments_dir()](#get_fragments_dir)
    - [set_endpoint()](#set_endpoint)
    - [get_endpoint()](#get_endpoint)
    - [VERSION](#version)

Module `graphqlapi.lua` is a main module which provides general functions to init/stop/reload module and also for setting/getting http-endpoint and for setting/getting GraphQLAPI fragments dir path.

It can be loaded by the following code:

```lua
    local graphqlapi = require('graphqlapi')
```

If module runs in Tarantool Cartridge Application Role you can also use the following syntax:

```lua
    local cartridge = require('cartridge')
    local graphqlapi = cartridge.service_get('cartridge')
```

## Lua API

### init()

`graphqlapi.init(httpd, middleware, endpoint, fragments_dir, opts)` - function is used to initialize GraphQLAPI module,

where:

- `httpd` (`table`) - mandatory, instance of a Tarantool HTTP server;

- `middleware` (`table`) - optional, instance of set of middleware callbacks;

- `endpoint` (`string`) - optional, URI of http endpoint to be used for interacting with GraphQLAPI module, default value: `http(s)://<server:port>/admin/graphql`;

- `fragments_dir` (`string`)  - optional, path to dir with customer GraphQL fragments, default value: `<app_root>/fragments`;

- `opts` (`table`) - optional, options of http-route, options are the same as http:route [HTTP routes](https://github.com/tarantool/http/tree/1.1.0#using-routes)

Example:

```lua
    local http = require('http.server')
    local graphqlapi = require('graphqlapi')

    local HOST = '0.0.0.0'
    local PORT = 8081
    local ENDPOINT = '/graphql'

    box.cfg({work_dir = './tmp'})

    local httpd = http.new(HOST, PORT,{ log_requests = false })

    httpd:start()
    graphqlapi.init(httpd, nil, ENDPOINT, '../example/fragments')
```

### stop()

`graphqlapi.stop()` - function is used to deinit GraphQL API module, remove all used variables, cleanup cache and destroy http-endpoint.

### reload()

`graphqlapi.reload()` - function is used to reload all fragments from disk. Usually used to load new fragments, that may be placed to the same fragments_dir.

### set_fragments_dir()

`graphqlapi.set_fragments_dir(fragments_dir)` - function is used to get GraphQL API fragments dir path, 

where:

- `fragments_dir` (`string`) - mandatory, path to GraphQL API fragments. Base path - is the path to root dir of the application, but absolute path is also possible.

Example:

```lua
    local graphqlapi = require('graphqlapi')
    graphqlapi.set_fragments_dir('fragments')
```

### get_fragments_dir()

`graphqlapi.get_fragments_dir()` - function is used to get GraphQL API fragments dir path, 

Returns `fragments_dir` (`string`) - path to GraphQL API fragments.

Example:

```lua
    local graphqlapi = require('graphqlapi')
    local log = require('log')
    local fragments_dir = graphqlapi.get_fragments_dir()
    log.info('GraphQL API fragments dir path: %s', fragments_dir)
```

### set_endpoint()

`graphqlapi.set_endpoint(endpoint)` - function is used to set endpoint in runtime.

where:

- `endpoint` (`string`) - mandatory, URI-endpoint of GraphQL API.

Example:

```lua
    local graphqlapi = require('graphqlapi')
    local endpoint = '/admin/graphql'
    graphqlapi.set_endpoint(endpoint)
```

### get_endpoint()

`graphqlapi.get_endpoint()` - function is used to get endpoint.

Returns:

- `endpoint` (`string`).

Example:

```lua
    local graphqlapi = require('graphqlapi')
    local log = require('log')
    local graphqlapi_endpoint = graphqlapi.get_endpoint()
    log.info('GraphQL API endpoint: %s', graphqlapi_endpoint)
```

### VERSION

GraphQLAPI module and Tarantool Cartridge role has `VERSION` constant to determine which version is installed.

Example:

```lua
    local graphqlapi = require('graphqlapi')
    local log = require('log')
    log.info('GraphQL API version: %s', graphqlapi.VERSION)
```
