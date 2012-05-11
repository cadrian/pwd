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

echo bootstrap
./bootstrap.sh

echo release binary
./release.sh

echo release on key
./release.sh -onkey

echo deploy
version=$(head -n 1 $dir/Changelog | awk '{print $1}')
target=$(gcc -v 2>&1 | awk '/^Target:/ {print $2}')
pkg=pwdmgr_$version
root=pwdmgr_$version\_$target
boot=pwdmgr-boot_$version
cd $dir/target
tar cfz $root.tgz --transform "s|^release|$pkg|" release/*
tar cfz $root-onkey.tgz --transform "s|^release-onkey|$pkg|" release-onkey/*
tar cfz $boot.tgz --transform "s|^bootstrap|$pkg|" bootstrap/*

echo done
