source ./run0LoadConfig.sh

root_path="$(pwd)"
data_path="${root_path}/data"

path="${root_path}/setup"
baseline_path="${path}/Baselines"

mkdir -p $data_path
dml_path="${baseline_path}/SystemDS/generate_matrix.dml"

cd "${baseline_path}/SystemDS"
matrix_data_path="${root_path}/data/matrix"
mkdir -p $matrix_data_path
$CMD -nvargs out=$matrix_data_path -config SystemDS-gen-config.xml -f generate_matrix.dml

matrix_data_path="${root_path}/data/matrix_large"
mkdir -p $matrix_data_path
$CMD -nvargs out=$matrix_data_path -config SystemDS-gen-config.xml -f generate_matrix_large.dml