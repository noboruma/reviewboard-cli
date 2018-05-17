#!/bin/bash
# Prepare diff command to be run manually

source ~/.reviewboardrc
initdir=$1

args=""
editcmd="edit"
commonroot=${2-'mat'}

for fp in `find $initdir -name '*.old'`;
do
    dir=`dirname $fp`
    reldir=`echo "$dir" | sed "s/^.*$commonroot/$commonroot/g"`
    file=`basename ${fp%.*}`
    if [ -z "$args" ]; then
        args="edit $reldir/$file | vert diffpatch $dir/`basename $file`.patch"
    else
        args="$args  | tabedit $reldir/$file | vert diffpatch $dir/`basename $file`.patch"
    fi
done

if [ -x "$(command -v xclip)" ]; then
    echo "copied into clipboard"
    echo "vimdiff -c '$args'" | xclip -sel clip
    echo "vimdiff -c '$args'"
else
    echo "Copy the following"
    echo "vimdiff -c '$args'"
fi

echo "Next step: go to a valid sandbox and paste the result"
