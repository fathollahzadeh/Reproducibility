. ./run0LoadConfig.sh

itr=$1
s=$2
root_path="$(pwd)"
data_path="${root_path}/data"
matrix_data_path="${root_path}/data/matrix_${s}"
path="${root_path}/setup"
baseline_path="${path}/Baselines"

dml_path="${root_path}/baselines/SystemDS/exp1_Task1.dml"
dml_read_path="${root_path}/baselines/SystemDS/exp1_Task1_Read.dml"
out_path="${root_path}/results"

cd "${baseline_path}/SystemDS"


start=$(date +%s%N)
$CMD -nvargs out=$out_path matrix_path=$matrix_data_path -config SystemDS-config.xml -f $dml_path
end=$(date +%s%N)
echo "TASK1,SystemDS,"${itr}","${s}","$((($end - $start) / 1000000)) >>${root_path}/results/TASK1.dat


start=$(date +%s%N)
$CMD -nvargs out=$out_path matrix_path=$matrix_data_path -config SystemDS-config.xml -f $dml_read_path
end=$(date +%s%N)
echo "TASK1,SystemDS,"${itr}","${s}","$((($end - $start) / 1000000)) >>${root_path}/results/TASK1_Read.dat

