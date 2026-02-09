#!/bin/bash

dataset=$1
dbms=$2
scale=$3
llm_model=$4

exp_path="$(pwd)"
log_fname="runExperiment3-${llm_model}"

work_load_SQL="${exp_path}/ReSQL-results/workload/${dbms}/${dataset}/${llm_model}"
CMD="./explocal/exp3_List/runExperiment3-${dataset}.sh"

$CMD ${dbms} ${scale} ${work_load_SQL} ${log_fname}