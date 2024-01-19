#!/bin/bash

dataset=$1
log_file_name=$2
parallel=$3

# write header
if [[ ! -f results/$log_file_name.dat ]] ; then
  echo "dataset,field,example_nrows,time,parallel" >>results/$log_file_name.dat
fi

examples=200
declare -a field_list=("F0" "F1" "F2" "F3" "F4" "F5" "F6" "F7" "F8" "F9" "F10" "F11" "F12" "F13" "F14" "F15" "F16" "F17" "F18" "F19" "F20" "F21" "F22" "F23" "F24" "F25" "F26" "F27" "F28")


for field in "${field_list[@]}"; do
  if [ -d "data/${dataset}/${field}" ]; then        
        SCRIPT="$CMD  -DsampleRawFileName=data/${dataset}/${field}/sample-${dataset}${examples}.raw\
                      -DsampleMatrixFileName=data/${dataset}/${field}/sample-${dataset}${examples}.matrix\
                      -Dparallel=${parallel}\
                      -cp ./setup/JavaBaselines/lib/*:./setup/JavaBaselines/JavaBaselines.jar at.tugraz.benchmark.GIOMatrixIdentification
                      "
        echo $SCRIPT

        # clean OS cache, need sudo privilege
        echo 3 >/proc/sys/vm/drop_caches && sync
        sleep 3

        start=$(date +%s%N)
        $SCRIPT
        end=$(date +%s%N)
        echo ${dataset}","${field}","${examples}","$((($end - $start) / 1000000))","${parallel} >>results/$log_file_name.dat
  fi
done
