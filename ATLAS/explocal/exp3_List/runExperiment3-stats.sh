#!/bin/bash

dbms=$1
scale=$2
work_load_path="$3/query"
log_fname=$4

exp_path="$(pwd)"
CMD="./explocal/run${dbms}.sh stats ${work_load_path}"

log_file_name="${exp_path}/results/${log_fname}-stats-${dbms}.dat"
echo "query_id,dataset,dbms,iteration,time" > ${log_file_name}

for v in $(seq 1 15); do
    $CMD 58-$v ${log_file_name}
    $CMD 120-$v ${log_file_name}
    $CMD 122-$v ${log_file_name}
    $CMD 126-$v ${log_file_name}
    $CMD 135-$v ${log_file_name}
    $CMD 108-$v ${log_file_name}
    $CMD 107-$v ${log_file_name}
    $CMD 68-$v ${log_file_name}
    $CMD 143-$v ${log_file_name}
    $CMD 30-$v ${log_file_name}
    $CMD 34-$v ${log_file_name}
    $CMD 140-$v ${log_file_name}
    $CMD 141-$v ${log_file_name}
    $CMD 142-$v ${log_file_name}
    $CMD 70-$v ${log_file_name}
    $CMD 57-$v ${log_file_name}
    $CMD 136-$v ${log_file_name}
    $CMD 105-$v ${log_file_name}
done

$CMD 58 ${log_file_name}
$CMD 120 ${log_file_name}
$CMD 122 ${log_file_name}
$CMD 126 ${log_file_name}
$CMD 135 ${log_file_name}
$CMD 108 ${log_file_name}
$CMD 107 ${log_file_name}
$CMD 68 ${log_file_name}
$CMD 143 ${log_file_name}
$CMD 30 ${log_file_name}
$CMD 34 ${log_file_name}
$CMD 140 ${log_file_name}
$CMD 141 ${log_file_name}
$CMD 142 ${log_file_name}
$CMD 70 ${log_file_name}
$CMD 57 ${log_file_name}
$CMD 136 ${log_file_name}
$CMD 105 ${log_file_name}