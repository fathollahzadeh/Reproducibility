#!/bin/bash

dbms=$1
scale=$2
work_load_path="$3/"
log_fname=$4

exp_path="$(pwd)"
CMD="./explocal/run${dbms}.sh imdb ${work_load_path}"

log_file_name="${exp_path}/results/${log_fname}-imdb-${dbms}.dat"
echo "query_id,dataset,dbms,iteration,time" > ${log_file_name}

for v in $(seq 1 15); do
    $CMD 20a-$v ${log_file_name}
    $CMD 20c-$v ${log_file_name}
    $CMD 20b-$v ${log_file_name}
    $CMD 29a-$v ${log_file_name}
    $CMD 16b-$v ${log_file_name}
    $CMD 19d-$v ${log_file_name}
    $CMD 17e-$v ${log_file_name}
    $CMD 17a-$v ${log_file_name}
    $CMD 126a-$v ${log_file_name}
done

$CMD 20a ${log_file_name}
$CMD 20c ${log_file_name}
$CMD 20b ${log_file_name}
$CMD 29a ${log_file_name}
$CMD 16b ${log_file_name}
$CMD 19d ${log_file_name}
$CMD 17e ${log_file_name}
$CMD 17a ${log_file_name}
$CMD 126a ${log_file_name}