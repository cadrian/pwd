#!/bin/bash

dir=$(dirname $(readlink -f $0))
cd $dir

test -d bootstrap && rm -rf bootstrap
mkdir bootstrap

for exe in daemon menu #console
do
    ace=$exe.ace
    ./make_ace.sh $ace dontclean
    se c2c $ace
    rm $ace
    mv $exe* bootstrap
done
