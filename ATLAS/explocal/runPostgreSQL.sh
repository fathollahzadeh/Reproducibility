#!/bin/bash

database=$1
work_load_path=$2
query=$3
log_file_name=$4

exp_path="$(pwd)"
result_log="${exp_path}/log/PosrgreSQL/${database}/${query}.txt"

mkdir -p "${exp_path}/log"
mkdir -p "${exp_path}/log/PosrgreSQL"
mkdir -p "${exp_path}/log/PosrgreSQL/${database}"

echo " ***PosrgreSQL: Database [${database}] -- Query [query ${query}]"

query_txt=`cat ${work_load_path}${query}.sql`
rm -rf "$result_log"
start=$(date +%s%N)
exe_time=$(
    {
      echo '\timing'            
      echo "$query_txt"
    } | psql -U postgres -d "${database}" -t 2>&1 | tee -a "$result_log" | grep 'Time' | awk '{print $2, $3}'
)
exe_time=$(echo "${exe_time}" | awk '{print $1}')
echo ${query}","${database}",PosrgreSQL,"$cur_iteration","$start","$exe_time >>$log_file_name 
