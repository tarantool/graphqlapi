local list = {}

function list:is_empty()
    return self.head == nil and self.tail == nil
end

function list:is_full()
    return self.size == self.max_size
end

function list:length()
    return self.size
end

function list:pop(item)
    if self:is_empty() then
        return
    end

    local value

    if item == nil then
        value = self.tail.value
        self.tail.value = nil
        if self.head == self.tail then
            self.head = nil
            self.tail = nil
        else
            self.tail = self.tail.next
            self.tail.prev.next = nil
            self.tail.prev = nil
        end
    else
        value = item.value
        local prev = item.prev
        local next = item.next

        if prev == nil and next == nil then
            self.tail = nil
            self.head = nil
        elseif prev == nil then
            next.prev = nil
            self.tail = next
        elseif next == nil then
            prev.next = nil
            self.head = prev
        else
            prev.next = next
            next.prev = prev
        end
        item.prev = nil
        item.next = nil
        item.value = nil
    end

    self.size = self.size - 1
    return value
end

function list:push(value)
    local item = {}
    item.value = value
    if self:is_empty() then
        item.prev = nil
        item.next = nil
        self.head = item
        self.tail = item
    else
        local up = self.head
        up.next = item
        item.prev = up
        item.next = nil
        self.head = item
    end
    self.size = self.size + 1
    return item
end

function list.new(max_size)
    assert(
        type(max_size) == 'number' and max_size > 0,
        'list.new(): List size must be positive integer'
    )
    local instance = {
        size = 0,
        head = nil,
        max_size = max_size,
        tail = nil,
        is_empty = list.is_empty,
        is_full = list.is_full,
        length = list.length,
        push = list.push,
        pop = list.pop,
    }
    return instance
end

return list
