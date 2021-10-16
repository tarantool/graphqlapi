local cartridge = require('cartridge')
local hotreload = require('cartridge.hotreload')
local graphqlapi = require('graphqlapi')
local helpers = require('graphqlapi.helpers')
local auth = require('cartridge.auth')

local function init()
    local httpd = cartridge.service_get('httpd')
    hotreload.whitelist_globals({
        '__GRAPHQLAPI_ENDPOINT',
        '__GRAPHQLAPI_MODELS_DIR',
    })
    graphqlapi.init(httpd, auth)
end

local function apply_config(conf, opts)
    helpers.update_config(conf, opts)
    return true
end

local function stop()
    graphqlapi.stop()
end

return setmetatable({
    role_name = 'graphqlapi',
    init = init,
    apply_config = apply_config,
    stop = stop,
}, { __index = graphqlapi })
