local data_ok, data = pcall(require, 'graphqlapi.helpers.data')
local spaces_ok, spaces = pcall(require, 'graphqlapi.helpers.spaces')

local test_data = require('app.test_data')

local function init(opts) -- luacheck: no unused args
    -- if opts.is_master then
    -- end

    if spaces_ok == true then
        spaces.init({ schema = 'Spaces' })
    end

    if data_ok == true then
        data.init({ schema = 'Data' })
    end

    return true
end

local function apply_config(conf, opts) -- luacheck: no unused args
    if opts.is_master then
        -- Create test space and fill it with test data
        test_data.fill()
    end

    return true
end

return {
    role_name = 'app.roles.custom',
    init = init,
    apply_config = apply_config,
    dependencies = {
        'cartridge.roles.vshard-router',
        'cartridge.roles.vshard-storage',
        'cartridge.roles.crud-router',
        'cartridge.roles.crud-storage',
        'cartridge.roles.graphqlide',
        'cartridge.roles.graphqlapi',
    },
}
