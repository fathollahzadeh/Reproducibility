#!/bin/bash

dataset=$1
dbms=$2

exp_path="$(pwd)"

workload_path="${exp_path}/workload/${dbms}/${dataset}"
rewrite_path="${exp_path}/workload/${dbms}/${dataset}-LLM2Rule"
output_path_verify="${exp_path}/workload/${dbms}/${dataset}-LLM2Rule-select"

rm -rf ${output_path_verify}
mkdir -p ${output_path_verify}

verify_log_path="${exp_path}/results/Experiment1-Verify-${dataset}-${dbms}.dat"

cd "${exp_path}/setup/Baselines/Workload"
source venv/bin/activate

CMD="python main_verify_LLM2Rule.py --workload-path ${workload_path} \
                    --database-name ${dataset} \
                    --dbms ${dbms} \
                    --rewrite-path ${rewrite_path} \
                    --verify-log-path ${verify_log_path} \
                    --output-path-verify ${output_path_verify}"

$CMD