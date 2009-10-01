#!/usr/bin/env bash

exe=$0
bindir=${exe%/*}
. "$bindir/common.sh"

function cleancb() {
    echo | xclip
}
trap cleancb EXIT INT TERM

while true; do
    echo
    echo -n "> "
    read cmd key pass
    case $cmd in

	"")
	    exit 0
	    ;;

	help)
	    less <<EOF
add <key> [pass]   Add a new password. Needs at least a key.
                   If the password is not specified it is randomly generated.
                   If the password already exists it is changed.
                   The password may be pasted twice.

rem <key>          Removes the password corresponding to the given key.

list               List the known passwords (show only the keys).

save               Save the password vault upto the server.

load               Replace the local vault with the server's version.

merge              Load the server version and compare to the local one.
                   Keep the most recent keys and save the merged version
                   back to the server.

master             Change the master password.

help               Show this screen :-)

Any other "command" is understood as a key.
In that case the password is stored in the clipboard.

An number as argument is the number of times the password may be pasted
(default: once) -- useful for change-password form filling.

EOF
	    ;;

	add)
	    if [ -z "$key" ]; then
		echo "Missing key"
	    elif [ "${key%:}" != "$key" ]; then
		echo 'Colon ":" not permitted (technical limitation, sorry)'
	    else
		pass="${pass:-$(genp)}"
		addp $key "$pass" "$vault"
		xclip -loops 2 <<<"$pass"
		echo "Copied new password for key $key"
	    fi
	    ;;

	rem)
	    if [ -z "$key" ]; then
		echo "Missing key"
	    else
		remp $key "$vault"
		echo "Removed key $key"
	    fi
	    ;;

	master)
	    VAULT_MASTER=$(changemaster "$vault")
	    if [ -e "$vault" ]; then
		openssl bf -d -a -pass env:VAULT_MASTER < "$vault" > /dev/null || exit 1
	    fi
	    ;;

	list)
	    listp "$vault" | less
	    ;;

	save)
	    savepwds "$vault"
	    ;;

	load)
	    loadpwds "$vault"
	    VAULT_MASTER=$(checkmaster "$vault")
	    ;;

	merge)
	    servervault="${vault}~server~"
	    localvault="${vault}~local~"
	    cp "$vault" "$localvault"
	    loadpwds "$servervault"
	    mergep "$servervault" "$localvault" "$vault"
	    savepwds "$vault"
	    ;;

	*)
	    key=$cmd
	    if [ -z "$key" ]; then
		echo "Missing key"
	    else
		n=${pass:-1}
		pass="$(showp "$key" "$vault")"
		if [ -z "$pass" ]; then
		    echo "Unknown key $key"
		else
		    echo -n "$pass" | xclip -loops $n
		    echo "Copied password for key $key"
		fi
	    fi
	    ;;

    esac
done
