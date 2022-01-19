local errors = require('errors')
local fiber = require('fiber')
local fio = require('fio')
local log = require('log')

local utils = require('graphqlapi.utils')

local _fragments = {}
local _loaded = {}

local e_fragment_load = errors.new_class('GraphQLAPI fragment load failed', { capture_stack = true, })
local e_fragment_assert = errors.new_class('GraphQLAPI fragment check failed', { capture_stack = true, })
local e_fragment_execute = errors.new_class('GraphQLAPI fragment execute failed', { capture_stack = true, })

local function list_modules()
    local list = {}
    for key in pairs(package.loaded) do
        list[key] = true
    end
    return list
end

local function fragments_list()
    local fragments = {}
    for key in pairs(_fragments) do
        table.insert(fragments, key)
    end
    return fragments
end

local function loaded_list()
    return _loaded
end

local function assert_fragment(fragment)
    assert(type(fragment) == 'table', 'fragment must be a table')
    if fragment.fragment == nil then
        error('fragment must contain \'fragment\' function', 0)
    end
    assert(type(fragment.fragment) == 'function', 'fragment.fragment must be function')
    if fragment.spaces then
        assert(type(fragment.spaces) == 'table', 'fragment.spaces must be a table')
        for _, space in pairs(fragment.spaces) do
            assert(
                type(space) == 'string',
                string.format("fragment.spaces item '%s' must be a string", tostring(space))
            )
        end
    end
    return fragment
end

local function load_fragment(filename)
    utils.is_string(1, filename, false)
    local modules_before = list_modules()
    local fragment_function, err = e_fragment_load:pcall(loadfile, fio.pathjoin(package.searchroot(), filename))
    if fragment_function then
        local fragment = fragment_function()
        local res, assert_err = e_fragment_assert:pcall(assert_fragment, fragment)
        if res then
            fragment.filename = filename
            fragment.name = filename:match("^(.+)%.lua$"):gsub('/', '%.'):lstrip('.')
            fragment.spaces = fragment.spaces or {}
            local modules_after = list_modules()
            utils.diff_maps(modules_before, modules_after, _loaded)
            _fragments[fragment.name] = fragment
            return fragment
        else
            log.error('%s', assert_err)
            return nil, assert_err
        end
    else
        log.error(err)
        return nil, err
    end
end

local function load_fragments(dir_name)
    utils.is_string(1, dir_name, false)
    local files = {}

    local function scandir(directory)
        local list = fio.listdir(fio.pathjoin(package.searchroot(), directory))

        for _, filename in pairs(list or {}) do
            local rel_path = fio.pathjoin(directory, filename)

            if fio.path.is_dir(fio.pathjoin(package.searchroot(), rel_path)) then
                scandir(rel_path)
            else
                if filename:match("^.+(%..+)$") == '.lua' then
                    local path = fio.pathjoin(directory, filename)
                    if path:startswith('./') then
                        path = path:sub(3)
                    end
                    table.insert(files, path)
                end
            end
        end
    end

    scandir(dir_name)

    table.sort(files)
    for _, filename in ipairs(files) do
        if filename:match("^.+(%..+)$") == '.lua' then
            load_fragment(filename)
        end
    end
end

local function apply_fragment(fragment)
    local _, err = e_fragment_execute:pcall(fragment.fragment)
    if err ~= nil then
        if string.match(err.err, "space '.+' doesn't exists") ~= nil then
            err.file = nil
            err.stack = nil
        end
        log.error("GraphQL API fragment '%s' not applied: %s", fragment.filename or 'unknown', err)
        return nil, err
    else
        log.info("GraphQL API fragment '%s' applied", fragment.filename)
        return true
    end
end

local function update_space_fragments(space_name)
    for _, fragment in pairs(_fragments) do
        for _, space in pairs(fragment.spaces) do
            if space == space_name and fragment.fragment ~= nil then
                fiber.yield()
                apply_fragment(fragment)
            end
        end
    end
end

local function remove_fragment(filename)
    utils.is_string(1, filename, false)
    if type(_fragments) == 'table' then
        local fragment = filename:match("^(.+)%.lua$")
        if fragment then
            _fragments[fragment:gsub('/', '%.'):lstrip('.')] = nil
        else
            _fragments[filename] = nil
        end
    end
end

local function remove_fragment_by_space_name(space_name)
    utils.is_string(1, space_name, false)
    for key, fragment in pairs(_fragments) do
        for _,space in pairs(fragment.spaces) do
            if space == space_name then
                _fragments[key] = nil
            end
        end
    end
end

local function remove_all()
    _fragments = {}
    for _, v in pairs(_loaded) do
        package.loaded[v] = nil
    end
    _loaded = {}
end

local function get_func(mod_path, mod_name, fun_name)
    if mod_name and fun_name then
        mod_path = mod_path or ''
        local fragment = _fragments[mod_path..'.'..mod_name]
        if fragment and fragment[fun_name] and type(fragment[fun_name]) == 'function' then
            return fragment[fun_name]
        else
            return nil
        end
    end
    return nil
end

local function init(dir_name)
    load_fragments(dir_name)
    for _, fragment in pairs(_fragments) do
        apply_fragment(fragment)
    end
end

local function stop()
    remove_all()
end

return {
    init = init,
    stop = stop,
    update_space_fragments = update_space_fragments,
    apply_fragment = apply_fragment,
    load_fragment = load_fragment,
    remove_fragment = remove_fragment,
    remove_fragment_by_space_name = remove_fragment_by_space_name,
    remove_all = remove_all,
    get_func = get_func,
    fragments_list = fragments_list,
    loaded_list = loaded_list,
}
