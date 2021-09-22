local errors = require('errors')
local fiber = require('fiber')
local log = require('log')
local string = require('string')

local defaults = require('graphqlapi.defaults')
local helpers = require('graphqlapi.helpers')
local fragments = require('graphqlapi.fragments')
local operations = require('graphqlapi.operations')
local types = require('graphqlapi.types')

local e_schema_updater_fiber = errors.new_class('schema updater fiber error', { capture_stack = true, })

local _schema_updater = nil

local function schema_updater_init()
    local channel = fiber.channel(defaults.SCHEMA_UPDATE_CHANNEL_CAPACITY)
    local updater_fiber = fiber.create(function()
        fiber.self():name('gql_schema', { truncate = true, })
        while true do
            fiber.testcancel()
            local ok, err = e_schema_updater_fiber:pcall(function()
                local message = channel:get(defaults.SCHEMA_UPDATE_CHANNEL_TIMEOUT)

                if message ~= nil then
                    if message.operation == 'DELETE' and
                       message.old_space and
                       message.old_space.name and
                       message.old_space.id > box.schema.SYSTEM_ID_MAX and
                       not string.startswith(message.old_space.name, '_') then

                        fragments.remove_fragment_by_space_name(message.old_space.name)
                        types.remove_types_by_space_name(message.old_space.name)
                        operations.remove_operations_by_space_name(message.old_space.name)
                        helpers.update_schema(message)
                    end

                    if message.operation ~= 'DELETE' and
                       message.new_space and
                       message.new_space.name and
                       message.new_space.id > box.schema.SYSTEM_ID_MAX and
                       not string.startswith(message.new_space.name, '_') then
                        fragments.update_space_fragments(message.new_space.name)
                        helpers.update_schema(message)
                    end
                end
            end)
            if not ok and err ~= nil and _schema_updater ~= nil then
                log.error('%s', err)
            end
        end
    end)

    _schema_updater = {
        fiber = updater_fiber,
        channel = channel,
    }
end

local function set_trigger(trigger)
    box.space._space:on_replace(trigger)
    return true
end

local function remove_trigger(trigger)
    local triggers = box.space._space:on_replace()
    for _, func in pairs(triggers) do
        if func == trigger then
            box.space._space:on_replace(nil, trigger)
        end
    end
end

local function space_trigger(old, new, _, operation)
    box.on_commit(function()
        if _schema_updater ~= nil then
            local old_space, new_space
            if new ~= nil then
                new_space = new:tomap({names_only = true})
            end
            if old ~= nil then
                old_space = old:tomap({names_only = true})
            end

            _schema_updater.channel:put({
                old_space = old_space,
                new_space = new_space,
                operation = operation,
            }, 0)
        end
    end)
end

local function init()
    if _schema_updater == nil then
        schema_updater_init()
        set_trigger(space_trigger)
    end
end

local function stop()
    remove_trigger(space_trigger)
    if _schema_updater and _schema_updater.fiber then
        if _schema_updater.fiber:status() ~= 'dead' then
            _schema_updater.fiber:cancel()
        end
        _schema_updater.channel:close()
        _schema_updater = nil
    end
end

return {
    init = init,
    stop = stop,
}
