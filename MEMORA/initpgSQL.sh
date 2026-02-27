#!/bin/bash

root_path="$(pwd)"
path="$(pwd)/setup"
baseline_path="${path}/Baselines"
psql_data_path="${root_path}/data/pgsql"
psql_setup_path="${baseline_path}/pgsql/18.3"

${psql_setup_path}/bin/pg_ctl -D ${psql_data_path} stop 
${psql_setup_path}/bin/postgres -D ${psql_data_path} &