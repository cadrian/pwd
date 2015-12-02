#!/usr/bin/env bash

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ #
#                                                                        #
# Build a C-generated source package to help package maintainers to      #
# install pwd without having to install LibertyEiffel first              #
#                                                                        #
# See also: release.sh, deploy.sh                                        #
#                                                                        #
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ #

. <(se -environment | grep -v '^#' | sed 's/^/export /g')

set -e
set -u

dir=$(dirname $(readlink -f $0))
cd $dir

MOCK=${MOCK:-yes}
EXE=${EXE:-"server menu console webclient"}

bootstrap_dir=$dir/target/bootstrap
rm -rf $bootstrap_dir
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

./protocol.sh

if [ $MOCK == yes ]; then
    while read section class; do
        if [ "$section" == '#' ]; then
            wait
        else
            echo "Mocking $class"
            mkdir -p $dir/test/testable/$section
            source=$(se find --loadpath test/loadpath.se "$class" | awk '{print $1}')
            base=$dir/test/testable/$section/$(echo "$class" | tr '[A-Z]' '[a-z]' | sed 's/_def$//')
            expect=${base}_expect.e
            mock=${base}_mock.e

            rm -f $expect $mock
            se mock --loadpath test/loadpath.se --expect $expect --mock $mock $class &
        fi

    done <<EOF
channel CHANNEL_FACTORY_DEF
channel CLIENT_CHANNEL
channel SERVER_CHANNEL
config SHARED_DEF
#
extern ENVIRONMENT_DEF
extern EXTERN_DEF
extern FILE_LOCK
extern FILE_LOCKER_DEF
extern FILESYSTEM_DEF
extern PROCESSOR_DEF
#
vault VAULT_FILE
vault VAULT_IO
se BINARY_INPUT_STREAM
se TERMINAL_OUTPUT_STREAM
se PROCESS
#
EOF
fi

for exe in $EXE
do
    mkdir -p $bootstrap_dir/c/$exe
    ace=$exe.ace
    ./make_ace.sh $ace dontclean
    rm -f *.[ch]
    if [ ${CLASS_CHECK:-no} = yes ]; then
        case ${DEBUG_C2C:-no} in
            yes|gdb)
                echo "Debugging class checking for $exe using $SE_TOOL_C2C"
                gdb $SE_TOOL_CLASS_CHECK --args $SE_TOOL_CLASS_CHECK $ace
                ;;
            yes|gdb)
                echo "Debugging class checking memory for $exe using $SE_TOOL_C2C"
                valgrind --trace-children=yes --log-file=valgrind-$exe.log $SE_TOOL_CLASS_CHECK $ace
                ;;
            no)
                echo "Checking $exe"
                se class_check $ace
                ;;
            *)
                echo "Unknown DEBUG_C2C=$DEBUG_C2C" >&2
                exit 1
                ;;
        esac
    else
        se clean $ace

        case ${DEBUG_C2C:-no} in
            gdb|yes)
                echo "Debugging Eiffel compilation for $exe using $SE_TOOL_C2C"
                gdb $SE_TOOL_C2C --args $SE_TOOL_C2C $ace
                ;;
            valgrind)
                echo "Debugging Eiffel compilation memory for $exe using $SE_TOOL_C2C"
                valgrind --trace-children=yes --log-file=valgrind-$exe.log $SE_TOOL_C2C $ace
                ;;
            no)
                echo "Eiffel compiling $exe"
                se c2c $ace
                ;;
            *)
                echo Unknown DEBUG_C2C=$DEBUG_C2C >&2
                exit 1
                ;;
        esac
        test -e $exe.make

        {
            echo
            echo "exe/$exe: exe "$(ls -1 $exe*.c | sed 's!^!c/'$exe'/!;s!\.c$!.o!')
            tail -1 $exe.make | sed 's!gcc!$(CC)!g;s!'$exe'.exe!$@!;s!'$exe'!c/'$exe'/'$exe'!g' | awk '{printf("\t%s\n", $0)}'
        } >> $MAKEFILE_BOOT

        egrep -o $exe'[0-9]*\.c$' $exe.make | while read gen; do
            mv $gen $bootstrap_dir/c/$exe/
        done
        mv *.h $bootstrap_dir/c/$exe/
        rm $ace $exe.id $exe.make
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
http://github.com/cadrian/pwd/tree/$(git rev-parse HEAD)
EOF

cat > $bootstrap_dir/install_local.sh <<EOF
#!/bin/sh
PREFIX=$HOME/.local CONFIG=$HOME/.config make install
EOF
chmod +x $bootstrap_dir/install_local.sh
