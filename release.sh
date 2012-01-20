#!/usr/bin/env bash

dir=$(dirname $(readlink -f $0))
cd $dir

make -j$(cat /proc/cpuinfo | grep ^processor | wc -l)

release_dir=$dir/target/release
test -d $release_dir && rm -rf $release_dir
mkdir -p $release_dir

for d in bin conf exe COPYING README.md
do
    cp -a $d $release_dir/
done

test -e $release_dir/bin/se && rm $release_dir/bin/se
