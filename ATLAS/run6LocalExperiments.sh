#!/bin/bash

# clean original results
rm -rf results/*;
mkdir -p results;

export iteration=1

CMDReSequel=./explocal/exp1_ReSequel/runExperiment1.sh
CMDBaseline=./explocal/exp2_Baselines/runExperiment2.sh
CMDBaselineLearnrewrite=./explocal/exp2_Baselines/runExperiment2-LearnRewrite.sh
CMDRunReSequel=./explocal/exp2_Baselines/runExperiment2-ReSequel.sh
CMDRunReSequelOR=./explocal/exp2_Baselines/runExperiment2-ReSequel-OR.sh
CMDRunReSequelMicroOR=./explocal/exp2_Baselines/runExperiment2-ReSequel-Micro-OR.sh

CMDDBMSConfig=./explocal/exp3_config/runExperiment3_PGConfig.sh
CMDBaselineConfig=./explocal/exp3_config/runExperiment3.sh
CMDRunReSequelConfig=./explocal/exp3_config/runExperiment3-ReSequel.sh

## Build Catalog
#***************
# $CMDReSequel BuildCatalog stats PostgreSQL 1
# $CMDReSequel BuildCatalog stats_ceb PostgreSQL 1
# $CMDReSequel BuildCatalog stackoverflow PostgreSQL 1
# $CMDReSequel BuildCatalog imdb PostgreSQL 1
# $CMDReSequel BuildCatalog tpch PostgreSQL 1
# $CMDReSequel BuildCatalog publicbibenchmark PostgreSQL 1

## Templatization
#****************
# $CMDReSequel Templatization imdb PostgreSQL 1
# $CMDReSequel Templatization imdb_13k PostgreSQL 1
# $CMDReSequel Templatization dsb PostgreSQL 1
# $CMDReSequel Templatization dsb_s100 PostgreSQL 1
# $CMDReSequel Templatization stackoverflow PostgreSQL 1
# $CMDReSequel Templatization tpch PostgreSQL 1
# $CMDReSequel Templatization stats PostgreSQL 1
# $CMDReSequel Templatization stats_ceb PostgreSQL 1
# $CMDReSequel Templatization publicbibenchmark PostgreSQL 1

# $CMDReSequel Templatization imdb MySQL 1
# $CMDReSequel Templatization tpch MySQL 1
# $CMDReSequel Templatization stats MySQL 1
# $CMDReSequel Templatization stackoverflow MySQL 1
# $CMDReSequel Templatization publicbibenchmark MySQL 1

# $CMDReSequel Templatization imdb DuckDB 1
# $CMDReSequel Templatization tpch DuckDB 1
# $CMDReSequel Templatization stats DuckDB 1
# $CMDReSequel Templatization stackoverflow DuckDB 1
# $CMDReSequel Templatization publicbibenchmark DuckDB 1

###  Rewrite
### **********
# $CMDReSequel Generate imdb PostgreSQL 1 gemini-2.5-pro
# $CMDReSequel Generate tpch PostgreSQL 1 gemini-2.5-pro
# $CMDReSequel Generate stats PostgreSQL 1 gemini-2.5-pro
# $CMDReSequel Generate stackoverflow PostgreSQL 1 gemini-2.5-pro
# $CMDReSequel Generate publicbibenchmark PostgreSQL 1 gemini-2.5-pro
# $CMDReSequel Generate dsb PostgreSQL 1 gemini-2.5-pro
# $CMDReSequel Generate dsb_s100 PostgreSQL 1 gemini-2.5-pro
# $CMDReSequel Generate imdb_13k PostgreSQL 1 gemini-2.5-pro

# $CMDReSequel Generate imdb PostgreSQL 1 gpt-oss-120b
# $CMDReSequel Generate tpch PostgreSQL 1 gpt-oss-120b
# $CMDReSequel Generate stats PostgreSQL 1 gpt-oss-120b
# $CMDReSequel Generate stackoverflow PostgreSQL 1 gpt-oss-120b
# $CMDReSequel Generate publicbibenchmark PostgreSQL 1 gpt-oss-120b

# $CMDReSequel Generate imdb MySQL 1 gemini-2.5-pro
# $CMDReSequel Generate tpch MySQL 1 gemini-2.5-pro
# $CMDReSequel Generate stats MySQL 1 gemini-2.5-pro
# $CMDReSequel Generate stackoverflow MySQL 1 gemini-2.5-pro
# $CMDReSequel Generate publicbibenchmark MySQL 1 gemini-2.5-pro

# $CMDReSequel Generate imdb DuckDB 1 gemini-2.5-pro
# $CMDReSequel Generate tpch DuckDB 1 gemini-2.5-pro
# $CMDReSequel Generate stats DuckDB 1 gemini-2.5-pro
# $CMDReSequel Generate stackoverflow DuckDB 1 gemini-2.5-pro
# $CMDReSequel Generate publicbibenchmark DuckDB 1 gemini-2.5-pro


###  Verify by Database Samples
### ***************************
# $CMDReSequel Downsampling imdb PostgreSQL 1 gemini-2.5-pro _ 5
#$CMDReSequel Downsampling imdb_d PostgreSQL 1 gemini-2.5-pro _ 5
# $CMDReSequel Downsampling tpch PostgreSQL 1 gemini-2.5-pro _ 1
#$CMDReSequel Downsampling stats PostgreSQL 1 gemini-2.5-pro _ 5
#$CMDReSequel Downsampling stackoverflow PostgreSQL 1 gemini-2.5-pro _ 5
#$CMDReSequel Downsampling publicbibenchmark PostgreSQL 1 gemini-2.5-pro _ 5


###  Labeling
### ***********
# $CMDReSequel Labeling tpch PostgreSQL 1 gemini-2.5-pro
# $CMDReSequel Labeling imdb PostgreSQL 1 gemini-2.5-pro
# $CMDReSequel Labeling stats PostgreSQL 1 gemini-2.5-pro
# $CMDReSequel Labeling stackoverflow PostgreSQL 1 gemini-2.5-pro
# $CMDReSequel Labeling publicbibenchmark PostgreSQL 1 gemini-2.5-pro

###  Reconstruct
### ***********
# $CMDReSequel Reconstruct imdb PostgreSQL 1 gemini-2.5-pro
# $CMDReSequel Reconstruct imdb_d PostgreSQL 1 gemini-2.5-pro
# $CMDReSequel Reconstruct tpch PostgreSQL 1 gemini-2.5-pro
# $CMDReSequel Reconstruct stats PostgreSQL 1 gemini-2.5-pro
# $CMDReSequel Reconstruct stackoverflow PostgreSQL 1 gemini-2.5-pro
# $CMDReSequel Reconstruct publicbibenchmark PostgreSQL 1 gemini-2.5-pro
# $CMDReSequel Reconstruct dsb PostgreSQL 1 gemini-2.5-pro
# $CMDReSequel Reconstruct imdb_13k PostgreSQL 1 gemini-2.5-pro

# $CMDReSequel Reconstruct imdb PostgreSQL 1 gpt-oss-120b
# $CMDReSequel Reconstruct imdb_d PostgreSQL 1 gpt-oss-120b
# $CMDReSequel Reconstruct tpch PostgreSQL 1 gpt-oss-120b
# $CMDReSequel Reconstruct stats PostgreSQL 1 gpt-oss-120b
# $CMDReSequel Reconstruct stackoverflow PostgreSQL 1 gpt-oss-120b
# $CMDReSequel Reconstruct publicbibenchmark PostgreSQL 1 gpt-oss-120b

# $CMDReSequel Reconstruct imdb MySQL 1 gemini-2.5-pro
# $CMDReSequel Reconstruct imdb_d MySQL 1 gemini-2.5-pro
# $CMDReSequel Reconstruct tpch MySQL 1 gemini-2.5-pro
# $CMDReSequel Reconstruct stats MySQL 1 gemini-2.5-pro
# $CMDReSequel Reconstruct stackoverflow MySQL 1 gemini-2.5-pro
# $CMDReSequel Reconstruct publicbibenchmark MySQL 1 gemini-2.5-pro

# $CMDReSequel Reconstruct imdb MySQL 1 gpt-oss-120b
# $CMDReSequel Reconstruct imdb_d MySQL 1 gpt-oss-120b
# $CMDReSequel Reconstruct tpch MySQL 1 gpt-oss-120b
# $CMDReSequel Reconstruct stats MySQL 1 gpt-oss-120b
# $CMDReSequel Reconstruct stackoverflow MySQL 1 gpt-oss-120b
# $CMDReSequel Reconstruct publicbibenchmark MySQL 1 gpt-oss-120b

# $CMDReSequel Reconstruct imdb DuckDB 1 gemini-2.5-pro
# $CMDReSequel Reconstruct imdb_d DuckDB 1 gemini-2.5-pro
# $CMDReSequel Reconstruct tpch DuckDB 1 gemini-2.5-pro
# $CMDReSequel Reconstruct stats DuckDB 1 gemini-2.5-pro
# $CMDReSequel Reconstruct stackoverflow DuckDB 1 gemini-2.5-pro
# $CMDReSequel Reconstruct publicbibenchmark DuckDB 1 gemini-2.5-pro

# $CMDReSequel Reconstruct imdb DuckDB 1 gpt-oss-120b
# $CMDReSequel Reconstruct imdb_d DuckDB 1 gpt-oss-120b
# $CMDReSequel Reconstruct tpch DuckDB 1 gpt-oss-120b
# $CMDReSequel Reconstruct stats DuckDB 1 gpt-oss-120b
# $CMDReSequel Reconstruct stackoverflow DuckDB 1 gpt-oss-120b
# $CMDReSequel Reconstruct publicbibenchmark DuckDB 1 gpt-oss-120b


###  Verify
### *******
# $CMDReSequel Verify imdb PostgreSQL 1 gemini-2.5-pro PostgreSQL
# $CMDReSequel Verify imdb_d PostgreSQL 1 gemini-2.5-pro PostgreSQL
# $CMDReSequel Verify tpch PostgreSQL 1 gemini-2.5-pro PostgreSQL
# $CMDReSequel Verify stats PostgreSQL 1 gemini-2.5-pro PostgreSQL
# $CMDReSequel Verify stackoverflow PostgreSQL 1 gemini-2.5-pro PostgreSQL
# $CMDReSequel Verify publicbibenchmark PostgreSQL 1 gemini-2.5-pro DuckDB
# $CMDReSequel Verify dsb PostgreSQL 1 gemini-2.5-pro DuckDB
# $CMDReSequel Verify dsb_s100 PostgreSQL 1 gemini-2.5-pro DuckDB
# $CMDReSequel Verify imdb_13k PostgreSQL 1 gemini-2.5-pro DuckDB

# $CMDReSequel Verify imdb PostgreSQL 1 gpt-oss-120b PostgreSQL
# $CMDReSequel Verify imdb_d PostgreSQL 1 gpt-oss-120b PostgreSQL
# $CMDReSequel Verify tpch PostgreSQL 1 gpt-oss-120b PostgreSQL
#$CMDReSequel Verify stats PostgreSQL 1 gpt-oss-120b PostgreSQL
# $CMDReSequel Verify stackoverflow PostgreSQL 1 gpt-oss-120b PostgreSQL
# $CMDReSequel Verify publicbibenchmark PostgreSQL 1 gpt-oss-120b DuckDB

# $CMDReSequel Verify imdb MySQL 1 gemini-2.5-pro MySQL
# $CMDReSequel Verify imdb_d MySQL 1 gemini-2.5-pro MySQL
# $CMDReSequel Verify tpch MySQL 1 gemini-2.5-pro MySQL
#$CMDReSequel Verify stats MySQL 1 gemini-2.5-pro MySQL
# $CMDReSequel Verify stackoverflow MySQL 1 gemini-2.5-pro MySQL
# $CMDReSequel Verify publicbibenchmark MySQL 1 gemini-2.5-pro MySQL

# $CMDReSequel Verify imdb DuckDB 1 gemini-2.5-pro DuckDB
# $CMDReSequel Verify imdb_d DuckDB 1 gemini-2.5-pro DuckDB
# $CMDReSequel Verify tpch DuckDB 1 gemini-2.5-pro DuckDB
# $CMDReSequel Verify stats DuckDB 1 gemini-2.5-pro DuckDB
# $CMDReSequel Verify stackoverflow DuckDB 1 gemini-2.5-pro DuckDB
# $CMDReSequel Verify publicbibenchmark DuckDB 1 gemini-2.5-pro DuckDB
# $CMDReSequel Verify dsb DuckDB 1 gemini-2.5-pro DuckDB
# $CMDReSequel Verify dsb_s100 DuckDB 1 gemini-2.5-pro DuckDB
# $CMDReSequel Verify imdb_13k DuckDB 1 gemini-2.5-pro DuckDB

###  Verify Orig vs Rewritten
### *******
# $CMDReSequel VerifyOR imdb PostgreSQL 1 gemini-2.5-pro PostgreSQL
# $CMDReSequel VerifyOR tpch PostgreSQL 1 gemini-2.5-pro PostgreSQL
# $CMDReSequel VerifyOR stats PostgreSQL 1 gemini-2.5-pro PostgreSQL
# $CMDReSequel VerifyOR stackoverflow PostgreSQL 1 gemini-2.5-pro PostgreSQL
# $CMDReSequel VerifyOR publicbibenchmark PostgreSQL 1 gemini-2.5-pro PostgreSQL

# $CMDReSequel VerifyOR imdb PostgreSQL 1 gpt-oss-120b PostgreSQL
# $CMDReSequel VerifyOR tpch PostgreSQL 1 gpt-oss-120b PostgreSQL
# $CMDReSequel VerifyOR stats PostgreSQL 1 gpt-oss-120b PostgreSQL
# $CMDReSequel VerifyOR stackoverflow PostgreSQL 1 gpt-oss-120b PostgreSQL
# $CMDReSequel VerifyOR publicbibenchmark PostgreSQL 1 gpt-oss-120b PostgreSQL

# $CMDReSequel VerifyOR imdb MySQL 1 gemini-2.5-pro MySQL
# $CMDReSequel VerifyOR tpch MySQL 1 gemini-2.5-pro MySQL
# $CMDReSequel VerifyOR stats MySQL 1 gemini-2.5-pro MySQL
# $CMDReSequel VerifyOR stackoverflow MySQL 1 gemini-2.5-pro MySQL
# $CMDReSequel VerifyOR publicbibenchmark MySQL 1 gemini-2.5-pro MySQL

# $CMDReSequel VerifyOR imdb DuckDB 1 gemini-2.5-pro DuckDB
# $CMDReSequel VerifyOR tpch DuckDB 1 gemini-2.5-pro DuckDB
# $CMDReSequel VerifyOR stats DuckDB 1 gemini-2.5-pro DuckDB
# $CMDReSequel VerifyOR stackoverflow DuckDB 1 gemini-2.5-pro DuckDB
# $CMDReSequel VerifyOR publicbibenchmark DuckDB 1 gemini-2.5-pro DuckDB


## Run Rewrite Queries
#********************
# $CMDRunReSequel stats PostgreSQL gemini-2.5-pro
# $CMDRunReSequel stats_ceb PostgreSQL gemini-2.5-pro
# $CMDRunReSequel tpch PostgreSQL gemini-2.5-pro
# $CMDRunReSequel stackoverflow PostgreSQL gemini-2.5-pro
# $CMDRunReSequel imdb PostgreSQL gemini-2.5-pro
# $CMDRunReSequel imdb_13k PostgreSQL gemini-2.5-pro
# $CMDRunReSequel publicbibenchmark PostgreSQL gemini-2.5-pro
# $CMDRunReSequel dsb PostgreSQL gemini-2.5-pro
# $CMDRunReSequel dsb_s100 PostgreSQL gemini-2.5-pro

# $CMDRunReSequel stats PostgreSQL gpt-oss-120b
# $CMDRunReSequel stats_ceb PostgreSQL gpt-oss-120b
# $CMDRunReSequel tpch PostgreSQL gpt-oss-120b
# $CMDRunReSequel stackoverflow PostgreSQL gpt-oss-120b
# $CMDRunReSequel imdb PostgreSQL gpt-oss-120b
# $CMDRunReSequel imdb_13k PostgreSQL gpt-oss-120b
# $CMDRunReSequel publicbibenchmark PostgreSQL gpt-oss-120b
# $CMDRunReSequel dsb PostgreSQL gpt-oss-120b
# $CMDRunReSequel dsb_s100 PostgreSQL gpt-oss-120b

# $CMDRunReSequel imdb MySQL gemini-2.5-pro
$CMDRunReSequel imdb_13k MySQL gemini-2.5-pro
# $CMDRunReSequel stats MySQL gemini-2.5-pro
# $CMDRunReSequel stats_ceb MySQL gemini-2.5-pro
# $CMDRunReSequel stackoverflow MySQL gemini-2.5-pro
# $CMDRunReSequel tpch MySQL gemini-2.5-pro
# $CMDRunReSequel publicbibenchmark MySQL gemini-2.5-pro

# $CMDRunReSequel imdb DuckDB gemini-2.5-pro
# $CMDRunReSequel imdb_13k DuckDB gemini-2.5-pro
# $CMDRunReSequel stats DuckDB gemini-2.5-pro
# $CMDRunReSequel stats_ceb DuckDB gemini-2.5-pro
# $CMDRunReSequel stackoverflow DuckDB gemini-2.5-pro
# $CMDRunReSequel tpch DuckDB gemini-2.5-pro
# $CMDRunReSequel publicbibenchmark DuckDB gemini-2.5-pro
# $CMDRunReSequel dsb DuckDB gemini-2.5-pro
# $CMDRunReSequel dsb_s100 DuckDB gemini-2.5-pro

# $CMDRunReSequel imdb DuckDB gpt-oss-120b
# $CMDRunReSequel imdb_13k DuckDB gpt-oss-120b
# $CMDRunReSequel stats DuckDB gpt-oss-120b
# $CMDRunReSequel stats_ceb DuckDB gpt-oss-120b
# $CMDRunReSequel stackoverflow DuckDB gpt-oss-120b
# $CMDRunReSequel tpch DuckDB gpt-oss-120b
# $CMDRunReSequel publicbibenchmark DuckDB gpt-oss-120b
# $CMDRunReSequel dsb DuckDB gpt-oss-120b
# $CMDRunReSequel dsb_s100 DuckDB gpt-oss-120b


## Run Rewrite Queries OR
#********************
# $CMDRunReSequelOR stats PostgreSQL gemini-2.5-pro
# $CMDRunReSequelOR tpch PostgreSQL gemini-2.5-pro
# $CMDRunReSequelOR stackoverflow PostgreSQL gemini-2.5-pro
# $CMDRunReSequelOR imdb PostgreSQL gemini-2.5-pro
# $CMDRunReSequelOR publicbibenchmark PostgreSQL gemini-2.5-pro

# $CMDRunReSequelOR stats PostgreSQL gpt-oss-120b
# $CMDRunReSequelOR tpch PostgreSQL gpt-oss-120b
# $CMDRunReSequelOR stackoverflow PostgreSQL gpt-oss-120b
# $CMDRunReSequelOR imdb PostgreSQL gpt-oss-120b
# $CMDRunReSequelOR publicbibenchmark PostgreSQL gpt-oss-120b

# $CMDRunReSequelOR imdb MySQL gemini-2.5-pro
# $CMDRunReSequelOR imdb_d MySQL gemini-2.5-pro
# $CMDRunReSequelOR stats MySQL gemini-2.5-pro
# $CMDRunReSequelOR stackoverflow MySQL gemini-2.5-pro
# $CMDRunReSequelOR tpch MySQL gemini-2.5-pro
# $CMDRunReSequelOR publicbibenchmark MySQL gemini-2.5-pro

# $CMDRunReSequelOR imdb DuckDB gemini-2.5-pro
# $CMDRunReSequelOR stats DuckDB gemini-2.5-pro
# $CMDRunReSequelOR stackoverflow DuckDB gemini-2.5-pro
# $CMDRunReSequelOR tpch DuckDB gemini-2.5-pro
# $CMDRunReSequelOR publicbibenchmark DuckDB gemini-2.5-pro

# $CMDRunReSequelOR imdb DuckDB gpt-oss-120b
# $CMDRunReSequelOR stats DuckDB gpt-oss-120b
# $CMDRunReSequelOR stackoverflow DuckDB gpt-oss-120b
# $CMDRunReSequelOR tpch DuckDB gpt-oss-120b
# $CMDRunReSequelOR publicbibenchmark DuckDB gpt-oss-120b


## Run Baselines
#***************
# $CMDBaseline stats PostgreSQL 1
# $CMDBaseline stats_ceb PostgreSQL 1
# $CMDBaseline tpch PostgreSQL 1
# $CMDBaseline stackoverflow PostgreSQL 1
# $CMDBaseline imdb PostgreSQL 1
# $CMDBaseline imdb_13k PostgreSQL 1
# $CMDBaseline publicbibenchmark PostgreSQL 1 
# $CMDBaseline dsb PostgreSQL 1 
# $CMDBaseline dsb_s100 PostgreSQL 1 

# $CMDBaseline imdb MySQL 1
# $CMDBaseline imdb_13k MySQL 1
# $CMDBaseline tpch MySQL 1
# $CMDBaseline stats MySQL 1
# $CMDBaseline stats_ceb MySQL 1
# $CMDBaseline stackoverflow MySQL 1
# $CMDBaseline publicbibenchmark MySQL 1 

# $CMDBaseline imdb DuckDB 1
# $CMDBaseline imdb_13k DuckDB 1
# $CMDBaseline tpch DuckDB 1
# $CMDBaseline stats DuckDB 1
# $CMDBaseline stats_ceb DuckDB 1
# $CMDBaseline stackoverflow DuckDB 1
# $CMDBaseline publicbibenchmark DuckDB 1
# $CMDBaseline dsb DuckDB 1
# $CMDBaseline dsb_s100 DuckDB 1

#########################################################################
# $CMDReSequel Reconstruct tpch_s1 PostgreSQL 1 gemini-2.5-pro
# $CMDReSequel Reconstruct tpch_s2 PostgreSQL 1 gemini-2.5-pro
# $CMDReSequel Reconstruct tpch_s3 PostgreSQL 1 gemini-2.5-pro
# $CMDReSequel Reconstruct tpch_s4 PostgreSQL 1 gemini-2.5-pro
# $CMDReSequel Reconstruct tpch_s5 PostgreSQL 1 gemini-2.5-pro
# $CMDReSequel Reconstruct tpch_s6 PostgreSQL 1 gemini-2.5-pro
# $CMDReSequel Reconstruct tpch_s7 PostgreSQL 1 gemini-2.5-pro
# $CMDReSequel Reconstruct tpch_s8 PostgreSQL 1 gemini-2.5-pro
# $CMDReSequel Reconstruct tpch_s9 PostgreSQL 1 gemini-2.5-pro
# $CMDReSequel Reconstruct tpch_s10 PostgreSQL 1 gemini-2.5-pro

# $CMDReSequel Reconstruct tpch_s1 PostgreSQL 1 gpt-oss-120b
# $CMDReSequel Reconstruct tpch_s2 PostgreSQL 1 gpt-oss-120b
# $CMDReSequel Reconstruct tpch_s3 PostgreSQL 1 gpt-oss-120b
# $CMDReSequel Reconstruct tpch_s4 PostgreSQL 1 gpt-oss-120b
# $CMDReSequel Reconstruct tpch_s5 PostgreSQL 1 gpt-oss-120b
# $CMDReSequel Reconstruct tpch_s6 PostgreSQL 1 gpt-oss-120b
# $CMDReSequel Reconstruct tpch_s7 PostgreSQL 1 gpt-oss-120b
# $CMDReSequel Reconstruct tpch_s8 PostgreSQL 1 gpt-oss-120b
# $CMDReSequel Reconstruct tpch_s9 PostgreSQL 1 gpt-oss-120b
# $CMDReSequel Reconstruct tpch_s10 PostgreSQL 1 gpt-oss-120b


# $CMDReSequel VerifyOR tpch_s1 PostgreSQL 1 gemini-2.5-pro PostgreSQL
# $CMDReSequel VerifyOR tpch_s2 PostgreSQL 1 gemini-2.5-pro PostgreSQL
# $CMDReSequel VerifyOR tpch_s3 PostgreSQL 1 gemini-2.5-pro PostgreSQL
# $CMDReSequel VerifyOR tpch_s4 PostgreSQL 1 gemini-2.5-pro PostgreSQL
# $CMDReSequel VerifyOR tpch_s5 PostgreSQL 1 gemini-2.5-pro PostgreSQL
# $CMDReSequel VerifyOR tpch_s6 PostgreSQL 1 gemini-2.5-pro PostgreSQL
# $CMDReSequel VerifyOR tpch_s7 PostgreSQL 1 gemini-2.5-pro PostgreSQL
# $CMDReSequel VerifyOR tpch_s8 PostgreSQL 1 gemini-2.5-pro PostgreSQL
# $CMDReSequel VerifyOR tpch_s9 PostgreSQL 1 gemini-2.5-pro PostgreSQL
# $CMDReSequel VerifyOR tpch_s10 PostgreSQL 1 gemini-2.5-pro PostgreSQL

# $CMDReSequel VerifyOR tpch_s1 PostgreSQL 1 gpt-oss-120b PostgreSQL
# $CMDReSequel VerifyOR tpch_s2 PostgreSQL 1 gpt-oss-120b PostgreSQL
# $CMDReSequel VerifyOR tpch_s3 PostgreSQL 1 gpt-oss-120b PostgreSQL
# $CMDReSequel VerifyOR tpch_s4 PostgreSQL 1 gpt-oss-120b PostgreSQL
# $CMDReSequel VerifyOR tpch_s5 PostgreSQL 1 gpt-oss-120b PostgreSQL
# $CMDReSequel VerifyOR tpch_s6 PostgreSQL 1 gpt-oss-120b PostgreSQL
# $CMDReSequel VerifyOR tpch_s7 PostgreSQL 1 gpt-oss-120b PostgreSQL
# $CMDReSequel VerifyOR tpch_s8 PostgreSQL 1 gpt-oss-120b PostgreSQL
# $CMDReSequel VerifyOR tpch_s9 PostgreSQL 1 gpt-oss-120b PostgreSQL
# $CMDReSequel VerifyOR tpch_s10 PostgreSQL 1 gpt-oss-120b PostgreSQL


# $CMDRunReSequelMicroOR tpch_s1 PostgreSQL gemini-2.5-pro tpch
# $CMDRunReSequelMicroOR tpch_s2 PostgreSQL gemini-2.5-pro tpch
# $CMDRunReSequelMicroOR tpch_s3 PostgreSQL gemini-2.5-pro tpch
# $CMDRunReSequelMicroOR tpch_s4 PostgreSQL gemini-2.5-pro tpch
# $CMDRunReSequelMicroOR tpch_s5 PostgreSQL gemini-2.5-pro tpch
# $CMDRunReSequelMicroOR tpch_s6 PostgreSQL gemini-2.5-pro tpch
# $CMDRunReSequelMicroOR tpch_s7 PostgreSQL gemini-2.5-pro tpch
# $CMDRunReSequelMicroOR tpch_s8 PostgreSQL gemini-2.5-pro tpch
# $CMDRunReSequelMicroOR tpch_s9 PostgreSQL gemini-2.5-pro tpch
# $CMDRunReSequelMicroOR tpch_s10 PostgreSQL gemini-2.5-pro tpch

# $CMDRunReSequelMicroOR tpch_s1 PostgreSQL gpt-oss-120b tpch
# $CMDRunReSequelMicroOR tpch_s2 PostgreSQL gpt-oss-120b tpch
# $CMDRunReSequelMicroOR tpch_s3 PostgreSQL gpt-oss-120b tpch
# $CMDRunReSequelMicroOR tpch_s4 PostgreSQL gpt-oss-120b tpch
# $CMDRunReSequelMicroOR tpch_s5 PostgreSQL gpt-oss-120b tpch
# $CMDRunReSequelMicroOR tpch_s6 PostgreSQL gpt-oss-120b tpch
# $CMDRunReSequelMicroOR tpch_s7 PostgreSQL gpt-oss-120b tpch
# $CMDRunReSequelMicroOR tpch_s8 PostgreSQL gpt-oss-120b tpch
# $CMDRunReSequelMicroOR tpch_s9 PostgreSQL gpt-oss-120b tpch
# $CMDRunReSequelMicroOR tpch_s10 PostgreSQL gpt-oss-120b tpch
