#!/bin/bash

target=$1
name=${target%.ace}
exe=$name.exe
CLASS=$(echo $name | tr '[a-z]' '[A-Z]')

cat > $target <<EOF
system "$exe"

root
    $CLASS:main

default
    assertion(boost)
    collect(yes)
    debug(no)
    trace(no)
    verbose(no)

cluster
    pwdmgr: "src"
    liberty: "\${path_liberty}src/loadpath.se"

generate
    no_strip(no)
    no_split(yes)
    clean(yes)

end
EOF
