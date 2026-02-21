#!/bin/bash

JAVA_HOME="/usr/lib/jvm/java-17-openjdk-amd64"
PATH="/usr/lib/jvm/java-17-openjdk-amd64/bin":$PATH

export SPARK_HOME="/home/saeed/Apps/spark-3.5.3-bin-hadoop3"
export PATH="$SPARK_HOME/bin:$PATH"
cd $root_path