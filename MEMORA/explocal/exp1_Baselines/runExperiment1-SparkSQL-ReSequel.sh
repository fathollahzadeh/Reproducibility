#!/bin/bash

dataset=$1
llm_model=$2
exp_path="$(pwd)"

output_path="${exp_path}/results/Experiment1_SparkSQL_${dataset}_${llm_model}"
data_path="${exp_path}/data/${dataset}-parquet"
workload_path="${exp_path}/workload/PostgreSQL/${dataset}-${llm_model}-select"

cd $exp_path/setup/Baselines/SparkSQL
source venv/bin/activate



for itr in $(seq 1 "$iteration"); do
    # sync
    # echo 3 | sudo tee /proc/sys/vm/drop_caches > /dev/null

    SCRIPT="python main.py \
        --dataset-name ${dataset} \
        --data-path ${data_path} \
        --workload-path ${workload_path} \
        --output-path ${output_path} \
        --iteration ${itr}"

    start=$(date +%s%N)
    $SCRIPT
    end=$(date +%s%N)
done    