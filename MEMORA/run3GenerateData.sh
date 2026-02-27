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


