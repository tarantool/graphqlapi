#!/bin/sh
# Call this script to install test dependencies

set -e

# Module dependencies:
tarantoolctl rocks install cartridge 2.7.1

# Test dependencies:
tarantoolctl rocks install luatest 0.5.5
tarantoolctl rocks install luacov 0.13.0
tarantoolctl rocks install luacheck 0.26.0
