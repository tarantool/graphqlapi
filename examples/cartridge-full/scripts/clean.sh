#!/bin/sh

SCRIPTPATH="$( cd "$(dirname "$0")" >/dev/null 2>&1 ; pwd -P )"
cd $SCRIPTPATH/..

sh ./scripts/stop.sh
sleep 3
rm -rf ./tmp/data
rm -rf ./tmp/log
rm -rf ./tmp/run
