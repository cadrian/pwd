#!/usr/bin/bash

ID_RSA=$HOME/.ssh/id_rsa_travis

echo -n $__B64_ID_RSA_{00..30} >> ${ID_RSA}.b64
base64 --decode --ignore-garbage ${ID_RSA}.b64 > $ID_RSA
chmod 600 $ID_RSA
