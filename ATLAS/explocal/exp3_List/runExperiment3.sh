#!/bin/bash

dataset=$1
dbms=$2
scale=$3

exp_path="$(pwd)"
log_fname="runExperiment3"

work_load_SQL="${exp_path}/workload/${dbms}/${dataset}"
CMD="./explocal/exp3_List/runExperiment3-${dataset}.sh"

$CMD ${dbms} ${scale} ${work_load_SQL} ${log_fname}