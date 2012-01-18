#!/bin/bash

dist=$(dirname $(dirname $(readlink -f $0)))
export PATH=$dist/bin:$PATH
if [ ! -e $dist/data/vault ]; then
    mkdir -p $dist/data
    touch $dist/data/vault
    chmod 0600 $dist/data/vault
fi
exec console $HOME/.pwdmgr_fifo $dist/data/vault $dist/conf/pwdmgr.properties
