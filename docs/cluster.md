# Submodule **cluster** Lua API

- [Submodule **cluster** Lua API](#submodule-cluster-lua-api)
  - [lua API](#lua-api)
    - [get_servers()](#get_servers)
    - [get_masters()](#get_masters)
    - [get_storages_instances()](#get_storages_instances)
    - [get_self_alias()](#get_self_alias)
    - [get_self_uri()](#get_self_uri)
    - [get_replicasets()](#get_replicasets)
    - [get_replicaset_instances()](#get_replicaset_instances)
    - [get_instances()](#get_instances)
    - [get_candidates()](#get_candidates)
    - [get_servers_by_list()](#get_servers_by_list)
    - [get_existing_spaces()](#get_existing_spaces)
    - [is_space_exists()](#is_space_exists)
    - [get_schema()](#get_schema)
    - [check_schema()](#check_schema)
    - [set_schema()](#set_schema)

Submodule `cluster.lua` is a part of GraphQL API module provided functions specific to cluster application architecture. This particular implementation was made for Tarantool Cartridge Application (requires: `Cartridge`, `VShard` and `DDL` modules), for any custom application architecture, for example for so called pure-Tarantool applications most functions of this module may need to be overridden to comply it.

## lua API

### get_servers()

`cluster.get_servers()` - method to get connections to all cluster instances,

returns:

- `[1]` (`table`) - array of maps with the following structure:
  - `alias` (`string`) - alias of instance
  - `conn` (`table`) - conn object. For more details see: [net_box module](https://www.tarantool.io/en/doc/latest/reference/reference_lua/net_box/#net-box-connect)
- `[2]` (`table`) - array of errors if any of need instances is not available.

### get_masters()

`cluster.get_masters()` - method to get connections to active master instances of all cluster replicasets,

returns:

- `[1]` (`table`) - array of maps with the following structure:
  - `alias` (`string`) - alias of instance
  - `conn` (`table`) - conn object. For more details see: [net_box module](https://www.tarantool.io/en/doc/latest/reference/reference_lua/net_box/#net-box-connect)
- `[2]` (`table`) - array of errors if any of need instances is not available.

### get_storages_instances()

`cluster.get_storages_instances(mode, prefer_replica, balance)` - method to get connections to get one instance from of all storage replicasets according to desired policy,

where:

- `mode` (`string`) - optional, have to be 'write' for replicaset masters (default) or 'read' for replicas if available;
- `prefer_replica` (`boolean`) - optional, if true then the preferred target is one of the replicas, false by default;
- `balance` (`boolean`) - use replica according to vshard load balancing policy;

returns:

- `[1]` (`table`) - array of maps with the following structure:
  - `alias` (`string`) - alias of instance
  - `conn` (`table`) - conn object. For more details see: [net_box module](https://www.tarantool.io/en/doc/latest/reference/reference_lua/net_box/#net-box-connect)
- `[2]` (`table`) - array of errors if any of need instances is not available.

### get_self_alias()

`cluster.get_self_alias()` - method to get instance alias this function called on,

returns:

- `[1]` (`string`) - name of instance.

### get_self_uri()

`cluster.get_self_uri()` - method to get instance URI this function called on,

returns:

- `[1]` (`string`) - URI (IP:port or FQDN:port) of instance.

### get_replicasets()

`cluster.get_replicasets()` - method to get all cluster replicasets alias names,

returns:

- `[1]` (`table`) - array of strings - cluster replicasets alias names.

### get_replicaset_instances()

`cluster.get_replicaset_instances(replicaset)` - method to get all replicaset instances alias names,

where:

- `replicaset` (`table`) - alias name of replicaset;

returns:

- `[1]` (`table`) - map with cluster replicaset instances, has the following format:
  - `alias` (`string`) - instance alias name;
  - `uri` (`string`) - instance connection string;
  - `status` (`string`) - server status.

### get_instances()

`cluster.get_instances()` - method to get all cluster replicasets alias names,

returns:

- `[1]` (`table`) - map with cluster replicaset instances, has the following format:
  - `alias` (`string`) - instance alias name;
  - `uri` (`string`) - instance connection string;
  - `status` (`string`) - server status.

### get_candidates()

`cluster.get_candidates(role)` - method to get all cluster instances with the provided role,

where:

- `role` (`string`) - mandatory, role name,

returns:

- `[1]` (`table`) - map with cluster replicaset instances, has the following format:
  - `alias` (`string`) - instance alias name;
  - `uri` (`string`) - instance connection string;
  - `status` (`string`) - server status.

### get_servers_by_list()

`cluster.get_servers_by_list()` - method to get servers objects by provided list of instances alias names,

returns:

- `[1]` (`table`) - array of conn objects to all servers. For more details see: [net_box module](https://www.tarantool.io/en/doc/latest/reference/reference_lua/net_box/#net-box-connect)

- `[2]` (`table`) - array of errors if some instances is not available.

### get_existing_spaces()

`cluster.get_existing_spaces()` - method to get list of existing spaces,

returns:

- `[1]` (`table`) - array of `strings` of existing non-system spaces on instance this function called on.

### is_space_exists()

`cluster.is_space_exists(space)` - method to check if the desired space is exists,

where:

- `space` (`string`) - name of space to be checked;

returns:

- `[1]` (`boolean`) - true if space exists, false - if not.

### get_schema()

`cluster.get_schema()` - method to get database schema (ddl.get_schema() wrapper),

returns:

- `[1]` (`table`) - database schema, for additional info see [ddl.get_schema()](https://github.com/tarantool/ddl#get-spaces-format).

### check_schema()

`cluster.check_schema()` - method to get database schema (ddl.check_schema() wrapper),

returns:

- `[1]` (`boolean`) - `true` if no error, otherwise return `nil`;
- `[2]` (`error`) - error object.

For additional info see [ddl.check_schema()](https://github.com/tarantool/ddl#check-compatibility).

### set_schema()

`cluster.set_schema()` - method to get database schema (ddl.set_schema() wrapper),

returns:

- `[1]` (`boolean`) - `true` if no error, otherwise return `nil`;
- `[2]` (`error`) - error object.

For additional info see [ddl.set_schema()](https://github.com/tarantool/ddl#set-spaces-format).
