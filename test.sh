#!/usr/bin/env bash

# Integration test: see test/test_webclient.sh for details

set -e
set -u

cd $(dirname $(readlink -f $0))

if [ $# -gt 0 ]; then
    case x$1 in
        xbootstrap)
            ./deploy.sh bootstrap
            ;;
    esac
fi
./deploy.sh release
exec test/test_webclient.sh "$@"
