#!/bin/bash

dbms=$1
scale=$2
work_load_path="$3/query"
log_fname=$4

exp_path="$(pwd)"
CMD="./explocal/run${dbms}.sh hits ${work_load_path}"

log_file_name="${exp_path}/results/${log_fname}-hits-${dbms}.dat"
echo "query_id,dataset,dbms,iteration,time" > ${log_file_name}

for v in $(seq 1 15); do
    $CMD 33-$v ${log_file_name}
    $CMD 17-$v ${log_file_name}
    $CMD 29-$v ${log_file_name}
    $CMD 19-$v ${log_file_name}
    $CMD 34-$v ${log_file_name}
    $CMD 35-$v ${log_file_name}
    $CMD 32-$v ${log_file_name}
    $CMD 30-$v ${log_file_name}
    $CMD 10-$v ${log_file_name}
    $CMD 18-$v ${log_file_name}
    $CMD 9-$v ${log_file_name}
    $CMD 16-$v ${log_file_name}
    $CMD 6-$v ${log_file_name}
    $CMD 5-$v ${log_file_name}
    $CMD 36-$v ${log_file_name}
    $CMD 31-$v ${log_file_name}
    $CMD 41-$v ${log_file_name}
    $CMD 13-$v ${log_file_name}
    $CMD 42-$v ${log_file_name}
    $CMD 28-$v ${log_file_name}
    $CMD 15-$v ${log_file_name}
    $CMD 14-$v ${log_file_name}
    $CMD 37-$v ${log_file_name}
done  

$CMD 33 ${log_file_name}
$CMD 17 ${log_file_name}
$CMD 29 ${log_file_name}
$CMD 19 ${log_file_name}
$CMD 34 ${log_file_name}
$CMD 35 ${log_file_name}
$CMD 32 ${log_file_name}
$CMD 30 ${log_file_name}
$CMD 10 ${log_file_name}
$CMD 18 ${log_file_name}
$CMD 9 ${log_file_name}
$CMD 16 ${log_file_name}
$CMD 6 ${log_file_name}
$CMD 5 ${log_file_name}
$CMD 36 ${log_file_name}
$CMD 31 ${log_file_name}
$CMD 41 ${log_file_name}
$CMD 13 ${log_file_name}
$CMD 42 ${log_file_name}
$CMD 28 ${log_file_name}
$CMD 15 ${log_file_name}
$CMD 14 ${log_file_name}
$CMD 37 ${log_file_name}
