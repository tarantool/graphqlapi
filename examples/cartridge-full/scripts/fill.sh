#!/bin/sh

SCRIPTPATH="$( cd "$(dirname "$0")" >/dev/null 2>&1 ; pwd -P )"
cd $SCRIPTPATH/..

cartridge admin --run-dir `pwd`/tmp/run/ --name cartridge-full --instance router migrations
cartridge admin --run-dir `pwd`/tmp/run/ --name cartridge-full --instance router fill
