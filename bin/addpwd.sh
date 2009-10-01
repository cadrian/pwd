#!/usr/bin/env bash

exe=$0
bindir=${exe%/*}
. "$bindir/common.sh"

stty -echo
echo -n 'Pass: '
read pass
echo
stty echo

key=$(getkey)
addp $key "$pass" "$vault"
