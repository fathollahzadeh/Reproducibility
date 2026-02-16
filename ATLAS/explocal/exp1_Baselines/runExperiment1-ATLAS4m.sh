itr=$1
s=$2
root_path="$(pwd)"
data_path="${root_path}/data"
matrix_data_path="${root_path}/data/matrix_${s}"
path="${root_path}/setup"
baseline_path="${path}/Baselines"

cd "${baseline_path}/ATLAS"
source venv/bin/activate


start=$(date +%s%N)
python task1.py ${matrix_data_path}
end=$(date +%s%N)
echo "TASK1,ATLAS,"${itr}","${s}","$((($end - $start) / 1000000)) >>${root_path}/results/TASK1.dat


start=$(date +%s%N)
python task1_Read.py ${matrix_data_path}
end=$(date +%s%N)
echo "TASK1,ATLAS,"${itr}","${s}","$((($end - $start) / 1000000)) >>${root_path}/results/TASK1_Read.dat
