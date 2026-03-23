#!/bin/bash

# clean original results
rm -rf results/*;
mkdir -p results;

root_path="$(pwd)"

export iteration=1

CMDCalciteExp1=./explocal/exp1_Baselines/runExperiment1-Calcite.sh
CMDCatalogExp1=./explocal/exp1_Baselines/runExperiment1-Catalog.sh
CMDD2PExp1=./explocal/exp1_Baselines/runExperiment1-Data2Parquet.sh
CMDSparkSQLWorkloadExp1=./explocal/exp1_Baselines/runExperiment1-SparkSQL-Workload.sh
CMDSparkSQLReSequelExp1=./explocal/exp1_Baselines/runExperiment1-SparkSQL-ReSequel.sh
CMDRunVerify=./explocal/exp1_Baselines/runExperiment1-Verify-LLM2Rule.sh
CMDRunLLM2RuleReWrite=./explocal/exp1_Baselines/runExperiment1-LLM2Rule.sh


# $CMDRunVerify stats PostgreSQL

$CMDRunLLM2RuleReWrite stats PostgreSQL cc

#------------------------------------
# $CMDD2PExp1 tpch
# $CMDD2PExp1 imdb
# $CMDD2PExp1 stats
# $CMDD2PExp1 stats_ceb

# $CMDSparkSQLWorkloadExp1 tpch
# $CMDSparkSQLWorkloadExp1 imdb
# $CMDSparkSQLWorkloadExp1 stats
# $CMDSparkSQLWorkloadExp1 stats_ceb
# $CMDSparkSQLWorkloadExp1 stackoverflow

# $CMDSparkSQLReSequelExp1 tpch gemini-2.5-pro
# $CMDSparkSQLReSequelExp1 imdb gemini-2.5-pro
# $CMDSparkSQLReSequelExp1 stats gemini-2.5-pro
# $CMDSparkSQLReSequelExp1 stats_ceb gemini-2.5-pro
# $CMDSparkSQLReSequelExp1 stackoverflow gemini-2.5-pro




# clcite_exp1_log_fname="${root_path}/results/clcite_exp1.dat"
# echo "baseline,dataset_name,iteration,best_plan,enable_logical_rules,enable_physical_rules,time" > ${clcite_exp1_log_fname}

# for itr in {1..1}; do
    # $CMDExp1 tpch PostgreSQL $itr false true false $clcite_exp1_log_fname true
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
               
# done   
