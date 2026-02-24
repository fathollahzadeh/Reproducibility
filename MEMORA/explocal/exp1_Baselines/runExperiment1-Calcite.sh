. ./run0LoadConfig.sh

dataset_name=$1
dbms=$2
itr=$3
best_plan=$4
enable_logical_rules=$5
enable_physical_rules=$6
log_fname=$7
save_log=$8


root_path="$(pwd)"
path="${root_path}/setup"
baseline_path="${path}/Baselines"

mkdir -p ${root_path}/Calcite-Results
mkdir -p ${root_path}/Calcite-Results/${dbms}
mkdir -p ${root_path}/Calcite-Results/${dbms}/${dataset_name}-${best_plan}-${enable_logical_rules}-${enable_physical_rules}
mkdir -p ${root_path}/Calcite-Results/${dbms}/${dataset_name}-${best_plan}-${enable_logical_rules}-${enable_physical_rules}/Logical-MEMOS
mkdir -p ${root_path}/Calcite-Results/${dbms}/${dataset_name}-${best_plan}-${enable_logical_rules}-${enable_physical_rules}/Physical-MEMOS
memora_results="${root_path}/Calcite-Results/${dbms}/${dataset_name}-${best_plan}-${enable_logical_rules}-${enable_physical_rules}"

workload_schema_path="${root_path}/catalog/${dataset_name}/schema.json"
workload_path="${root_path}/workload/${dbms}/${dataset_name}"
logical_memos_merged="${memora_results}/Logical-MEMOS-Merged.csv"
logical_memos_count="${memora_results}/Logical-MEMOS-Count.csv"
logical_memos="${memora_results}/Logical-MEMOS"
physical_memos_merged="${memora_results}/Physical-Merged.csv"
physical_memos_count="${memora_results}/Physical-Count.csv"
physical_memos="${memora_results}/Physical-MEMOS"


cd "${baseline_path}/MEMORA"

physical_params=""

if [[ "$best_plan" == "true" ]]; then
    physical_params="-Dphysical_memos_merged=${physical_memos_merged} -Dphysical_memos_count=${physical_memos_count} -Dphysical_memos=${physical_memos}"
fi

if [ $dataset_name == "publicbibenchmark" ]; then
    workload_path="${workload_path}/queries"
fi

SCRIPT="${CMD} -Dworkload_schema_path=${workload_schema_path} \
    -Dworkload_path=${workload_path} \
    -Dlogical_memos_merged=${logical_memos_merged} \
    -Dlogical_memos_count=${logical_memos_count} \
    -Dlogical_memos=${logical_memos} \
    -Dbest_plan=${best_plan} \
    -Denable_logical_rules=${enable_logical_rules} \
    -Denable_physical_rules=${enable_physical_rules} \
    ${physical_params} \
    -Dsave_log=${save_log} \
    -jar MEMORA.jar"

# echo $SCRIPT

start=$(date +%s%N)
$SCRIPT 
end=$(date +%s%N)
echo "Calcite,"${dataset_name}","${itr}","${best_plan}","${enable_logical_rules}","${enable_physical_rules}","$((($end - $start) / 1000000)) >>${log_fname}