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
    comments_url=$4

    curl -k --create-dirs $input_oldfile -o $out_file.old -sS
    curl -k --create-dirs $input_newfile -o $out_file.new -sS

    ## Get and add comments
    comments=`curl -s -k --create-dirs $comments_url -H "Accept: application/json"`
    echo $comments

    total_comments=`echo $comments | jq '.total_results'`
    total_comments=`expr $total_comments - 1`
    for i in $(seq 0 $total_comments); do
        userid=`echo $comments | jq '.diff_comments['$i'].links.user.title'`
        timestamp=`echo $comments | jq '.diff_comments['$i'].timestamp'`
        status=`echo $comments | jq '.diff_comments['$i'].issue_status'`
        text=`echo $comments | jq '.diff_comments['$i'].text'`
        first_line=`echo $comments | jq '.diff_comments['$i'].first_line'`
        num_lines=`echo $comments | jq '.diff_comments['$i'].num_lines'`
        last_line=`expr $first_line + $num_lines`
        formated_comment=`echo "/* $timestamp, $userid: $text */"`
        if jq -e '.diff_comments['$i'].issue_opened' >/dev/null 2>&1 <<<"$comments"; then
            sed -i "${first_line}i /* @@ begin @@ */" $out_file.new
            sed -i "${first_line}i $formated_comment" $out_file.new
            sed -i "${last_line}i /* @@ end @@ */ " $out_file.new
        else
            sed -i "${first_line}i $formated_comment" $out_file.new
        fi
    done

    diff -u $out_file.old $out_file.new > $out_file.patch
    echo "$out_file.patch generated"
}

rbdiff=`curl -s -k $REVIEWBOARD_URL/api/review-requests/$rbid/diffs/ -H "Accept: application/json"`
echo $rbdiff
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
    comments=`echo $rbdifffiles | jq -r '.files['$i'].links.diff_comments.href'`
    original_file=`echo $rbdifffiles | jq -r '.files['$i'].links.original_file.href'`
    patched_file=`echo $rbdifffiles | jq -r '.files['$i'].links.patched_file.href'`

    destination_filename=`echo $rbdifffiles | jq -r '.files['$i'].dest_file'`
    destination_filename=`echo "$destination_filename" | sed "s/^.*$commonroot/$commonroot/g"`

    download_and_patch $original_file $patched_file $outFolder/$destination_filename $comments &
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
