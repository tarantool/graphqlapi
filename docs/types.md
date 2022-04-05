# Submodule **types** methods

- [Submodule **types** methods](#submodule-types-methods)
  - [GraphQL types](#graphql-types)
    - [Field](#field)
    - [Int](#int)
    - [Long](#long)
    - [Boolean](#boolean)
    - [Float](#float)
    - [ID](#id)
    - [String](#string)
    - [nullable](#nullable)
    - [scalar()](#scalar)
    - [enum()](#enum)
    - [nonNull()](#nonnull)
    - [list()](#list)
    - [object()](#object)
    - [inputObject()](#inputobject)
    - [interface()](#interface)
    - [union()](#union)
    - [any](#any)
    - [map](#map)
    - [mapper](#mapper)
  - [Directives](#directives)
    - [directive()](#directive)
    - [include](#include)
    - [skip](#skip)
    - [specifiedBy](#specifiedby)
    - [add_directive()](#add_directive)
    - [get_directives()](#get_directives)
    - [is_directive_exists()](#is_directive_exists)
    - [directives_list()](#directives_list)
    - [remove_directive()](#remove_directive)
  - [Lua API](#lua-api)
    - [remove()](#remove)
    - [remove_recursive()](#remove_recursive)
    - [remove_types_by_space_name()](#remove_types_by_space_name)
    - [remove_all()](#remove_all)
    - [add_space_object()](#add_space_object)
    - [add_space_input_object()](#add_space_input_object)
    - [types_list()](#types_list)
    - [get_non_leaf_types()](#get_non_leaf_types)
    - [types()](#types)
    - [space_fields()](#space_fields)

Submodule `types.lua` - is a part of GraphQL API module which provides a set of functions to add/remove GraphQL various types. Submodule is an extension of [Tarantool GraphQL module type system](https://github.com/tarantool/graphql).

## GraphQL types

GraphQL for Tarantool module provides a base set of GraphQL types to be described in this paragraph. For more detailed information refer to:

[Lua implementation of GraphQL for Tarantool](https://github.com/tarantool/graphql)
[GraphQL specification](https://spec.graphql.org/draft/)

### Field

Most GraphQL types has fields that describes one discrete piece of information available to request within a selection set or represent an input data. Every field may have the following structure:

- `kind` (`table`) - any GraphQL type presents in GraphQL schema,

or

- `field` (`table`) - mandatory, field name key where value has the following parameters:
  - `kind` (`table`) - any GraphQL type presents in GraphQL schema;
  - `description` (`string`) - optional, any arbitrary text that describes field;
  - `deprecationReason` (`string`) - optional, any arbitrary text that describes field deprecation reason;
  - `arguments` (`table`) - optional, list of GraphQL directives;
  - `resolve` (`function`) - optional, resolve function.

Examples:

```lua
    types.object({
        name = 'Entity',
        description = 'Entity object',
        fields = {
            entity_new = types.string.nonNull,
            entity = {
                kind = types.string.nonNull,
                description = 'Old entity representation',
                deprecationReason = 'Deprecated in favor of entity_new',
                arguments = { types.include },
            }
        }
    })
```

### Int

`types.int` - GraphQL standard integer type, for more info refer to [Int](http://spec.graphql.org/draft/#sec-Int).

### Long

`types.long` - custom scalar type that represents non-fractional signed whole numeric values. It can represent values from -(2^52) to 2^52 - 1, inclusive.

### Boolean

`types.boolean` - GraphQL standard boolean scalar type represents `true` or `false`, for more info refer to [Boolean](http://spec.graphql.org/draft/#sec-Boolean).

### Float

`types.float` - GraphQL standard float scalar type represents signed double-precision finite values as specified by [IEEE 754](https://en.wikipedia.org/wiki/IEEE_floating_point), for more info refer to [Float](http://spec.graphql.org/draft/#sec-Float).

### ID

`types.id` - GraphQL standard id scalar, for more info refer to [ID](http://spec.graphql.org/draft/#sec-ID).

### String

`types.string` - GraphQL standard string scalar, for more info refer to [String](http://spec.graphql.org/draft/#sec-String).

### nullable

`types.nullable` - wrapper to make any other scalar or complex type nullable.

### scalar()

Scalar types represent primitive leaf values in a GraphQL type system. GraphQL responses take the form of a hierarchical tree; the leaves of this tree are typically GraphQL Scalar types (but may also be Enum types or null values).

`types.scalar(opts)` - method is used to create a custom instance of GraphQL scalar type,

where:

- `opts` (`table`) - mandatory, GraphQL scalar type with the following parameters:
  - `name` (`string`) - mandatory, name of created GraphQL scalar type;
  - `description` (`string`) - optional, any arbitrary text that describes created GraphQL scalar type;
  - `serialize` (`function`) - mandatory, function that takes as input string representation of scalar and coerce it to desired lua type;
  - `parseValue` (`function`) - optional, function that takes as input string representation of scalar and coerce it to desired lua type;
  - `parseLiteral` (`function`) - mandatory, function that takes as input a node of GraphQL tree representation, extracts nodes value and returns coerced to desired lua type;  
  - `isValueOfTheType` (`function`) - mandatory, function that takes lua variable and checks it's type. If type is OK it returns true, if not - false.

returns:

- `[1]` (`table`) - GraphQL scalar type map, which has the following structure:
  - `__type` (`string`) - equals to string constant: "Scalar";
  - `name` (`string`) - scalar name;
  - `description` (`string`) - description;
  - `serialize` (`function`) - serialize function;
  - `parseValue` (`function`) - parseValue function;
  - `parseLiteral` (`function`) - parseLiteral function;
  - `isValueOfTheType` (`function`) - isValueOfTheType function.

Example:

```lua
    local double = types.scalar({
        name = 'Double',
        serialize = tonumber,
        parseValue = tonumber,
        parseLiteral = function(node)
          -- 'float' and 'int' are names of immediate value types
          if node.kind == 'float' or node.kind == 'int' then
            return tonumber(node.value)
          end
        end,
        isValueOfTheType = function(value)
          return type(value) == 'number'
        end,
    })
```

### enum()

GraphQL Enum types, like Scalar types, also represent leaf values in a GraphQL type system. However Enum types describe the set of possible values, for more info refer to [Enum](http://spec.graphql.org/draft/#sec-Enums).

`types.enum(opts)` - method is used to create a custom GraphQL enum type,

where:

- `opts` (`table`) - mandatory, GraphQL enum type with the following parameters:
  - `name` (`string`) - mandatory, name of created GraphQL enum type;
  - `description` (`string`) - optional, any arbitrary text that describes created GraphQL enum type;
  - `values` (`table`) - mandatory, set of possible values.

returns:

- `[1]` (`table`) - GraphQL enum type map, with the following structure:
  - `__type` (`string`) - equals to string constant: "Enum";
  - `name` (`string`) - enum name;
  - `description` (`string`) - description;
  - `values` (`table`) - values;
  - `serialize` (`function`) - serialize.

Example:

```lua
    local index_type = types.enum({
        name = 'SpaceIndexType',
        description = 'Space index type',
        values = {
            tree = 'TREE',
            hash = 'HASH',
            bitset = 'BITSET',
            rtree = 'RTREE',
        }
    })
```

this will create a new enum:

```graphql
    """Space index type"""
    enum SpaceIndexType {
        tree
        hash
        bitset
        rtree
    }
```

### nonNull()

By default, all types in GraphQL are nullable; the null value is a valid response for all Scalars, Objects, Interfaces, Unions and Enums types. To declare a type that disallows null, the GraphQL Non-Null type can be used. This type wraps an underlying type, and this type acts identically to that wrapped type, with the exception that null is not a valid response for the wrapping type.

`nonNull(kind)` - method to wrap any GraphQL type to disallow it's nullability,

where:

- `kind` (`any`) - mandatory, any type but can't be nil.

returns:

- `[1]` (`table`) - GraphQL nonNull type map, which has the following structure:
  - `__type` (`string`) - equals to string constant: NonNull";
  - `ofType` (`table`) - kind - any valid GraphQL type.

Example:

```lua
    types.object({
        name = 'Entity',
        description = 'Entity object',
        fields = {
            entity = types.nonNull(types.string), -- also can be used shorten syntax: types.string.nonNull
        }
    })
```

this will create an GraphQL object with the following structure:

```graphql
    """Entity object"""
    type entity {
        entity: String!
    }
```

### list()

A GraphQL list is a special collection type which declares the type of each item in the List, for more info refer to [List](http://spec.graphql.org/draft/#sec-List).

`types.list(kind)` - method to create GraphQL list structure,

where:

- `kind` (`string|table`) - mandatory, GraphQL type.

returns:

- `[1]` (`table`) - GraphQL list type map, which has the following structure:
  - `__type` (`string`) - equals to string constant: "List";
  - `ofType` (`table`) - kind - any valid GraphQL type.

Example:

```lua
    local entity_list = types.list(types.object({
        name = 'Entity',
        description = 'Entity object',
        fields = {
            entity = types.string.nonNull,
        }
    })
```

### object()

GraphQL Objects represent a list of named fields, each of which yield a value of a specific type, for more info refer to [Object](http://spec.graphql.org/draft/#sec-Objects).

`types.object(opts)` - method to create GraphQL object structure,

where:

- `opts` (`table`) - mandatory, GraphQL object type with the following parameters:
  - `name` (`string`) - mandatory, name of created GraphQL object type;
  - `description` (`string`) - optional, any arbitrary text that describes created GraphQL object type;
  - `fields` (`table|function`) - mandatory, single GraphQL type or map of fields where keys are GraphQL types or function that returns GraphQL type map;
  - `interfaces` (`table`) - optional, map of GraphQL interfaces.

returns:

- `[1]` (`table`) - GraphQL object type map, which has the following structure:
  - `__type` (`string`) - equals to string constant: "Object";
  - `name` (`string`) - object name;
  - `description` (`string`) - description;
  - `isTypeOf` (`function`) - isTypeOf;
  - `fields` (`table`) - fields [Field](#field);
  - `interfaces` (`table`) - interfaces.

Example:

```lua
    local object = types.object({
        name = 'SpaceField',
        description = 'Space field',
        fields = {
            name = types.string,
            type = types.SpaceFieldType,
            is_nullable = types.boolean,
        }
    })
```

### inputObject()

A GraphQL Input Object defines a set of input fields; the input fields are either scalars, enums, or other input objects, for more info refer to [inputObject](http://spec.graphql.org/draft/#sec-Input-Objects).

`types.inputObject(opts)` - method to create GraphQL input object structure,

where:

- `opts` (`table`) - mandatory, GraphQL input object type with the following parameters:
  - `name` (`string`) - mandatory, name of created GraphQL input object type;
  - `description` (`string`) - optional, any arbitrary text that describes created GraphQL input object type;
  - `fields` (`table`) - mandatory, single GraphQL type or map of fields where keys are GraphQL type.

returns:

- `[1]` (`table`) - GraphQL input object type map, which has the following structure:
  - `__type` (`string`) - equals to string constant: "InputObject";
  - `name` (`string`) - input object name;
  - `description` (`string`) - description;
  - `fields` (`table`) - fields [Field](#field).

### interface()

GraphQL interfaces represent a list of named fields and their arguments. GraphQL objects and interfaces can then implement these interfaces which requires that the implementing type will define all fields defined by those interfaces, for more info refer to [Interface](http://spec.graphql.org/draft/#sec-Interfaces).

`types.interface(opts)` - method to create GraphQL interface structure,

where:

- `opts` (`table`) - mandatory, GraphQL interface type with the following parameters:
  - `name` (`string`) - mandatory, name of created GraphQL interface type;
  - `description` (`string`) - optional, any arbitrary text that describes created GraphQL interface type;
  - `fields` (`table`) - mandatory, single GraphQL type or map of fields where keys are GraphQL type;
  - `resolveType` - optional, resolve function.

returns:

- `[1]` (`table`) - GraphQL interface type map, which has the following structure:
  - `__type` (`string`) - equals to string constant: "Interface";
  - `name` (`string`) - interface name;
  - `description` (`string`) - description;
  - `fields` (`table`) - fields [Field](#field);
  - `resolveType` (`function`) - resolveType.

### union()

GraphQL Unions represent an object that could be one of a list of GraphQL Object types, but provides for no guaranteed fields between those types, for more info refer to [Union](http://spec.graphql.org/draft/#sec-Unions).

`types.union(opts)` - method to create GraphQL union structure,

where:

- `opts` (`table`) - mandatory, GraphQL interface type with the following parameters:
  - `name` (`string`) - mandatory, name of created GraphQL interface type;
  - `types` (`table`) - mandatory, list of GraphQL types;

returns:

- `[1]` (`table`) - GraphQL union type map, which has the following structure:
  - `__type` (`string`) - equals to string constant: "Union";
  - `name` (`string`) - union name;
  - `types` (`table`) - list of any valid GraphQL types.

### any

`types.any` - custom GraphQL scalar type represents any of the following scalars:

- [Boolean](#boolean) ;
- [Double](#double);
- [Float](#float);
- [Int](#int);
- [Long](#long);
- Null;
- [String](#string);
- [ID](#id).

### map

`types.map` - custom GraphQL scalar type represents a map.

### mapper

`types.mapper` - static map with predefined lua types mapping to GraphQL types:

```lua
    types.mapper = {
        ['any'] = { ['type'] = types.any, name = 'Any', },
        ['array'] = { ['type'] = types.list(types.any), name = 'List', },
        ['boolean'] = { ['type'] = types.boolean, name = 'Boolean', },
        ['decimal'] = { ['type'] = types.long, name = 'Long', },
        ['double'] = { ['type'] = types.float, name = 'Float', },
        ['integer'] = { ['type'] = types.long, name = 'Long', },
        ['map'] = { ['type'] = types.map, name = 'Map', },
        ['number'] = { ['type'] = types.float, name = 'Float', },
        ['scalar'] = { ['type'] = types.any, name = 'Any', },
        ['string'] = { ['type'] = types.string, name = 'String', },
        ['unsigned'] = { ['type'] = types.long, name = 'Long',},
        ['uuid'] = { ['type'] = types.id, name = 'ID', },
    }
```

## Directives

### directive()

A GraphQL schema describes directives which are used to annotate various parts of a GraphQL document as an indicator that they should be evaluated differently by a validator, executor, for more info refer to [Directives](http://spec.graphql.org/draft/#sec-Validation.Directives).

`types.directive(opts)` - method to create GraphQL directive structure,

where:

- `opts` (`table`) - mandatory, GraphQL directive type with the following parameters:
  - `name` (`string`) - mandatory, name of created GraphQL directive type;
  - `description` (`string`) - optional, any arbitrary text that describes created GraphQL directive type;
  - `args` (`table`) - optional, list of GraphQL types;
  - `onQuery` (`boolean`) - optional, flag to indicate that directive is applicable to queries;
  - `onMutation` (`boolean`) - optional, flag to indicate that directive is applicable to mutations;
  - `onField` (`boolean`) - optional, flag to indicate that directive is applicable to fields;
  - `onFragmentDefinition` (`boolean`) - optional, flag to indicate that directive is applicable to fragment definitions;
  - `onFragmentSpread` (`boolean`) - optional, flag to indicate that directive is applicable to fragment spreads;
  - `onInlineFragment` (`boolean`) - optional, flag to indicate that directive is applicable to inline fragments;
  - `onVariableDefinition` (`boolean`) - optional, flag to indicate that directive is applicable to variable definition;
  - `onSchema` (`boolean`) - optional, flag to indicate that directive is applicable to schema root;
  - `onScalar` (`boolean`) - optional, flag to indicate that directive is applicable to scalar;
  - `onObject` (`boolean`) - optional, flag to indicate that directive is applicable to object;
  - `onFieldDefinition` (`boolean`) - optional, flag to indicate that directive is applicable to filed definition;
  - `onArgumentDefinition` (`boolean`) - optional, flag to indicate that directive is applicable to argument definition;
  - `onInterface` (`boolean`) - optional, flag to indicate that directive is applicable to interface;
  - `onUnion` (`boolean`) - optional, flag to indicate that directive is applicable to union;
  - `onEnum` (`boolean`) - optional, flag to indicate that directive is applicable to enum;
  - `onEnumValue` (`boolean`) - optional, flag to indicate that directive is applicable to enum value;
  - `onInputObject` (`boolean`) - optional, flag to indicate that directive is applicable to input object;
  - `onInputFieldDefinition` (`boolean`) - optional, flag to indicate that directive is applicable to input field definition;
  - `isRepeatable` (`boolean`) - optional, flag to indicate that directive may be used repeatedly at a single location.

returns:

- `[1]` (`table`) - GraphQL directive type map, which has the following structure:
  - `__type` (`string`) - equals to string constant: "Directive";
  - `name` (`string`) - directive name;
  - `description` (`string`) - description;
  - `arguments` (`table`) - directive arguments;
  - `onQuery` (`boolean`) - onQuery flag;
  - `onMutation` (`boolean`) - onMutation flag;
  - `onField` (`boolean`) - onField flag;
  - `onFragmentDefinition` (`boolean`) - onFragmentDefinition flag;
  - `onFragmentSpread` (`boolean`) - onFragmentSpread flag;
  - `onInlineFragment` (`boolean`) - onInlineFragment flag;
  - `onVariableDefinition` (`boolean`) - onVariableDefinition flag;
  - `onSchema` (`boolean`) - onSchema flag;
  - `onScalar` (`boolean`) - onScalar flag;
  - `onObject` (`boolean`) - onObject flag;
  - `onFieldDefinition` (`boolean`) - onFieldDefinition flag;
  - `onArgumentDefinition` (`boolean`) - onArgumentDefinition flag;
  - `onInterface` (`boolean`) - onInterface flag;
  - `onUnion` (`boolean`) - onUnion flag;
  - `onEnum` (`boolean`) - onEnum flag; 
  - `onEnumValue` (`boolean`) - onEnumValue flag;
  - `onInputObject` (`boolean`) - onInputObject flag;
  - `onInputFieldDefinition` (`boolean`) - onInputFieldDefinition flag;
  - `isRepeatable` (`boolean`) - isRepeatable flag.

Example:

```lua
    local exclude = types.directive({
        name = 'exclude',
        description = 'Directs the executor to exclude this field or fragment only when the `if` argument is true.',
        arguments = {
            ['if'] = { kind = types.boolean.nonNull, description = 'Excluded when true.'}
        },
        onField = true,
        onFragmentSpread = true,
        onInlineFragment = true
    })
```

### include

`types.include` - GraphQL build-in directive may be provided for fields, fragment spreads, and inline fragments, and allows for conditional inclusion during execution as described by the `if` argument, for more info refer to [@include](http://spec.graphql.org/draft/#sec--include).

### skip

`types.skip` - GraphQL built-in directive may be provided for fields, fragment spreads, and inline fragments, and allows for conditional exclusion during execution as described by the `if` argument, for more info refer to [@skip](http://spec.graphql.org/draft/#sec--skip).

### specifiedBy

`types.specifiedBy` - GraphQL built-in directive is used within the type system definition language to provide a scalar specification URL for specifying the behavior of custom scalar types, for more info refer to [specifiedBy](http://spec.graphql.org/draft/#sec--specifiedBy).

### add_directive()

`types.add_directive(opts)` - method to add GraphQL directive to desired schema,

where:

- `opts` (`table`) - mandatory, directive options:
  - `schema` (`string`) - optional, schema name, if nil - then default schema is used [Default schema](defaults.md#default_schema_name);
  - `name` (`string`) - mandatory, name of created GraphQL directive type;
  - `description` (`string`) - optional, any arbitrary text that describes created GraphQL directive type;
  - `args` (`table`) - optional, list of GraphQL types;
  - `onQuery` (`boolean`) - optional, flag to indicate that directive is applicable to queries;
  - `onMutation` (`boolean`) - optional, flag to indicate that directive is applicable to mutations;
  - `onField` (`boolean`) - optional, flag to indicate that directive is applicable to fields;
  - `onFragmentDefinition` (`boolean`) - optional, flag to indicate that directive is applicable to fragment definitions;
  - `onFragmentSpread` (`boolean`) - optional, flag to indicate that directive is applicable to fragment spreads;
  - `onInlineFragment` (`boolean`) - optional, flag to indicate that directive is applicable to inline fragments;
  - `onVariableDefinition` (`boolean`) - optional, flag to indicate that directive is applicable to variable definition;
  - `onSchema` (`boolean`) - optional, flag to indicate that directive is applicable to schema root;
  - `onScalar` (`boolean`) - optional, flag to indicate that directive is applicable to scalar;
  - `onObject` (`boolean`) - optional, flag to indicate that directive is applicable to object;
  - `onFieldDefinition` (`boolean`) - optional, flag to indicate that directive is applicable to filed definition;
  - `onArgumentDefinition` (`boolean`) - optional, flag to indicate that directive is applicable to argument definition;
  - `onInterface` (`boolean`) - optional, flag to indicate that directive is applicable to interface;
  - `onUnion` (`boolean`) - optional, flag to indicate that directive is applicable to union;
  - `onEnum` (`boolean`) - optional, flag to indicate that directive is applicable to enum;
  - `onEnumValue` (`boolean`) - optional, flag to indicate that directive is applicable to enum value;
  - `onInputObject` (`boolean`) - optional, flag to indicate that directive is applicable to input object;
  - `onInputFieldDefinition` (`boolean`) - optional, flag to indicate that directive is applicable to input field definition;
  - `isRepeatable` (`boolean`) - optional, flag to indicate that directive may be used repeatedly at a single location.

returns:

`[1]` (`table`) - directive structure, for more info refer to [directive()](#directive)

### get_directives()

`types.get_directives(schema)` - method to get all registered directives for desired schema,

where:
  - `schema` (`string`) - optional, schema name, if nil - then default schema is used [Default schema](defaults.md#default_schema_name).

### is_directive_exists()

`types.is_directive_exists(name, schema)` - method to check if directive exists in the desired schema,

where:

- `name` (`string`) - mandatory, directive name;
- `schema` (`string`) - optional, schema name, if nil - then default schema is used [Default schema](defaults.md#default_schema_name).

### directives_list()

`types.directives_list(schema)` - method to get list of directives in the desired schema,

where:

- `schema` (`string`) - optional, schema name, if nil - then default schema is used [Default schema](defaults.md#default_schema_name).

### remove_directive()

`types.remove_directive(name, schema)` - method to remove directive from desired schema,

where:

- `name` (`string`) - mandatory, directive name;
- `schema` (`string`) - optional, schema name, if nil - then default schema is used [Default schema](defaults.md#default_schema_name).

## Lua API

### remove()

`types.remove(type_name, schema)` - method to remove any GraphQL type from GraphQL schema excluding internal types that can't be removed anyway,

where:

- `type_name` (`string`) - mandatory, GraphQL type name to be removed;
- `schema` (`string`) - optional, schema name, if nil - then default schema is used [Default schema](defaults.md#default_schema_name).

Example:

```lua
    types.remove('MyEntity')
```

### remove_recursive()

`types.remove_recursive(type_name, schema)` - method to remove any GraphQL type from GraphQL schema excluding internal types that can't be removed anyway and also remove all types and operations that using this type to avoid queries and mutations execution errors and keep schema consistent,

where:

- `type_name` (`string`) - mandatory, GraphQL type name to be removed;
- `schema` (`string`) - optional, schema name, if nil - then default schema is used [Default schema](defaults.md#default_schema_name).

Example:

```lua
    types.remove_recursive('MyEntity')
```

### remove_types_by_space_name()

`types.remove_types_by_space_name(space_name, schema)` - method is used to remove all objects and input objects related to provided space created by `types.add_space_object()` and `types.add_space_input_object()`,

where:

- `space_name` (`string`) - mandatory, name of the space;
- `schema` (`string`) - optional, schema name, if nil - then default schema is used [Default schema](defaults.md#default_schema_name).

Example:

```lua
    types.remove_types_by_space_name('entity')
```

### remove_all()

`types.remove_all(schema)` - method to remove all GraphQL schema types excluding internal types that can't be removed anyway,

where:

- `schema` (`string`) - optional, schema name, if box.NULL - then default schema is used [Default schema](defaults.md#default_schema_name) and if nil - then all types in all schemas will be removed.

### add_space_object()

`types.add_space_object(opts)` - helper function to create GraphQL object type with fieldset based on current space format. Function also allows to flexibly set additional fields or mask any space fields to comply your goals,

where:

- `opts` (`table`) - mandatory, description of GraphQL space object which has the following options:
  - `schema` (`string`) - optional, schema name, if box.NULL - then default schema is used [Default schema](defaults.md#default_schema_name) and if nil - then all types in all schemas will be removed;
  - `name` (`string`) - mandatory, name of created GraphQL object;
  - `description` (`string`) - optional, any arbitrary text that describes created space object;
  - `space` (`string`) - mandatory, space name created GraphQL space object will be based on;
  - `fields` (`table`) - optional, a map of fields need to be added, overridden or masked in created GraphQL space object;
  - `interfaces` (`table`) - optional, a map of interfaces.

Example:

If space has the following format:

```lua
    local format = {
        { name = 'bucket_id', type = 'unsigned', is_nullable = false },
        { name = 'entity_id', type = 'string', is_nullable = false },
        { name = 'entity', type = 'string', is_nullable = true },
    }
```

and need to add GraphQL object with corresponding structure to some schema:

```lua
    types.add_space_object({
        name = 'entity',
        description = 'Entity object',
        space = 'entity',
    })
```

this will create an GraphQL space object and also register a relation between space and created type with the following structure:

```graphql
    """Entity object"""
    type entity {
        bucket_id: Long!
        entity_id: String!
        entity: String
    }
```

If we want to mask some fields and add some custom one use the following tricks:

```lua
    types.add_space_object({
        name = 'entity',
        description = 'Entity object',
        space = 'entity',
        fields = {
            bucket_id = box.NULL,
            entity_id_hash = types.string,
        }
    })
```

this will create an GraphQL space object and also register a relation between space and created type with th following structure:

```graphql
    """Entity object"""
    type entity {
        entity_id: String!
        entity: String,
        entity_id_hash: String,
    }
```

### add_space_input_object()

`add_space_input_object(opts)` - method to create GraphQL input object type with fieldset based on current space format. Method also allows to flexibly set additional fields or mask any space fields to comply your goals,

where:

- `opts` (`table`) - mandatory, description of GraphQL space input object which has the following parameters:
  - `schema` (`string`) - optional, schema name, if box.NULL - then default schema is used [Default schema](defaults.md#default_schema_name) and if nil - then all types in all schemas will be removed;
  - `name` (`string`) - mandatory, name of created GraphQL input object;
  - `description` (`string`) - optional, any arbitrary text that describes created space input object;
  - `space` (`string`) - mandatory, space name created GraphQL space input object will be based on;
  - `fields` (`table`) - optional, a map of fields need to be added, overridden or masked in created GraphQL space input object.

Example:

If space has the following format:

```lua
    local format = {
        { name = 'bucket_id', type = 'unsigned', is_nullable = false },
        { name = 'entity_id', type = 'string', is_nullable = false },
        { name = 'entity', type = 'string', is_nullable = true },
    }
```

and need to add GraphQL object with corresponding structure to some schema:

```lua
    types.add_space_input_object({
        name = 'entity',
        description = 'Entity input object',
        space = 'entity',
    })
```

this will create an GraphQL space input object and also register a relation between space and created type with the following structure:

```graphql
    """Entity input object"""
    input entity {
        bucket_id: Long!
        entity_id: String!
        entity: String
    }
```

### types_list()

`types.types_list(schema)` - method to get a list of all types registered in the desired schema,

where:

- `schema` (`string`) - optional, schema name, if box.NULL - then default schema is used [Default schema](defaults.md#default_schema_name) and if nil - then all types in all schemas will be removed,

returns:

- `[1]` (`table`) - array with all registered type names.

### get_non_leaf_types()

`types.get_non_leaf_types(t)` - method to get list of all non-leaf types that is used in: query, mutation, prefix, type or any other valid GraphQL structure,

where:

`t` (`table`) - mandatory, query, mutation, prefix, type or any other valid GraphQL structure.

### types()

`types(schema)` - method to get all registered types for the desired schema,

where:

- `schema` (`string`) - optional, schema name, if box.NULL - then default schema is used [Default schema](defaults.md#default_schema_name) and if nil - then all types in all schemas will be removed,

returns:

- `[1]` (`table`) - map with all registered types in the desired schema.

### space_fields()

`types.space_fields(space, required)` - method to create [fields](#field) map based on current space format,

where:

- `space` (`string`) - mandatory, existed space name;
- `required` (`boolean`) - optional, if `true` - all fields with is_nullable ~= true in the resulting map will be nonNull, if `false` or `nil` - all fields will be nullable.
