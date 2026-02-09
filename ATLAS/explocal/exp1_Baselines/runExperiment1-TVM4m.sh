root_path="$(pwd)"
data_path="${root_path}/data"
matrix_data_path="${root_path}/data/matrix"
path="${root_path}/setup"
baseline_path="${path}/Baselines"

cd "${baseline_path}/Python"
source venv/bin/activate

CMD="python TVM_exp1_ABCD.py ${matrix_data_path}"

$CMD