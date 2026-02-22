#!/bin/bash

root_path="$(pwd)"
path="${root_path}/setup"
baseline_path="${path}/Baselines"

mkdir -p ${path}
mkdir -p ${baseline_path}

# Setup MEMORA
memora_path="${path}/Baselines/MEMORA"
rm -rf ${memora_path}
mkdir -p ${memora_path}
cp -r /home/saeed/Documents/Github/MEMORA/* ${memora_path}
cd ${memora_path}

mvn clean
mvn clean package -P distribution

# mv target/lib/ ${memora_path}
mv target/MEMORA-dist-1.0-SNAPSHOT.jar ${memora_path}/MEMORA.jar


