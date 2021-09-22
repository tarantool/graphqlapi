local cartridge = require('cartridge')
local data_ok = pcall(require, 'graphqlapi.helpers.data')
local schema_ok = pcall(require, 'graphqlapi.helpers.schema')
local service_ok = pcall(require, 'graphqlapi.helpers.service')
local spaces_ok = pcall(require, 'graphqlapi.helpers.spaces')
local middleware = table.copy(require('graphqlapi.middleware'))

local function init(opts) -- luacheck: no unused args
    -- if opts.is_master then
    -- end

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
        middleware.request_wrapper = metrics.http_middleware.v1
        graphqlapi.set_middleware(middleware)
    end

    local graphqlide = cartridge.service_get('graphqlide')
    if graphqlide ~= nil then
        graphqlide.set_endpoint({
            name = 'Admin',
            path = '/admin/api',
            options = {
                specifiedByUrl = false,
                directiveIsRepeatable = false,
            }
        })
        graphqlide.set_endpoint({ name = 'Default', path = '/admin/graphql', default = true })
        if data_ok == true then
            graphqlide.set_endpoint({ name = 'Data', path = '/admin/graphql' })
        end
        if schema_ok == true then
            graphqlide.set_endpoint({ name = 'Schema', path = '/admin/graphql' })
        end
        if service_ok == true then
            graphqlide.set_endpoint({ name = 'Service', path = '/admin/graphql' })
        end
        if spaces_ok == true then
            graphqlide.set_endpoint({ name = 'Spaces', path = '/admin/graphql' })
        end
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
        'cartridge.roles.graphqlapi',
        'cartridge.roles.graphqlide',
    }
}
