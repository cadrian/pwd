#!/usr/bin/env bash

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ #
#                                                                        #
# Generate a complete version number, based on the date for snapshots.   #
#                                                                        #
# See also: bootstrap.sh, release.sh, deploy.sh                          #
#                                                                        #
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ #

dir=$(dirname $(readlink -f $0))
test -e $dir/.version || {
    echo $(
        if dpkg -s liberty-eiffel-tools >/dev/null 2>&1; then
            version=$(dpkg -s liberty-eiffel-tools | awk '/^Version:/ {print $2; exit}')
        else
            version=$(se --version | awk '$1 == "release" {print $2; exit}')
        fi
        head -n 1 $dir/debian/changelog | awk -F'[()]' '{print $2}' | \
            sed -r "s/#SNAPSHOT#/$(date -u +'~%Y%m%d%H%M%S')~liberty-eiffel-$version/"
        ) > $dir/.version
}
cat $dir/.version
