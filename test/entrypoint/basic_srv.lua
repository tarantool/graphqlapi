#!/usr/bin/env tarantool

require('strict').on()

local log = require('log')
local errors = require('errors')
local cartridge = require('cartridge')

package.preload['app.roles.api'] = function()
    local function init(opts) -- luacheck: no unused args
        -- if opts.is_master then
        -- end
        return true
    end

    local function stop()
       cartridge.service_get('graphqlapi').stop()
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
            'cartridge.roles.graphqlapi',
        },
    }
end

package.preload['app.roles.storage'] = function()
    local function init(opts) -- luacheck: no unused args
        -- if opts.is_master then
        -- end
        return true
    end

    local function stop()
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
        role_name = 'app.roles.storage',
        init = init,
        stop = stop,
        validate_config = validate_config,
        apply_config = apply_config,
        dependencies = {
            'cartridge.roles.vshard-storage',
        },
    }
end

package.preload['graphqlide'] = function()
    local ENDPOINTS = {}

    local function get_endpoints()
        return ENDPOINTS
    end

    local function remove_side_slashes(path)
        if path:startswith('/') then
            path = path:sub(2)
        end
        if path:endswith('/') then
            path = path:sub(1, -2)
        end
        return path
    end

    local function set_endpoint(endpoint)
        if endpoint.default == true then
            for name in pairs(ENDPOINTS) do
                ENDPOINTS[name].default = false
            end
        end

        ENDPOINTS[endpoint.name] = {
            path = remove_side_slashes(endpoint.path),
            default = endpoint.default or false,
            options = endpoint.options
        }

    end

    local function remove_endpoint(name)
        if ENDPOINTS[name] ~= nil then
            ENDPOINTS[name] = nil
            return true
        end
        return false
    end

    return {
        get_endpoints = get_endpoints,
        set_endpoint = set_endpoint,
        remove_endpoint = remove_endpoint,
    }
end

local ok, err = errors.pcall('CartridgeCfgError', cartridge.cfg, {
    roles = {
        'cartridge.roles.vshard-storage',
        'cartridge.roles.vshard-router',
        'cartridge.roles.graphqlapi',
        'app.roles.api',
        'app.roles.storage',
    },
    roles_reload_allowed = true,
})

if not ok then
    log.error('%s', err)
    os.exit(1)
end
