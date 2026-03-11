#!/bin/bash

dataset=$1
exp_path="$(pwd)"

log_file_name="${exp_path}/results/Experiment1_SparkSQL_${dataset}.dat"

data_path="${exp_path}/data/${dataset}"
target_path="${exp_path}/data/${dataset}-parquet"
schema_path="${exp_path}/catalog/${dataset}/schema.json"

rm -rf ${target_path}
mkdir ${target_path}

cd $exp_path/setup/Baselines/SparkSQL
source venv/bin/activate

SCRIPT="python convert_data.py --dataset-name ${dataset} --data-path ${data_path} --target-path ${target_path} --schema-path ${schema_path}"


start=$(date +%s%N)
$SCRIPT
end=$(date +%s%N)

#echo ${dataset}",PosrgreSQL,"$((($end - $start) / 1000000)) >>$log_file_name