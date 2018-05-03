#!/bin/bash
# Prepare diff command to be run manually

source ~/.reviewboardrc
initdir=$1

args=""
editcmd="edit"

for fp in `find $initdir -name '*.old'`;
do
    dir=`dirname $fp`
    file=`basename ${fp%.*}`
    if [ -z "$args" ]; then
        args="edit $file.old | vert diffsplit $dir/$file.new"
    else
        args="$args  | tabedit $file.old | vert diffsplit $dir/$file.new"
    fi
done

if [ -x "$(command -v xclip)" ]; then
    echo "copied into clipboard"
    echo "vimdiff -c '$args'" | xclip -sel clip
else
    echo "execute the following: "
    echo "vimdiff -c '$args'"
fi