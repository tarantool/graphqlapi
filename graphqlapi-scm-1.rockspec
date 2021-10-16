package = 'graphqlapi'
version = 'scm-1'
source  = {
    url = 'git+https://github.com/no1seman/graphqlapi.git',
    branch = 'master',
}
description = {
    summary     = "GraphQL API backend module for Tarantool and Tarantool Cartridge",
    homepage    = 'https://github.com/no1seman/graphqlapi',
    license     = 'BSD',
    maintainer  = "Yaroslav Shumakov <noiseman2000@mail.ru>";
}
dependencies = {
    'lua >= 5.1',
    'luagraphqlparser == 0.1.0-1',
    'ddl ~> 1.5',
    'http == 1.1.0-1',
    'checks ~> 3.1',
    'errors ~> 2.2',
    'vshard ~> 0.1',
}
build = {
    type = 'builtin',
    modules = {
        ['graphqlapi'] = 'graphqlapi.lua',
        ['graphqlapi.cluster'] = 'graphqlapi/cluster.lua',
        ['graphqlapi.defaults'] = 'graphqlapi/defaults.lua',
        ['graphqlapi.funcall'] = 'graphqlapi/funcall.lua',
        ['graphqlapi.graphql.execute'] = 'graphqlapi/graphql/execute.lua',
        ['graphqlapi.graphql.introspection'] = 'graphqlapi/graphql/introspection.lua',
        ['graphqlapi.graphql.parse'] = 'graphqlapi/graphql/parse.lua',
        ['graphqlapi.graphql.query_util'] = 'graphqlapi/graphql/query_util.lua',
        ['graphqlapi.graphql.rules'] = 'graphqlapi/graphql/rules.lua',
        ['graphqlapi.graphql.schema'] = 'graphqlapi/graphql/schema.lua',
        ['graphqlapi.graphql.types'] = 'graphqlapi/graphql/types.lua',
        ['graphqlapi.graphql.util'] = 'graphqlapi/graphql/util.lua',
        ['graphqlapi.graphql.validate'] = 'graphqlapi/graphql/validate.lua',
        ['graphqlapi.graphql.validate_variables'] = 'graphqlapi/graphql/validate_variables.lua',
        ['graphqlapi.helpers'] = 'graphqlapi/helpers.lua',
        ['graphqlapi.middleware'] = 'graphqlapi/middleware.lua',
        ['graphqlapi.fragments'] = 'graphqlapi/fragments.lua',
        ['graphqlapi.operations'] = 'graphqlapi/operations.lua',
        ['graphqlapi.schemas'] = 'graphqlapi/schemas.lua',
        ['graphqlapi.trigger'] = 'graphqlapi/trigger.lua',
        ['graphqlapi.types'] = 'graphqlapi/types.lua',
        ['graphqlapi.utils'] = 'graphqlapi/utils.lua',
        ['cartridge.roles.graphqlapi'] = 'cartridge/roles/graphqlapi.lua',
    },
}
