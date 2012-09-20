#!/usr/bin/env bash

target=$1
name=${target%.ace}
exe=$name.exe
CLASS=$(echo $name | tr '[a-z]' '[A-Z]')

clean=${2:+no}
clean=${clean:-${DO_CLEAN:-yes}}

trace=no
rescue=yes
debug_pwd=no
debug_liberty=no
if [ $clean = yes ]; then
    no_strip=no
    no_split=yes
else
    no_strip=yes
    no_split=no
fi

case $name in
    console)
        #trace=yes
        #rescue=no
        #debug_pwd=yes
        #debug_liberty='"json/parser"); debug("socket"'
        ;;
    menu)
        #trace=yes
        #rescue=no
        #debug_pwd=yes
        #debug_liberty='"json/parser"); debug("socket"'
        ;;
    server)
        #trace=yes
        #rescue=no
        #debug_pwd=yes
        #debug_liberty='"json/parser"); debug("socket"'
        #debug_liberty='"socket"'
        ;;
esac

cat > $target <<EOF
system "$exe"

root
    $CLASS:make

default
    assertion(boost)
    collect(yes)
    debug(no)
    trace($trace)
    verbose(no)
    rescue($rescue)

cluster
    pwdmgr: "src/loadpath.se"
        default
            assertion(invariant)
            debug($debug_pwd)
        end

    liberty: "\${path_liberty}src/loadpath.se"
        default
            debug($debug_liberty)
        end

generate
    no_strip($no_strip)
    no_split($no_split)
    clean($clean)

end
EOF
