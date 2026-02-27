#!/bin/bash

root_path="$(pwd)"
data_path="${root_path}/data"
path="${root_path}/setup"
baseline_path="${path}/Baselines"

mkdir -p ${path}
mkdir -p ${baseline_path}

cd ${baseline_path}
rm -rf GDB

git clone https://github.com/fathollahzadeh/GDB.git
cd GDB

## Install PostgreSQL 18.3
***************************
cd Install-Postgres-v18.3
./setup.sh ${baseline_path} "${data_path}"
cd ${root_path}
./initpgSQL.sh

sleep 5

psql -U postgres -c "\i ${pg_config}"

./initpgSQL.sh
sleep 3

# Setup MEMORA
memora_path="${path}/Baselines/MEMORA"
# rm -rf ${memora_path}
mkdir -p ${memora_path}
# cp -r /home/saeed/Documents/Github/MEMORA/* ${memora_path}
# cd ${memora_path}

### MEMORA JAVA
# mvn clean
# mvn clean package -P distribution

# # mv target/lib/ ${memora_path}
# mv target/MEMORA-dist-1.0-SNAPSHOT.jar ${memora_path}/MEMORA.jar


# memora_path_cpp="${path}/Baselines/MEMORA/cpp"
# #rm -rf ${memora_path_cpp}
# mkdir -p ${memora_path_cpp}
# cp -r /home/saeed/Documents/Github/MEMORA/src/cpp/* ${memora_path_cpp}
# cd ${memora_path_cpp}

# set -euo pipefail
# # Clean-up
# # rm -rf build
# # rm -rf bin
# mkdir -p build
# cd build

# # Configure
# echo "===== Configuring ====="
# cmake .. -DCMAKE_BUILD_TYPE=Release

# # Build
# echo "===== Building ====="
# cmake --build . -j$(nproc)


