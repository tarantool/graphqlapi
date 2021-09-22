#!/bin/sh

SCRIPTPATH="$( cd "$(dirname "$0")" >/dev/null 2>&1 ; pwd -P )"
cd $SCRIPTPATH/..

cartridge replicasets setup --file ./replicasets.yml --bootstrap-vshard
sleep 2
cartridge failover setup --file failover.yml
