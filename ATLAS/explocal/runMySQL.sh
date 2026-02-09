#!/bin/bash

database=$1
work_load_path=$2
query=$3
log_file_name=$4

sync
echo 3 | sudo tee /proc/sys/vm/drop_caches > /dev/null

exp_path="$(pwd)"
result_log="${exp_path}/log/MySQL/${database}/${query}.txt"

mkdir -p "${exp_path}/log"
mkdir -p "${exp_path}/log/MySQL"
mkdir -p "${exp_path}/log/MySQL/${database}"

echo " ***MySQL: Database [${database}] -- Query [query ${query}]"
for it in $(seq 1 $iteration); do
    rm -rf ${result_log}

    start=$(date +%s%N)
    sudo mysql ${database} < "${work_load_path}${query}.sql" > ${result_log}
    end=$(date +%s%N)

    echo ${query}","${database}",MySQL,"$it","$((($end - $start) / 1000000)) >>$log_file_name
 done   