source ./run0LoadConfig.sh

itr=$1
root_path="$(pwd)"
data_path="${root_path}/data"
matrix_data_path="${root_path}/data/matrix"
path="${root_path}/setup"
baseline_path="${path}/Baselines"

dml_path="${root_path}/baselines/SystemDS/exp1_ABCD.dml"
dml_read_path="${root_path}/baselines/SystemDS/exp1_ABCD_Read.dml"
out_path="${root_path}/results"

cd "${baseline_path}/SystemDS"

# CMD="java -Xmx28g -Xms28g -Xmn2g --add-modules jdk.incubator.vector \
#     -cp SystemDS.jar:lib/* \
#     -Dlog4j.configuration=file:log4j-silent.properties \
#     org.apache.sysds.api.DMLScript \
#     -exec singlenode \
#     -debug \
#     -stats -nvargs out=$out_path matrix_path=$matrix_data_path
#     -config SystemDS-config.xml"

start=$(date +%s%N)
$CMD -nvargs out=$out_path matrix_path=$matrix_data_path -config SystemDS-config.xml -f $dml_path
end=$(date +%s%N)
echo "ABCD,SystemDS,"${itr}","$((($end - $start) / 1000000)) >>${root_path}/results/ABCD.dat


start=$(date +%s%N)
$CMD -nvargs out=$out_path matrix_path=$matrix_data_path -config SystemDS-config.xml -f $dml_read_path
end=$(date +%s%N)
echo "ABCD,SystemDS,"${itr}","$((($end - $start) / 1000000)) >>${root_path}/results/ABCD_Read.dat

