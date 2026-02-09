#!/bin/bash

dataset=$1
workload_path=$2
dbms=$3
llm_model=$4

exp_path="$(pwd)"

date=$(date '+%Y-%m-%d-%H-%M-%S')

template_path="${exp_path}/workload/${dbms}/${dataset}-template"
template_rewrite_path="${exp_path}/archive/SIGMOD2026/LLM-workloads/${dbms}/V2/${dataset}/${llm_model}"
workload_output="${exp_path}/workload/${dbms}/${dataset}-${llm_model}"

rm -rf $workload_output
mkdir -p ${workload_output}

if [ $dataset == "publicbibenchmark" ]; then
    workload_output="${workload_output}/queries"
    mkdir -p "${workload_output}"
fi 

log_file_name="${exp_path}/results/Experiment1_Reconstruct.dat"

if [ ! -f $log_file_name ]; then
    echo "dataset_name,dbms,llm_model,time" > $log_file_name
fi

cd "${exp_path}/setup/Baselines/ReSequel"
source venv/bin/activate

SCRIPT="python main.py --dataset-name ${dataset} \
                       --dbms ${dbms} \
                       --reconstruct \
                       --workload-path ${workload_path} \
                       --template-path ${template_path} \
                       --template-rewrite-path ${template_rewrite_path} \
                       --workload-output ${workload_output}"

start=$(date +%s%N)
$SCRIPT
end=$(date +%s%N)

echo ${dataset}","${dbms}","${llm_model}","$((($end - $start) / 1000000)) >>$log_file_name

