#!/usr/bin/env bash

ID_RSA=$HOME/.ssh/id_rsa_travis

test -d $HOME/.ssh || mkdir -p $HOME/.ssh
chmod 700 $HOME/.ssh
{
    echo -n $__B64_ID_RSA_{00..74}
    echo
} | base64 --decode --ignore-garbage > $ID_RSA
chmod 600 $ID_RSA
