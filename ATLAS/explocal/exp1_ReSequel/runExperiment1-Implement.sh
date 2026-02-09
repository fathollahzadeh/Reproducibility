#!/bin/bash

dataset=$1
catalog_path=$2
dbms=$3
llm_model=$4

exp_path="$(pwd)"

date=$(date '+%Y-%m-%d-%H-%M-%S')
system_log="${exp_path}/system-log-${date}.dat"

output_path="${exp_path}/ReSQL-results/implement/${dataset}"
mkdir -p ${output_path}
result_log_path="${exp_path}/results/Experiment1_LLM_Implement.dat"

cd "${exp_path}/setup/Baselines/ReSQL"
source venv/bin/activate

SCRIPT="python main.py --dataset-name ${dataset} \
                       --dbms ${dbms} \
                       --implement \
                       --catalog-path ${catalog_path} \
                       --llm-model ${llm_model} \
                       --output-path ${output_path} \
                       --system-log ${system_log} \
                       --result-log-path ${result_log_path}"

echo ${SCRIPT}
$SCRIPT
