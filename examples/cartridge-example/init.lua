#!/usr/bin/env tarantool

require('strict').on()

if package.setsearchroot ~= nil then
    package.setsearchroot()
end

local cartridge = require('cartridge')

local ok, err = cartridge.cfg({
    roles = {
        'cartridge.roles.vshard-storage',
        'cartridge.roles.vshard-router',
        'cartridge.roles.crud-storage',
        'cartridge.roles.crud-router',
        'cartridge.roles.metrics',
        -- 'cartridge.roles.graphqlapi',
        -- 'cartridge.roles.graphqlide',
        'migrator',
        'app.roles.api',
        'app.roles.storage',
    },
})

assert(ok, tostring(err))

-- register admin function to use it with 'cartridge admin' command
local admin = require('app.admin')
admin.init()

-- add metrics
local metrics = require('cartridge.roles.metrics')
metrics.set_export({
    {
        path = '/metrics',
        format = 'prometheus'
    },
    {
        path = '/health',
        format = 'health'
    }
})
