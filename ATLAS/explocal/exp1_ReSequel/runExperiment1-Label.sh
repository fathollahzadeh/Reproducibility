#!/bin/bash

dataset=$1
workload_path=$2
dbms=$3
llm_model=$4

exp_path="$(pwd)"

date=$(date '+%Y-%m-%d-%H-%M-%S')

log_file_name="${exp_path}/results/Experiment1-Labeling-${dataset}-${llm_model}.dat"

cd "${exp_path}/setup/Baselines/ReSequel"
source venv/bin/activate

SCRIPT="python main.py --dataset-name ${dataset} \
                       --dbms ${dbms} \
                       --labeling \
                       --llm-model ${llm_model} \
                       --workload-path ${workload_path} \
                       --result-log-path ${log_file_name}"

start=$(date +%s%N)
$SCRIPT
end=$(date +%s%N)
