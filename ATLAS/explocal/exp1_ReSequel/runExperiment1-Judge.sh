#!/bin/bash

dataset=$1
catalog_path=$2
llm_model=$3
dbms=$4
template_path=$5


exp_path="$(pwd)"

date=$(date '+%Y-%m-%d-%H-%M-%S')
system_log="${exp_path}/system-log-${date}.dat"

template_rewrite_path="${exp_path}/workload/${dbms}/${dataset}-template-${llm_model}"
workload_output="${exp_path}/workload/${dbms}/${dataset}-${llm_model}-Judge"
rm -rf $workload_output
mkdir -p ${workload_output}

output_path="${exp_path}/ReSequel-results/Judge/${dataset}"
mkdir -p "${exp_path}/ReSequel-results/Judge"
mkdir -p ${output_path}

result_log_path="${exp_path}/results/Experiment1-LLM-Judge-${dataset}-${dbms}.dat"

cd "${exp_path}/setup/Baselines/ReSequel"
source venv/bin/activate

SCRIPT="python main.py --dataset-name ${dataset} \
                       --dbms ${dbms} \
                       --judge \
                       --catalog-path ${catalog_path} \
                       --llm-model ${llm_model} \
                       --template-path ${template_path} \
                       --template-rewrite-path ${template_rewrite_path} \
                       --workload-output ${workload_output}
                       --output-path ${output_path} \
                       --system-log ${system_log} \
                       --result-log-path ${result_log_path}"

echo ${SCRIPT}
$SCRIPT
