local utils = require('graphqlapi.utils')

local function render_response(resp)
    return resp
end

local function request_wrapper(handler)
    return handler
end

local function authorize_request(req) -- luacheck: no unused args
    utils.is_table(1, req, false)
    return true
end

return {
    render_response = render_response,
    request_wrapper = request_wrapper,
    authorize_request = authorize_request,
}
