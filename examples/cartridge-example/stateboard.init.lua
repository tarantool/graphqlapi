#!/usr/bin/env tarantool

require('strict').on()

if package.setsearchroot ~= nil then
    package.setsearchroot()
end

require('cartridge.stateboard').cfg()
