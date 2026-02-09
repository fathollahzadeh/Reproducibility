#!/bin/bash

database=$1
work_load_path=$2
query=$3
log_file_name=$4

root_path="$(pwd)"
CMD="${root_path}/setup/Baselines/duckdb/build/release/duckdb"
db="${root_path}/data/duckdb/${database}"

sync
echo 3 | sudo tee /proc/sys/vm/drop_caches > /dev/null

exp_path="$(pwd)"
result_log="${exp_path}/log/DuckDB/${database}/${query}.txt"

mkdir -p "${exp_path}/log"
mkdir -p "${exp_path}/log/DuckDB"
mkdir -p "${exp_path}/log/DuckDB/${database}"

echo " ***DuckDB: Database [${database}] -- Query [query ${query}]"
for it in $(seq 1 $iteration); do
rm -rf ${result_log}

start=$(date +%s%N)

$CMD ${db} <<EOF
.output ${result_log} 
.read "${work_load_path}${query}.sql" 
EOF

end=$(date +%s%N)

echo ${query}","${database}",DuckDB,"$it","$((($end - $start) / 1000000)) >>$log_file_name

done    