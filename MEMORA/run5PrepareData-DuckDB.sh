#!/bin/bash

root_path="$(pwd)"
data_path="${root_path}/data"
duckdb_data_path="${root_path}/data/duckdb"
workload_path="${root_path}/workload/DuckDB"

CMD="${root_path}/setup/Baselines/duckdb/build/release/duckdb"

mkdir -p ${duckdb_data_path}

imdb_data="${data_path}/imdb"
stats_data="${data_path}/stats"
stats_ceb_data="${data_path}/stats_ceb"
stackoverflow_data="${data_path}/stackoverflow"
tpcds_data="${root_path}/data/tpcds"
dsb_data="${root_path}/data/dsb"
tpch_data="${root_path}/data/tpch"
hits_data="${root_path}/data/hits.csv"
publicbi_data="${root_path}/data/PublicBIbenchmark"


# ## Load IMDB Dataset into DuckDB
# #*******************************
# cd ${imdb_data}
# imdb_data_duckdb="${duckdb_data_path}/imdb"
# rm -rf ${imdb_data_duckdb}
# $CMD ${imdb_data_duckdb} .databases -init ${workload_path}/imdb/schema.sql
# echo '-------------------<< IMDB database (DuckDB) is ready >>-------------------'


# ## Load STATS Dataset into DuckDB
# ********************************
cd ${stats_data}
stats_data_duckdb="${duckdb_data_path}/stats"
rm -rf ${stats_data_duckdb}
$CMD ${stats_data_duckdb} .databases -init ${workload_path}/stats/schema.sql
echo '-------------------<< STATS database (DuckDB) is ready >>-------------------'

# ## Load STATS-CEB Dataset into DuckDB
# ********************************
cd ${stats_ceb_data}
stats_ceb_data_duckdb="${duckdb_data_path}/stats_ceb"
rm -rf ${stats_ceb_data_duckdb}
$CMD ${stats_ceb_data_duckdb} .databases -init ${workload_path}/stats_ceb/schema.sql
echo '-------------------<< STATS-CEB database (DuckDB) is ready >>-------------------'

# ## Load stackoverflow Dataset into DuckDB
# ********************************
# cd ${stackoverflow_data}
# stackoverflow_data_duckdb="${duckdb_data_path}/stackoverflow"
# rm -rf ${stackoverflow_data_duckdb}
# $CMD ${stackoverflow_data_duckdb} .databases -init ${workload_path}/stackoverflow/schema.sql
# echo '-------------------<< stackoverflow database (DuckDB) is ready >>-------------------'

# ## Load hits Dataset into DuckDB
# ********************************
# hit_data_duckdb="${duckdb_data_path}/hits"
# rm -rf ${hit_data_duckdb}

# $CMD ${hit_data_duckdb} .databases -init ${workload_path}/hits/schema.sql 
# $CMD ${hit_data_duckdb} -c "COPY hits FROM '${hits_data}' (DELIMITER ',', ignore_errors true)"
# echo '-------------------<< hits database (DuckDB) is ready >>-------------------'

# ## Load TPC-DS Dataset into DuckDB
# ***********************************
# cd ${tpcds_data}
# tpcds_data_duckdb="${duckdb_data_path}/tpcds"
# rm -rf ${tpcds_data_duckdb}
# $CMD ${tpcds_data_duckdb} .databases -init ${workload_path}/tpcds/schema.sql 
# echo '-------------------<< TPC-DS database (DuckDB) is ready >>-------------------'

## Load DSB Dataset into DuckDB
## ***********************************
# cd ${dsb_data}
# dsb_data_duckdb="${duckdb_data_path}/dsb"
# rm -rf ${dsb_data_duckdb}
# $CMD ${dsb_data_duckdb} .databases -init ${workload_path}/dsb/schema.sql 
# echo '-------------------<< DSB database (DuckDB) is ready >>-------------------'

# # # Load TPC-H Dataset into DuckDB
# # ######################################
# cd ${tpch_data}
# tpch_data_duckdb="${duckdb_data_path}/tpch"
# rm -rf ${tpch_data_duckdb}
# $CMD ${tpch_data_duckdb} .databases -init ${workload_path}/tpch/schema.sql 
# echo '-------------------<< TPC-H database (DuckDB) is ready >>-------------------'

# ## Load PublicBIbenchmark Dataset into DuckDB
# ***********************************
# cd ${publicbi_data}
# schema_path="${workload_path}/publicbibenchmark/schema"
# publicbi_data_duckdb="${duckdb_data_path}/publicbibenchmark"
# rm -rf ${publicbi_data_duckdb}
# $CMD ${publicbi_data_duckdb} .databases -init ${workload_path}/publicbibenchmark/schema.sql 

# db_list="Eixo,CMSprovider,Motos,Taxpayer,Provider,Generico,MulheresMil,RealEstate1,MedPayment2,Physicians,Medicare1,Medicare2,CommonGovernment,USCensus,Telco,RealEstate2,Arade,PanCreactomy2,SalariesFrance,Bimbo,Medicare3,NYC,TrainsUK2"

# IFS=',' read -ra DBS <<< "${db_list}"

# for db in "${DBS[@]}"; do 
#   db_path="${publicbi_data}/${db}"
#   cd $db_path
#   #echo "++++++++++++++++++++++ ${db_path} ++++++++++++++++++++++++"
#   for i in `ls *.csv`; do
#     table=${i/.csv/}
#     table=$(echo "$table" | tr '[:upper:]' '[:lower:]' | tr -d '_')
#     #echo "++> ${table} "
#     cc="COPY ${table} FROM '${db}/${i}' (DELIMITER '|', QUOTE '\"', nullstr 'null');"
#     echo $cc
#   done
# done

# echo '-------------------<< PublicBIbenchmark database (DuckDB) is ready >>-------------------'