#!/usr/bin/env bash

dir=$(dirname $(readlink -f $0))
cd $dir

EXE="pwdsrv menu console"

bootstrap_dir=$dir/target/bootstrap
test -d $bootstrap_dir && rm -rf $bootstrap_dir
mkdir -p $bootstrap_dir/bin
mkdir -p $bootstrap_dir/c

for script in pwdmgr_*
do
    cp bin/$script $bootstrap_dir/bin/
done

for d in conf COPYING README.md
do
    cp -a $d $bootstrap_dir/
done

MAKEFILE_BOOT=$bootstrap_dir/Makefile
cat > $MAKEFILE_BOOT <<EOF
#!/usr/bin/env make -f

.PHONY: all clean
.SILENT:

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
        printf '\t%s\n' '$(CC) -o $@ $<'
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
} >> $MAKEFILE_BOOT

chmod +x $MAKEFILE_BOOT

cat > $bootstrap_dir/c/README <<EOF
Those files were generated using LibertyEiffel
(http://github.com/LibertyEiffel/Liberty)
EOF
