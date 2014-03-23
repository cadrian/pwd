#!/usr/bin/env bash

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ #
#                                                                        #
# Prepare both bootstrap and binary packages of pwdmgr                   #
# (with the correct version number)                                      #
#                                                                        #
# See also: bootstrap.sh, release.sh                                     #
#                                                                        #
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ #

dir=$(dirname $(readlink -f $0))
cd $dir

rm -rf target
$dir/protocol.sh

BOOTSTRAP=false
RELEASE=false
ONKEY=false
DEBIAN=false
INSTALL=false

if [ x$1 == x ]; then
    BOOTSTRAP=true
    RELEASE=true
    ONKEY=true
else
    case $1 in
        bootstrap)
            BOOTSTRAP=true
            ;;
        release)
            RELEASE=true
            ;;
        onkey)
            ONKEY=true
            ;;
        debian)
            BOOTSTRAP=true
            DEBIAN=true
            ;;
        install)
            RELEASE=true
            INSTALL=true
            ;;
        *)
            echo unrecognized option >&2
            exit 1
    esac
fi

if $BOOTSTRAP; then
    echo bootstrap
    ./bootstrap.sh
fi

if $RELEASE; then
    echo release binary
    ./release.sh
fi

if $ONKEY; then
    echo release on key
    ./release.sh -onkey
fi

if $DEBIAN; then
    echo release Debian
    ./release.sh -debian
fi

echo deploy
version=$(head -n 1 $dir/debian/changelog | awk -F'[()]' '{print $2}')
target=$(gcc -v 2>&1 | awk '/^Target:/ {print $2}')
pkg=pwdmgr_$version
root=${pkg}_$target
boot=${pkg}-bootstrap

cd $dir/target
$RELEASE   && tar cfz $root.tgz --transform "s|^release|$pkg|" release/*
$ONKEY     && tar cfz $root-onkey.tgz --transform "s|^release-onkey|$pkg|" release-onkey/*
$BOOTSTRAP && tar cfz $boot.tgz --transform "s|^bootstrap|$pkg|" bootstrap/*

if $INSTALL; then
    echo install
    $dir/target/release/install.sh
fi

if $DEBIAN; then
    echo building Debian packages
    for file in bin c conf README.md Makefile; do
        cp -a bootstrap/$file release-debian/pwd/
    done
    cd release-debian/pwd
    debuild -us -uc
fi

echo done
