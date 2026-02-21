#!/bin/bash

# clean original results
rm -rf results/*;
mkdir -p results;


CMDSystemDSExp1=./explocal/exp1_Baselines/runExperiment1-SystemDS4m.sh
CMDTorchFXExp1=./explocal/exp1_Baselines/runExperiment1-TorchFX4m.sh
CMDTVMExp1=./explocal/exp1_Baselines/runExperiment1-TVM4m.sh
CMDJAXExp1=./explocal/exp1_Baselines/runExperiment1-JAX4m.sh
CMDATLASExp1=./explocal/exp1_Baselines/runExperiment1-ATLAS4m.sh

for itr in {1..3}; do
    for s in 1000 4000 8000 16000 20000 24000 28000 32000; do 
        $CMDSystemDSExp1 $itr $s
        $CMDTorchFXExp1 $itr $s
        $CMDTVMExp1 $itr $s
        $CMDJAXExp1 $itr $s
        # $CMDATLASExp1 $itr $s
    done       
done    