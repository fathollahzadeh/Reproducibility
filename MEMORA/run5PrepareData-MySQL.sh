#!/bin/bash

root_path="$(pwd)"
data_path="${root_path}/data"
workload_path="${root_path}/workload/MySQL"

imdb_data="${data_path}/imdb"
stats_data="${data_path}/stats"
stats_ceb_data="${data_path}/stats_ceb"
stackoverflow_data="${data_path}/stackoverflow"
tpcds_data="${root_path}/data/tpcds"
tpch_data="${root_path}/data/tpch"
ssb_data="${root_path}/data/ssb"
hits_data="${root_path}/data/hits.csv"
publicbi_data="${root_path}/data/PublicBIbenchmark"


# ## Load IMDB Dataset into MySQL
# # ###################################
# cd ${imdb_data}
# sudo mysql -e "DROP DATABASE IF EXISTS imdb;"
# sudo mysql -e "CREATE DATABASE imdb CHARACTER SET utf8;"
# sudo mysql imdb < "${workload_path}/imdb/schema.sql"
# sudo mysql imdb < "${workload_path}/imdb/import.sql"
# sudo mysql imdb < "${workload_path}/imdb/index.sql"
# echo '-------------------<< IMDB database (MySQL) is ready >>-------------------'

# ### Load STATS Dataset into MySQL
# #***********************************
cd ${stats_data}
sudo mysql -e "DROP DATABASE IF EXISTS stats;"
sudo mysql -e "CREATE DATABASE stats;"
sudo mysql stats < "${workload_path}/stats/schema.sql"
# sudo mysql stats < "${workload_path}/stats/import.sql"
echo '-------------------<< STATS database (MySQL) is ready >>-------------------'

### Load STATS-CEB Dataset into MySQL
#***********************************
cd ${stats_ceb_data}
sudo mysql -e "DROP DATABASE IF EXISTS stats_ceb;"
sudo mysql -e "CREATE DATABASE stats_ceb;"
sudo mysql stats_ceb < "${workload_path}/stats_ceb/schema.sql"
# sudo mysql stats_ceb < "${workload_path}/stats_ceb/import.sql"
sudo mysql stats_ceb < "${workload_path}/stats_ceb/index.sql"
echo '-------------------<< STATS-CEB database (MySQL) is ready >>-------------------'

# # ## Load stackoverflow Dataset into MySQL
# # ***********************************
# cd ${stackoverflow_data}
# sudo mysql -e "DROP DATABASE IF EXISTS stackoverflow;"
# sudo mysql -e "CREATE DATABASE stackoverflow;"
# sudo mysql stackoverflow < "${workload_path}/stackoverflow/schema.sql"

# sudo mysql -e "use stackoverflow; LOAD DATA LOCAL INFILE 'PostHistoryTypes.csv' INTO TABLE PostHistoryTypes COLUMNS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '\"';"
# ./initpgSQL.sh

# sudo mysql -e "use stackoverflow; LOAD DATA LOCAL INFILE 'LinkTypes.csv' INTO TABLE LinkTypes COLUMNS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '\"';"
# ./initpgSQL.sh

# sudo mysql -e "use stackoverflow; LOAD DATA LOCAL INFILE 'PostTypes.csv' INTO TABLE PostTypes COLUMNS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '\"';"
# ./initpgSQL.sh

# sudo mysql -e "use stackoverflow; LOAD DATA LOCAL INFILE 'CloseReasonTypes.csv' INTO TABLE CloseReasonTypes COLUMNS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '\"';"
# ./initpgSQL.sh

# sudo mysql -e "use stackoverflow; LOAD DATA LOCAL INFILE 'VoteTypes.csv' INTO TABLE VoteTypes COLUMNS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '\"';"
# ./initpgSQL.sh

# sudo mysql -e "use stackoverflow; LOAD DATA LOCAL INFILE 'Users.csv' INTO TABLE Users COLUMNS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '\"';"
# ./initpgSQL.sh

# sudo mysql -e "use stackoverflow; LOAD DATA LOCAL INFILE 'Badges.csv' INTO TABLE Badges COLUMNS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '\"';"
# ./initpgSQL.sh

# sudo mysql -e "use stackoverflow; LOAD DATA LOCAL INFILE 'Posts.csv' INTO TABLE Posts COLUMNS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '\"';"
# ./initpgSQL.sh

# sudo mysql -e "use stackoverflow; LOAD DATA LOCAL INFILE 'Comments.csv' INTO TABLE Comments COLUMNS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '\"';"
# ./initpgSQL.sh

# sudo mysql -e "use stackoverflow; LOAD DATA LOCAL INFILE 'PostHistory.csv' INTO TABLE PostHistory COLUMNS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '\"';"
# ./initpgSQL.sh

# sudo mysql -e "use stackoverflow; LOAD DATA LOCAL INFILE 'PostLinks.csv' INTO TABLE PostLinks COLUMNS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '\"';"
# ./initpgSQL.sh

# sudo mysql -e "use stackoverflow; LOAD DATA LOCAL INFILE 'Tags.csv' INTO TABLE Tags COLUMNS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '\"';"
# ./initpgSQL.sh

# sudo mysql -e "use stackoverflow; LOAD DATA LOCAL INFILE 'Votes.csv' INTO TABLE Votes COLUMNS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '\"';"
# ./initpgSQL.sh
# echo '-------------------<< stackoverflow database (MySQL) is ready >>-------------------'

# # ## Load hits Dataset into MySQL
# # *******************************
# cd ${data_path}
# sudo mysql -e "DROP DATABASE IF EXISTS hits;"
# sudo mysql -e "CREATE DATABASE hits;"
# sudo mysql hits < "${workload_path}/hits/schema.sql"
# sudo mysql hits < "${workload_path}/hits/import.sql"
# echo '-------------------<< hits database (MySQL) is ready >>-------------------'


# ## Load TPC-DS Dataset into MySQL
# ######################################
# cd ${tpcds_data}
# sudo mysql -e "DROP DATABASE IF EXISTS tpcds;"
# sudo mysql -e "CREATE DATABASE tpcds character set utf8mb4;"
# sudo mysql tpcds < "${workload_path}/tpcds/schema.sql"
# sudo mysql tpcds < "${workload_path}/tpcds/import.sql"
# sudo mysql tpcds < "${workload_path}/tpcds/index.sql"
# echo '-------------------<< TPC-DS database (MySQL) is ready >>-------------------'

# ## Load TPC-H Dataset into MySQL
# #######################################
# cd ${tpch_data}
# sudo mysql -e "DROP DATABASE IF EXISTS tpch;"
# sudo mysql -e "CREATE DATABASE tpch character set utf8mb4;"
# sudo mysql tpch < "${workload_path}/tpch/schema.sql"
# sudo mysql tpch < "${workload_path}/tpch/import.sql"
# sudo mysql tpch < "${workload_path}/tpch/index.sql"
# echo '-------------------<< TPC-H database (MySQL) is ready >>-------------------'

# ## Load PublicBIbenchmark Dataset into PostgreSQL
# ***********************************
# schema_path="${workload_path}/publicbibenchmark/schema"
# sudo mysql -e "DROP DATABASE IF EXISTS publicbibenchmark;"
# sudo mysql -e "CREATE DATABASE publicbibenchmark character set utf8mb4;"

# cd $schema_path

# db_list="Eixo,CMSprovider,Motos,Taxpayer,Provider,Generico,MulheresMil,RealEstate1,MedPayment2,Physicians,Medicare1,Medicare2,CommonGovernment,USCensus,Telco,RealEstate2,Arade,PanCreactomy2,SalariesFrance,Bimbo,Medicare3,NYC,TrainsUK2"

# IFS=',' read -ra DBS <<< "${db_list}"

# for i in `ls *.sql`; do
#     sudo mysql publicbibenchmark < "${workload_path}/publicbibenchmark/schema/${i}"
# done

# for db in "${DBS[@]}"; do 
#   db_path="${publicbi_data}/${db}"
#   cd $db_path
#   echo "++++++++++++++++++++++ ${db_path} ++++++++++++++++++++++++"
#   for i in `ls *.csv`; do
#     table=${i/.csv/}
#     table=$(echo "$table" | tr '[:upper:]' '[:lower:]' | tr -d '_')
#     echo "++> ${table} "
#     sed 's/|null|/||/g; s/^null|/|/g; s/|null$/|/g' "$i" > "${i}_clean"
#     sudo mysql -e "use publicbibenchmark; LOAD DATA LOCAL INFILE '${i}_clean' INTO TABLE ${table} COLUMNS TERMINATED BY '|' OPTIONALLY ENCLOSED BY '\"';"
#     rm -rf "${i}_clean"
    
#     sudo service mysql restart
#   done
# done

# echo '-------------------<< PublicBIbenchmark database (MySQL) is ready >>-------------------'