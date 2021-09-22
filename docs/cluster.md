# Submodule **cluster** Lua API

- [Submodule **cluster** Lua API](#submodule-cluster-lua-api)
  - [lua API](#lua-api)
    - [get_servers()](#get_servers)
    - [get_masters()](#get_masters)
    - [get_storages_masters()](#get_storages_masters)
    - [get_self_alias()](#get_self_alias)
    - [get_self_uri()](#get_self_uri)
    - [get_replicasets()](#get_replicasets)
    - [get_replicaset_instances(replicaset)](#get_replicaset_instancesreplicaset)
    - [get_instances()](#get_instances)
    - [get_existing_spaces()](#get_existing_spaces)
    - [is_space_exists()](#is_space_exists)
    - [get_schema()](#get_schema)

Submodule `cluster.lua` is a part of GraphQL API module provided functions specific to cluster application architecture. This particular implementation was made for Tarantool Cartridge Application (requires: `Cartridge`, `VShard` and `DDL` modules), for any custom application architecture, for example for so called pure-Tarantool applications most functions of this module may need to be overridden to comply it.

## lua API

### get_servers()

`cluster.get_servers()` - function to get connections to all cluster instances,

returns:

- `servers` (`table`) - array of conn objects to all servers. For more details see: [net_box module](https://www.tarantool.io/en/doc/latest/reference/reference_lua/net_box/#net-box-connect)

- `connect_errors` (`table`) - array of errors if some cluster instances is not available.

### get_masters()

`cluster.get_masters()` - function to get connections to active master instances of all replicasets,

returns:

- `servers` (`table`) - array of conn objects to all servers. For more details see: [net_box module](https://www.tarantool.io/en/doc/latest/reference/reference_lua/net_box/#net-box-connect)

- `connect_errors` (`table`) - array of errors if some master instances is not available.

### get_storages_masters()

`cluster.get_storages_masters()` - function to get connections to master instances of all storage replicasets,

- `servers` (`table`) - array of conn objects to all servers. For more details see: [net_box module](https://www.tarantool.io/en/doc/latest/reference/reference_lua/net_box/#net-box-connect)

- `connect_errors` (`table`) - array of errors if some master instances is not available.

### get_self_alias()

`cluster.get_self_alias()` - function to get instance alias this function called on,

returns:

- `instance_name` (`string`) - name of instance.

### get_self_uri()

`cluster.get_self_uri()` - function to get instance URI this function called on,

returns:

- `uri` (`string`) - URI (IP:port or FQDN:port) of instance.

### get_replicasets()

`cluster.get_replicasets()` - function to get all cluster replicasets alias names,

returns:

- `replicasets` (`table`) - array of strings - cluster replicasets alias names.

### get_replicaset_instances(replicaset)

`cluster.get_replicaset_instances()` - function to get all replicaset instances alias names,

where:

- `replicaset` (`string`) - alias name of replicaset;

returns:

- `replicasets` (`table`) - array of strings - cluster replicasets aliases names.

### get_instances()

`cluster.get_instances()` - function to get all cluster replicasets alias names,

returns:

- `replicasets` (`table`) - array of strings - cluster replicasets alias names.

### get_existing_spaces()

`cluster.get_existing_spaces()` - function to get list of existing spaces on instance,

returns:

- `spaces` (`table`) - array of existing non-system spaces on instance.

### is_space_exists()

`cluster.is_space_exists(space)` - function to check if the desired space is exists on instance,

where:

- `space` (`string`) - name of space;

returns:

- `status` (`boolean`) - true if space exists, false - if not.

### get_schema()

`cluster.get_schema()` - function to get database schema,

returns:

- `schema` (`table`) - database schema, for additional info see [ddl.get_schema()](https://github.com/tarantool/ddl#get-spaces-format).
