package = 'graphqlapi'
version = 'scm-1'
source  = {
    url = 'git+https://github.com/tarantool/graphqlapi.git',
    branch = 'master',
}
description = {
    summary     = "GraphQL API backend module for Tarantool and Tarantool Cartridge",
    homepage    = 'https://github.com/tarantool/graphqlapi',
    license     = 'BSD',
    maintainer  = "Yaroslav Shumakov <noiseman2000@mail.ru>";
}
dependencies = {
    'lua >= 5.1',
    'luagraphqlparser ~> 0',
    'ddl >= 1.6',
    'http ~> 1',
    'errors ~> 2',
    'vshard ~> 0.1',
    'cartridge ~> 2',
}
build = {
    type = 'cmake',
    variables = {
        TARANTOOL_DIR = '$(TARANTOOL_DIR)',
        TARANTOOL_INSTALL_LIBDIR = '$(LIBDIR)',
        TARANTOOL_INSTALL_LUADIR = '$(LUADIR)',
        TARANTOOL_INSTALL_BINDIR = '$(BINDIR)',
    }
}
