#!/bin/bash

dataset=$1
log_file_name=$2
parallel=true

# write header
if [[ ! -f results/$log_file_name.dat ]] ; then
  echo "baseline,dataset,field,example_nrows,time,parallel" >>results/$log_file_name.dat
fi

examples=200
declare -a field_list=("F1" "F2" "F3" "F4" "F5" "F6" "F7" "F8" "F9" "F10")


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
        echo "GIO,"${dataset}","${field}","${examples}","$((($end - $start) / 1000000))","${parallel} >>results/$log_file_name.dat
  fi
done
