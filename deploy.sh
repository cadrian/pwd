#!/usr/bin/env bash

dir=$(dirname $(readlink -f $0))
cd $dir

rm -rf target

echo bootstrap
./bootstrap.sh

echo release
./release.sh

echo deploy
version=$(head -n 1 $dir/Changelog | awk '{print $1}')
target=$(gcc -v 2>&1 | awk '/^Target:/ {print $2}')
pkg=pwdmgr_$version
root=pwdmgr_$version\_$target
boot=pwdmgr-boot_$version
cd $dir/target
tar cfz $root.tgz --transform "s|^release|$pkg|" release/*
tar cfz $boot.tgz --transform "s|^bootstrap|$pkg|" bootstrap/*

echo done
