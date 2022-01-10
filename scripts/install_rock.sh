#!/bin/bash

SCRIPTPATH="$( cd "$(dirname "$0")" >/dev/null 2>&1 ; pwd -P )"

tarantoolctl rocks install $SCRIPTPATH/../graphqlapi-scm-1.all.rock
