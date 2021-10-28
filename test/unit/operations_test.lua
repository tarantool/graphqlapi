local t = require('luatest')
local g = t.group('operations')

local test_helper = require('test.helper')
local operations = require('graphqlapi.operations')
local schemas = require('graphqlapi.schemas')
local types = require('graphqlapi.types')

g.before_each(function()
    types.remove_all()
    operations.remove_all()
end)

g.after_each(function()
    types.remove_all()
    operations.remove_all()
end)

g.test_add_remove_query_default_schema_no_prefix = function()
    operations.add_query({
        name = 'entity',
        doc = 'Get entity',
        args = {
            entity_id = types.long,
        },
        kind = types.string,
        callback = 'fragments.entity.entity_get',
    })

    t.assert_equals(operations.is_query_exists({ name = 'entity', }), true)
    t.assert_equals(type(operations.get_queries()['entity']), 'table')
    t.assert_equals(operations.get_queries()['entity'].description, 'Get entity')
    t.assert_equals(schemas.is_invalid(), true)
    t.assert_items_equals(schemas.schemas_list(), {'Default'})

    schemas.reset_invalid()
    t.assert_equals(schemas.is_invalid(), false)

    t.assert_items_equals(operations.queries_list(), {'entity'})

    local ok, err = pcall(function()
        operations.add_query({
            name = 'entity',
            doc = 'Get entity',
            args = {
                entity_id = types.long,
            },
            kind = types.string,
            callback = 'fragments.entity.entity_get',
        })
    end)

    t.assert_equals(ok, false)
    t.assert_equals(err, 'query "entity" already exists in schema: "Default"')

    operations.remove_query({name = 'entity'})

    t.assert_equals(operations.get_queries()['entity'], nil)

    t.assert_equals(schemas.is_invalid(), true)
    schemas.reset_invalid()
    t.assert_equals(schemas.is_invalid(), false)
end

g.test_add_remove_query_default_schema_with_prefix = function()
    operations.add_queries_prefix({
        prefix = 'test',
        doc = 'Simple prefix test',
    })

    t.assert_items_equals(operations.get_queries()['test'].resolve(), {})

    t.assert_equals(type(operations.get_queries()['test']), 'table')
    t.assert_equals(operations.is_queries_prefix_exists({ prefix = 'test' }), true)
    t.assert_equals(operations.get_queries()['test'].description, 'Simple prefix test')
    t.assert_equals(schemas.is_invalid(), true)

    schemas.reset_invalid()
    t.assert_equals(schemas.is_invalid(), false)

    local ok, err = pcall(function()
        operations.add_queries_prefix({
            prefix = 'test',
            doc = 'Simple prefix test',
        })
    end)

    t.assert_equals(ok, false)
    t.assert_equals(err, 'query or prefix with name "test" already exists in schema: "Default"')

    operations.add_query({
        prefix = 'test',
        name = 'entity_1',
        doc = 'Get entity 1',
        args = {
            entity_id = types.long,
        },
        kind = types.string,
        callback = 'fragments.entity.entity_1_get',
    })

    t.assert_equals(type(operations.get_queries()['test'].kind.fields['entity_1']), 'table')
    t.assert_equals(operations.get_queries()['test'].kind.fields['entity_1'].description, 'Get entity 1')
    t.assert_equals(schemas.is_invalid(), true)

    schemas.reset_invalid()
    t.assert_equals(schemas.is_invalid(), false)

    ok, err = pcall(function()
        operations.add_query({
            prefix = 'test',
            name = 'entity_1',
            doc = 'Get entity 1',
            args = {
                entity_id = types.long,
            },
            kind = types.string,
            callback = 'fragments.entity.entity_1_get',
        })
    end)

    t.assert_equals(ok, false)
    t.assert_equals(err, 'query "entity_1" already exists in prefix "test" in schema: "Default"')

    operations.add_query({
        prefix = 'test',
        name = 'entity_2',
        doc = 'Get entity 2',
        args = {
            entity_id = types.long,
        },
        kind = types.string,
        callback = 'fragments.entity.entity_2_get',
    })

    t.assert_equals(operations.is_query_exists({ name = 'entity_2', prefix = 'test'}), true)
    t.assert_equals(type(operations.get_queries()['test'].kind.fields['entity_1']), 'table')
    t.assert_equals(operations.get_queries()['test'].kind.fields['entity_1'].description, 'Get entity 1')
    t.assert_equals(type(operations.get_queries()['test'].kind.fields['entity_2']), 'table')
    t.assert_equals(operations.get_queries()['test'].kind.fields['entity_2'].description, 'Get entity 2')
    t.assert_equals(schemas.is_invalid(), true)
    schemas.reset_invalid()
    t.assert_equals(schemas.is_invalid(), false)

    t.assert_items_equals(operations.queries_list(), {'test.entity_1', 'test.entity_2'})

    operations.remove_query({
        name = 'entity_1',
        prefix = 'test',
    })
    t.assert_equals(type(operations.get_queries()['test'].kind.fields['entity_2']), 'table')
    t.assert_equals(operations.get_queries()['test'].kind.fields['entity_2'].description, 'Get entity 2')
    t.assert_equals(schemas.is_invalid(), true)
    schemas.reset_invalid()
    t.assert_equals(schemas.is_invalid(), false)

    operations.remove_queries_prefix({prefix = 'test'})
    t.assert_equals(operations.is_queries_prefix_exists({ prefix = 'test' }), false)
    t.assert_equals(operations.get_queries()['test'], nil)
    t.assert_equals(schemas.is_invalid(), true)
    schemas.reset_invalid()
    t.assert_equals(schemas.is_invalid(), false)

    t.assert_error_msg_content_equals(
        'No such query prefix "test1"',
        operations.add_query,
        {
            prefix = 'test1',
            name = 'entity_2',
            doc = 'Get entity 2',
            args = {
                entity_id = types.long,
            },
            kind = types.string,
            callback = 'fragments.entity.entity_2_get',
        }
    )
end

g.test_add_remove_query_custom_schema_no_prefix = function()
    operations.add_query({
        schema = 'test_schema',
        name = 'entity',
        doc = 'Get entity',
        args = {
            entity_id = types.long,
        },
        kind = types.string,
        callback = 'fragments.entity.entity_get',
    })

    t.assert_equals(type(operations.get_queries('test_schema')['entity']), 'table')
    t.assert_equals(operations.get_queries('test_schema')['entity'].description, 'Get entity')
    t.assert_equals(schemas.is_invalid('test_schema'), true)

    schemas.reset_invalid('test_schema')
    t.assert_equals(schemas.is_invalid('test_schema'), false)

    t.assert_items_equals(operations.queries_list('test_schema'), {'entity'})

    operations.remove_query({name = 'entity', schema = 'test_schema'})

    t.assert_equals(operations.get_queries('test_schema')['entity'], nil)

    t.assert_equals(schemas.is_invalid('test_schema'), true)
    schemas.reset_invalid('test_schema')
    t.assert_equals(schemas.is_invalid('test_schema'), false)
end

g.test_add_remove_query_custom_schema_with_prefix = function()
    operations.add_queries_prefix({
        prefix = 'test',
        schema = 'test_schema',
        doc = 'Simple prefix test',
    })

    t.assert_items_equals(operations.get_queries('test_schema')['test'].resolve(), {})

    t.assert_equals(type(operations.get_queries('test_schema')['test']), 'table')
    t.assert_equals(operations.get_queries('test_schema')['test'].description, 'Simple prefix test')
    t.assert_equals(schemas.is_invalid('test_schema'), true)

    schemas.reset_invalid('test_schema')
    t.assert_equals(schemas.is_invalid('test_schema'), false)

    operations.add_query({
        schema = 'test_schema',
        prefix = 'test',
        name = 'entity_1',
        doc = 'Get entity 1',
        args = {
            entity_id = types.long,
        },
        kind = types.string,
        callback = 'fragments.entity.entity_1_get',
    })

    t.assert_equals(type(operations.get_queries('test_schema')['test'].kind.fields['entity_1']), 'table')
    t.assert_equals(operations.get_queries('test_schema')['test'].kind.fields['entity_1'].description, 'Get entity 1')
    t.assert_equals(schemas.is_invalid('test_schema'), true)

    schemas.reset_invalid('test_schema')
    t.assert_equals(schemas.is_invalid('test_schema'), false)

    operations.add_query({
        schema = 'test_schema',
        prefix = 'test',
        name = 'entity_2',
        doc = 'Get entity 2',
        args = {
            entity_id = types.long,
        },
        kind = types.string,
        callback = 'fragments.entity.entity_2_get',
    })

    t.assert_equals(type(operations.get_queries('test_schema')['test'].kind.fields['entity_1']), 'table')
    t.assert_equals(operations.get_queries('test_schema')['test'].kind.fields['entity_1'].description, 'Get entity 1')
    t.assert_equals(type(operations.get_queries('test_schema')['test'].kind.fields['entity_2']), 'table')
    t.assert_equals(operations.get_queries('test_schema')['test'].kind.fields['entity_2'].description, 'Get entity 2')
    t.assert_equals(schemas.is_invalid('test_schema'), true)
    schemas.reset_invalid('test_schema')
    t.assert_equals(schemas.is_invalid('test_schema'), false)

    t.assert_items_equals(operations.queries_list('test_schema'), {'test.entity_1', 'test.entity_2'})

    operations.remove_query({
        name = 'entity_1',
        schema = 'test_schema',
        prefix = 'test',
    })

    t.assert_equals(type(operations.get_queries('test_schema')['test'].kind.fields['entity_2']), 'table')
    t.assert_equals(operations.get_queries('test_schema')['test'].kind.fields['entity_2'].description, 'Get entity 2')
    t.assert_equals(schemas.is_invalid('test_schema'), true)
    schemas.reset_invalid('test_schema')
    t.assert_equals(schemas.is_invalid('test_schema'), false)

    operations.remove_queries_prefix({prefix = 'test', schema = 'test_schema'})
    t.assert_equals(operations.get_queries('test_schema')['test'], nil)
    t.assert_equals(schemas.is_invalid('test_schema'), true)
    schemas.reset_invalid('test_schema')
    t.assert_equals(schemas.is_invalid('test_schema'), false)

    t.assert_error_msg_content_equals(
        'No such query prefix "test1"',
        operations.add_query,
        {
            schema = 'test_schema',
            prefix = 'test1',
            name = 'entity_2',
            doc = 'Get entity 2',
            args = {
                entity_id = types.long,
            },
            kind = types.string,
            callback = 'fragments.entity.entity_2_get',
        }
    )
end

g.test_add_remove_mutation_default_schema_no_prefix = function()
    operations.add_mutation({
        name = 'entity',
        doc = 'Mutate entity',
        args = {
            name = types.long,
        },
        kind = types.string,
        callback = 'fragments.entity.entity_set',
    })

    t.assert_equals(operations.is_mutation_exists({ name = 'entity', }), true)
    t.assert_equals(type(operations.get_mutations()['entity']), 'table')
    t.assert_equals(operations.get_mutations()['entity'].description, 'Mutate entity')
    t.assert_equals(schemas.is_invalid(), true)

    schemas.reset_invalid()
    t.assert_equals(schemas.is_invalid(), false)

    t.assert_items_equals(operations.mutations_list(), {'entity'})

    local ok, err = pcall(function()
        operations.add_mutation({
            name = 'entity',
            doc = 'Mutate entity',
            args = {
                name = types.long,
            },
            kind = types.string,
            callback = 'fragments.entity.entity_set',
        })
    end)

    t.assert_equals(ok, false)
    t.assert_equals(err, 'mutation "entity" already exists in schema: "Default"')


    operations.remove_mutation({ name = 'entity' })
    t.assert_equals(operations.get_mutations()['entity'], nil)

    t.assert_equals(schemas.is_invalid(), true)
    schemas.reset_invalid()
    t.assert_equals(schemas.is_invalid(), false)
end

g.test_add_remove_mutation_default_schema_with_prefix = function()
    operations.add_mutations_prefix({
        prefix = 'test',
        doc = 'Simple prefix test',
    })

    t.assert_equals(type(operations.get_mutations()['test']), 'table')
    t.assert_equals(operations.is_mutations_prefix_exists({ prefix = 'test' }), true)
    t.assert_equals(operations.get_mutations()['test'].description, 'Simple prefix test')
    t.assert_equals(operations.get_mutations()['test'].resolve(), {})
    t.assert_equals(schemas.is_invalid(), true)

    schemas.reset_invalid()
    t.assert_equals(schemas.is_invalid(), false)

    local ok, err = pcall(function()
        operations.add_mutations_prefix({
            prefix = 'test',
            doc = 'Simple prefix test',
        })
    end)

    t.assert_equals(ok, false)
    t.assert_equals(err, 'mutation or prefix with name "test" already exists in schema: "Default"')

    operations.add_mutation({
        prefix = 'test',
        name = 'entity_1',
        doc = 'Mutate entity 1',
        args = {
            name = types.long,
        },
        kind = types.string,
        callback = 'fragments.entity.entity_1_set',
    })

    t.assert_equals(operations.is_mutation_exists({ prefix = 'test', name = 'entity_1', }), true)
    t.assert_equals(type(operations.get_mutations()['test'].kind.fields['entity_1']), 'table')
    t.assert_equals(operations.get_mutations()['test'].kind.fields['entity_1'].description, 'Mutate entity 1')
    t.assert_equals(schemas.is_invalid(), true)
    schemas.reset_invalid()
    t.assert_equals(schemas.is_invalid(), false)

    ok, err = pcall(function()
        operations.add_mutation({
            prefix = 'test',
            name = 'entity_1',
            doc = 'Mutate entity 1',
            args = {
                name = types.long,
            },
            kind = types.string,
            callback = 'fragments.entity.entity_1_set',
        })
    end)

    t.assert_equals(ok, false)
    t.assert_equals(err, 'mutation "entity_1" already exists in prefix "test" in schema: "Default"')

    operations.add_mutation({
        prefix = 'test',
        name = 'entity_2',
        doc = 'Mutate entity 2',
        args = {
            name = types.long,
        },
        kind = types.string,
        callback = 'fragments.entity.entity_2_set',
    })

    t.assert_equals(type(operations.get_mutations()['test'].kind.fields['entity_1']), 'table')
    t.assert_equals(operations.get_mutations()['test'].kind.fields['entity_1'].description, 'Mutate entity 1')
    t.assert_equals(type(operations.get_mutations()['test'].kind.fields['entity_2']), 'table')
    t.assert_equals(operations.get_mutations()['test'].kind.fields['entity_2'].description, 'Mutate entity 2')
    t.assert_equals(schemas.is_invalid(), true)
    schemas.reset_invalid()
    t.assert_equals(schemas.is_invalid(), false)

    t.assert_items_equals(operations.mutations_list(), {'test.entity_1', 'test.entity_2'})

    operations.remove_mutation({
        name = 'entity_1',
        prefix = 'test',
    })
    t.assert_equals(type(operations.get_mutations()['test'].kind.fields['entity_2']), 'table')
    t.assert_equals(operations.get_mutations()['test'].kind.fields['entity_2'].description, 'Mutate entity 2')
    t.assert_equals(schemas.is_invalid(), true)
    schemas.reset_invalid()
    t.assert_equals(schemas.is_invalid(), false)

    operations.remove_mutations_prefix({prefix = 'test'})
    t.assert_equals(operations.is_mutations_prefix_exists({ prefix = 'test' }), false)
    t.assert_equals(operations.get_mutations()['test'], nil)
    t.assert_equals(schemas.is_invalid(), true)
    schemas.reset_invalid()
    t.assert_equals(schemas.is_invalid(), false)


    t.assert_error_msg_content_equals(
        'No such mutation prefix "test1"',
        operations.add_mutation,
        {
            prefix = 'test1',
            name = 'entity_2',
            doc = 'Mutate entity 2',
            args = {
                name = types.long,
            },
            kind = types.string,
            callback = 'fragments.entity.entity_2_set',
        }
    )
end

g.test_add_remove_mutation_custom_schema_no_prefix = function()
    operations.add_mutation({
        schema = 'test_schema',
        name = 'entity',
        doc = 'Mutate entity',
        args = {
            name = types.long,
        },
        kind = types.string,
        callback = 'fragments.entity.entity_set',
    })
    t.assert_equals(type(operations.get_mutations('test_schema')['entity']), 'table')
    t.assert_equals(operations.get_mutations('test_schema')['entity'].description, 'Mutate entity')
    t.assert_equals(schemas.is_invalid('test_schema'), true)

    schemas.reset_invalid('test_schema')
    t.assert_equals(schemas.is_invalid('test_schema'), false)

    t.assert_items_equals(operations.mutations_list('test_schema'), {'entity'})

    operations.remove_mutation({name = 'entity', schema = 'test_schema'})
    t.assert_equals(operations.get_mutations('test_schema')['entity'], nil)

    t.assert_equals(schemas.is_invalid('test_schema'), true)
    schemas.reset_invalid('test_schema')
    t.assert_equals(schemas.is_invalid('test_schema'), false)
end

g.test_add_remove_mutation_custom_schema_with_prefix = function()
    operations.add_mutations_prefix({
        prefix = 'test',
        schema = 'test_schema',
        doc = 'Simple prefix test',
    })

    t.assert_equals(type(operations.get_mutations('test_schema')['test']), 'table')
    t.assert_equals(operations.get_mutations('test_schema')['test'].description, 'Simple prefix test')
    t.assert_equals(operations.get_mutations('test_schema')['test'].resolve(), {})
    t.assert_equals(schemas.is_invalid('test_schema'), true)

    schemas.reset_invalid('test_schema')
    t.assert_equals(schemas.is_invalid('test_schema'), false)

    operations.add_mutation({
        schema = 'test_schema',
        prefix = 'test',
        name = 'entity_1',
        doc = 'Mutate entity 1',
        args = {
            name = types.long,
        },
        kind = types.string,
        callback = 'fragments.entity.entity_1_set',
    })

    t.assert_equals(type(operations.get_mutations('test_schema')['test'].kind.fields['entity_1']), 'table')
    t.assert_equals(
        operations.get_mutations('test_schema')['test'].kind.fields['entity_1'].description,
        'Mutate entity 1'
    )
    t.assert_equals(schemas.is_invalid('test_schema'), true)
    schemas.reset_invalid('test_schema')
    t.assert_equals(schemas.is_invalid('test_schema'), false)

    operations.add_mutation({
        schema = 'test_schema',
        prefix = 'test',
        name = 'entity_2',
        doc = 'Mutate entity 2',
        args = {
            name = types.long,
        },
        kind = types.string,
        callback = 'fragments.entity.entity_2_set',
    })

    t.assert_equals(type(operations.get_mutations('test_schema')['test'].kind.fields['entity_1']), 'table')
    t.assert_equals(
        operations.get_mutations('test_schema')['test'].kind.fields['entity_1'].description,
        'Mutate entity 1'
    )
    t.assert_equals(type(operations.get_mutations('test_schema')['test'].kind.fields['entity_2']), 'table')
    t.assert_equals(
        operations.get_mutations('test_schema')['test'].kind.fields['entity_2'].description,
        'Mutate entity 2'
    )
    t.assert_equals(schemas.is_invalid('test_schema'), true)
    schemas.reset_invalid('test_schema')
    t.assert_equals(schemas.is_invalid('test_schema'), false)

    t.assert_items_equals(operations.mutations_list('test_schema'), {'test.entity_1', 'test.entity_2'})

    operations.remove_mutation({
        name = 'entity_1',
        schema = 'test_schema',
        prefix = 'test',
    })
    t.assert_equals(type(operations.get_mutations('test_schema')['test'].kind.fields['entity_2']), 'table')
    t.assert_equals(
        operations.get_mutations('test_schema')['test'].kind.fields['entity_2'].description,
        'Mutate entity 2'
    )
    t.assert_equals(schemas.is_invalid('test_schema'), true)
    schemas.reset_invalid('test_schema')
    t.assert_equals(schemas.is_invalid('test_schema'), false)

    operations.remove_mutations_prefix({
        prefix = 'test',
        schema = 'test_schema',
    })
    t.assert_equals(operations.get_mutations('test_schema')['test'], nil)
    t.assert_equals(schemas.is_invalid('test_schema'), true)
    schemas.reset_invalid('test_schema')
    t.assert_equals(schemas.is_invalid('test_schema'), false)

    t.assert_error_msg_content_equals(
        'No such mutation prefix "test1"',
        operations.add_mutation,
        {
            schema = 'test_schema',
            prefix = 'test1',
            name = 'entity_2',
            doc = 'Mutate entity 2',
            args = {
                name = types.long,
            },
            kind = types.string,
            callback = 'fragments.entity.entity_2_set',
        }
    )
end

g.test_add_remove_space_query_default_schema_no_prefix = function()
    local space = test_helper.create_space()

        operations.add_space_query({
            space = 'entity',
            doc = 'Get entity',
            args = {
                entity_id = types.int.nonNull,
            },
            callback = 'fragments.entity.entity_get',
        })

        t.assert_equals(type(operations.get_queries()['entity']), 'table')
        t.assert_equals(operations.get_queries()['entity'].description, 'Get entity')
        t.assert_equals(schemas.is_invalid(), true)
        schemas.reset_invalid()
        t.assert_equals(schemas.is_invalid(), false)
        t.assert_items_equals(operations.queries_list(), {'entity'})

        operations.remove_space_query({
            space = 'entity'
        })
        t.assert_equals(schemas.is_invalid(), true)
        schemas.reset_invalid()

        t.assert_items_equals(operations.queries_list(), {})

    space:drop()

    t.assert_error_msg_contains(
        'space \'entity\' doesn\'t exists',
        operations.add_space_query,
        {
            prefix = 'test',
            space = 'entity',
            doc = 'Get entity',
            args = {
                entity_id = types.int.nonNull,
            },
            callback = 'fragments.entity.entity_get',
        }
    )
end

g.test_add_remove_space_query_default_schema_with_prefix = function()
    local space = test_helper.create_space()

    operations.add_queries_prefix({
        prefix = 'test',
        doc = 'Simple prefix test',
    })

    operations.add_space_query({
        prefix = 'test',
        space = 'entity',
        doc = 'Get entity',
        args = {
            entity_id = types.int.nonNull,
        },
        callback = 'fragments.entity.entity_get',
    })

    t.assert_equals(type(operations.get_queries()['test'].kind.fields['entity']), 'table')
    t.assert_equals(operations.get_queries()['test'].kind.fields['entity'].description, 'Get entity')
    t.assert_equals(schemas.is_invalid(), true)
    schemas.reset_invalid()
    t.assert_equals(schemas.is_invalid(), false)
    t.assert_items_equals(operations.queries_list(), {'test.entity'})

    operations.remove_queries_prefix({prefix = 'test'})
    t.assert_equals(schemas.is_invalid(), true)
    schemas.reset_invalid()
    t.assert_equals(schemas.is_invalid(), false)

    t.assert_items_equals(operations.queries_list(), {})

    operations.add_queries_prefix({
        prefix = 'test',
        doc = 'Simple prefix test',
    })

    operations.add_space_query({
        prefix = 'test',
        space = 'entity',
        doc = 'Get entity',
        args = {
            entity_id = types.int.nonNull,
        },
        callback = 'fragments.entity.entity_get',
    })

    operations.remove_space_query({
        space = 'entity',
        prefix = 'test',
    })

    t.assert_items_equals(operations.queries_list(), {})

    operations.add_space_query({
        prefix = 'test',
        space = 'entity',
        doc = 'Get entity',
        args = {
            entity_id = types.int.nonNull,
        },
        callback = 'fragments.entity.entity_get',
    })

    operations.remove_space_query({
        space = 'entity',
        name = 'entity',
        prefix = 'test',
    })

    t.assert_items_equals(operations.queries_list(), {})

    space:drop()
end

g.test_add_remove_space_query_custom_schema_no_prefix = function()
    local space = test_helper.create_space()

    operations.add_space_query({
        schema = 'test_schema',
        space = 'entity',
        doc = 'Get entity',
        args = {
            entity_id = types.int.nonNull,
        },
        callback = 'fragments.entity.entity_get',
    })

    t.assert_equals(type(operations.get_queries('test_schema')['entity']), 'table')
    t.assert_equals(operations.get_queries('test_schema')['entity'].description, 'Get entity')
    t.assert_equals(schemas.is_invalid('test_schema'), true)
    schemas.reset_invalid('test_schema')
    t.assert_equals(schemas.is_invalid('test_schema'), false)
    t.assert_items_equals(operations.queries_list('test_schema'), {'entity'})

    operations.remove_space_query({
        schema = 'test_schema',
        space = 'entity'
    })
    t.assert_equals(schemas.is_invalid('test_schema'), true)
    schemas.reset_invalid('test_schema')
    t.assert_equals(schemas.is_invalid('test_schema'), false)

    t.assert_items_equals(operations.queries_list('test_schema'), {})

    space:drop()
end

g.test_add_remove_space_query_custom_schema_with_prefix = function()
    local space = test_helper.create_space()

    operations.add_queries_prefix({
        prefix = 'test',
        schema = 'test_schema',
        doc = 'Simple prefix test',
    })

    operations.add_space_query({
        prefix = 'test',
        schema = 'test_schema',
        space = 'entity',
        doc = 'Get entity',
        args = {
            entity_id = types.int.nonNull,
        },
        callback = 'fragments.entity.entity_get',
    })

    t.assert_equals(type(operations.get_queries('test_schema')['test'].kind.fields['entity']), 'table')
    t.assert_equals(operations.get_queries('test_schema')['test'].kind.fields['entity'].description, 'Get entity')
    t.assert_equals(schemas.is_invalid('test_schema'), true)
    schemas.reset_invalid('test_schema')
    t.assert_equals(schemas.is_invalid('test_schema'), false)
    t.assert_items_equals(operations.queries_list('test_schema'), {'test.entity'})

    operations.remove_query({
        schema = 'test_schema',
        name = 'entity',
        prefix = 'test',
    })

    t.assert_items_equals(operations.queries_list('test_schema'), {})

    t.assert_equals(schemas.is_invalid('test_schema'), true)
    schemas.reset_invalid('test_schema')
    t.assert_equals(schemas.is_invalid('test_schema'), false)

    operations.remove_queries_prefix({
        schema = 'test_schema',
        prefix = 'test',
    })

    space:drop()
end

g.test_add_remove_space_mutation_default_schema_no_prefix = function()
    local space = test_helper.create_space()

    operations.add_space_mutation({
        space = 'entity',
        doc = 'Mutate entity',
        args = {
            entity_id = types.int.nonNull
        },
        list = true,
        kind = types.string,
        callback = "fragments.entity.entity_set"
    })
    t.assert_equals(type(operations.get_mutations()['entity']), 'table')
    t.assert_equals(operations.get_mutations()['entity'].description, 'Mutate entity')
    t.assert_equals(schemas.is_invalid(), true)
    schemas.reset_invalid()
    t.assert_equals(schemas.is_invalid(), false)
    t.assert_items_equals(operations.mutations_list(), {'entity'})

    operations.remove_space_mutation({
        space = 'entity'
    })

    t.assert_equals(schemas.is_invalid(), true)
    schemas.reset_invalid()

    t.assert_items_equals(operations.mutations_list(), {})

    space:drop()

    -- test add_space_mutation() with unexisting space
    t.assert_error_msg_contains(
        'space \'entity\' doesn\'t exists',
        operations.add_space_mutation,
        {
            prefix = 'test',
            space = 'entity',
            doc = 'Mutate entity',
            args = {
                entity_id = types.int.nonNull,
            },
            kind = types.string,
            callback = 'fragments.entity.entity_set',
        }
    )
end

g.test_add_remove_space_mutation_default_schema_with_prefix = function()
    local space = test_helper.create_space()

    operations.add_mutations_prefix({
        prefix = 'test',
        doc = 'Simple prefix test',
    })

    operations.add_space_mutation({
        prefix = 'test',
        space = 'entity',
        doc = 'Mutate entity',
        args = {
            entity_id = types.int.nonNull,
        },
        list = true,
        callback = 'fragments.entity.entity_set',
    })

    t.assert_equals(type(operations.get_mutations()['test'].kind.fields['entity']), 'table')
    t.assert_equals(operations.get_mutations()['test'].kind.fields['entity'].description, 'Mutate entity')
    t.assert_equals(schemas.is_invalid(), true)
    schemas.reset_invalid()
    t.assert_equals(schemas.is_invalid(), false)
    t.assert_items_equals(operations.mutations_list(), {'test.entity'})

    operations.remove_mutations_prefix({prefix = 'test'})

    t.assert_equals(schemas.is_invalid(), true)
    schemas.reset_invalid()
    t.assert_equals(schemas.is_invalid(), false)

    t.assert_items_equals(operations.mutations_list(), {})

    operations.add_mutations_prefix({
        prefix = 'test',
        doc = 'Simple prefix test',
    })

    operations.add_space_mutation({
        prefix = 'test',
        space = 'entity',
        doc = 'Mutate entity',
        args = {
            entity_id = types.int.nonNull,
        },
        callback = 'fragments.entity.entity_set',
    })

    operations.remove_space_mutation({
        prefix = 'test',
        space = 'entity',
    })

    t.assert_items_equals(operations.mutations_list(), {})

    operations.add_space_mutation({
        prefix = 'test',
        space = 'entity',
        doc = 'Mutate entity',
        args = {
            entity_id = types.int.nonNull,
        },
        callback = 'fragments.entity.entity_set',
    })

    operations.remove_space_mutation({
        prefix = 'test',
        space = 'entity',
        name = 'entity',
    })

    t.assert_items_equals(operations.mutations_list(), {})

    space:drop()
end

g.test_add_remove_space_mutation_custom_schema_no_prefix = function()
    local space = test_helper.create_space()

    operations.add_space_mutation({
        schema = 'test_schema',
        space = 'entity',
        doc = 'Mutate entity',
        args = {
            entity_id = types.int.nonNull
        },
        callback = "fragments.entity.entity_set"
    })
    t.assert_equals(type(operations.get_mutations('test_schema')['entity']), 'table')
    t.assert_equals(operations.get_mutations('test_schema')['entity'].description, 'Mutate entity')
    t.assert_equals(schemas.is_invalid('test_schema'), true)
    schemas.reset_invalid('test_schema')
    t.assert_equals(schemas.is_invalid('test_schema'), false)
    t.assert_items_equals(operations.mutations_list('test_schema'), {'entity'})

    operations.remove_space_mutation({
        schema = 'test_schema',
        space = 'entity'
    })

    t.assert_equals(schemas.is_invalid('test_schema'), true)
    schemas.reset_invalid('test_schema')

    t.assert_items_equals(operations.mutations_list('test_schema'), {})

    space:drop()
end

g.test_add_remove_space_mutation_custom_schema_with_prefix = function()
    local space = test_helper.create_space()

    operations.add_mutations_prefix({
        prefix = 'test',
        schema = 'test_schema',
        doc = 'Simple prefix test',
    })

    operations.add_space_mutation({
        prefix = 'test',
        schema = 'test_schema',
        space = 'entity',
        doc = 'Mutate entity',
        args = {
            entity_id = types.int.nonNull
        },
        callback = "fragments.entity.entity_set"
    })
    t.assert_equals(type(operations.get_mutations('test_schema')['test'].kind.fields['entity']), 'table')
    t.assert_equals(operations.get_mutations('test_schema')['test'].kind.fields['entity'].description, 'Mutate entity')
    t.assert_equals(schemas.is_invalid('test_schema'), true)
    schemas.reset_invalid('test_schema')
    t.assert_equals(schemas.is_invalid('test_schema'), false)
    t.assert_items_equals(operations.mutations_list('test_schema'), {'test.entity'})

    operations.remove_mutation({
        schema = 'test_schema',
        name = 'entity',
        prefix = 'test',
    })

    t.assert_items_equals(operations.mutations_list('test_schema'), {})

    t.assert_equals(schemas.is_invalid('test_schema'), true)
    schemas.reset_invalid('test_schema')
    t.assert_equals(schemas.is_invalid('test_schema'), false)

    operations.remove_mutations_prefix({
        schema = 'test_schema',
        prefix = 'test',
    })

    space:drop()
end

g.test_operations_remove_all = function()
    operations.add_query({
        name = 'entity',
        doc = 'Get entity',
        args = {
            entity_id = types.long,
        },
        kind = types.string,
        callback = 'fragments.entity.entity_get',
    })

    t.assert_items_equals(operations.queries_list(), {'entity'})

    operations.add_queries_prefix({
        prefix = 'test',
        doc = 'Simple prefix test',
    })

    operations.add_query({
        prefix = 'test',
        name = 'entity',
        doc = 'Get entity',
        args = {
            entity_id = types.long
        },
        kind = types.string,
        callback = 'fragments.entity.entity_get'
    })

    t.assert_items_equals(operations.queries_list(), {'entity', 'test.entity'})

    operations.add_query({
        schema = 'test_schema',
        name = 'entity',
        doc = 'Get entity',
        args = {
            entity_id = types.long
        },
        kind = types.string,
        callback = 'fragments.entity.entity_get'
    })

    t.assert_items_equals(operations.queries_list('test_schema'), {'entity'})

    operations.add_queries_prefix({
        schema = 'test_schema',
        prefix = 'test',
        doc = 'Simple prefix test',
    })

    operations.add_query({
        schema = 'test_schema',
        prefix = 'test',
        name = 'entity',
        doc = 'Get entity',
        args = {
            entity_id = types.long
        },
        kind = types.string,
        callback = 'fragments.entity.entity_get'
    })

    t.assert_items_equals(operations.queries_list('test_schema'), {'entity', 'test.entity'})

    operations.add_mutation({
        name = 'entity',
        doc = 'Mutate entity',
        args = {
            name = types.long,
        },
        kind = types.string,
        callback = 'fragments.entity.entity_set'
    })

    t.assert_items_equals(operations.mutations_list(), {'entity'})

    operations.add_mutations_prefix({
        prefix = 'test',
        doc = 'Simple prefix test',
    })

    operations.add_mutation({
        prefix = 'test',
        name = 'entity',
        doc = 'Mutate entity',
        args = {
            name = types.long,
        },
        kind = types.string,
        callback = 'fragments.entity.entity_set'
    })

    t.assert_items_equals(operations.mutations_list(), {'entity', 'test.entity'})

    operations.add_mutation({
        schema = 'test_schema',
        name = 'entity',
        doc = 'Mutate entity',
        args = {
            name = types.long,
        },
        kind = types.string,
        callback = 'fragments.entity.entity_set'
    })

    t.assert_items_equals(operations.mutations_list('test_schema'), {'entity'})

    operations.add_mutations_prefix({
        schema = 'test_schema',
        prefix = 'test',
        doc = 'Simple prefix test',
    })

    operations.add_mutation({
        schema = 'test_schema',
        name = 'entity',
        prefix = 'test',
        doc = 'Mutate entity',
        args = {
            name = types.long,
        },
        kind = types.string,
        callback = 'fragments.entity.entity_set'
    })

    t.assert_items_equals(operations.mutations_list('test_schema'), {'entity', 'test.entity'})

    operations.remove_all({schema = box.NULL})

    t.assert_items_equals(operations.get_queries(), {})
    t.assert_items_equals(operations.get_mutations(), {})
    t.assert_items_equals(operations.queries_list(), {})
    t.assert_items_equals(operations.mutations_list(), {})

    operations.remove_all()
    t.assert_items_equals(operations.get_queries(), {})
    t.assert_items_equals(operations.get_mutations(), {})
    t.assert_items_equals(operations.queries_list(), {})
    t.assert_items_equals(operations.mutations_list(), {})
    t.assert_items_equals(operations.get_queries('test_schema'), {})
    t.assert_items_equals(operations.get_mutations('test_schema'), {})
    t.assert_items_equals(operations.queries_list('test_schema'), {})
    t.assert_items_equals(operations.mutations_list('test_schema'), {})

    local space = test_helper.create_space()

    operations.add_space_query({
        space = 'entity',
        doc = 'Get entity',
        args = {
            entity_id = types.int.nonNull,
        },
        callback = 'fragments.entity.entity_get',
    })

    operations.add_space_mutation({
        space = 'entity',
        doc = 'Mutate entity',
        args = {
            entity_id = types.int.nonNull,
        },
        callback = 'fragments.entity.entity_set',
    })

    operations.remove_all({schema = box.NULL})

    t.assert_items_equals(operations.get_queries(), {})
    t.assert_items_equals(operations.get_mutations(), {})
    t.assert_items_equals(operations.queries_list(), {})
    t.assert_items_equals(operations.mutations_list(), {})

    space:drop()
end

g.test_operations_stop = function()
    operations.add_query({
        name = 'entity',
        doc = 'Get entity',
        args = {
            entity_id = types.long,
        },
        kind = types.string,
        callback = 'fragments.entity.entity_get',
    })

    t.assert_equals(type(operations.get_queries()['entity']), 'table')
    t.assert_equals(operations.get_queries()['entity'].description, 'Get entity')
    t.assert_equals(schemas.is_invalid(), true)
    t.assert_items_equals(schemas.schemas_list(), {'Default'})

    schemas.reset_invalid()
    t.assert_equals(schemas.is_invalid(), false)

    operations.add_mutation({
        name = 'entity',
        doc = 'Mutate entity',
        args = {
            name = types.long,
        },
        kind = types.string,
        callback = 'fragments.entity.entity_set'
    })

    operations.stop()
    t.assert_equals(operations.get_queries(), {})
    t.assert_equals(operations.get_mutations(), {})
    t.assert_items_equals(operations.queries_list(), {})
    t.assert_items_equals(operations.mutations_list(), {})
end

g.test_on_resolve_trigger = function()
    operations.add_query({
        name = 'entity',
        doc = 'Get entity',
        args = {
            entity_id = types.long,
        },
        kind = types.string,
        callback = 'test.unit.operations_test.stub1',
    })

    local res = operations.get_queries()['entity'].resolve()
    t.assert_equals(res, "Operations test")

    local on_resolve_trigger1 = function(operation_type, operation_schema, operation_prefix, operation_name)
        error(
            operation_type ..' '.. tostring(operation_schema) ..' '..tostring(operation_prefix) ..' '.. operation_name,
            0
        )
    end

    operations.on_resolve(on_resolve_trigger1, nil)
    t.assert_error_msg_contains('query Default nil entity', operations.get_queries()['entity'].resolve)

    operations.stop()

    operations.add_query({
        name = 'entity',
        doc = 'Get entity',
        args = {
            entity_id = types.long,
        },
        kind = types.string,
        callback = 'test.unit.operations_test.stub2',
    })

    local on_resolve_trigger2 = function(_, field_name)
        return field_name
    end

    operations.on_resolve(on_resolve_trigger2, nil)
    t.assert_error_msg_contains('callback error', operations.get_queries()['entity'].resolve)

    operations.on_resolve(nil, on_resolve_trigger2)
    t.assert_error_msg_contains('callback error', operations.get_queries()['entity'].resolve)
    operations.stop()

end

g.test_remove_operations_by_space_name = function()
    local space = test_helper.create_space()

    operations.add_space_query({
        space = 'entity',
        doc = 'Get entity',
        args = {
            entity_id = types.int.nonNull,
        },
        callback = 'fragments.entity.entity_get',
    })

    t.assert_items_equals(operations.queries_list(), {'entity'})

    operations.add_queries_prefix({
        prefix = 'test',
        doc = 'Simple prefix test',
    })

    operations.add_space_query({
        prefix = 'test',
        space = 'entity',
        doc = 'Get entity',
        args = {
            entity_id = types.int.nonNull,
        },
        callback = 'fragments.entity.entity_get',
    })

    t.assert_items_equals(operations.queries_list(), {'entity', 'test.entity'})

    operations.add_space_query({
        schema = 'test_schema',
        space = 'entity',
        doc = 'Get entity',
        args = {
            entity_id = types.int.nonNull,
        },
        callback = 'fragments.entity.entity_get',
    })

    t.assert_items_equals(operations.queries_list('test_schema'), {'entity'})

    operations.add_queries_prefix({
        prefix = 'test',
        schema = 'test_schema',
        doc = 'Simple prefix test',
    })

    operations.add_space_query({
        prefix = 'test',
        schema = 'test_schema',
        space = 'entity',
        doc = 'Get entity',
        args = {
            entity_id = types.int.nonNull,
        },
        callback = 'fragments.entity.entity_get',
    })

    t.assert_items_equals(operations.queries_list('test_schema'), {'entity', 'test.entity'})

    operations.add_space_mutation({
        space = 'entity',
        doc = 'Mutate entity',
        args = {
            entity_id = types.int.nonNull
        },
        callback = "fragments.entity.entity_set"
    })

    t.assert_items_equals(operations.mutations_list(), {'entity'})

    operations.add_mutations_prefix({
        prefix = 'test',
        doc = 'Simple prefix test'
    })

    operations.add_space_mutation({
        prefix = 'test',
        space = 'entity',
        doc = 'Mutate entity',
        args = {
            entity_id = types.int.nonNull,
        },
        callback = 'fragments.entity.entity_set',
    })

    t.assert_items_equals(operations.mutations_list(), {'entity', 'test.entity'})

    operations.add_space_mutation({
        schema = 'test_schema',
        space = 'entity',
        doc = 'Mutate entity',
        args = {
            entity_id = types.int.nonNull
        },
        callback = "fragments.entity.entity_set"
    })

    t.assert_items_equals(operations.mutations_list('test_schema'), {'entity'})

    operations.add_mutations_prefix({
        prefix = 'test',
        schema = 'test_schema',
        doc = 'Simple prefix test',
    })

    operations.add_space_mutation({
        prefix = 'test',
        schema = 'test_schema',
        space = 'entity',
        doc = 'Mutate entity',
        args = {
            entity_id = types.int.nonNull
        },
        callback = "fragments.entity.entity_set"
    })

    t.assert_items_equals(operations.mutations_list('test_schema'), {'entity', 'test.entity'})

    operations.remove_operations_by_space_name('entity')
    t.assert_items_equals(operations.queries_list(), {})
    t.assert_items_equals(operations.mutations_list(), {})
    t.assert_items_equals(operations.queries_list('test_schema'), {})
    t.assert_items_equals(operations.mutations_list('test_schema'), {})

    space:drop()
end


local function stub1()
    return 'Operations test'
end

local function stub2()
    return nil, 'callback error'
end

return {
    stub1 = stub1,
    stub2 = stub2,
}
