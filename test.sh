#!/usr/bin/env bash

# Integration test: see test/test_webclient.sh for details

cd $(dirname $(readlink -f $0))
./deploy.sh bootstrap
./deploy.sh release
exec test/test_webclient.sh "$@"
