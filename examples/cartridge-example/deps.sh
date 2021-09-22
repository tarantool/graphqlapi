#!/bin/sh
# Call this script to install test dependencies

set -e

# App dependencies:
tarantoolctl rocks make
sh ./cartridge.post-build

# Test dependencies:
tarantoolctl rocks install luatest 0.5.5
tarantoolctl rocks install luacov 0.13.0
tarantoolctl rocks install luacheck 0.26.0
