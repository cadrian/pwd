#!/usr/bin/env bash

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ #
#                                                                        #
# A simple sanity check of the project                                   #
#                                                                        #
# See also: bootstrap.sh                                                 #
#                                                                        #
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ #

export CLASS_CHECK=yes
exec $(dirname $(readlink -f $0))/bootstrap.sh "$@"
