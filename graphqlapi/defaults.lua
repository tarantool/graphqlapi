local defaults = {
    -- default fragments dir path
    DEFAULT_MODELS_DIR = 'fragments',
    -- default http endpoint
    DEFAULT_ENDPOINT = 'admin/graphql',
    -- name of default schema
    DEFAULT_SCHEMA_NAME = 'Default',
    -- default config update channel capacity for change space messages
    CONFIG_UPDATE_CHANNEL_CAPACITY = 100,
    -- default schema update channel capacity for change space messages
    SCHEMA_UPDATE_CHANNEL_CAPACITY = 100,
    -- default schema update channel timeout in seconds
    CONFIG_UPDATE_CHANNEL_TIMEOUT = 10,
    -- default config update channel timeout in seconds
    SCHEMA_UPDATE_CHANNEL_TIMEOUT = 10,
    -- default name prefix for prefixed queries
    QUERIES_PREFIX = 'API_',
    -- default name prefix for prefixed mutations
    MUTATIONS_PREFIX = 'MUTATION_API_',
    -- remove_recursive_max_depth
    REMOVE_RECURSIVE_MAX_DEPTH = 128,
    -- default name of field description key in format structure
    DEFAULT_DESCRIPTION_KEY = 'comment',
}

return setmetatable({}, {
    __index = defaults,
    __newindex = function(_, key, value)
        if key == 'REMOVE_RECURSIVE_MAX_DEPTH' and value < 2 then
            defaults.REMOVE_RECURSIVE_MAX_DEPTH = 2
        else
            defaults[key] = value
        end
    end
})
