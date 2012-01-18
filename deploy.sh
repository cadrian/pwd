#!/usr/bin/env bash

dir=$(dirname $(readlink -f $0))
cd $dir

rm -rf target

echo bootstrap
./bootstrap.sh

echo release
./release.sh

echo deploy
version=$(< $dir/version.txt)
target=$(gcc -v 2>&1 | awk '/^Target:/ {print $2}')
root=pwdmgr_$version\_$target
boot=pwdmgr-boot_$version
cd $dir/target
tar cfz $root.tgz --transform "s|^release|$root|" release/*
tar cfz $boot.tgz --transform "s|^bootstrap|$boot|" bootstrap/*

echo done
