#!/usr/bin/env bash

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ #
#                                                                        #
# Make a pwdmgr binary release                                           #
#                                                                        #
# See also: bootstrap.sh, deploy.sh                                      #
#                                                                        #
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ #

JOBS=${NB_JOBS:+-j$NB_JOBS}
JOBS=${JOBS:--j$((2 * $(cat /proc/cpuinfo | grep ^processor | wc -l)))}

ON_KEY=false
MINGW=false
DEBIAN=false
while [ $# -gt 0 ]; do
    case "$1" in
        -onkey)
            ON_KEY=true
            ;;
        -mingw)
            MINGW=true
            PATH=$(dirname $(readlink -f $0))/xcompile/mingw:$PATH # use a specific gcc launcher
            ;;
        -debian)
            DEBIAN=true
            ;;
        -j*)
            JOBS=$1
            ;;
        *)
            echo "Unknown option: $1 (ignored)" >&2
            ;;
    esac
    shift
done

dir=$(dirname $(readlink -f $0))
cd $dir

make $JOBS

release_dir=$dir/target/release
$MINGW && release_dir=${release_dir}-mingw
$ON_KEY && release_dir=${release_dir}-onkey
$DEBIAN && release_dir=${release_dir}-debian
test -d $release_dir && rm -rf $release_dir

BIN=$release_dir/data/bin
EXE=$release_dir/data/share/pwdmgr/exe
DOC=$release_dir/data/share/doc/pwdmgr
CONF=$release_dir/config/pwdmgr

for dir in $BIN $EXE $DOC $CONF
do
    mkdir -p $dir
done

umask 222

for src in bin/pwdmgr_*
do
    tgt=$BIN/$(basename $src)
    if $ON_KEY; then
        sed 's|^dist=.*$|home=$(dirname $(dirname $(dirname $(readlink -f $0)))); echo home=$home\nXDG_DATA_HOME=$home/local/share; export XDG_DATA_HOME\nXDG_CONFIG_HOME=$home/config; export XDG_CONFIG_HOME\nXDG_CACHE_HOME=$home/cache; export XDG_CACHE_HOME\nexe=$XDG_DATA_HOME/pwdmgr/exe|;s| \$prop$| \$1|g' < $src > $tgt
    else
        sed 's|^dist=.*$|exe=$(dirname $(dirname $(readlink -f $0)))/share/pwdmgr/exe|;s| \$prop$| \$1|g' < $src > $tgt
    fi
    chmod a+x $tgt
done

cp -a debian $release_dir/
sed "s/#DATE#/$(date -R)/" -i $release_dir/debian/changelog

cp exe/* $EXE/
cp COPYING README.md $DOC/
cp $release_dir/debian/changelog $DOC/Changelog
cp conf/pwdmgr-local.properties $DOC/sample-local-config.rc
cp conf/pwdmgr-remote-curl.properties $DOC/sample-remote-curl-config.rc
cp conf/pwdmgr-remote-scp.properties $DOC/sample-remote-scp-config.rc
cp conf/pwdmgr-remote.properties $CONF/config.rc
cp conf/*.rc $CONF/

if $ON_KEY; then
    cat <<EOF
#!/bin/sh

dir=\$(dirname \$(readlink -f \$0))

if test -z "\$1"; then
    echo "Please provide the install directory, which will behave as a portable HOME" >&2
    exit 1
fi

mkdir -p "\$1"/local
mkdir -p "\$1"/config/pwdmgr
mkdir -p "\$1"/cache/pwdmgr

cp -a \$dir/data/*   "\$1"/local/

for src in \$dir/config/pwdmgr/*.rc; do
    tgt="\$1"/\${src#\$dir/}
    if test -e \$tgt; then
        echo "There is already a config file named \$tgt -- not overriding."
        echo " The new config file is installed as \$tgt.pkg (please check)"
        cp -f \$src \$tgt.pkg
    else
        cp \$src \$tgt
    fi
done

chmod +w "\$1"/config/pwdmgr/*.rc
EOF

else

    cat <<EOF
#!/bin/sh

dir=\$(dirname \$(readlink -f \$0))

if test \$(id -u) -eq 0; then
    echo Installing as root
    PREFIX_BIN=\${PREFIX:-/usr/local}/bin     # for package install:
    PREFIX_DATA=\${PREFIX:-/usr/local}/share  #  - set \$PREFIX to /usr
    CONFIG=\${CONFIG:-/usr/local/etc}         #  - set \$CONFIG to /etc/xdg
    binmod=555
else
    echo Installing as user \$USER
    PREFIX_BIN=\${PREFIX:-\$HOME/.local}/bin
    PREFIX_DATA=\${PREFIX:-\$HOME/.local}/share
    CONFIG=\${CONFIG:-\$HOME/.config}
    binmod=500
fi

mkdir -p \$PREFIX_BIN
mkdir -p \$PREFIX_DATA/doc/pwdmgr
mkdir -p \$PREFIX_DATA/pwdmgr
mkdir -p \$CONFIG/pwdmgr

for src in \$dir/data/bin/*
do
    tgt=\$PREFIX_BIN/\${src#\$dir/data/bin/}
    test -e \$tgt && rm -f \$tgt
    sed 's|^exe=.*\$|exe='"\$PREFIX_DATA/pwdmgr/exe"'|' < \$src > \$tgt
    chmod \$binmod \$tgt
done

for dirsrc in \$dir/data/share/pwdmgr \$dir/data/share/doc/pwdmgr
do
    for src in \$dirsrc/*; do
        tgt=\$PREFIX_DATA/\${src#\$dir/data/share/}
        test -d \$tgt && rm -rf \$tgt
        cp -rf \$src \$tgt
    done
done

for src in \$dir/config/pwdmgr/*
do
    tgt=\$CONFIG/\${src#\$dir/config/}
    if test -e \$tgt; then
        echo "There is already a config file named \$tgt -- not overriding."
        echo " The new config file is installed as \$tgt.pkg (please check)"
        cp -f \$src \$tgt.pkg
    else
        cp \$src \$tgt
    fi
done

if test \$(id -u) -ne 0; then
    chmod u+w \$CONFIG/pwdmgr/*.rc
fi
EOF
fi >$release_dir/install.sh

chmod a+x $release_dir/install.sh
