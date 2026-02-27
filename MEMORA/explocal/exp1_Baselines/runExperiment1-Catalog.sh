#!/bin/bash

dataset=$1
exp_path="$(pwd)"

log_file_name="${exp_path}/results/Experiment1_Catalog_${dataset}.dat"

mkdir -p "${exp_path}/catalog"
mkdir -p "${exp_path}/catalog/${dataset}"
catalog_path="${exp_path}/catalog/${dataset}"

cd $exp_path/setup/Baselines/MEMORA/cpp/bin
SCRIPT="./minidb ${dataset} ${catalog_path}"

start=$(date +%s%N)
$SCRIPT
end=$(date +%s%N)

echo ${dataset}",PosrgreSQL,"$((($end - $start) / 1000000)) >>$log_file_name