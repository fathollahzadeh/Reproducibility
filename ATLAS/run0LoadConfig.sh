#!/bin/bash

export CMD="java -Xmx28g -Xms28g -Xmn2g --add-modules jdk.incubator.vector \
            -cp SystemDS.jar:lib/* -Dlog4j.configuration=file:log4j-silent.properties \
             org.apache.sysds.api.DMLScript -exec singlenode -debug -stats"
