local cartridge = require('cartridge')
local log = require('log')
local json = require('json')
local operations = require('graphqlapi.operations')

local json_options = {
    encode_use_tostring = true,
    encode_deep_as_nil = true,
    encode_max_depth = 7,
    encode_invalid_as_nil = true,
}

-- GraphQL request logging trigger
local function log_request(operation_type, operation_schema, operation_prefix, operation_name, ...)
    local _, arguments, info = ...

    -- user will be nil if no cartridge auth is enabled
    local user = cartridge.http_get_username()

    log.info("\nGraphQL request by username: %s =>\n"..
             "\toperation: %s\n"..
             "\tschema: %s\n"..
             "\tprefix: %s\n"..
             "\toperation name: %s\n"..
             "\targuments: %s\n"..
             "\targuments defaults: %s\n"..
             "\tdirectives: %s\n"..
             "\tdirectives defaults: %s\n",
        tostring(user or 'unknown'),
        operation_type,
        tostring(operation_schema),
        tostring(operation_prefix),
        operation_name,
        json.encode(arguments, json_options),
        json.encode(info.defaultValues, json_options),
        json.encode(info.directives, json_options),
        json.encode(info.directivesDefaultValues, json_options)
    )
end

-- enable logging GraphQL requests
local function enable_graphql_log()
    operations.on_resolve(log_request)
end

-- disable logging GraphQL requests
-- local function disable_graphql_log()
--     operations.on_resolve(nil, log_request)
-- end

-- deny GraphQL mutations trigger
-- local function deny_mutations(operation_type, _, _, operation_name)
--     if operation_type:upper() == 'MUTATION' then
--       log.error('GraphQL %s "%s" temporarily prohibited', operation_type, _, _, operation_name)
--       return nil, "Mutations temporarily prohibited"
--     end
-- end

-- disable GraphQL mutations
-- local function disable_mutations()
--     operations.on_resolve(deny_mutations)
-- end

-- enable GraphQL mutations
-- local function enable_mutations()
--     operations.on_resolve(nil, deny_mutations)
-- end

local function fragment()
    enable_graphql_log()
end

return {
    fragment = fragment,
}
