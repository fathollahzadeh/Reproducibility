#!/bin/bash

dataset=$1
exp_path="$(pwd)"

target_path="${exp_path}/data/${dataset}-parquet"

rm -rf ${target_path}
mkdir ${target_path}

cd $exp_path/setup/Baselines/SparkSQL
source venv/bin/activate

SCRIPT="python convert_data.py --dataset-name ${dataset} --target-path ${target_path}"

start=$(date +%s%N)
$SCRIPT
end=$(date +%s%N)