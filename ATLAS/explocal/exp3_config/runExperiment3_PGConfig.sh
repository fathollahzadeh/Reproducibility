#!/bin/bash

shared_buffers=$1
work_mem=$2


sync
echo 3 | sudo tee /proc/sys/vm/drop_caches > /dev/null

exp_path="$(pwd)"
pgconfig_path="${exp_path}/data/pgsql/postgresql.auto.conf"


cd "${exp_path}/setup/Baselines/Workload"
source venv/bin/activate

CMD="python main_PGConfig.py --config-path ${pgconfig_path} \
                    --shared-buffers ${shared_buffers} \
                    --work-mem ${work_mem}"

$CMD

cd ${exp_path}
./initpgSQL.sh

sleep 5