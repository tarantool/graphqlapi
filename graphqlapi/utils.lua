local digest = require('digest')
local errors = require('errors')
local msgpack = require('msgpack')

local defaults = require('graphqlapi.defaults')

local e_argument_validation = errors.new_class('function argument validation error', { capture_stack = true, })

local function value_in(val, arr)
    if not arr then return false end
    for i, elem in ipairs(arr) do
        if val == elem then
            return true, i
        end
    end
    return false
end

local function diff_maps(t1, t2, ret)
    for k in pairs(t2) do
        if not t1[k] and not value_in(k, ret) then
            table.insert(ret, k)
        end
    end
    return ret
end

local function diff_arrays(t1, t2)
    local ret = {}
    for _,space in ipairs(t1) do
        if value_in(space, t2) then
            table.insert(ret, space)
        end
    end
    return ret
end

local function merge_maps(...)
    local ret = {}
    for i = 1, select('#', ...) do
        local tbl = select(i, ...)
        assert(type(tbl) == 'table')
        for k, v in pairs(tbl) do
            if v == box.NULL then
                ret[k] = nil
            else
                ret[k] = v
            end
        end
    end

    return ret
end

local function merge_arrays(a1, a2)
    local a = table.copy(a1)
    for _, value in ipairs(a2) do
        if not value_in(value, a) then
            table.insert(a, value)
        end
    end
    return a
end

local function concat_arrays(...)
    local t = {}
    for n = 1,select("#",...) do
        local arg = select(n,...)
        if type(arg)=="table" then
            for _,v in ipairs(arg) do
                t[#t+1] = v
            end
        else
            t[#t+1] = arg
        end
    end
    return t
end

local function is_string_array(data)
    if type(data) ~= 'table' then
        return false
    end
    if #data == 0 then return true end
    for _, v in pairs(data) do
        if type(v) ~= 'string' then
            return false
        end
    end
    return #data > 0 and next(data, #data) == nil
end

local function dedup_array(tbl)
    if not tbl or type(tbl) ~= 'table' then
        return {}
    end
    local kv = {}
    for i = #tbl, 1, -1 do
        local str = tbl[i]
        if not kv[str] then
            kv[str] = true
        else
            table.remove(tbl, i)
        end
    end

    return tbl
end

local function is_map(tbl)
    if type(tbl) ~= 'table' then
        return false
    end

    local key, _ = next(tbl)

    return type(key) == 'string'
end

local function coerce_schema(schema)
    if schema == nil or (type(schema) == 'string' and schema == '') then
        schema = defaults.DEFAULT_SCHEMA_NAME
    end
    return schema
end

local function map_by_field(arr, field_name)
    local map = {}
    for _, field in pairs(arr or {}) do
        if field[field_name] ~= nil then
            map[field[field_name]] = field
        end
    end
    return map
end

local function encode_cursor(cursor, space_name)
    if cursor == nil then
        return nil
    end

    local indexes_keys = {}
    local space = box.space[space_name]

    if space == nil then
        return nil
    end

    if space.index ~= nil and not next(space.index) then
        return nil
    end

    for key, index in pairs(space.index) do
        if type(key) == 'number' then
            for _, part in ipairs(index.parts) do
                table.insert(indexes_keys, part.fieldno)
            end
        end
    end

    local indexes_keys_only = {}
    table.insert(indexes_keys_only, #cursor)
    for key, value in ipairs(cursor) do
        if value_in(key, indexes_keys) then
            table.insert(indexes_keys_only, key)
            table.insert(indexes_keys_only, value)
        end
    end

    local raw = msgpack.encode(indexes_keys_only)
    local encoded = digest.base64_encode(raw, {
            nopad=true,
            nowrap=true,
            urlsafe=true,
    })

    return encoded
end

local function decode_cursor(cursor)
    if cursor == nil then
        return nil, string.format('Failed to decode cursor: %q', cursor)
    end

    local ok, raw = pcall(digest.base64_decode, cursor)

    if not ok then
        return nil, string.format('Failed to decode cursor: %q', cursor)
    end

    local ok1, decoded = pcall(msgpack.decode, raw)

    if not ok1 or #decoded %2 == 0 or #decoded < 1 then
        return nil, string.format('Failed to decode cursor: %q', cursor)
    end

    local index = 2
    local tuple = {}
    for i = 1, decoded[1] do
        if index < #decoded and i == decoded[index] then
            table.insert(tuple, decoded[index+1])
            index = index + 2
        else
            table.insert(tuple, box.NULL)
        end
    end

    return tuple
end

local function capitalize(str, option)
    if option == true then
        return str:upper()
    end
    return str
end

local function is_box_null(value)
    if value and value == nil then
        return true
    end
    return false
end

local function to_compat(cache, name)
    if type(name) == 'string' and cache ~= nil and type(cache) == 'table' then
        local found = name:match('%W')
        if found ~= nil and found ~= '_' then
            local compat = name:gsub("%W", "_")
            cache[compat] = name
            return compat
        end
    end
    return name
end

local function from_compat(cache, name)
    if type(name) == 'string' and cache ~= nil and type(cache) == 'table' and cache[name] ~= nil then
        return cache[name]
    end
    return name
end

local function get_tnt_version()
    local major_minor_patch = _G._TARANTOOL:split('-', 1)[1]
    local major_minor_patch_parts = major_minor_patch:split('.', 2)

    local version = {
        major = tonumber(major_minor_patch_parts[1]),
        minor = tonumber(major_minor_patch_parts[2]),
        patch = tonumber(major_minor_patch_parts[3]),
        enterprise = (_G._TARANTOOL):match('-r%d+') ~= nil,
    }
    return version
end

local function count_map(t)
    if t ~= nil and type(t) == 'table' then
        local count = 0
        for _ in pairs(t) do count = count + 1 end
        return count
    end
    return 0
end

local function is_nil(num, value)
    if type(value) ~= 'nil' then
        error(e_argument_validation:new('bad argument #%s (nil expected, got %s)', num, type(value)), 0)
    end
    return true
end

local function check_type(num, value, optional, variable_type)
    if optional == true and value ~= nil and type(value) ~= variable_type then
        error(e_argument_validation:new(
            'bad argument #%s (%s or nil expected, got %s)',
            num,
            variable_type,
            type(value)
        ), 0)
    end
    if optional == false and type(value) ~= variable_type then
        error(e_argument_validation:new(
            'bad argument #%s (%s expected, got %s)',
            num,
            variable_type,
            type(value)
        ), 0)
    end
    return true
end

local function is_string(num, value, optional)
    return check_type(num, value, optional, 'string')
end

local function is_boolean(num, value, optional)
    return check_type(num, value, optional, 'boolean')
end

local function is_number(num, value, optional)
    return check_type(num, value, optional, 'number')
end

local function is_function(num, value, optional)
    return check_type(num, value, optional, 'function')
end

local function is_table(num, value, optional)
    return check_type(num, value, optional, 'table')
end

local function is_table_or_string(num, value, optional)
    if optional == true and value ~= nil and type(value) ~= 'table' and type(value) ~= 'string' then
        error(e_argument_validation:new(
            'bad argument #%s (table or string or nil expected, got %s)',
            num,
            type(value)
        ), 0)
    end
    if optional == false and type(value) ~= 'table' and type(value) ~= 'string' then
        error(e_argument_validation:new(
            'bad argument #%s (table or string expected, got %s)',
            num,
            type(value)
        ), 0)
    end
    return true
end

return {
    value_in = value_in,
    diff_maps = diff_maps,
    diff_arrays = diff_arrays,
    merge_maps = merge_maps,
    merge_arrays = merge_arrays,
    concat_arrays = concat_arrays,
    is_string_array = is_string_array,
    dedup_array = dedup_array,
    is_map = is_map,
    coerce_schema = coerce_schema,
    map_by_field = map_by_field,
    encode_cursor = encode_cursor,
    decode_cursor = decode_cursor,
    capitalize = capitalize,
    is_box_null = is_box_null,
    to_compat = to_compat,
    from_compat = from_compat,
    get_tnt_version = get_tnt_version,
    count_map = count_map,
    is_nil = is_nil,
    is_string = is_string,
    is_boolean = is_boolean,
    is_number = is_number,
    is_function = is_function,
    is_table = is_table,
    is_table_or_string = is_table_or_string,
}
