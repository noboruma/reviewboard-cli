#!/bin/bash

source ~/.reviewboardrc
TMPDIR="/tmp"
rbid=$1
# commonroot used for patch application
commonroot=${2-'mat'}

function download_and_patch() {

    input_oldfile=$1
    input_newfile=$2

    out_file=$3

    curl -k --create-dirs $input_oldfile -o $out_file.old -sS
    curl -k --create-dirs $input_newfile -o $out_file.new -sS

    diff -u $out_file.old $out_file.new > $out_file.patch
    echo "$out_file.patch generated"
}

rbdiff=`curl -s -k $REVIEWBOARD_URL/api/review-requests/$rbid/diffs/ -H "Accept: application/json"`
last_diff=`echo $rbdiff | jq '.total_results'`
echo "This RB contains $last_diff diffs"
echo "Diff last diff against original"

rbdifffiles=`curl -s -k $REVIEWBOARD_URL/api/review-requests/$rbid/diffs/$last_diff/files/ -H "Accept: application/json"`

outFolder="$TMPDIR/rb$rbid"
mkdir -p $outFolder

pids=""
total_files=`echo $rbdifffiles | jq '.total_results'`
total_files=`expr $total_files - 1`
for i in $(seq 0 $total_files); do
    fileid=`echo $rbdifffiles | jq '.files['$i'].id'`
    original_file=`echo $rbdifffiles | jq -r '.files['$i'].links.original_file.href'`
    patched_file=`echo $rbdifffiles | jq -r '.files['$i'].links.patched_file.href'`

    destination_filename=`echo $rbdifffiles | jq -r '.files['$i'].dest_file'`
    destination_filename=`echo "$destination_filename" | sed "s/^.*$commonroot/$commonroot/g"`

    download_and_patch $original_file $patched_file $outFolder/$destination_filename &
    pids="$pids $!"
done

for pid in $pids; do
    wait $pid
    #if [ $? -eq 0 ]; then
    #    #echo "SUCCESS - Job $pid exited with a status of $?"
    #else
    #    #echo "FAILED - Job $pid exited with a status of $?"
    #fi
done

echo "diffs & downloads located at $outFolder"
