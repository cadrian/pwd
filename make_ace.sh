#!/bin/bash

target=$1
exe=${target%.ace}
CLASS=$(echo $exe | tr '[a-z]' '[A-Z]')

cat > $target <<EOF
system "bin/$exe"

root
    $CLASS:main

default
    assertion(boost)
    collect(yes)
    debug(no)
    trace(no)
    verbose(yes)

cluster
    pwdmgr: "src"
    liberty: "\${path_liberty}src/loadpath.se"

generate
    no_strip(no)
    no_split(yes)
    clean(yes)

end
EOF
