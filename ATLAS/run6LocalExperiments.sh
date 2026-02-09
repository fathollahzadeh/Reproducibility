#!/bin/bash

# clean original results
rm -rf results/*;
mkdir -p results;

export iteration=1

CMDSystemDSExp1=./explocal/exp1_Baselines/runExperiment1-SystemDS4m.sh
CMDTorchFXExp1=./explocal/exp1_Baselines/runExperiment1-TorchFX4m.sh
CMDTVMExp1=./explocal/exp1_Baselines/runExperiment1-TVM4m.sh
CMDJAXExp1=./explocal/exp1_Baselines/runExperiment1-JAX4m.sh

$CMDSystemDSExp1
$CMDTorchFXExp1
$CMDTVMExp1
$CMDJAXExp1