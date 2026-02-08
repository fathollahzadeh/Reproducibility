#!/bin/bash

root_path="$(pwd)"
data_path="${root_path}/data"
path="${root_path}/setup"
baseline_path="${path}/Baselines"

mkdir -p ${baseline_path}
mkdir -p ${data_path}


### Setup Baelines
#******************
pybaseline_path="${path}/Baselines/Python"
rm -rf ${pybaseline_path}
mkdir -p ${pybaseline_path}

cd ${root_path}
cd ..
cp -r baselines/Python/* ${pybaseline_path}
cd ${pybaseline_path}

rm -rf venv 
python3.10 -m venv venv
source venv/bin/activate
pip install --upgrade pip
pip install -r requirements.txt

