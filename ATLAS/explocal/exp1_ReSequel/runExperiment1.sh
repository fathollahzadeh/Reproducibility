#!/bin/bash

op=$1
dataset=$2
dbms=$3
scale=$4
llm_model=$5
runner_dbms=$6
sample_fraction=$7
exp_path="$(pwd)"

catalog_dir="${exp_path}/catalog"
mkdir -p ${catalog_dir}

if [ $dataset == "tpcds" ] || [ $dataset == "tpch" ]; then
    catalog_path="${catalog_dir}/${dataset}-s${scale}"
else 
    catalog_path="${catalog_dir}/${dataset}"
fi 

mkdir -p ${catalog_path}

workload_path="${exp_path}/workload/${dbms}/${dataset}"

CMDBuildCatalog=./explocal/exp1_ReSequel/runExperiment1-BuildCatalog.sh
CMDTemplatization=./explocal/exp1_ReSequel/runExperiment1-Templatization.sh
CMDReconstruct=./explocal/exp1_ReSequel/runExperiment1-Reconstruct.sh
CMDLabeling=./explocal/exp1_ReSequel/runExperiment1-Label.sh
CMDVerify=./explocal/exp1_ReSequel/runExperiment1-Verify.sh
CMDVerifyOR=./explocal/exp1_ReSequel/runExperiment1-Verify-OR.sh
CMDDownsampling=./explocal/exp1_ReSequel/runExperiment1-Downsampling.sh
CMDJudge=./explocal/exp1_ReSequel/runExperiment1-Judge.sh
CMDImplement="./explocal/exp1_ReSequel/runExperiment1-Implement.sh ${dataset} ${catalog_path} ${dbms}"
CMDReSequel="./explocal/exp1_ReSequel/runExperiment1-ReSequel.sh ${dataset} ${catalog_path} ${llm_model} ${dbms}"


if [ $op == "BuildCatalog" ]; then
    $CMDBuildCatalog ${dataset} ${catalog_path}

elif [ $op == "Templatization" ]; then  
    $CMDTemplatization ${dataset} ${workload_path} ${dbms}  

elif [ $op == "Generate" ]; then
    export generate_list="--query-list"
    workload_path="${exp_path}/workload/${dbms}/${dataset}-template"
    $CMDReSequel ${workload_path}

elif [ $op == "Reconstruct" ]; then  
    $CMDReconstruct ${dataset} ${workload_path} ${dbms} ${llm_model} 

elif [ $op == "Labeling" ]; then  
    $CMDLabeling ${dataset} ${workload_path} ${dbms} ${llm_model}     

elif [ $op == "Verify" ]; then  
    $CMDVerify ${dataset} ${workload_path} ${dbms} ${llm_model} ${runner_dbms}

elif [ $op == "VerifyOR" ]; then  
    $CMDVerifyOR ${dataset} ${workload_path} ${dbms} ${llm_model} ${runner_dbms}

elif [ $op == "Downsampling" ]; then  
    $CMDDownsampling ${dataset} ${workload_path} ${dbms} ${llm_model} ${catalog_path} ${sample_fraction}

elif [ $op == "Judge" ]; then  
    workload_path="${exp_path}/workload/${dbms}/${dataset}-template"
    $CMDJudge  ${dataset} ${catalog_path} ${llm_model} ${dbms}  ${workload_path}   

elif [ $op == "Implement" ]; then
     $CMDImplement ${llm_model}

else     
    export generate_list=""
    $CMDReSQL ${llm_model}
fi 

