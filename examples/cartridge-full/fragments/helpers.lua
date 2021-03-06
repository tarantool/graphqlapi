local data_ok, data = pcall(require, 'graphqlapi.helpers.data')
local service_ok, service = pcall(require, 'graphqlapi.helpers.service')
local spaces_ok, spaces = pcall(require, 'graphqlapi.helpers.spaces')

local function fragment()
    if data_ok == true then
        data.init({
            schema = 'Data',
            group_by_operations = false,
            get = { enabled = true, include = {}, exclude = {} },
            select = { enabled = true, include = {}, exclude = {}, by_indexes_only = false },
            count = { enabled = true, include = {}, exclude = {} },
            delete = { enabled = true, include = {}, exclude = {} },
            update = { enabled = true, include = {}, exclude = {} },
            upsert = { enabled = true, include = {}, exclude = {} },
            replace = { enabled = true, include = {}, exclude = {} },
            insert = { enabled = true, include = {}, exclude = {} },
        })
    end
    if spaces_ok == true then
        spaces.init({
            schema = 'Spaces',
            info = { enabled = true, include = {}, exclude = {} },
            drop = { enabled = true, include = {}, exclude = {} },
            truncate = { enabled = true, include = {}, exclude = {} },
            alter = { enabled = true, include = {}, exclude = {} },
            create = { enabled = true, include = {}, exclude = {} },
        })
    end
    if service_ok == true then
        service.init({
            schema = 'Service',
            box_cfg_get = { enabled = true, },
            box_cfg_set = { enabled = true, },
            fiber_info = { enabled = true, },
            fiber_top = { enabled = true, },
            fiber_cancel = { enabled = true, },
        })
    end
end

return {
    fragment = fragment,
}
