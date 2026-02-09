itr=$1
root_path="$(pwd)"
data_path="${root_path}/data"
matrix_data_path="${root_path}/data/matrix"
path="${root_path}/setup"
baseline_path="${path}/Baselines"

cd "${baseline_path}/ATLAS"
source venv/bin/activate


start=$(date +%s%N)
python main.py ${matrix_data_path}
end=$(date +%s%N)
echo "ATLAS,JAX,"${itr}","$((($end - $start) / 1000000)) >>${root_path}/results/ABCD.dat


start=$(date +%s%N)
python main_Read.py ${matrix_data_path}
end=$(date +%s%N)
echo "ABCD,JAX,"${itr}","$((($end - $start) / 1000000)) >>${root_path}/results/ABCD_Read.dat
