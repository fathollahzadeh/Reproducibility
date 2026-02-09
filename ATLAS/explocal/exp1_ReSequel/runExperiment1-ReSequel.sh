#!/bin/bash

dataset=$1
catalog_path=$2
llm_model=$3
dbms=$4
template_path=$5

exp_path="$(pwd)"

date=$(date '+%Y-%m-%d-%H-%M-%S')
system_log="${exp_path}/system-log-${date}.dat"

output_path="${exp_path}/ReSequel-results/Rewrite/${dataset}"
mkdir -p "${exp_path}/ReSequel-results/Rewrite"
mkdir -p ${output_path}

result_log_path="${exp_path}/results/Experiment1-LLM-Rewrite-${dataset}-${dbms}.dat"

workload_output="${exp_path}/ReSequel-results/workload/${dbms}/${dataset}/${llm_model}"
mkdir -p "${exp_path}/ReSequel-results/workload"
mkdir -p "${exp_path}/ReSequel-results/workload/${dbms}"
mkdir -p "${exp_path}/ReSequel-results/workload/${dbms}/${dataset}"
mkdir -p "${exp_path}/ReSequel-results/workload/${dbms}/${dataset}/${llm_model}"

cd "${exp_path}/setup/Baselines/ReSequel"
source venv/bin/activate

SCRIPT="python main.py --dataset-name ${dataset} \
                       --dbms ${dbms} \
                       $generate_list \
                       --catalog-path ${catalog_path} \
                       --llm-model ${llm_model} \
                       --template-path ${template_path} \
                       --workload-output ${workload_output}
                       --output-path ${output_path} \
                       --system-log ${system_log} \
                       --result-log-path ${result_log_path}"

echo ${SCRIPT}
$SCRIPT
