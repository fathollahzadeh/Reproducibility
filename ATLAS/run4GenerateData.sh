source ./run0LoadConfig.sh

root_path="$(pwd)"
data_path="${root_path}/data"

path="${root_path}/setup"
baseline_path="${path}/Baselines"

mkdir -p $data_path
dml_path="${baseline_path}/SystemDS/generate_matrix.dml"

cd "${baseline_path}/SystemDS"

for s in {1000,4000,8000,16000,20000,24000,28000,32000}; do 
    matrix_data_path="${root_path}/data/matrix_${s}"
    mkdir -p $matrix_data_path
    $CMD -nvargs out=$matrix_data_path s=$s -config SystemDS-gen-config.xml -f generate_matrix.dml
done    
