itr=$1
root_path="$(pwd)"
data_path="${root_path}/data"
matrix_data_path="${root_path}/data/matrix"
path="${root_path}/setup"
baseline_path="${path}/Baselines"

cd "${baseline_path}/Python"
source venv/bin/activate

start=$(date +%s%N)
python TVM_exp1_ABCD.py ${matrix_data_path}
end=$(date +%s%N)
echo "ABCD,TVM,"${itr}","$((($end - $start) / 1000000)) >>${root_path}/results/ABCD.dat


start=$(date +%s%N)
python TVM_exp1_ABCD_Read.py ${matrix_data_path}
end=$(date +%s%N)
echo "ABCD,TVM,"${itr}","$((($end - $start) / 1000000)) >>${root_path}/results/ABCD_Read.dat