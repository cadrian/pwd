#!/usr/bin/env bash

# Integration test: see test/test_webclient.sh for details

set -e
set -u

cd $(dirname $(readlink -f $0))

if [ $# -gt 0 ]; then
    case x$1 in
        xbootstrap)
            echo "Bootstrapping..."
            ./bootstrap.sh
            echo "Compiling..."
            make -j2
            ;;
    esac
fi
echo "Starting test web server."
exec test/test_webclient.sh "$@"
