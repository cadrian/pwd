#!/usr/bin/env bash

exe=$0
bindir=${exe%/*}
. "$bindir/common.sh"

key=$(getkey)
pass="$(genp)"
addp $key "$pass" "$vault"
xclip -loops 1 <<<"$pass"
read
