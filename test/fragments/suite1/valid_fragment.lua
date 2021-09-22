local module = require('module')

return {
    spaces = {'fragment'},
    fragment = function()
        _G._test_fragment = (_G._test_fragment or 0) + 1
        return {}
    end,
    f = module.func
}
