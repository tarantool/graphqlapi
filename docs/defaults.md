# Submodule **defaults** Lua API

- [Submodule **defaults** Lua API](#submodule-defaults-lua-api)
  - [Defaults](#defaults)
    - [DEFAULT_FRAGMENTS_DIR](#default_fragments_dir)
    - [DEFAULT_ENDPOINT](#default_endpoint)
    - [DEFAULT_SCHEMA_NAME](#default_schema_name)
    - [CONFIG_UPDATE_CHANNEL_CAPACITY](#config_update_channel_capacity)
    - [SCHEMA_UPDATE_CHANNEL_CAPACITY](#schema_update_channel_capacity)
    - [CONFIG_UPDATE_CHANNEL_TIMEOUT](#config_update_channel_timeout)
    - [SCHEMA_UPDATE_CHANNEL_TIMEOUT](#schema_update_channel_timeout)
    - [QUERIES_PREFIX](#queries_prefix)
    - [MUTATIONS_PREFIX](#mutations_prefix)
    - [REMOVE_RECURSIVE_MAX_DEPTH](#remove_recursive_max_depth)
    - [DEFAULT_DESCRIPTION_KEY](#default_description_key)
    - [GRAPHQL_QUERY_CACHE_SIZE](#graphql_query_cache_size)

Submodule `defaults.lua` is a part of GraphQL API module provided a set of defaults.
## Defaults

### DEFAULT_FRAGMENTS_DIR

`DEFAULT_FRAGMENTS_DIR` (`string`) - default relative or absolute path to fragments. Relative path relative path is counted from App root dir. Default value: 'fragments'.

### DEFAULT_ENDPOINT

`DEFAULT_ENDPOINT` (`string`) - default relative URI of http-endpoint of GraphQL API. Default value: 'admin/graphql'.

### DEFAULT_SCHEMA_NAME

`DEFAULT_SCHEMA_NAME` (`string`) - default display name of default schema. Default value: 'Default'.

### CONFIG_UPDATE_CHANNEL_CAPACITY

`CONFIG_UPDATE_CHANNEL_CAPACITY` (`number`) - default channel capacity for change config messages. Default: 100.

### SCHEMA_UPDATE_CHANNEL_CAPACITY

`SCHEMA_UPDATE_CHANNEL_CAPACITY` (`number`) - default channel capacity for space change messages. Default: 100.

### CONFIG_UPDATE_CHANNEL_TIMEOUT

`CONFIG_UPDATE_CHANNEL_TIMEOUT` (`number`) - default change config messages processing timeout in seconds. Default: 10 s.

### SCHEMA_UPDATE_CHANNEL_TIMEOUT

`SCHEMA_UPDATE_CHANNEL_TIMEOUT` (`number`) - default change space messages processing timeout in seconds. Default: 10 s.

### QUERIES_PREFIX

`QUERIES_PREFIX` (`string`) - default prefix for queries schema prefix (group of queries). This prefix in order to distinguish prefix and queries. Default: 'API_'.

### MUTATIONS_PREFIX

`MUTATIONS_PREFIX` (`string`) - default prefix for mutations schema prefix (group of mutations). This prefix in order to distinguish prefix and mutations. Default: 'MUTATION_API_'.

### REMOVE_RECURSIVE_MAX_DEPTH

`REMOVE_RECURSIVE_MAX_DEPTH` (`number`) - default max depth of GraphQL schema recursive search. This limit is used in `types.get_non_leaf_types()` to prevent possible infinite cycles. Min value: 2. Default: 128.

### DEFAULT_DESCRIPTION_KEY

`DEFAULT_DESCRIPTION_KEY` - default key name of space field format with field description. Default: 'comment'.

### GRAPHQL_QUERY_CACHE_SIZE

`GRAPHQL_QUERY_CACHE_SIZE` - default number of cached requests for each schema.
