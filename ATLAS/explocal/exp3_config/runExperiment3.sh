#!/bin/bash

dataset=$1
dbms=$2
scale=$3
shared_buffers=$4
work_mem=$5

sync
echo 3 | sudo tee /proc/sys/vm/drop_caches > /dev/null

exp_path="$(pwd)"
log_fname="${exp_path}/results/runExperiment2-${dataset}-${dbms}-SB-${shared_buffers}-WM-${work_mem}"
query_log_fname="${exp_path}/log-baseline/${dbms}/${dataset}"

workload_path="${exp_path}/workload/${dbms}/${dataset}"
database_path="${exp_path}/data/duckdb"

cd "${exp_path}/setup/Baselines/Workload"
source venv/bin/activate

CMD="python main.py --workload-path ${workload_path} \
                    --database-name ${dataset} \
                    --database-path ${database_path} \
                    --dbms ${dbms} \
                    --iterations ${iteration} \
                    --query-log-path ${query_log_fname} \
                    --output-path ${log_fname}"

$CMD