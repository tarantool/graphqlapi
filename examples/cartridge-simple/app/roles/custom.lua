local data = require('graphqlapi.helpers.data')
local spaces = require('graphqlapi.helpers.spaces')

local test_data = require('app.test_data')

local function init(opts) -- luacheck: no unused args
    -- if opts.is_master then
    -- end
    spaces.init({ schema = 'Spaces' })
    data.init({ schema = 'Data' })

    test_data.fill()

    return true
end

return {
    role_name = 'app.roles.custom',
    init = init,
    dependencies = {
        'cartridge.roles.vshard-router',
        'cartridge.roles.vshard-storage',
        'cartridge.roles.crud-router',
        'cartridge.roles.crud-storage',
        'cartridge.roles.graphqlide',
        'cartridge.roles.graphqlapi',
    },
}
