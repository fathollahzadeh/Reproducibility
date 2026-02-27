#!/bin/bash

root_path="$(pwd)"
data_path="${root_path}/data"
workload_path="${root_path}/workload/PostgreSQL"

writer_path="${root_path}/setup/Baselines/ImportData/"

imdb_data="${data_path}/imdb"
stats_data="${data_path}/stats"
stats_ceb_data="${data_path}/stats_ceb"
stackoverflow_data="${data_path}/stackoverflow"
tpcds_data="${root_path}/data/tpcds"
dsb_data="${root_path}/data/dsb"
tpch_data="${root_path}/data/tpch"
ssb_data="${root_path}/data/ssb"
hits_data="${root_path}/data/hits.csv"
stack_data="${data_path}/stack_dump"
publicbi_data="${root_path}/data/PublicBIbenchmark"



# ## Load IMDB Dataset into PostgreSQL
# # ***********************************
# cd ${imdb_data}
# psql -U postgres -c "DROP DATABASE IF EXISTS imdb;"
# psql -U postgres -c "CREATE DATABASE imdb;"
# psql -U postgres -d imdb -c "\i ${workload_path}/imdb/schema.sql;"
# psql -U postgres -d imdb -c "\i ${workload_path}/imdb/import.sql;"
# psql -U postgres  -d imdb -c "\i ${workload_path}/imdb/index.sql;"
# echo '-------------------<< IMDB database (PostgreSQL) is ready >>-------------------'

# ## Load STATS Dataset into PostgreSQL
# ***********************************
# cd ${stats_data}
# psql -U postgres -c "DROP DATABASE IF EXISTS stats;"
# psql -U postgres -c "CREATE DATABASE stats;"
# psql -U postgres -d stats -c "\i ${workload_path}/stats/schema.sql;"
# # psql -U postgres -d stats -f "${workload_path}/stats/import.sql"
# echo '-------------------<< STATS database (PostgreSQL) is ready >>-------------------'

# ## Load STATS-CEB Dataset into PostgreSQL
# ***********************************
# cd ${stats_ceb_data}
# psql -U postgres -c "DROP DATABASE IF EXISTS stats_ceb;"
# psql -U postgres -c "CREATE DATABASE stats_ceb;"
# psql -U postgres -d stats_ceb -c "\i ${workload_path}/stats_ceb/schema.sql;"
# psql -U postgres -d stats_ceb -f "${workload_path}/stats_ceb/import.sql"
# echo '-------------------<< STATS-CEB database (PostgreSQL) is ready >>-------------------'

# ## Load stackoverflow Dataset into PostgreSQL
# ***********************************
# cd ${stackoverflow_data}
# psql -U postgres -c "DROP DATABASE IF EXISTS stackoverflow;"
# psql -U postgres -c "CREATE DATABASE stackoverflow;"
# psql -U postgres -d stackoverflow -c "\i ${workload_path}/stackoverflow/schema.sql;"
# psql -U postgres -d stackoverflow -f "${workload_path}/stackoverflow/import.sql"
# echo '-------------------<< stackoverflow database (PostgreSQL) is ready >>-------------------'

# ## Load hits Dataset into PostgreSQL
# ***********************************
# psql -U postgres -c "DROP DATABASE IF EXISTS hits;"
# psql -U postgres -c "CREATE DATABASE hits ENCODING 'UTF8';"
# psql -U postgres -d hits -c "\i ${workload_path}/hits/schema.sql;"
# psql -U postgres -d hits -c  "\copy hits from ${hits_data} CSV DELIMITER ','"
# echo '-------------------<< hits database (PostgreSQL) is ready >>-------------------'


# # # Load DSB Dataset into PostgreSQL
# ***************************************
# cd ${dsb_data}
# psql -U postgres -c "DROP DATABASE IF EXISTS dsb;"
# psql -U postgres -c "CREATE DATABASE dsb ENCODING 'UTF8';"
# psql -U postgres -d dsb -c "\i ${workload_path}/dsb/schema.sql;"

# for i in `ls *.dat`; do
#   table=${i/.dat/}
#   echo "Loading $table..."
#   psql -U postgres -d dsb -c  "\copy ${table} from ${i} CSV DELIMITER '|'"
# done

# psql -U postgres -d dsb -c "\i ${workload_path}/dsb/index.sql;"

# for i in `ls *.dat`; do
#   table=${i/.dat/}
#   psql -U postgres -d dsb -c  "ANALYZE ${table};"
# done

# echo '-------------------<< DSB database (PostgreSQL) is ready >>-------------------'

### Load TPC-H Dataset into PostgreSQL
#**************************************
cd ${tpch_data}
psql -U postgres -c "DROP DATABASE IF EXISTS tpch;"
psql -U postgres -c "CREATE DATABASE tpch ENCODING 'UTF8';"
psql -U postgres -d tpch -c "\i ${workload_path}/tpch/schema.sql;"

for i in `ls *.tbl`; do
   table=${i/.tbl/}
   echo "Loading $table..."
   psql -U postgres -d tpch -c  "\copy ${table} from ${i} CSV DELIMITER '|'"
 done

 psql -U postgres -d tpch -c "\i ${workload_path}/tpch/index.sql;"
 psql -U postgres -d tpch -c "\i ${workload_path}/tpch/add_FK.sql;"

 echo '-------------------<< TPC-H database (PostgreSQL) is ready >>-------------------'

# ## Load PublicBIbenchmark Dataset into PostgreSQL
# ***********************************
# schema_path="${workload_path}/publicbibenchmark/schema"
# psql -U postgres -c "DROP DATABASE IF EXISTS publicbibenchmark;"
# psql -U postgres -c "CREATE DATABASE publicbibenchmark ENCODING 'UTF8';"

# cd $schema_path

# db_list="Eixo,CMSprovider,Motos,Taxpayer,Provider,Generico,MulheresMil,RealEstate1,MedPayment2,Physicians,Medicare1,Medicare2,CommonGovernment,USCensus,Telco,RealEstate2,Arade,PanCreactomy2,SalariesFrance,Bimbo,Medicare3,NYC,TrainsUK2"

# IFS=',' read -ra DBS <<< "${db_list}"

# for i in `ls *.sql`; do
#   psql -U postgres -d publicbibenchmark -c "\i ${workload_path}/publicbibenchmark/schema/${i};"
# done

# for db in "${DBS[@]}"; do 
#   db_path="${publicbi_data}/${db}"
#   cd $db_path
#   echo "++++++++++++++++++++++ ${db_path} ++++++++++++++++++++++++"
#   for i in `ls *.csv`; do
#     table=${i/.csv/}
#     table=$(echo "$table" | tr '[:upper:]' '[:lower:]' | tr -d '_')
#     echo "++> ${table} "
#     psql -U postgres -d publicbibenchmark -c  "\copy \"${table}\" from ${i} CSV DELIMITER '|' NULL 'null'"
#   done
# done

# echo '-------------------<< PublicBIbenchmark database (PostgreSQL) is ready >>-------------------'


### Load TPC-H Dataset into PostgreSQL
#**************************************
#  for i in 1 2 3 4 5 6 7 8 9 10
#     do
#         tpch_data="${root_path}/data/tpch_s${i}"
#         cd ${tpch_data}
#         psql -U postgres -c "DROP DATABASE IF EXISTS tpch_s${i};"
#         psql -U postgres -c "CREATE DATABASE tpch_s${i} ENCODING 'UTF8';"
#         psql -U postgres -d tpch_s${i} -c "\i ${workload_path}/tpch_s${i}/schema.sql;"

#         for ti in `ls *.tbl`; do
#             table=${ti/.tbl/}
#             echo "Loading $table..."
#             psql -U postgres -d tpch_s${i} -c  "\copy ${table} from ${ti} CSV DELIMITER '|'"
#         done

#         psql -U postgres -d tpch_s${i} -c "\i ${workload_path}/tpch_s${i}/index.sql;"
#         psql -U postgres -d tpch_s${i} -c "\i ${workload_path}/tpch_s${i}/add_FK.sql;"

#         echo "-------------------<< TPC-H (s${i}) database (PostgreSQL) is ready >>-------------------"
#     done    
