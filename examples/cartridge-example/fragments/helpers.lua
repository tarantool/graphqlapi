local data_ok, data = pcall(require, 'graphqlapi.helpers.data')
local schema_ok, schema = pcall(require, 'graphqlapi.helpers.schema')
local service_ok, service = pcall(require, 'graphqlapi.helpers.service')
local spaces_ok, spaces = pcall(require, 'graphqlapi.helpers.spaces')

local function fragment()
    if data_ok == true then
        data.init({
            schema = 'Data',
            group_by_operations = false,
            get = { enabled = true, include = {}, exclude = {} },
            select = { enabled = true, by_indexes_only = false, },
            count = { enabled = true, },
            delete = { enabled = true, },
            update = { enabled = true, },
            upsert = { enabled = true, },
            replace = { enabled = true, },
            insert = { enabled = true, },
        })
    end
    if schema_ok == true then
        schema.init({ schema = 'Schema', })
    end
    if service_ok == true then
        spaces.init({ schema = 'Spaces', })
    end
    if spaces_ok == true then
        service.init({ schema = 'Service', })
    end
end

return {
    fragment = fragment,
}
