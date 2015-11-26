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
debug_extra=no
assert=${assert:-boost}
if [ $clean = yes ]; then
    no_strip=no
    no_split=yes
else
    no_strip=yes
    no_split=no
fi
verbose=${VERBOSE:-no}

case $name in
    console)
        #trace=yes
        #rescue=no
        #debug_pwd=yes
        #debug_liberty='"json/parser"); debug("socket"'
        #assert=no
        #no_strip=yes
        #clean=no
        ;;
    menu)
        #trace=yes
        #rescue=no
        #debug_pwd=yes
        #debug_liberty='"json/parser"); debug("socket"'
        #assert=require
        #no_strip=yes
        #clean=no
        ;;
    webclient)
        #trace=yes
        #rescue=no
        #debug_pwd=yes
        #debug_liberty='"json/parser"); debug("socket"'
        #assert=require
        #no_strip=yes
        #clean=no
        ;;
    server)
        #trace=yes
        #rescue=no
        #debug_pwd=yes
        #debug_liberty='"json/parser"); debug("socket"'
        #debug_liberty='"socket"'
        #assert=no
        #no_strip=yes
        #clean=no
        ;;
esac

path_liberty_core=$(se -environment|egrep '^path_(.+_)?core='|awk -F= '{print $1}')
path_liberty_extra=$(se -environment|egrep '^path_(.+_)?extra='|awk -F= '{print $1}')

if [[ -z "$path_liberty_core" ]]; then
    echo "Missing path_liberty_core" >&2
    se -environment
    exit 1
elif [[ -z "$path_liberty_extra" ]]; then
    echo "Missing path_liberty_extra" >&2
    se -environment
    exit 1
fi

cat > $target <<EOF
system "$exe"

root
    $CLASS:make

default
    assertion(boost)
    collect(yes)
    debug(no)
    trace($trace)
    verbose($verbose)
    rescue($rescue)

cluster
    generated: "target/bootstrap/eiffel"

    pwd: "src/loadpath.se"
        default
            assertion($assert)
            debug($debug_pwd)
        end

    testable: "src/testable"
        default
            assertion($assert)
            debug($debug_pwd)
        end

    liberty_core: "\${$path_liberty_core}loadpath.se"
        default
            debug($debug_liberty)
        end

    liberty_extra: "\${$path_liberty_extra}loadpath.se"
        default
            debug($debug_extra)
        end

generate
    no_strip($no_strip)
    no_split($no_split)
    clean($clean)

end
EOF
