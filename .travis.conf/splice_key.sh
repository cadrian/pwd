#!/usr/bin/env bash

ID_RSA=$HOME/.ssh/id_rsa_travis

test -d $HOME/.ssh || mkdir -p $HOME/.ssh
chmod 700 $HOME/.ssh
rm -f ${ID_RSA}.b64 && touch ${ID_RSA}.b64
echo -n $__B64_ID_RSA_{00..74} >> ${ID_RSA}.b64
base64 --decode --ignore-garbage ${ID_RSA}.b64 > $ID_RSA
chmod 600 $ID_RSA
