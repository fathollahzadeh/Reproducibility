#!/bin/bash

dataset=$1
workload_path=$2
dbms=$3
exp_path="$(pwd)"

date=$(date '+%Y-%m-%d-%H-%M-%S')

workload_output="${exp_path}/workload/${dbms}/${dataset}-template"
rm -rf $workload_output
mkdir -p ${workload_output}

log_file_name="${exp_path}/results/Experiment1_Templatization.dat"

if [ ! -f $log_file_name ]; then
    echo "dataset_name,dbms,time" > $log_file_name
fi

if [ $dataset == "publickbibenchmark" ]; then
    workload_path="${workload_path}/queries"
fi

cd "${exp_path}/setup/Baselines/ReSequel"
source venv/bin/activate

SCRIPT="python main.py --dataset-name ${dataset} \
                       --dbms ${dbms} \
                       --templatization \
                       --workload-path ${workload_path} \
                       --workload-output ${workload_output}"

start=$(date +%s%N)
$SCRIPT
end=$(date +%s%N)

echo ${dataset}",${dbms},"$((($end - $start) / 1000000)) >>$log_file_name

