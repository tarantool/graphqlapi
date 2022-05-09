#!/bin/sh

SCRIPTPATH="$( cd "$(dirname "$0")" >/dev/null 2>&1 ; pwd -P )"
cd $SCRIPTPATH/..

cartridge replicasets setup --file ./replicasets.yml --bootstrap-vshard

# Make stop and start because of a bug of single instance bootstrap in Cartridge
# cartridge stop
# sleep 5
# cartridge start -d
# sleep 60
# cartridge replicasets setup --file ./replicasets.yml --bootstrap-vshard
# sleep 5
# cartridge replicasets setup --file ./replicasets.yml --bootstrap-vshard
