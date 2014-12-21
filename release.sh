#!/usr/bin/env bash

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ #
#                                                                        #
# Make a pwd binary release                                              #
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
$DEBIAN && release_dir=${release_dir}-debian/pwd
rm -rf $release_dir

BIN=$release_dir/data/bin
EXE=$release_dir/data/lib/pwd/exe
DOC=$release_dir/data/share/doc/pwd
CONF=$release_dir/config/pwd/conf
TMPL=$release_dir/config/pwd/templates

for d in $BIN $EXE $DOC $CONF $TMPL
do
    mkdir -p $d
done

umask 222

for src in bin/pwd_*
do
    tgt=$BIN/$(basename $src)
    if $ON_KEY; then
        sed 's|^dist=.*$|home=$(dirname $(dirname $(dirname $(readlink -f $0)))); echo home=$home\nXDG_DATA_HOME=$home/local/share; export XDG_DATA_HOME\nXDG_CONFIG_HOME=$home/config; export XDG_CONFIG_HOME\nXDG_CACHE_HOME=$home/cache; export XDG_CACHE_HOME\nexe=$XDG_DATA_HOME/pwd/exe|;s| \$prop$| \$1|g' < $src > $tgt
    else
        sed 's|^dist=.*$|exe=$(dirname $(dirname $(readlink -f $0)))/lib/pwd/exe|;s| \$prop$| \$1|g' < $src > $tgt
    fi
    chmod a+x $tgt
done

cp -a debian $release_dir/
version=$($dir/version.sh)
sed "s/#DATE#/$(date -R)/;s/#SNAPSHOT#/~${version#*~}/" -i $release_dir/debian/changelog

cp exe/* $EXE/
cp COPYING README.md $DOC/
cp $release_dir/debian/changelog $DOC/Changelog
cp conf/pwd-local.properties $DOC/sample-local-config.rc
cp conf/pwd-remote-curl.properties $DOC/sample-remote-curl-config.rc
cp conf/pwd-remote-scp.properties $DOC/sample-remote-scp-config.rc
cp conf/pwd-remote.properties $CONF/config.rc
cp conf/*.rc $CONF/
cp templates/*.html $TMPL/

if $DEBIAN; then
    sed -i 's!^template.path =.*$!template.path = /usr/share/pwd/templates!' $CONF/config.rc
fi

if $ON_KEY; then
    cat <<EOF
#!/bin/sh

dir=\$(dirname \$(readlink -f \$0))

if test -z "\$1"; then
    echo "Please provide the install directory, which will behave as a portable HOME" >&2
    exit 1
fi

mkdir -p "\$1"/local
mkdir -p "\$1"/config/pwd
mkdir -p "\$1"/cache/pwd

cp -a \$dir/data/*   "\$1"/local/

for src in \$dir/config/pwd/*.rc; do
    tgt="\$1"/\${src#\$dir/}
    if test -e \$tgt; then
        echo "There is already a config file named \$tgt -- not overriding."
        echo " The new config file is installed as \$tgt.pkg (please check)"
        cp -f \$src \$tgt.pkg
    else
        cp \$src \$tgt
    fi
done

chmod +w "\$1"/config/pwd/*.rc
EOF

else

    cat <<EOF
#!/bin/sh

dir=\$(dirname \$(readlink -f \$0))

if test \$(id -u) -eq 0; then
    echo Installing as root
    PREFIX_BIN=\${PREFIX:-/usr/local}/bin     # for package install:
    PREFIX_EXE=\${PREFIX:-/usr/local}/lib     #  - set \$PREFIX to /usr
    PREFIX_DATA=\${PREFIX:-/usr/local}/share  #  - set \$PREFIX to /usr
    CONFIG=\${CONFIG:-/usr/local/etc}         #  - set \$CONFIG to /etc/xdg
    binmod=555
else
    echo Installing as user \$USER
    PREFIX_BIN=\${PREFIX:-\$HOME/.local}/bin
    PREFIX_EXE=\${PREFIX:-\$HOME/.local}/lib
    PREFIX_DATA=\${PREFIX:-\$HOME/.local}/share
    CONFIG=\${CONFIG:-\$HOME/.config}
    binmod=500
fi

mkdir -p \$PREFIX_BIN
mkdir -p \$PREFIX_DATA/pwd/templates
mkdir -p \$PREFIX_DATA/doc/pwd
mkdir -p \$PREFIX_EXE/pwd
mkdir -p \$CONFIG/pwd

for src in \$dir/data/bin/*
do
    tgt=\$PREFIX_BIN/\${src#\$dir/data/bin/}
    rm -f \$tgt
    sed 's|^exe=.*\$|exe='"\$PREFIX_EXE/pwd/exe"'|' < \$src > \$tgt
    chmod \$binmod \$tgt
done

for dirsrc in \$dir/data/share/pwd \$dir/data/share/doc/pwd
do
    for src in \$dirsrc/*; do
        tgt=\$PREFIX_DATA/\${src#\$dir/data/share/}
        rm -rf \$tgt
        cp -rf \$src \$tgt
    done
done

for dirsrc in \$dir/data/lib/pwd
do
    for src in \$dirsrc/*; do
        tgt=\$PREFIX_EXE/\${src#\$dir/data/lib/}
        rm -rf \$tgt
        cp -rf \$src \$tgt
    done
done

for src in \$dir/config/pwd/conf/*
do
    tgt=\$CONFIG/pwd/\${src#\$dir/config/pwd/conf}
    if test -e \$tgt; then
        echo "There is already a config file named \$tgt -- not overriding."
        echo " The new config file is installed as \$tgt.pkg (please check)"
        cp -f \$src \$tgt.pkg
    else
        cp \$src \$tgt
    fi
done

for src in \$dir/config/pwd/templates/*
do
    tgt=\$PREFIX_DATA/pwd/templates/\${src#\$dir/config/pwd/templates}
    if test -e \$tgt; then
        echo "There is already a config file named \$tgt -- not overriding."
        echo " The new config file is installed as \$tgt.pkg (please check)"
        cp -f \$src \$tgt.pkg
    else
        cp \$src \$tgt
    fi
done

if test \$(id -u) -ne 0; then
    chmod u+w \$CONFIG/pwd/conf/*.rc
fi
EOF
fi >$release_dir/install.sh

chmod a+x $release_dir/install.sh
