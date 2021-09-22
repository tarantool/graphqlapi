# Submodule **fragments** Lua API

- [Submodule **fragments** Lua API](#submodule-fragments-lua-api)
  - [GraphQL API fragment structure](#graphql-api-fragment-structure)
  - [Lua API](#lua-api)
    - [init()](#init)
    - [stop()](#stop)
    - [update_space_fragments()](#update_space_fragments)
    - [apply_fragment()](#apply_fragment)
    - [load_fragment()](#load_fragment)
    - [remove_fragment()](#remove_fragment)
    - [remove_fragment_by_space_name()](#remove_fragment_by_space_name)
    - [remove_all()](#remove_all)
    - [list_fragments()](#list_fragments)
    - [list_loaded()](#list_loaded)

Submodule `fragments.lua` is a part of GraphQL API module that is used to load, remove and manipulate custom user GraphQL fragments. GraphQL fragments for this module must be written using GraphQLAPI module API and placed to project's subdirectory.

## GraphQL API fragment structure

Each fragment must be a valid *.lua which returns a table of the following structure:

```lua
    return {
        -- main fragment function
        fragment = function()
            ...
        end,
        -- list of spaces names
        spaces = {}, 
        ...
        func_1 = function() end,
        func_n = function() end,
        ...
    }
```

where:

- `fragment` (`function`) - mandatory, main function of GraphQL API fragment that can perform all needed operations to add GraphQL types or/and queries or/and mutations or/and directives;

- `spaces` (`table`) - optional, array of strings with spaces names this particular fragment associated with.

Fragment function (`fragment.fragment()`) must be idempotent because it will be called on every space changes:

- any space format changes;
- any space indexes changes.

It's highly recommended not to use fiber.yield() inside fragment() function because it can lead to undefined behavior.

GraphQL API fragment may require any available module including module placed in the same directory tree as fragments itself.

If any lua-file in fragments dir tree doesn't return fragment function - it will not be loaded as GraphQL API fragment.

## Lua API

### init()

`fragments.init(dir_name)` - function to init `fragments` module including loading and apply custom GraphQL fragments provided by application,

where:

`dir_name` (`string`) - optional, GraphQL API fragments dir path. Base path - is the path to root dir of the application, but absolute path is also possible.

This function is used by internal routines and performs the following actions:

- validate and load all fragments (*.lua) from `dir_name` including all subdirectories;
- save all fragments and provided settings to internal module variables;
- apply fragments that was successfully validated and loaded in previous steps;
- save list of required modules.

### stop()

`fragments.stop()` - function to deinit `fragments` module, it removes all fragments and cleanup all internal module variables including unload all modules that was required by all fragments functions. This behavior is needed to make possible hot-reload of all fragments.

### update_space_fragments()

`fragments.update_space_fragments(space_name)` - function to reload fragments related to provided `space_name`,

where:

`space_name` (`string`) - mandatory, space_name related fragments that have to be reloaded.

This function is usually called when space with `space_name` is changed. It makes full reload of all loaded fragments that includes space_name in spaces parameter.

### apply_fragment()

`fragments.apply_fragment(fragment)` - function to apply fragment,

where:

- `fragment` (`table`) - mandatory, GraphQL API fragment.

returns:

- `result` (`boolean`) - true if success, false if not

- `error` (`error`) - if apply fragment fails second return value will contain an error object. 

### load_fragment()

`fragments.load_fragment(filename)` - function to load GraphQL API fragment from file,

where:

- `filename` (`string`) - mandatory, path to GraphQL API fragment file. Base path - is the path to root dir of the application, but absolute path is also possible.

Function `load_fragment()` performs the following actions:

- validate and load fragment's lua-file;
- save fragment to internal modules cache if valid;
- save list of modules required by fragment.

### remove_fragment()

`fragments.remove_fragment(filename)` - function is used to remove GraphQL API fragment from fragments internal cache,

where:

- `filename` (`string`) - mandatory, path to GraphQL API fragment file.

Note: internal fragment cache is indexed by GraphQL API fragment filenames.

### remove_fragment_by_space_name()

`fragments.remove_fragment_by_space_name(space_name)` - function is used to remove all GraphQL API fragment(s) from fragments internal cache by spaces names,

where:

`space_name` (`string`) - mandatory, space_name related fragments that have to be reloaded.

Function `remove_fragment_by_space_name()` is called when space is removed.

### remove_all()

`fragments.remove_all()` - function to remove all GraphQL API fragments from fragments internal cache.

### list_fragments()

`fragments.list_fragments()` - function is used to get array of path's of loaded fragments,

returns:

- `fragments` (`table`) - array of loaded fragments paths. Each fragment is represented by fragment lua-file path divided by dot instead of "/".

### list_loaded()

`fragments.list_loaded()` - function is used to get array of loaded fragments,

returns:

- `fragments` (`table`) - array of loaded fragments ([GraphQL API fragment structure](#graphql-api-fragment-structure)).
