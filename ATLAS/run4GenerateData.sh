#!/bin/bash

root_path="$(pwd)"
data_path="${root_path}/data"

mkdir -p ${data_path}
gdb_path="${root_path}/setup/Baselines/GDB"
gendb_path="${root_path}/setup/Baselines/GenerateData"

#rm -rf "${data_path}/imdb" # clean-up
# rm -rf "${data_path}/tpcds" # clean-up
# rm -rf "${data_path}/dsb" # clean-up
rm -rf "${data_path}/tpch" # clean-up
# rm -rf "${data_path}/ssb" # clean-up

# ## TPC-DS Scale=100
#********************
# cd ${gdb_path}
# cd TPC-DS-v3.2
# ./runAll.sh 1 "${data_path}/tpcds" "/tmp/" 1

# ## TPC-H Scale=100
#*******************
cd ${gdb_path}
cd TPC-H
./runAll.sh 1 "${data_path}/tpch" "/tmp/"

# ## DSB Scale=10
#*******************
# cd ${gdb_path}
# cd DSB
# ./runAll.sh 1 "${data_path}/dsb" "/tmp/"

#cd ${gdb_path}
#cd TPC-H
#./runAll.sh 1 "${data_path}/tpch" "/tmp/"
#mv "${data_path}/tpch" "${data_path}/tpch_s1"

# cd ${gdb_path}
# cd TPC-H
# ./runAll.sh 2 "${data_path}/tpch" "/tmp/"
# mv "${data_path}/tpch" "${data_path}/tpch_s2"

# cd ${gdb_path}
# cd TPC-H
# ./runAll.sh 3 "${data_path}/tpch" "/tmp/"
# mv "${data_path}/tpch" "${data_path}/tpch_s3"

# cd ${gdb_path}
# cd TPC-H
# ./runAll.sh 4 "${data_path}/tpch" "/tmp/"
# mv "${data_path}/tpch" "${data_path}/tpch_s4"

# cd ${gdb_path}
# cd TPC-H
# ./runAll.sh 5 "${data_path}/tpch" "/tmp/"
# mv "${data_path}/tpch" "${data_path}/tpch_s5"

# cd ${gdb_path}
# cd TPC-H
# ./runAll.sh 6 "${data_path}/tpch" "/tmp/"
# mv "${data_path}/tpch" "${data_path}/tpch_s6"

# cd ${gdb_path}
# cd TPC-H
# ./runAll.sh 7 "${data_path}/tpch" "/tmp/"
# mv "${data_path}/tpch" "${data_path}/tpch_s7"

# cd ${gdb_path}
# cd TPC-H
# ./runAll.sh 8 "${data_path}/tpch" "/tmp/"
# mv "${data_path}/tpch" "${data_path}/tpch_s8"

# cd ${gdb_path}
# cd TPC-H
# ./runAll.sh 9 "${data_path}/tpch" "/tmp/"
# mv "${data_path}/tpch" "${data_path}/tpch_s9"

# cd ${gdb_path}
# cd TPC-H
# ./runAll.sh 10 "${data_path}/tpch" "/tmp/"
# mv "${data_path}/tpch" "${data_path}/tpch_s10"
