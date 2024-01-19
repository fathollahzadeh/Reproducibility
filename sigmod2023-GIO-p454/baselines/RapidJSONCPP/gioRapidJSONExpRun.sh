#!/usr/bin/env bash

./makeClean.sh

# Set properties
root_data_path="/media/sfathollahzadeh/Windows1/saeedData/NestedDatasets"
home_log="/media/sfathollahzadeh/Windows1/saeedData/NestedDatasets/LOG"
sep="_"

declare -a  datasets=("imdb" "aminer")

#valgrind --leak-check=yes
BASE_SCRIPT="taskset -c 0 ./bin/gioMain"

for ro in "GIO_1" "GIO_2" "GIO_3" "GIO_4" "GIO_5"
do
  for d in "${datasets[@]}"; do
    ./resultPath.sh $home_log $d$ro
    data_file_name="$root_data_path/$d/$d.data"
      for p in 0.1 0.2 0.3 0.4 0.5 0.6 0.7 0.8 0.9 1.0
        do
          SCRIPT="$BASE_SCRIPT\
                  $data_file_name\
                  $p\
                  $d\
                  $home_log/benchmark/RapidJSONNestedExperiment/$d$ro.csv
          "
          echo 3 > /proc/sys/vm/drop_caches && sync
          sleep 20
          time $SCRIPT
        done
  done
done
