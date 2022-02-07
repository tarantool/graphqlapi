# GraphQLAPI Tarantool Cartridge-based application full featured example

This Example shows mostly all base capabilities of using the following set of modules:

- [Tarantool GraphQLIDE 0.0.19+](https://github.com/tarantool/graphqlide)
- [Tarantool GraphQLAPI 0.0.8+](https://github.com/tarantool/graphqlapi)
- [Tarantool GraphQLAPI Helpers 0.0.8+](https://github.com/tarantool/graphqlapi-helpers) - this particular module available only in Tarantool Enterprise SDK bundle

## Quick start

To build application, start it and setup topology:

```bash
# build application
cartridge build

# start all instances including stateboard
cartridge start -d

# configure replicasets and bootstrap vshard
cartridge replicasets setup --bootstrap-vshard

# configure failover
cartridge failover setup --file failover.yml

# fire migrations
cartridge admin --run-dir `pwd`/tmp/run/ --name cartridge-full --instance router migrations

# fill test data
cartridge admin --run-dir `pwd`/tmp/run/ --name cartridge-full --instance router fill
```

or use bash-scripts:

```bash
# install dependencies
./deps.sh

# build and start application
./scripts/start.sh

# bootstrap cluster and failover
./scripts/bootstrap.sh

# create spaces (fire migrations) and fill test data
./scripts/fill.sh

```

Now you can visit http://localhost:8081 and see your application's Admin Web UI.

**Note**, that application stateboard is always started by default.
See [`.cartridge.yml`](./.cartridge.yml) file to change this behavior.

## Application

Application entry point is [`init.lua`](./init.lua) file.
It configures Cartridge, initializes admin functions and exposes metrics endpoints.
Before requiring `cartridge` module `package_compat.cfg()` is called.
It configures package search path to correctly start application on production
(e.g. using `systemd`).

## Roles

Application has two simple roles:

- [`app.roles.api`](./app/roles/api.lua).
- [`app.roles.storage`](./app/roles/storage.lua)

Both `api` and `storage` roles exposes `/metrics` endpoints:

```bash
curl localhost:8081/metrics
```

### api role

Custom user `api` role uses the following Cartridge roles:

- cartridge.roles.vshard-router
- cartridge.roles.crud-router
- cartridge.roles.graphqlide
- cartridge.roles.graphqlapi

### storage role

Custom user `storage` role uses the following roles:

- cartridge.roles.vshard-storage
- cartridge.roles.crud-storage

### Fragments

Fragments - separate parts of GraphQL schemas located in `./fragments/*.lua`:

- `entity.lua` - fragment adds 3 custom queries to `Default` schema:
  - `entity_get_by_id`;
  - `entity_get_by_name`;
  - `entity_get_all`;
- `helpers.lua` - fragment adds 3 schemas:
  - `Data` - CRUD GraphQL API generated based on the current cluster data schema;
  - `Service` - ;
  - `Spaces`;
- `logging.lua` - fragment adds custom logging for GraphQL API requests;
- `owner.lua` - fragment adds 3 custom queries to `Default` schema:
  - `owner_get_by_id`;
  - `owner_get_by_username`;
  - `owner_get_all`.

## GraphqlIDE

After starting application on [`router` - http://localhost:8081](http://localhost:8081) instance GraphQL IDE will be available:

![GraphQL IDE](./resources/GraphQLIDE.png "GraphQL IDE")

The following schemes are available in this demo application:

- `Admin` - Tarantool Cartridge admin GraphQL API;
- `Data` - CRUD GraphQL API generated based on the current cluster data schema;
- `Default` - custom GraphQL API generated from `./fragments/*.lua`;
- `Service` - a set of service queries and mutations;
- `Spaces` - a set of queries and mutations to manipulate spaces.

### Example requests

Switch to `Default` schema in GraphQL IDE and make the following requests:

```graphql
query {
  owner_get_all {
    bucket_id
    owner_surname
    owner_name
    owner_age
    owner_username
    owner_id
  }
}
```

```graphql
query {
  owner_get_by_id(owner_id: 1) {
    owner_surname
    owner_id
    owner_age
    owner_name
    owner_username
  }
}
```

```graphql
query {
  owner_get_by_username(owner_username: "rapid") {
    owner_surname
    owner_id
    owner_username
    owner_age
    owner_name
    entities {
      entity_description
      entity_owner_id
      entity_name
      entity_id
    }
  }
}
```

```graphql
query{
  entity_get_all {
    bucket_id
    entity_description
    entity_owner_id
    entity_name
    entity_id
  }
}
```

```graphql
query {
  entity_get_by_id(entity_id: 1) {
    entity_description
    entity_owner_id
    entity_name
    entity_id
  }
}
```

```graphql
query{
  entity_get_by_name(entity_name: "SSD") {
    entity_description
    entity_owner_id
    entity_name
    entity_id
  }
}
```

For other schemas all available queries and mutations may be found in GraphiQL Docs.
