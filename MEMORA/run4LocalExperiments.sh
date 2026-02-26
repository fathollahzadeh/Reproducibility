#!/bin/bash

# clean original results
rm -rf results/*;
mkdir -p results;

root_path="$(pwd)"

CMDExp1=./explocal/exp1_Baselines/runExperiment1-Calcite.sh

clcite_exp1_log_fname="${root_path}/results/clcite_exp1.dat"
echo "baseline,dataset_name,iteration,best_plan,enable_logical_rules,enable_physical_rules,time" > ${clcite_exp1_log_fname}

for itr in {1..1}; do
    $CMDExp1 tpch PostgreSQL $itr false true false $clcite_exp1_log_fname true
    # $CMDExp1 stackoverflow PostgreSQL $itr false true false $clcite_exp1_log_fname true
    # $CMDExp1 stackoverflow-1190 PostgreSQL $itr false true false $clcite_exp1_log_fname true
    # $CMDExp1 imdb PostgreSQL $itr false true false $clcite_exp1_log_fname true
    # $CMDExp1 dsb PostgreSQL $itr false true false $clcite_exp1_log_fname true
    # $CMDExp1 stats PostgreSQL $itr false true false $clcite_exp1_log_fname true
    # $CMDExp1 publicbibenchmark PostgreSQL $itr false true false $clcite_exp1_log_fname true
    # $CMDExp1 imdb_13k PostgreSQL $itr false true false $clcite_exp1_log_fname true
    # $CMDExp1 imdb_d PostgreSQL $itr false true false $clcite_exp1_log_fname true

 
    # $CMDExp1 tpch PostgreSQL $itr true true true $clcite_exp1_log_fname true
    # $CMDExp1 stackoverflow PostgreSQL $itr true true true $clcite_exp1_log_fname true
    # $CMDExp1 stackoverflow-1190 PostgreSQL $itr true true true $clcite_exp1_log_fname true
    # $CMDExp1 imdb PostgreSQL $itr true true true $clcite_exp1_log_fname true
    # $CMDExp1 dsb PostgreSQL $itr true true true $clcite_exp1_log_fname true
    # $CMDExp1 stats PostgreSQL $itr true true true $clcite_exp1_log_fname true
    # $CMDExp1 publicbibenchmark PostgreSQL $itr true true true $clcite_exp1_log_fname true
    # $CMDExp1 imdb_13k PostgreSQL $itr true true true $clcite_exp1_log_fname true
    # $CMDExp1 imdb_d PostgreSQL $itr true true true $clcite_exp1_log_fname true
               
done   
