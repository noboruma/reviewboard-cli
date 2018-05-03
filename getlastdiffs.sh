#!/bin/bash

source ~/.reviewboardrc
TMPDIR="/tmp"
rbid=$1

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
    wget --no-check-certificate $original_file -O $outFolder/$fileid -q --show-progress &
    pids="$pids $!"
    wget --no-check-certificate $patched_file -O $outFolder/$fileid.patch -q --show-progress &
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

echo "diffs located at $outFolder"
