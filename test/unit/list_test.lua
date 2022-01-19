local t = require('luatest')
local g = t.group('list')

require('test.helper')
local list = require('graphqlapi.list')

g.test_list = function()
    local capacity = 10
    local cache = list.new(capacity)
    local storage

    t.assert_equals(cache:is_empty(), true)
    t.assert_equals(cache:pop(), nil)

    -- fill full list
    local function fill()
        storage = {}
        for i = 1, capacity do
            local item = cache:push(i)
            table.insert(storage, item)
        end

        t.assert_equals(cache:length(), capacity)
        t.assert_equals(cache:is_full(), true)
    end

    -- remove all from tail
    fill()
    for i = 1, capacity do
        t.assert_equals(cache:pop(), i)
    end

    -- remove all by items from head to tail
    fill()
    for i = capacity, 1, -1 do
        t.assert_equals(cache:pop(storage[i]), i)
    end

    -- remove all by items from tail to head
    fill()
    for i = 1, capacity do
        t.assert_equals(cache:pop(storage[i]), i)
    end

    -- remove half of items from head to tail
    fill()
    for i = capacity/2, 1, -1 do
        t.assert_equals(cache:pop(storage[i]), i)
    end

    t.assert_equals(cache:length(), capacity/2)
    for _ = 1, capacity/2 do cache:pop() end
    t.assert_equals(cache:length(), 0)

    -- remove all by items from tail to head
    fill()
    for i = 1, capacity/2 do
        t.assert_equals(cache:pop(storage[i]), i)
    end

    t.assert_equals(cache:length(), capacity/2)
    for _ = 1, capacity/2 do cache:pop() end
    t.assert_equals(cache:length(), 0)
end
