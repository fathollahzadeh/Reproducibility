#!/bin/bash

root_path="$(pwd)"
data_path="${root_path}/data"
path="${root_path}/setup"
baseline_path="${path}/Baselines"

mkdir -p ${baseline_path}
mkdir -p ${data_path}


# ### Setup Python Baelines
# #******************
pybaseline_path="${path}/Baselines/Python"
rm -rf ${pybaseline_path}
mkdir -p ${pybaseline_path}

cd ${root_path}
cp -r baselines/Python/* ${pybaseline_path}
cd ${pybaseline_path}

rm -rf venv 
python3.10 -m venv venv
source venv/bin/activate
pip install --upgrade pip
pip install -r requirements.txt


### Setup ATLAS
#******************
atlas_path="${path}/Baselines/ATLAS"
rm -rf ${atlas_path}
mkdir -p ${atlas_path}

cd ${root_path}
cp -r baselines/ATLAS/* ${atlas_path}
cd ${atlas_path}

rm -rf venv 
python3.10 -m venv venv
source venv/bin/activate
pip install --upgrade pip
pip install -r requirements.txt

# Setup Apache SystemDS
sysdsbaseline_path="${path}/Baselines/SystemDS"
rm -rf ${sysdsbaseline_path}
mkdir -p ${sysdsbaseline_path}
cp -r ${root_path}/baselines/SystemDS/* ${sysdsbaseline_path}
cd ${sysdsbaseline_path}

git clone https://github.com/apache/systemds.git
cd systemds
mvn clean package -P distribution

mv target/lib/ ${sysdsbaseline_path}
mv target/SystemDS.jar ${sysdsbaseline_path}


