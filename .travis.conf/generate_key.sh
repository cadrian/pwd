#!/usr/bin/env bash

ID_RSA=$HOME/.ssh/id_rsa_travis

rm -f $ID_RSA
ssh-keygen -t rsa -C "cyril.adrian@gmail.com" -f $ID_RSA -N ""
base64 --wrap=0 $ID_RSA > ${ID_RSA}.b64
ENCRYPTION_FILTER="echo \$(echo \"- secure: \")\$(travis encrypt \"\$FILE='\`cat $FILE\`'\" -r cadrian/pwd)"
split --bytes=30 --numeric-suffixes --suffix-length=2 --filter="$ENCRYPTION_FILTER" ${ID_RSA}.b64 __B64_ID_RSA_ > travis_key.yml
wc -l travis_key.yml
