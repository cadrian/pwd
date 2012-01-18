#!/bin/bash

dist=$(dirname $(dirname $(readlink -f $0)))
export PATH=$dist/bin:$PATH
umask 077
test -d $dist/data || mkdir -p $dist/data
test -d $dist/log || mkdir -p $dist/log
exec console $HOME/.pwdmgr_fifo $dist/data/vault $dist/log $dist/conf/pwdmgr.properties
