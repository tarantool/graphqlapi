local checks = require('checks')

local function render_response(resp)
    return resp
end

local function request_wrapper(handler)
    return handler
end

local function authorize_request(req) -- luacheck: no unused args
    checks('table')
    return true
end

return {
    render_response = render_response,
    request_wrapper = request_wrapper,
    authorize_request = authorize_request,
}
