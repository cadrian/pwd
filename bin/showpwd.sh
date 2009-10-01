#!/usr/bin/env bash

exe=$0
bindir=${exe%/*}
. "$bindir/common.sh"

function cleancb() {
    echo | xclip
}
trap cleancb EXIT INT TERM

while true; do
    key=$(getkey)
    test -z "$key" && exit 0
    showp $key "$vault" | xclip -loops 1
    echo "Copied password for key $key"
done
