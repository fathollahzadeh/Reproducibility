#!/bin/bash

dataset=$1
workload_path=$2
dbms=$3
llm_model=$4
runner_dbms=$5

# sync
# echo 3 | sudo tee /proc/sys/vm/drop_caches > /dev/null

exp_path="$(pwd)"

rewrite_path="${exp_path}/workload/${dbms}/${dataset}-${llm_model}"
output_path_verify="${exp_path}/workload/${dbms}/${dataset}-${llm_model}-verify"
output_path_select="${exp_path}/workload/${dbms}/${dataset}-${llm_model}-select"
database_path="${exp_path}/data/duckdb"

rm -rf ${output_path_verify}
rm -rf ${output_path_select}
mkdir -p ${output_path_verify}
mkdir -p ${output_path_select}

if [ $dataset == "publicbibenchmark" ]; then
    mkdir -p "${output_path_verify}/queries"
    mkdir -p "${output_path_select}/queries"
fi    

if [ $dbms == "PostgreSQL" ]; then
    ./initpgSQL.sh  
    sleep 10

elif [ $dbms == "MySQL" ]; then  
    ./initMySQL.sh   
    sleep 10 
fi 

verify_log_path="${exp_path}/results/Experiment1_Verify.dat"

cd "${exp_path}/setup/Baselines/Workload"
source venv/bin/activate

CMD="python main_verify.py --workload-path ${workload_path} \
                    --database-name ${dataset} \
                    --database-path ${database_path} \
                    --dbms ${dbms} \
                    --runner-dbms ${runner_dbms} \
                    --rewrite-path ${rewrite_path} \
                    --verify-log-path ${verify_log_path} \
                    --output-path-verify ${output_path_verify} \
                    --output-path-select ${output_path_select}"

$CMD