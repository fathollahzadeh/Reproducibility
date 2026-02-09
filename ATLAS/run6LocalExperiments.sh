#!/bin/bash

# clean original results
rm -rf results/*;
mkdir -p results;

export iteration=5

CMDSystemDSExp1=./explocal/exp1_Baselines/runExperiment1-SystemDS4m.sh
CMDTorchFXExp1=./explocal/exp1_Baselines/runExperiment1-TorchFX4m.sh
CMDTVMExp1=./explocal/exp1_Baselines/runExperiment1-TVM4m.sh
CMDJAXExp1=./explocal/exp1_Baselines/runExperiment1-JAX4m.sh

for itr in $(seq 1 "$iteration"); do
    #$CMDSystemDSExp1 $itr
    $CMDTorchFXExp1 $itr
    # $CMDTVMExp1 $itr
    # $CMDJAXExp1 $itr
done    