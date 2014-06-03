#!/usr/bin/env bash

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ #
#                                                                        #
# Generate a complete version number, based on the date for snapshots.   #
#                                                                        #
# See also: bootstrap.sh, release.sh, deploy.sh                          #
#                                                                        #
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ #

dir=$(dirname $(readlink -f $0))
test -e $dir/.version || echo $(head -n 1 $dir/debian/changelog | awk -F'[()]' '{print $2}' | sed -r "s/#SNAPSHOT#/$(date -u +'~%Y%m%d%H%M%S')") > $dir/.version
cat $dir/.version
