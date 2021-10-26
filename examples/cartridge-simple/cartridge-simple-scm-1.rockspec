package = 'cartridge-simple'
version = 'scm-1'
source  = {
    url = '/dev/null',
}
-- Put any modules your app depends on here
dependencies = {
    'tarantool',
    'lua >= 5.1',
    'cartridge == 2.7.2-1',
    'metrics == 0.11.0-1',
    'crud == 0.9.0',
}
build = {
    type = 'none';
}
