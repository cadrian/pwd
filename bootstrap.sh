#!/usr/bin/env bash

dir=$(dirname $(readlink -f $0))
cd $dir

EXE="server menu console"

bootstrap_dir=$dir/target/bootstrap
test -d $bootstrap_dir && rm -rf $bootstrap_dir
mkdir -p $bootstrap_dir/bin
mkdir -p $bootstrap_dir/c

for src in bin/pwdmgr_*
do
    tgt=$bootstrap_dir/bin/$(basename $src)
    sed 's|^dist=.*$|exe=$(dirname $(dirname $(readlink -f $0)))/share/pwdmgr|;s| \$prop$||g' < $src > $tgt
    chmod a+x $tgt
done

for d in conf COPYING README.md
do
    cp -a $d $bootstrap_dir/
done

MAKEFILE_BOOT=$bootstrap_dir/Makefile
cat > $MAKEFILE_BOOT <<EOF
#!/usr/bin/env make -f

.PHONY: all clean install
.SILENT:

PREFIX   ?= /usr/local
LINKFLAGS = -lm

all: $EXE
EOF

for exe in $EXE
do
    printf '\texe/%s\n' $exe
done >> $MAKEFILE_BOOT

for exe in $EXE
do
    {
        echo
        echo "exe/$exe: exe c/$exe.[ch]"
        printf '\t$(CC) -o $@ $< $(LINKFLAGS)\n'
    } >> $MAKEFILE_BOOT

    ace=$exe.ace
    ./make_ace.sh $ace dontclean
    se c2c $ace
    rm $ace $exe.id $exe.make
    mv $exe.[ch] $bootstrap_dir/c/
done

{
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
    printf '\tinstall -d $(PREFIX)/share\n'
    printf '\tinstall -d $(PREFIX)/share/pwdmgr\n'
    printf '\tinstall -d $(PREFIX)/share/doc\n'
    printf '\tinstall -d $(PREFIX)/share/doc/pwdmgr\n'
    printf '\tinstall -d $(PREFIX)/etc\n'
    for exe in $EXE
    do
        printf '\tinstall -m555 exe/%s $(PREFIX)/share/pwdmgr/\n' $exe
    done
    printf '\tinstall -m444 conf/pwdmgr-remote.properties $(PREFIX)/etc/pwdmgr.rc\n'
    printf '\tinstall -m444 conf/pwdmgr-local.properties $(PREFIX)/share/doc/pwdmgr/sample-local-pwdmgr.rc\n'
    printf '\tinstall -m444 conf/pwdmgr-remote-curl.properties $(PREFIX)/share/doc/pwdmgr/sample-remote-curl-pwdmgr.rc\n'
    printf '\tinstall -m444 conf/pwdmgr-remote-scp.properties $(PREFIX)/share/doc/pwdmgr/sample-remote-scp-pwdmgr.rc\n'
    printf '\tinstall -m444 README.md $(PREFIX)/share/doc/pwdmgr/\n'
    printf '\tinstall -m444 COPYING $(PREFIX)/share/doc/pwdmgr/\n'
} >> $MAKEFILE_BOOT

chmod +x $MAKEFILE_BOOT

cat > $bootstrap_dir/c/README <<EOF
Those files were generated using LibertyEiffel
(http://github.com/LibertyEiffel/Liberty)
EOF
