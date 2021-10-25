local cartridge = require('cartridge')
local graphqlide_ok, graphqlide = pcall(require, 'graphqlide')

local function init(opts) -- luacheck: no unused args
    -- if opts.is_master then
    -- end

    -- add wrapper to to be able collect metrics on GraphQL http endpoint requests
    local metrics = cartridge.service_get('metrics')
    local graphqlapi = cartridge.service_get('graphqlapi')
    if metrics ~= nil and graphqlapi ~= nil then
        local latency_collector = metrics.summary(
            'http_server_request_latency',
            'HTTP Server Request Latency',
            { [0.5] = 1e-6, [0.9] = 1e-6, [0.99] = 1e-6, },
            { max_age_time = 60, age_buckets_count = 5, }
        )
        metrics.http_middleware.set_default_collector(latency_collector)
        local middleware = {}
        middleware.request_wrapper = metrics.http_middleware.v1
        graphqlapi.set_middleware(middleware)
    end

    if graphqlide_ok == true then
        -- add Tarantool Cartridge GraphQL API schema to GraphQLIDE
        graphqlide.add_cartridge_api_endpoint('Admin')
        -- make Tarantool Cartridge GraphQL API schema default
        graphqlide.set_default('Admin')
    end

    return true
end

local function stop()
    return true
end

local function validate_config(conf_new, conf_old) -- luacheck: no unused args

    return true
end

local function apply_config(conf, opts) -- luacheck: no unused args
    -- if opts.is_master then
    -- end

    return true
end

return {
    role_name = 'app.roles.api',
    init = init,
    stop = stop,
    validate_config = validate_config,
    apply_config = apply_config,
    dependencies = {
        'cartridge.roles.vshard-router',
        'cartridge.roles.crud-router',
        'cartridge.roles.graphqlide',
        'cartridge.roles.graphqlapi',
    }
}
