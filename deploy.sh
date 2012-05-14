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

BOOTSTRAP=false
RELEASE=false
ONKEY=false

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

echo deploy
version=$(head -n 1 $dir/Changelog | awk '{print $1}')
target=$(gcc -v 2>&1 | awk '/^Target:/ {print $2}')
pkg=pwdmgr_$version
root=pwdmgr_$version\_$target
boot=pwdmgr-boot_$version
cd $dir/target
$RELEASE && tar cfz $root.tgz --transform "s|^release|$pkg|" release/*
$ONKEY && tar cfz $root-onkey.tgz --transform "s|^release-onkey|$pkg|" release-onkey/*
$BOOTSTRAP && tar cfz $boot.tgz --transform "s|^bootstrap|$pkg|" bootstrap/*

echo done
