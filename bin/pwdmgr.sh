#!/bin/bash

dist=$(dirname $(dirname $(readlink -f $0)))
export PATH=$dist/bin:$PATH
umask 077
test -d $dist/data || mkdir -p $dist/data
exec console $HOME/.pwdmgr_fifo $dist/data/vault $dist/conf/pwdmgr.properties
