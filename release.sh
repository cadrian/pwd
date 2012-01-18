#!/usr/bin/env bash

dir=$(dirname $(readlink -f $0))
cd $dir

make

release_dir=$dir/target/release
test -d $release_dir && rm -rf $release_dir
mkdir -p $release_dir

for d in bin src conf COPYING *.sh Makefile README.md
do
    cp -a $d $release_dir/
done
