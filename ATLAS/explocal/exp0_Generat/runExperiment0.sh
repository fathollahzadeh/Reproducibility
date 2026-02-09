#!/bin/bash

dataset=$1
exp_path="$(pwd)"

catalog_dir="${exp_path}/catalog"
mkdir -p ${catalog_dir}
catalog_path="${catalog_dir}/${dataset}"
mkdir -p ${catalog_path}

CMD="./explocal/exp0/runExperiment0-Build-Catalog.sh ${dataset} ${catalog_path}"

$CMD PosrgreSQL
#$CMD MySQL
