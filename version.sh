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
        if dpkg -l liberty-eiffel-tools 2>/dev/null; then
            version=$(dpkg -l liberty-eiffel-tools | tail -n 1 | awk '{print $3}')
        else
            version=$(se --version | awk 'NR==4 {print $2;exit}')
        fi
        head -n 1 $dir/debian/changelog | awk -F'[()]' '{print $2}' | \
            sed -r "s/#SNAPSHOT#/$(date -u +'~%Y%m%d.%H%M%S')~liberty-eiffel-$version/"
        ) > $dir/.version
}
cat $dir/.version
