#!/usr/bin/env bash

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ #
#                                                                        #
# Build a C-generated source package to help package maintainers to      #
# install pwd without having to install LibertyEiffel first              #
#                                                                        #
# See also: release.sh, deploy.sh                                        #
#                                                                        #
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ #

set -e
set -u

dir=$(dirname $(readlink -f $0))
cd $dir

EXE=${EXE:-"server menu console webclient"}

bootstrap_dir=$dir/target/bootstrap
test -d $bootstrap_dir && rm -rf $bootstrap_dir
mkdir -p $bootstrap_dir/bin
mkdir -p $bootstrap_dir/c
mkdir -p $bootstrap_dir/eiffel

version=$($dir/version.sh)
cat > $bootstrap_dir/eiffel/version.e <<EOF
-- Generated file, don't edit!
-- $(date -R)
expanded class VERSION

feature {ANY}
   version: FIXED_STRING is
      once
         Result := "$version".intern
      end

end
EOF

for src in bin/pwd_*
do
    tgt=$bootstrap_dir/bin/$(basename $src)
    sed 's|^dist=.*$|exe=$(dirname $(dirname $(readlink -f $0)))/lib/pwd/exe|;s| \$prop$||g' < $src > $tgt
    chmod a+x $tgt
done

for d in conf web COPYING README.md
do
    cp -a $d $bootstrap_dir/
done

MAKEFILE_BOOT=$bootstrap_dir/Makefile
cat > $MAKEFILE_BOOT <<EOF
#!/usr/bin/env make -f

.PHONY: all clean install
.SILENT:

ifdef DESTDIR
PREFIX    ?= \$(DESTDIR)/usr
CONFIG    ?= \$(DESTDIR)/etc
else
PREFIX    ?= /usr/local
CONFIG    ?= /usr/local/etc
endif

all:$(for exe in $EXE; do printf ' %s' exe/$exe; done; echo)
EOF


while read class; do
    mkdir -p $dir/test/testable/$(dirname "$class")
    base=$(echo "$class" | sed 's!\.e$!!;s!_def$!!')
    expect=$dir/test/testable/${base}_expect.e
    mock=$dir/test/testable/${base}_mock.e
    source=$dir/src/$class

    rm -f $expect $mock
    se mock --expect $expect --mock $mock $source

done <<EOF
channel/channel_factory_def.e
channel/client_channel.e
channel/server_channel.e
config/shared_def.e
extern/extern_def.e
EOF


for exe in $EXE
do
    mkdir -p $bootstrap_dir/c/$exe
    ace=$exe.ace
    ./make_ace.sh $ace dontclean
    if [ ${CLASS_CHECK:-no} = yes ]; then
        if [ ${DEBUG_C2C:-no} = yes ]; then
            . <(se -environment | sed 's/^/export /g')
            echo Debugging class checking for $exe using $SE_TOOL_C2C
            gdb $SE_TOOL_CLASS_CHECK --args $SE_TOOL_CLASS_CHECK $ace
        else
            echo Checking $exe
            se class_check $ace || exit $?
        fi
    else
        se clean $ace

        if [ ${DEBUG_C2C:-no} = yes ]; then
            . <(se -environment | sed 's/^/export /g')
            echo Debugging compilation for $exe using $SE_TOOL_C2C
            gdb $SE_TOOL_C2C --args $SE_TOOL_C2C $ace
        else
            echo Compiling $exe
            se c2c $ace || exit $?
        fi
        test -e $exe.make || exit 1

        {
            echo
            echo "exe/$exe: exe "$(ls -1 $exe*.c | sed 's!^!c/'$exe'/!;s!\.c$!.o!')
            tail -1 $exe.make | sed 's!gcc!$(CC)!g;s!'$exe'.exe!$@!;s!'$exe'!c/'$exe'/'$exe'!g' | awk '{printf("\t%s\n", $0)}'
        } >> $MAKEFILE_BOOT

        rm $ace $exe.id $exe.make
        mv *.[ch] $bootstrap_dir/c/$exe/
    fi
done

if [ ${CLASS_CHECK:-no} = yes ]; then
    exit 0
fi

{
    echo
    echo "%.o: %.c"
    printf '\t%s\n' '$(CC) -pipe -g -c -x c $< -o $@'
    echo
    echo "exe:"
    printf '\t%s\n' 'mkdir exe'
    echo
    echo "clean:"
    printf '\t%s\n' 'rm -rf exe'
    echo
    echo "install: all"
    printf '\tinstall -d $(PREFIX)\n'
    printf '\tinstall -d $(PREFIX)/bin\n'
    printf '\tinstall -d $(PREFIX)/lib\n'
    printf '\tinstall -d $(PREFIX)/lib/pwd\n'
    printf '\tinstall -d $(PREFIX)/lib/pwd/exe\n'
    printf '\tinstall -d $(PREFIX)/share\n'
    printf '\tinstall -d $(PREFIX)/share/doc\n'
    printf '\tinstall -d $(PREFIX)/share/doc/pwd\n'
    printf '\tinstall -d $(PREFIX)/share/pwd\n'
    printf '\tinstall -d $(PREFIX)/share/pwd/web\n'
    printf '\tinstall -d $(PREFIX)/share/pwd/web/templates\n'
    printf '\tinstall -d $(PREFIX)/share/pwd/web/static\n'
    printf '\tinstall -d $(CONFIG)\n'
    printf '\tinstall -d $(CONFIG)/pwd\n'
    for exe in $EXE
    do
        printf '\tinstall -m555 exe/%s $(PREFIX)/lib/pwd/exe/\n' $exe
    done
    for bin in bin/pwd_*
    do
        printf '\tinstall -m555 %s $(PREFIX)/bin/\n' $bin
    done
    printf '\tinstall -b -m444 conf/pwd-remote.properties $(CONFIG)/pwd/config.rc\n'
    printf '\tinstall -b -m444 conf/*.rc $(CONFIG)/pwd/\n'
    printf '\tinstall -m444 conf/pwd-local.properties $(PREFIX)/share/doc/pwd/sample-local-config.rc\n'
    printf '\tinstall -m444 conf/pwd-remote-curl.properties $(PREFIX)/share/doc/pwd/sample-remote-curl-config.rc\n'
    printf '\tinstall -m444 conf/pwd-remote-scp.properties $(PREFIX)/share/doc/pwd/sample-remote-scp-config.rc\n'
    printf '\tinstall -m444 README.md $(PREFIX)/share/doc/pwd/\n'
    for template in web/templates/*
    do
        printf '\tinstall -m444 %s $(PREFIX)/share/pwd/web/templates/\n' $template
    done
    for template in web/static/*
    do
        printf '\tinstall -m444 %s $(PREFIX)/share/pwd/web/static/\n' $template
    done
} >> $MAKEFILE_BOOT

chmod +x $MAKEFILE_BOOT

# echo '~~8<~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~'
# cat $MAKEFILE_BOOT
# echo '~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~>8~~'

cat > $bootstrap_dir/c/README <<EOF
Those files were generated using Liberty Eiffel
http://www.liberty-eiffel.org

Original source:
http://github.com/cadrian/pwd
EOF

cat > $bootstrap_dir/install_local.sh <<EOF
#!/bin/sh
PREFIX=$HOME/.local CONFIG=$HOME/.config make install
EOF
chmod +x $bootstrap_dir/install_local.sh
