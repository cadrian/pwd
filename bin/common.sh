# vault format: one line per key
# <key>:<id>:<delid>:<pass>
#
# <key>       the user's key
# <id>        an internal add id
# <delid>     an internal deleted id - the key is deleted if delid = id
# <pass>      the password
#
# Only one line per key is kept.
# The file is kept sorted.
#
# + openssl bf encryption

export VAULT_TTY=$(tty)

exe=$0
prog=${exe##*/}
bindir=${exe%/*}
cd $bindir
bindir=$(pwd)
basedir=${bindir%/*}
datadir="$basedir/data"
vault="$datadir/vault"
export PROPERTIES="$basedir/conf/${prog%.sh}.properties"

test -d "$datadir" || mkdir "$datadir"

# use cat for plain-text tests
export DECODE=decode #cat
export ENCODE=encode #cat

function decode() {
    envname=$1
    openssl bf -d -a -pass env:$envname
}

function encode() {
    envname=$1
    openssl bf -a -pass env:$envname
}

function checkmaster() {
    (
	vault="$1"
	stty -F $VAULT_TTY -echo
	echo -n 'Master: ' >$VAULT_TTY
	read master
	echo >$VAULT_TTY
	stty -F $VAULT_TTY echo
	export master

	if [ -e "$vault" ]; then
	    $DECODE master < "$vault" > /dev/null || exit 1
	fi
	echo $master
    ) || return 1
}

function getkey() {
    echo -n 'Key: ' >$VAULT_TTY
    read key remainder

    if [ "${key%:}" != "$key" ]; then
	echo 'Colon ":" not permitted (technical limitation, sorry)' >$VAULT_TTY
    elif [ -n "$remainder" ]; then
	echo 'Space character not permitted (technical limitation, sorry)' >$VAULT_TTY
    else
	echo "$key"
    fi
}

function addp() {
    key=$1
    pass="$2"
    vault="$3"
    if [ "${key%:}" != "$key" ]; then
	echo 'Colon ":" not permitted in key (technical limitation, sorry)' >$VAULT_TTY
    elif [ "${pass%:}" != "$pass" ]; then
	echo 'Colon ":" not permitted in password (technical limitation, sorry)' >$VAULT_TTY
    fi
    if [ -e "$vault" ]; then
	cp -fp "$vault" "${vault}~"
	$DECODE VAULT_MASTER < "${vault}~" | awk -F: -vkey=$key -vpass="$pass" \
	   '{
                if ($1 == key) {
                    n = $2;
                    d = $3;
                    n = d > n ? d+1 : n+1;
                    printf("%s:%d:%d:%s\n", key, n, d, pass);
                    found=1;
                } else {
                    print $0;
                }
            }
            END {
                if (!found) {
                    printf("%s:1:0:%s\n", key, pass);
                }
            }' | sort | $ENCODE VAULT_MASTER > "$vault"
    else
	echo $key':1:0:'"$pass" | $ENCODE VAULT_MASTER > "$vault"
    fi
}

function remp() {
    key=$1
    vault="$2"
    if [ -e "$vault" ]; then
	cp -fp "$vault" "${vault}~"
	$DECODE VAULT_MASTER < "${vault}~" | awk -F: -vkey=$key -vpass="$pass" \
	    '{
                 if ($1 == key) {
                     n = $2;
                     d = $3;
                     d = d >= n ? d : n;
                     printf("%s:%d:%d:%s\n", key, n, d, $4);
                 } else {
                     print $0;
                 }
            }' | $ENCODE VAULT_MASTER > "$vault"
    fi
}

function showp() {
    key="$1"
    vault="$2"
    if [ -e "$vault" ]; then
	$DECODE VAULT_MASTER < "${vault}" | grep -E '^'$key':' | awk -F: \
	    '{
                 n = $2;
                 d = $3;
                 if (d < n) {
                     printf("%s", $4);
                 }
             }'
    fi
}

function listp() {
    vault="$1"
    if [ -e "$vault" ]; then
	$DECODE VAULT_MASTER < "${vault}" | awk -F: \
	    '{
                 n = $2;
                 d = $3;
                 if (d < n) {
                     printf("%s\n", $1);
                 }
             }'
    fi
}

function genp() {
    awk 'BEGIN {
             letters = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789";
             symbols = "(-_)~#{[|^@]}+=<>,?./!§";
             printf("%s", substr(letters, length(letters)*rand(), 1));
             printf("%s", substr(symbols, length(symbols)*rand(), 1));

             table = letters symbols letters letters;
             n = length(table);
             for (i = 0; i < 15; i++) {
                 printf("%s", substr(table, n*rand(), 1));
             }
             printf("\n");
         }' </dev/zero
}

function savepwds() {
    (
	. "$PROPERTIES"
	vault="$1"
	if [ -z "${server_pwdkey}" ]; then
	    # anonymous upload
	    curl -# -T "$vault" "${server_vault_url}"
	else
	    davpwd=$(showp "${server_pwdkey}" "$vault")
	    if [ -z "$davpwd" ]; then
		echo "Missing ${server_pwdkey} password" >$VAULT_TTY
		return 1
	    else
		curl -u ${server_login}:"$davpwd" -# -T "$vault" "${server_vault_url}"
	    fi
	fi
    )
}

function loadpwds() {
    (
	. "$PROPERTIES"
	vault="$1"
	if [ -z "${server_pwdkey}" ]; then
	    # anonymous download
	    curl -# "${server_vault_url}" -o "$vault"
	else
	    davpwd=$(showp "${server_pwdkey}" "$vault")
	    if [ -z "$davpwd" ]; then
		echo "Missing ${server_pwdkey} password" >$VAULT_TTY
		return 1
	    else
		curl -u ${server_login}:"$davpwd" -\# "${server_vault_url}" -o "$vault"
	    fi
	fi
    )
}

# Merge passwords.
# The greatest id is kept.
# If the ids are equal the local is kept.
# Asks the server password but encrypts back using the local password
function mergep() {
    (
	servervault="$1"
	localvault="$2"
	vault="$3"
	export localmaster="$VAULT_MASTER"
	export servermaster="$(checkmaster)" || return 1
	{
	    $DECODE servermaster < "$servervault"
	    $DECODE localmaster < "$localvault"
	} | sort | awk -F: \
	    '{
                 newkey = $1;
                 if (newkey != key) {
                     if (id > 0) {
                         printf("%s:%d:%d:%s\n", key, id, delid, pass);
                     }
                     key = newkey;
                     id = 0;
                 }
                 n = $2;
                 d = $3;
                 if (id < n) {
                     id = n;
                     pass = $4;
                 }
                 if (delid < d) {
                     delid = d;
                 }
             }
             END {
                 if (id > 0) {
                     printf("%s:%d:%d:%s\n", key, id, delid, pass);
                 }
             }' | $ENCODE VAULT_MASTER > "$vault"
    )
}

function changemaster() {
    (
	vault="$1"
	stty -F $VAULT_TTY -echo
	echo -n "Old master: " >$VAULT_TTY
	read old
	echo >$VAULT_TTY
	stty -F $VAULT_TTY echo
	export old

	if [ -e "$vault" ]; then
	    $DECODE old < "$vault" > /dev/null || exit 1
	fi

	stty -F $VAULT_TTY -echo
	echo -n "New master: " >$VAULT_TTY
	read new
	echo >$VAULT_TTY
	echo -n "Confirm: " >$VAULT_TTY
	read con
	echo >$VAULT_TTY
	stty -F $VAULT_TTY echo

	if [ "$new" != "$con" ]; then
	    echo "Password mismatch" >$VAULT_TTY
	else
	    export new
	    if [ -e "$vault" ]; then
		cp -fp "$vault" "${vault}~"
		$DECODE old < "${vault}~" | $ENCODE new > "$vault"
	    fi

	    echo "$new"
	fi
    )
}

export VAULT_MASTER=$(checkmaster "$vault")
