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
    - [set_middleware()](#set_middleware)
    - [get_middleware()](#get_middleware)
    - [VERSION](#version)

Module `graphqlapi.lua` is a main module which provides general functions to init/stop/reload module and also for setting/getting http-endpoint, setting/getting middleware and setting/getting GraphQLAPI fragments dir path.

It can be loaded by the following code:

```lua
    local graphqlapi = require('graphqlapi')
```

If module runs in Tarantool Cartridge Application Role you can also use the following syntax:

```lua
    local cartridge = require('cartridge')
    local graphqlapi = cartridge.service_get('graphqlapi')
```

## Lua API

### init()

`graphqlapi.init(httpd, middleware, endpoint, fragments_dir, opts)` - method is used to initialize GraphQLAPI module,

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

`graphqlapi.stop()` - method is used to deinit GraphQL API module, remove all used variables, cleanup cache and destroy http-endpoint.

### reload()

`graphqlapi.reload()` - method is used to reload all fragments from disk. Usually used to load new fragments, that may be placed to the same fragments_dir.

### set_fragments_dir()

`graphqlapi.set_fragments_dir(fragments_dir)` - method is used to get GraphQL API fragments dir path, 

where:

- `fragments_dir` (`string`) - mandatory, path to GraphQL API fragments. Base path - is the path to root dir of the application, but absolute path is also possible.

Example:

```lua
    local graphqlapi = require('graphqlapi')
    graphqlapi.set_fragments_dir('fragments')
```

### get_fragments_dir()

`graphqlapi.get_fragments_dir()` - method is used to get GraphQL API fragments dir path, 

Returns `fragments_dir` (`string`) - path to GraphQL API fragments.

Example:

```lua
    local graphqlapi = require('graphqlapi')
    local log = require('log')
    local fragments_dir = graphqlapi.get_fragments_dir()
    log.info('GraphQL API fragments dir path: %s', fragments_dir)
```

### set_endpoint()

`graphqlapi.set_endpoint(endpoint)` - method is used to set endpoint in runtime.

where:

- `endpoint` (`string`) - mandatory, URI-endpoint of GraphQL API.

Example:

```lua
    local graphqlapi = require('graphqlapi')
    local endpoint = '/admin/graphql'
    graphqlapi.set_endpoint(endpoint)
```

### get_endpoint()

`graphqlapi.get_endpoint()` - method is used to get endpoint.

Returns:

- `endpoint` (`string`).

Example:

```lua
    local graphqlapi = require('graphqlapi')
    local log = require('log')
    local graphqlapi_endpoint = graphqlapi.get_endpoint()
    log.info('GraphQL API endpoint: %s', graphqlapi_endpoint)
```

### set_middleware()

`graphqlapi.set_middleware(http_middleware)` - method is used to set custom middleware triggers,

where:

- `http_middleware` (`table`) - mandatory, table with one or more provided middleware functions:

```lua
    http_middleware = {
        render_response = function(resp) return resp end,
        request_wrapper = function(handler) return handler end,
        authorize_request = function(req) return true end,
    }
```

For more detailed info about this triggers refer to [middleware submodule](middleware.md).

Example:

```lua
    local graphqlapi = require('graphqlapi')
    local http_middleware = require('middleware')
    graphqlapi.set_endpoint(http_middleware)
```

### get_middleware()

`graphqlapi.get_middleware()` - method is used to set custom middleware triggers,

returns:

`[1]` (`table`) - current http-middleware triggers. For more info refer to [middleware submodule](middleware.md).

### VERSION

GraphQLAPI module and Tarantool Cartridge role has `VERSION` constant to determine which version is installed.

Example:

```lua
    local graphqlapi = require('graphqlapi')
    local log = require('log')
    log.info('GraphQL API version: %s', graphqlapi.VERSION)
```
