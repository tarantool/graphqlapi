local errors = require('errors')
local fiber = require('fiber')
local log = require('log')

local defaults = require('graphqlapi.defaults')
local utils  =require('graphqlapi.utils')

local e_schema_updater_fiber = errors.new_class('schema updater fiber error', { capture_stack = true, })
local e_stop_trigger = errors.new_class('stop trigger error', { capture_stack = true, })
local e_update_config_trigger = errors.new_class('update config trigger error', { capture_stack = true, })
local e_update_schema_trigger = errors.new_class('update schema trigger error', { capture_stack = true, })

local _on_update_schema_triggers = {}
local _on_update_config_triggers = {}
local _on_stop_triggers = {}
local _shared = {}
local _config_updater = nil

local function update_config(conf, opts)
    if _config_updater ~= nil then
        _config_updater.channel:put({ conf = conf, opts = opts, }, 0)
    end
end

local function config_updater_init()
    local channel = fiber.channel(defaults.CONFIG_UPDATE_CHANNEL_CAPACITY)
    local updater_fiber = fiber.create(function()
        fiber.self():name('gql_config', { truncate = true, })
        while true do
            fiber.testcancel()
            local ok, err = e_schema_updater_fiber:pcall(function()
                local message = channel:get(defaults.CONFIG_UPDATE_CHANNEL_TIMEOUT)

                if message ~= nil then
                    for update_config_trigger in pairs(_on_update_config_triggers) do
                        local _, err =
                            e_update_config_trigger:pcall(update_config_trigger, message.conf, message.opts)

                        if err then
                            log.error('%s', err)
                        end
                    end
                end
            end)
            if not ok and err ~= nil and _config_updater ~= nil then
                log.error('%s', err)
            end
        end
    end)

    _config_updater = {
        fiber = updater_fiber,
        channel = channel,
    }
end

local function config_updater_stop()
    if _config_updater then
        if _config_updater.fiber:status() ~= 'dead' then
            _config_updater.fiber:cancel()
        end
        _config_updater.channel:close()
        _config_updater = nil
    end
end

local function is_update_config_trigger_set(trigger)
    for update_config_trigger in pairs(_on_update_config_triggers) do
        if update_config_trigger == trigger then return true end
    end
    return false
end

local function on_update_config(trigger_new, trigger_old)
    utils.is_function(1, trigger_new, true)
    utils.is_function(2, trigger_old, true)

    if trigger_old ~= nil then
        _on_update_config_triggers[trigger_old] = nil
    end
    if trigger_new ~= nil then
        if not is_update_config_trigger_set(trigger_new) then
            _on_update_config_triggers[trigger_new] = true
        end
    end

    if type(_on_update_config_triggers) == 'table' and
       next(_on_update_config_triggers) and _config_updater == nil then
        config_updater_init()
    end
    if type(_on_update_config_triggers) == 'table' and
       next(_on_update_config_triggers) == nil then
        config_updater_stop()
    end
    return trigger_new
end

local function update_schema(message)
    for update_schema_trigger in pairs(_on_update_schema_triggers) do
        local _, err = e_update_schema_trigger:pcall(update_schema_trigger, message)
        if err then
            log.error('%s', err)
        end
    end
end

local function is_update_schema_trigger_set(trigger)
    utils.is_function(1, trigger, false)

    for update_schema_trigger in pairs(_on_update_schema_triggers) do
        if update_schema_trigger == trigger then return true end
    end
    return false
end

local function on_update_schema(trigger_new, trigger_old)
    utils.is_function(1, trigger_new, true)
    utils.is_function(2, trigger_old, true)

    if trigger_old ~= nil then
        _on_update_schema_triggers[trigger_old] = nil
    end
    if trigger_new ~= nil then
        if not is_update_schema_trigger_set(trigger_new) then
            _on_update_schema_triggers[trigger_new] = true
        end
    end
    return trigger_new
end

local function is_stop_trigger_set(trigger)
    utils.is_function(1, trigger, false)

    for stop_trigger in pairs(_on_stop_triggers) do
        if stop_trigger == trigger then return true end
    end
    return false
end

local function on_stop(trigger_new, trigger_old)
    utils.is_function(1, trigger_new, true)
    utils.is_function(2, trigger_old, true)

    if trigger_old ~= nil then
        _on_stop_triggers[trigger_old] = nil
    end
    if trigger_new ~= nil then
        if not is_stop_trigger_set(trigger_new) then
            _on_stop_triggers[trigger_new] = true
        end
    end
    return trigger_new
end

local function stop()
    for stop_trigger in pairs(_on_stop_triggers) do
        local _, err = e_stop_trigger:pcall(stop_trigger)
        if err then
            log.error('%s', err)
        end
    end
    _on_update_config_triggers = {}
    _on_update_schema_triggers = {}
    _on_stop_triggers = {}
    config_updater_stop()
end

local function add_shared(schema, class, name, helper)
    utils.is_string(1, schema, false)
    utils.is_string(2, class, false)
    utils.is_string(3, name, false)
    utils.is_string(4, helper, false)

    _shared[schema] = _shared[schema] or {}
    _shared[schema][class] = _shared[schema][class] or {}
    _shared[schema][class][name] = _shared[schema][class][name] or {}
    _shared[schema][class][name][helper] = true
end

local function remove_shared(schema, class, name, helper)
    utils.is_string(1, schema, false)
    utils.is_string(2, class, true)
    utils.is_string(3, name, true)
    utils.is_string(4, helper, true)
    _shared[schema] = _shared[schema] or {}
    _shared[schema][class] = _shared[schema][class] or {}
    _shared[schema][class][name] = _shared[schema][class][name] or {}
    _shared[schema][class][name][helper] = nil
end

local function is_shared(schema, class, name, helper)
    utils.is_string(1, schema, false)
    utils.is_string(2, class, false)
    utils.is_string(3, name, false)
    utils.is_string(4, helper, false)
    _shared[schema] = _shared[schema] or {}
    _shared[schema][class] = _shared[schema][class] or {}
    _shared[schema][class][name] = _shared[schema][class][name] or {}
    for key in pairs(_shared[schema][class][name]) do
        if key ~= helper then
            return true
        end
    end
    return false
end

local function clean_shared(schema, class)
    utils.is_string(1, schema, false)
    utils.is_string(2, class, true)
    _shared[schema] = _shared[schema] or {}
    if class == nil then
        _shared[schema] = {}
    else
        _shared[schema] = _shared[schema] or {}
        _shared[schema][class] = nil
    end
end

return {
    -- Update schema callbacks API
    update_schema = update_schema,
    on_update_schema = on_update_schema,

    -- Update cluster config callbacks API
    update_config = update_config,
    on_update_config = on_update_config,

    -- Stop helpers callback API
    stop = stop,
    on_stop = on_stop,

    -- Shared entities API
    add_shared = add_shared,
    remove_shared = remove_shared,
    is_shared = is_shared,
    clean_shared = clean_shared,
}
