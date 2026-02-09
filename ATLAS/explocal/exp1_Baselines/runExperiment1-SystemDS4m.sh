log_file_name=ABCD.dat
root_path="$(pwd)"
data_path="${root_path}/data"
matrix_data_path="${root_path}/data/matrix"
path="${root_path}/setup"
baseline_path="${path}/Baselines"

dml_path="${root_path}/baselines/SystemDS/exp1_ABCD.dml"
out_path="${root_path}/results"

cd "${baseline_path}/SystemDS"

CMD="java -Xmx28g -Xms28g -Xmn2g --add-modules jdk.incubator.vector \
    -cp SystemDS.jar:lib/* \
    -Dlog4j.configuration=file:log4j-silent.properties \
    org.apache.sysds.api.DMLScript \
    -exec singlenode \
    -debug \
    -stats -nvargs out=$out_path matrix_path=$matrix_data_path
    -config SystemDS-config.xml"

start=$(date +%s%N)
$CMD -f $dml_path
end=$(date +%s%N)
echo "ABCD,SystemDS,"$((($end - $start) / 1000000)) >>${root_path}/results/$log_file_name

