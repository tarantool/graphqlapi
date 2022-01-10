package = 'cartridge-simple'
version = 'scm-1'
source  = {
    url = '/dev/null',
}
-- Put any modules your app depends on here
dependencies = {
    'tarantool',
    'lua >= 5.1',
    'cartridge == 2.7.3-1',
    'metrics == 0.12.0-1',
    'crud == 0.10.0',
}
build = {
    type = 'none';
}
