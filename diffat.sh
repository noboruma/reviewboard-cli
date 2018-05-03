# Prepare diff command to be run manually
#!/bin/bash

source ~/.reviewboardrc
dir=$1

args=""
editcmd="edit"
for file in $dir/*.patch; do
    args="$args -c '$editcmd $file | vert diffsplit $dir/`basename $file .patch`'"
    editcmd="tabedit"
done

echo "vimdiff $args"
