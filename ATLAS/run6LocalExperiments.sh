#!/bin/bash

# clean original results
# rm -rf results/*;
mkdir -p results;


CMDSystemDSExp1=./explocal/exp1_Baselines/runExperiment1-SystemDS4m.sh
CMDTorchFXExp1=./explocal/exp1_Baselines/runExperiment1-TorchFX4m.sh
CMDTVMExp1=./explocal/exp1_Baselines/runExperiment1-TVM4m.sh
CMDJAXExp1=./explocal/exp1_Baselines/runExperiment1-JAX4m.sh
CMDATLASExp1=./explocal/exp1_Baselines/runExperiment1-ATLAS4m.sh

for itr in {1..3}; do
    # $CMDSystemDSExp1 $itr
    # $CMDTorchFXExp1 $itr
    # $CMDTVMExp1 $itr
    # $CMDJAXExp1 $itr
    $CMDATLASExp1 $itr

done    