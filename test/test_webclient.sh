#!/usr/bin/env bash

# A manual test framework.
# Launches a user lighttpd on port 8888 configured to accept the webclient CGI.
# The basic auth credentials are test/pwd
# The vault is created at startup with the password pwd

echo "Configuring..."

pwdhome=$(dirname $(dirname $(readlink -f $0)))
DIR=$(mktemp --tmpdir -d test_webclient.XXXXXX)
CONF=$DIR/conf
ROOT=$DIR/root
LOG=$DIR/log
RUN=$DIR/run

mkdir -p $CONF $ROOT $LOG $RUN

cat > $CONF/lighttpd.conf <<EOF
server.chroot = "$DIR"
server.document-root = "$ROOT"
server.port = 8888
server.tag = "test_webclient"
server.modules = ("mod_cgi","mod_auth")

auth.backend = "plain"
auth.backend.plain.userfile = "$CONF/users"
auth.require = ( "/" => (
        "method" => "basic",
        "realm" => "Password protected area",
        "require" => "user=test"
    )
)

mimetype.assign = (
    ".html" => "text/html",
    ".txt"  => "text/plain",
    ".jpg"  => "image/jpeg",
    ".png"  => "image/png",
    ""      => "application/octet-stream"
)

static-file.exclude-extensions = ( ".fcgi", ".php", ".rb", "~", ".inc", ".cgi" )
index-file.names = ( "index.html" )

server.errorlog = "$LOG/error.log"
server.breakagelog = "$LOG/breakage.log"

\$HTTP["url"] =~ "^/pwd\.cgi" {
    cgi.assign = ( ".cgi" => "$(which bash)" )
}
EOF

cat > $CONF/users <<EOF
test:pwd
EOF

cat > $ROOT/index.html <<EOF
<html>
    <head>
        <meta http-equiv="refresh" content="0; url=/pwd.cgi">
    </head>
</html>
EOF

cat >$ROOT/pwd.cgi <<EOF
PATH=$pwdhome/exe:\$PATH
exec webclient $CONF/pwd.properties
EOF

cat > $CONF/pwd.properties <<EOF
[shared]
log.level        = trace
default_recipe   = 8ans
channel.method   = fifo
master.command   = /bin/false
master.arguments =
[webclient]
template.path    = $pwdhome/web/templates
static.path      = $pwdhome/web/static
[vault]
openssl.cipher   = bf
EOF

export HOME=$DIR
export XDG_CACHE_HOME=$RUN
export XDG_RUNTIME_DIR=$RUN
export XDG_DATA_HOME=$RUN
export XDG_CONFIG_HOME=$CONF
export XDG_DATA_DIRS=$RUN
export XDG_CONFIG_DIRS=$RUN

echo -n | openssl bf -a -pass pass:pwd > $RUN/vault

echo "Starting HTTP server into $DIR"

cd $DIR

if [[ -x /usr/sbin/lighttpd ]]; then
    # on cygwin systems
    lighttpd=/usr/sbin/lighttpd
else
    lighttpd=$(which lighttpd)
fi

exec $lighttpd -D -f $CONF/lighttpd.conf