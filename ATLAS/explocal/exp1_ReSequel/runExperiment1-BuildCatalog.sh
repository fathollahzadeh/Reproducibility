#!/bin/bash

dataset=$1
catalog_path=$2
exp_path="$(pwd)"

log_file_name="${exp_path}/results/Experiment1_Catalog.dat"

cd "${exp_path}/setup/Baselines/ReSequel"
source venv/bin/activate

SCRIPT="python main.py --dataset-name ${dataset} \
                       --prepare-data-catalog \
                       --catalog-path ${catalog_path}"

start=$(date +%s%N)
$SCRIPT
end=$(date +%s%N)

echo ${dataset}",PosrgreSQL,"$((($end - $start) / 1000000)) >>$log_file_name
