log_file_name=ABCD.dat
root_path="$(pwd)"
data_path="${root_path}/data"
matrix_data_path="${root_path}/data/matrix"
path="${root_path}/setup"
baseline_path="${path}/Baselines"

cd "${baseline_path}/Python"
source venv/bin/activate

CMD="python JAX_exp1_ABCD.py ${matrix_data_path}"

start=$(date +%s%N)
$CMD
end=$(date +%s%N)
echo "ABCD,JAX,"$((($end - $start) / 1000000)) >>${root_path}/results/$log_file_name

