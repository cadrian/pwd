#!/usr/bin/env bash

target=$1
name=${target%.ace}
exe=$name.exe
CLASS=$(echo $name | tr '[a-z]' '[A-Z]')

clean=${2:+no}
clean=${clean:-yes}

cat > $target <<EOF
system "$exe"

root
    $CLASS:make

default
    assertion(boost)
    collect(yes)
    debug(no)
    trace(no)
    verbose(no)

cluster
    pwdmgr: "src/loadpath.se"
    liberty: "\${path_liberty}src/loadpath.se"

generate
    no_strip(no)
    no_split(yes)
    clean($clean)

end
EOF
