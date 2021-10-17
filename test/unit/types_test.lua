local t = require('luatest')
local g = t.group('types')

local helper = require('test.helper')

local defaults = require('graphqlapi.defaults')
local operations = require('graphqlapi.operations')
local types = require('graphqlapi.types')
local schemas = require('graphqlapi.schemas')

local json = require('json')

g.before_all(function()
    types.remove_all()
end)

g.after_each(function()
    types.remove_all()
end)

local function add_test_enum(schema)
    types.enum({
        name = 'TestEnum',
        schema = schema,
        description = 'Test Enum',
        values = {
            E2E = 'E2E',
            UNIT = 'UNIT',
            INTEGRATION = 'INTEGRATION',
        },
    })
end

g.test_enum = function()
    add_test_enum()

    local ok, err = pcall(function()
        add_test_enum()
    end)

    t.assert_equals(ok, false)
    t.assert_str_contains(err, 'enum "TestEnum" already exists in schema: "Default"')
end

g.test_input_object = function()
    types.inputObject({
        name = 'Human',
        fields = {
            name = types.string.nonNull,
        }
    })

    local ok, err = pcall(function()
        types.inputObject({
            name = 'Human',
            fields = {
                name = types.string.nonNull,
            }
        })
    end)

    t.assert_equals(ok, false)
    t.assert_str_contains(err, 'inputObject "Human" already exists in schema: "Default"')
end

g.test_interface = function()
    types.interface({
        name = 'Human',
        fields = {
            name = types.string.nonNull,
        }
    })

    local ok, err = pcall(function()
        types.interface({
            name = 'Human',
            fields = {
                name = types.string.nonNull,
            }
        })
    end)

    t.assert_equals(ok, false)
    t.assert_str_contains(err, 'interface "Human" already exists in schema: "Default"')
end

g.test_object = function()
    types.object({
        name = 'Human',
        fields = {
            name = types.string.nonNull,
        }
    })

    local ok, err = pcall(function()
        types.object({
            name = 'Human',
            fields = {
                name = types.string.nonNull,
            }
        })
    end)

    t.assert_equals(ok, false)
    t.assert_str_contains(err, 'object "Human" already exists in schema: "Default"')
end

g.test_union = function()
    local human = types.object({
        name = 'Human',
        fields = {
            name = types.string.nonNull,
        }
    })

    local cat = types.object({
        name = 'Cat',
        fields = {
            name = types.string.nonNull,
            nickname = types.string,
            meowVolume = types.int,
        }
    })

    types.union({
        name = 'CatOrDog',
        types = { cat, human, }
    })

    local ok, err = pcall(function()
        types.union({
            name = 'CatOrDog',
            types = { cat, human, }
        })
    end)

    t.assert_equals(ok, false)
    t.assert_str_contains(err, 'union "CatOrDog" already exists in schema: "Default"')
end

g.test_double = function()
    local double = types.double
    t.assert_equals(double.__type, 'Scalar')
    t.assert_equals(double.name, 'Double')
    local double_test_suite = {
        {'int', '123', 123, }, {'int', '-123', -123, }, {'float', '0.0', 0.0},
        {'float', '-0.0', -0.0}, {'float', '12.34', 12.34}, {'float', '1e0', 1e0},
        {'float', '1e3', 1e3}, {'float', '1.0e3', 1.0e3}, {'float', '1.0e+3', 1.0e+3},
        {'float', '1.0e-3', 1.0e-3}, {'float', '1.00e-30', 1.00e-30},
    }

    for _, ts in pairs(double_test_suite) do
        t.assert_equals(double.serialize(ts[2]), ts[3])
        t.assert_equals(double.parseValue(ts[2]), ts[3])
        t.assert_equals(double.parseLiteral({kind = ts[1], value = ts[2]}), ts[3])
        t.assert_equals(double.isValueOfTheType(ts[3]), true)
    end
end

g.test_any = function()
    local any = types.any
    t.assert_equals(any.__type, 'Scalar')
    t.assert_equals(any.name, 'Any')
    local any_test_suite = {
        {'boolean', 'true', true, }, {'float', '-1.23', -1.23, },
        {'int', '123', 123}, {'long', '1234567890000', 1234567890000},
        {'null', 'null', nil}, {'string', 'string', 'string'},
    }
    for _, ts in pairs(any_test_suite) do
        t.assert_equals(any.serialize(ts[2]), ts[2])
        t.assert_equals(any.parseValue(ts[2]), ts[2])
        t.assert_equals(any.parseLiteral({kind = ts[1], value = ts[2]}), ts[3])
        t.assert_equals(any.isValueOfTheType(ts[3]), true)
    end

    local ok, err = pcall(function()
        any.serialize({})
    end)
    t.assert_equals(ok, false)
    t.assert_str_contains(err, 'table is not a scalar kind')

    ok, err = pcall(function()
        any.parseValue({})
    end)
    t.assert_equals(ok, false)
    t.assert_str_contains(err, 'table is not a scalar kind')
end

g.test_map = function()
    local test_map = { a = 'a', b = 1, c = 1.1, d = 'd', }
    local map = types.map
    t.assert_equals(map.__type, 'Scalar')
    t.assert_equals(map.name, 'Map')

    t.assert_equals(map.serialize(test_map), json.encode(test_map))
    t.assert_equals(map.parseValue(), nil)
    t.assert_equals(map.parseValue(123), nil)
    t.assert_items_equals(map.parseValue(json.encode(test_map)), test_map)
    t.assert_equals(map.parseLiteral({kind = 'string', value = json.encode(test_map)}), test_map)
    t.assert_equals(map.parseLiteral({}), nil)
    t.assert_equals(map.isValueOfTheType(), true)
    t.assert_equals(map.isValueOfTheType(''), true)
    t.assert_equals(map.isValueOfTheType(1), false)
end

g.test_space_fields = function()
    local space = helper.create_space('entity')
    local fields = types.space_fields('entity')

    t.assert_equals(fields['bucket_id'].kind.__type, 'Scalar')
    t.assert_equals(fields['entity_id'].kind.__type, 'Scalar')
    t.assert_equals(fields['entity'].kind.__type, 'Scalar')
    t.assert_equals(fields['property'].__type, 'Scalar')
    t.assert_equals(fields['feature'].__type, 'Scalar')

    fields = types.space_fields('entity', true)

    t.assert_equals(fields['bucket_id'].kind.__type, 'NonNull')
    t.assert_equals(fields['entity_id'].kind.__type, 'NonNull')
    t.assert_equals(fields['entity'].kind.__type, 'Scalar')
    t.assert_equals(fields['property'].__type, 'Scalar')
    t.assert_equals(fields['feature'].__type, 'NonNull')

    space:drop()
end

g.test_remove = function()
    local space = helper.create_space('entity')
    types.add_space_object({
        name = 'entity',
        description = 'Entity object',
        space = 'entity',
    })

    t.assert_items_equals(types.list_types(), {'entity'})
    types.remove('entity')

    space:drop()
end

g.test_remove_all = function()
    t.assert_items_equals(types.list_types(), {})
    t.assert_items_equals(types.list_types('Spaces'), {})

    add_test_enum()
    add_test_enum('Spaces')

    t.assert_items_equals(schemas.list_schemas(), {'Spaces', 'Default'})

    t.assert_items_equals(types.list_types(), {'TestEnum'})
    t.assert_items_equals(types.list_types('Spaces'), {'TestEnum'})

    types.remove_all()
    t.assert_items_equals(types.list_types(), {})
    t.assert_items_equals(types.list_types('Spaces'), {})

    add_test_enum()
    add_test_enum('Spaces')

    t.assert_items_equals(schemas.list_schemas(), {'Spaces', 'Default'})

    t.assert_items_equals(types.list_types(), {'TestEnum'})
    t.assert_items_equals(types.list_types('Spaces'), {'TestEnum'})

    types.remove_all(box.NULL)
    t.assert_items_equals(types.list_types(), {})

    types.remove_all('Spaces')
    t.assert_items_equals(types.list_types('Spaces'), {})

    local space = helper.create_space('entity')

    types.add_space_object({ space = 'entity', name = 'entity', })
    types.add_space_object({ space = 'entity', name = 'entity1', })
    t.assert_items_equals(types.list_types(), {'entity', 'entity1'})
    types.remove_all('Default')

    types.add_space_object({
        name = 'entity',
        description = 'Entity object',
        space = 'entity',
    })

    types.add_directive({
        name = 'my_directive',
        description = 'Test directive',
        args = {
            nickname = types.string,
        },
        onField = true,
    })

    t.assert_items_equals(types.directives_list(), { 'my_directive', })

    types.remove_all(box.NULL)
    types.remove_all()
    types.remove_all()

    t.assert_items_equals(types.list_types(), {})
    t.assert_items_equals(types.directives_list(), {})

    types.add_space_object({
        schema = 'spaces',
        name = 'entity',
        description = 'Entity object',
        space = 'entity',
    })

    types.add_directive({
        schema = 'spaces',
        name = 'my_directive',
        description = 'Test directive',
        args = {
            nickname = types.string,
        },
        onField = true,
    })

    types.remove_all('spaces')

    t.assert_items_equals(types.list_types('spaces'), {})
    t.assert_items_equals(types.directives_list('spaces'), {})

    space:drop()
end

g.test_add_remove_space_object = function ()
    local err = select(3, types.add_space_object({
        name = 'entity',
        description = 'Entity object',
        space = 'entity',
    }))
    t.assert_equals(err.err, "space 'entity' doesn't exists")

    local space = helper.create_space()

    types.add_space_object({
        name = 'entity',
        description = 'Entity object',
        space = 'entity',
    })

    t.assert_equals(type(types()['entity']), 'table')
    t.assert_equals(types()['entity'].description, 'Entity object')
    t.assert_items_include(types.list_types(), {'entity'})
    t.assert_equals(schemas.is_invalid(), true)
    schemas.reset_invalid()
    t.assert_equals(schemas.is_invalid(), false)
    t.assert_items_include(types.list_types(), {'entity'})
    types.remove('entity')
    t.assert_equals(schemas.is_invalid(), true)
    schemas.reset_invalid()
    t.assert_equals(schemas.is_invalid(), false)
    t.assert_equals(types['entity'], nil)
    space:drop()

    space = helper.create_space()

    types.add_space_object({
        name = 'entity',
        description = 'Entity object',
        space = 'entity',
        fields = {
            bucket_id = box.NULL,
            instance_alias = types.string,
        }
    })

    t.assert_items_include(types.list_types(), {'entity'})

    t.assert_equals(type(types()['entity'].fields.entity), 'table')
    t.assert_equals(type(types()['entity'].fields.instance_alias), 'table')
    t.assert_equals(type(types()['entity'].fields.entity_id), 'table')
    t.assert_equals(types()['entity'].fields.bucket_id, nil)

    types.remove('entity')
    space:drop()
end

g.test_add_remove_space_input_object = function ()
    local err = select(3, types.add_space_input_object({
        name = 'input_entity',
        description = 'entity input object',
        space = 'entity',
    }))
    t.assert_equals(err.err, "space 'entity' doesn't exists")

    local space = helper.create_space()

    types.add_space_input_object({
        name = 'input_entity',
        description = 'Entity input object',
        space = 'entity',
    })

    t.assert_equals(type(types()['input_entity']), 'table')
    t.assert_equals(types()['input_entity'].description, 'Entity input object')
    t.assert_items_include(types.list_types(), {'input_entity'})
    t.assert_equals(schemas.is_invalid(), true)
    schemas.reset_invalid()
    t.assert_equals(schemas.is_invalid(), false)
    t.assert_items_include(types.list_types(), {'input_entity'})
    types.remove('input_entity')
    t.assert_equals(schemas.is_invalid(), true)
    schemas.reset_invalid()
    t.assert_equals(schemas.is_invalid(), false)
    t.assert_equals(types['input_entity'], nil)
    space:drop()

    space = helper.create_space()
    types.add_space_input_object({
        name = 'entity',
        description = 'Entity object',
        space = 'entity',
        fields = {
            bucket_id = box.NULL,
            instance_alias = types.string,
        }
    })

    t.assert_items_include(types.list_types(), {'entity'})

    t.assert_equals(type(types()['entity'].fields.entity), 'table')
    t.assert_equals(type(types()['entity'].fields.instance_alias), 'table')
    t.assert_equals(type(types()['entity'].fields.entity_id), 'table')
    t.assert_equals(types()['entity'].fields.bucket_id, nil)

    types.remove('entity')
    space:drop()
end

g.test_remove_types_by_space_name = function()
    local space = helper.create_space()

    types.add_space_object({
        name = 'entity',
        description = 'Entity object',
        space = 'entity',
    })
    t.assert_items_include(types.list_types(), {'entity'})
    t.assert_equals(schemas.is_invalid(), true)
    schemas.reset_invalid()
    t.assert_equals(schemas.is_invalid(), false)

    types.add_space_input_object({
        name = 'input_entity',
        description = 'Entity input object',
        space = 'entity',
    })

    t.assert_equals(type(types()['input_entity']), 'table')
    t.assert_equals(schemas.is_invalid(), true)
    schemas.reset_invalid()
    t.assert_equals(schemas.is_invalid(), false)

    types.remove_types_by_space_name('entity')
    t.assert_equals(types()['entity'], nil)
    t.assert_equals(types()['input_entity'], nil)
    t.assert_equals(schemas.is_invalid(), true)
    schemas.reset_invalid()
    t.assert_equals(schemas.is_invalid(), false)
    space:drop()
end

g.test_get_non_leaf_types = function()
    local custom_scalar = types.scalar({
        name = 'CustomInt',
        description = "The `CustomInt` scalar type represents non-fractional signed whole numeric values. " ..
                      "Int can represent values from -(2^31) to 2^31 - 1, inclusive.",
        serialize = function(value)
            return value
        end,
        parseLiteral = function(node)
            return node.value
        end,
        isValueOfTheType = function(_)
            return true
        end,
    })

    local dogCommand = types.enum({
        name = 'DogCommand',
        values = {
            SIT = true,
            DOWN = true,
            HEEL = true,
        }
    })
    t.assert_items_equals(types.get_non_leaf_types(dogCommand), {})

    local pet = types.interface({
        name = 'Pet',
        fields = {
            name = types.string.nonNull,
            nickname = custom_scalar,
            command = dogCommand,
        }
    })

    t.assert_items_equals(types.get_non_leaf_types(pet), {'DogCommand', 'CustomInt'})

    local dog = types.object({
        name = 'Dog',
        interfaces = { pet = pet },
        arguments = { command = dogCommand },
        fields = {
            name = types.string,
            nickname = types.string,
            barkVolume = types.int,
            doesKnowCommand = {
                kind = types.boolean.nonNull,
                arguments = {
                    dogCommand = dogCommand.nonNull,
                },
                interfaces = { pet = pet },
            },
            isHouseTrained = {
                kind = types.boolean.nonNull,
                arguments = {
                    atOtherHomes = types.boolean,
                }
            },
            complicatedField = {
                kind = types.boolean,
                interfaces = { pet = pet },
                arguments = {
                    complicatedArgument = types.inputObject({
                        name = 'complicated',
                        fields = {
                            x = types.string,
                            y = types.integer,
                            z = types.inputObject({
                                name = 'alsoComplicated',
                                fields = {
                                    x = types.string,
                                    y = types.double,
                                },
                                arguments = {
                                    dogCommand = dogCommand.nonNull,
                                },
                            })
                        },
                        interfaces = { pet = pet, },
                    })
                }
            }
        }
    })

    t.assert_items_equals(types.get_non_leaf_types(dog),
    {
        'Pet',
        'DogCommand',
        'complicated',
        'alsoComplicated',
        'CustomInt',
    })

    local alien = types.object({
        name = 'Alien',
        -- interfaces = { sentient },
        fields = {
            name = types.string.nonNull,
            homePlanet = types.string,
        }
    })

    local human = types.object({
        name = 'Human',
        fields = {
            name = types.string.nonNull,
        }
    })

    local cat = types.object({
        name = 'Cat',
        fields = {
            name = types.string.nonNull,
            nickname = types.string,
            meowVolume = types.int,
        }
    })

    local catOrDog = types.union({
        name = 'CatOrDog',
        types = { cat, dog, }
    })

    local dogOrHuman = types.union({
        name = 'DogOrHuman',
        types = { dog, human, }
    })

    local humanOrAlien = types.union({
        name = 'HumanOrAlien',
        types = { human, alien, }
    })

    local query = types.object({
        name = 'Query',
        fields = {
            dog = {
                kind = dog,
                args = {
                    name = {
                        kind = types.string,
                    }
                }
            },
            cat = cat,
            pet = pet,
            catOrDog = catOrDog,
            humanOrAlien = humanOrAlien,
            dogOrHuman = dogOrHuman,
        }
    })

    t.assert_items_equals(types.get_non_leaf_types(query),{
        'DogOrHuman',
        'Pet',
        'CatOrDog',
        'Dog',
        'DogCommand',
        'complicated',
        'alsoComplicated',
        'Cat',
        'HumanOrAlien',
        'Human',
        'Alien',
        'CustomInt',
    })

    operations.add_queries_prefix({
        prefix = 'test_prefix',
    })

    operations.add_query({
        name = 'test_query',
        prefix = 'test_prefix',
        args = {
            query = query,
        },
        interfaces = {
            pet = pet,
        },
        kind = types.string,
        callback = 'self.callback',
    })

    local query_types = types.get_non_leaf_types(operations.get_queries())

    t.assert_items_equals(query_types,{
        'API_test_prefix',
        'Query',
        'DogOrHuman',
        'CatOrDog',
        'Dog',
        'complicated',
        'alsoComplicated',
        'Pet',
        'DogCommand',
        'CustomInt',
        'Cat',
        'HumanOrAlien',
        'Human',
        'Alien',
    })

    query_types = types.get_non_leaf_types(operations.get_queries()['test_prefix'])

    t.assert_items_equals(query_types,{
        'Query',
        'DogOrHuman',
        'CatOrDog',
        'Dog',
        'complicated',
        'alsoComplicated',
        'Pet',
        'DogCommand',
        'CustomInt',
        'Cat',
        'HumanOrAlien',
        'Human',
        'Alien',
    })

    query_types = types.get_non_leaf_types(operations.get_queries()['test_prefix'].kind.fields['test_query'])


    t.assert_items_equals(query_types,{
        'Query',
        'DogOrHuman',
        'CatOrDog',
        'Dog',
        'complicated',
        'alsoComplicated',
        'Pet',
        'DogCommand',
        'CustomInt',
        'Cat',
        'HumanOrAlien',
        'Human',
        'Alien',
    })

    operations.add_mutations_prefix({
        prefix = 'test_prefix',
    })

    operations.add_mutation({
        name = 'test_mutation',
        prefix = 'test_prefix',
        args = {
            query = query,
        },
        kind = types.string,
        callback = 'self.callback',
    })

    local mutation_types = types.get_non_leaf_types(operations.get_mutations())

    t.assert_items_equals(mutation_types,{
        'MUTATION_API_test_prefix',
        'Query',
        'DogOrHuman',
        'CatOrDog',
        'Dog',
        'complicated',
        'alsoComplicated',
        'Pet',
        'DogCommand',
        'CustomInt',
        'Cat',
        'HumanOrAlien',
        'Human',
        'Alien',
    })

    mutation_types = types.get_non_leaf_types(operations.get_mutations()['test_prefix'])

    t.assert_items_equals(mutation_types,{
        'Query',
        'DogOrHuman',
        'CatOrDog',
        'Dog',
        'complicated',
        'alsoComplicated',
        'Pet',
        'DogCommand',
        'CustomInt',
        'Cat',
        'HumanOrAlien',
        'Human',
        'Alien',
    })

    mutation_types = types.get_non_leaf_types(operations.get_mutations()['test_prefix'].kind.fields['test_mutation'])

    t.assert_items_equals(mutation_types,{
        'Query',
        'DogOrHuman',
        'CatOrDog',
        'Dog',
        'complicated',
        'alsoComplicated',
        'Pet',
        'DogCommand',
        'CustomInt',
        'Cat',
        'HumanOrAlien',
        'Human',
        'Alien',
    })

    operations.remove_all()

    local temp = defaults.REMOVE_RECURSIVE_MAX_DEPTH
    defaults.REMOVE_RECURSIVE_MAX_DEPTH = 1

    t.assert_equals(defaults.REMOVE_RECURSIVE_MAX_DEPTH, 2)

    t.assert_items_equals(types.get_non_leaf_types(query),{
        'DogOrHuman',
        'CatOrDog',
        'Dog',
        'complicated',
        'Pet',
        'Cat',
        'HumanOrAlien',
    })

    defaults.REMOVE_RECURSIVE_MAX_DEPTH = temp
end

g.test_remove_recursive = function()
    local dogCommand = types.enum({
        name = 'DogCommand',
        values = {
            SIT = true,
            DOWN = true,
            HEEL = true,
        }
    })

    local pet = types.interface({
        name = 'Pet',
        fields = {
            name = types.string.nonNull,
            command = dogCommand,
        }
    })

    types.object({
        name = 'Dog',
        interfaces = { pet },
        arguments = { dogCommand },
        fields = {
            name = types.string,
            nickname = types.string,
            barkVolume = types.int,
            doesKnowCommand = {
                kind = types.boolean.nonNull,
                arguments = {
                    dogCommand = dogCommand.nonNull,
                }
            },
            isHouseTrained = {
                kind = types.boolean.nonNull,
                arguments = {
                    atOtherHomes = types.boolean,
                }
            },
            complicatedField = {
                kind = types.boolean,
                interfaces = {pet},
                arguments = {
                    complicatedArgument = types.inputObject({
                        name = 'complicated',
                        fields = {
                            x = types.string,
                            y = types.integer,
                            z = types.inputObject({
                                name = 'alsoComplicated',
                                fields = {
                                    x = types.string,
                                    y = types.double,
                                }
                            })
                        },
                        interfaces = {pet},
                    })
                }
            }
        }
    })

    t.assert_items_equals(types.list_types(), { 'DogCommand', 'Pet', 'complicated', 'Dog', 'alsoComplicated', })
    t.assert_items_equals(types.remove_recursive('DogCommand'), { 'DogCommand', 'Pet', 'Dog', })
    t.assert_items_equals(types.list_types(), { 'complicated', 'alsoComplicated', })
end

g.test_directives = function()
    local directive = {
        name = 'my_directive',
        description = 'Test directive',
        args = {
            nickname = types.string,
        },
        onQuery = true,
        onMutation = true,
        onField = true,
        onFragmentDefinition = true,
        onFragmentSpread = true,
        onInlineFragment = true,
        onVariableDefinition = true,
        onSchema = true,
        onScalar = true,
        onObject = true,
        onFieldDefinition = true,
        onArgumentDefinition = true,
        onInterface = true,
        onUnion = true,
        onEnum = true,
        onEnumValue = true,
        onInputObject = true,
        onInputFieldDefinition = true,
        isRepeatable = true,
    }

    types.add_directive(directive)

    t.assert_equals(types.is_directive_exists('my_directive'), true)

    local ok, err = pcall(function()
        types.add_directive(directive)
    end)

    t.assert_equals(ok, false)
    t.assert_str_contains(err, 'directive "my_directive" already exists in schema: "Default"')

    t.assert_equals(types.get_directives()['my_directive'].__type, "Directive")

    types.remove_directive('my_directive')
end
