redefined = false
include_files = {'**/*.lua', '*.rockspec', '*.luacheckrc'}
exclude_files = {
    'lua_modules/',
    '.luarocks/',
    '.rocks/',
    'tmp/',
    '.history/',
    'test/fragments',
    'examples/cartridge-full/.rocks/',
    'examples/cartridge-simple/.rocks/',
    'sdk/'
}

max_line_length = 120
globals = {'box', 'table', 'jit', 'unpack', 'debug', 'tonumber64', 'crud'}
