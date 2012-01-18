#!/bin/bash

dist=$(dirname $(dirname $(readlink -f $0)))
export PATH=$dist/bin:$PATH
exec console $HOME/.pwdmgr_fifo $dist/data/vault
