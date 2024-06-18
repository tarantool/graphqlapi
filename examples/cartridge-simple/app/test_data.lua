local ddl
local ok, rc = pcall(require, 'ddl-ee')
if ok then
    ddl = rc
else
    ddl = require('ddl')
end

local log = require('log')

local function fill()
    log.info('Create spaces and fill test data')
    local schema = {
        spaces = {
            customer = {
                engine = 'memtx',
                is_local = false,
                temporary = false,
                format = {
                    { name = 'customer_id', is_nullable = false, type = 'unsigned' },
                    { name = 'bucket_id',   is_nullable = false, type = 'unsigned' },
                    { name = 'fullname',    is_nullable = false, type = 'string' },
                },
                indexes = { {
                    name = 'customer_id',
                    type = 'TREE',
                    unique = true,
                    parts = {
                        { path = 'customer_id', is_nullable = false, type = 'unsigned' }
                    }
                }, {
                    name = 'bucket_id',
                    type = 'TREE',
                    unique = false,
                    parts = {
                        { path = 'bucket_id', is_nullable = false, type = 'unsigned' }
                    }
                }, {
                    name = 'fullname',
                    type = 'TREE',
                    unique = true,
                    parts = {
                        { path = 'fullname', is_nullable = false, type = 'string' }
                    }
                } },
                sharding_key = { 'customer_id' },
            }
        }
    }

    local res, err = ddl.check_schema(schema)
    if not res then
        error(err)
    end

    res, err = ddl.set_schema(schema)
    if not res then
        error(err)
    end

    if box.space['customer'] ~= nil then
        for id = 1, 250 do
            local bucket_id = ddl.bucket_id('customer', { id })
            crud.replace('customer', { id, bucket_id, 'Test Customer ' .. tostring(id) })
        end
    end
end

return {
    fill = fill,
}
