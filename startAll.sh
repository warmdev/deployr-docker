#!/bin/bash
INSTALL_FOLDER=/home/deployr/deployr/7.4.1
$INSTALL_FOLDER/mongo/mongod.sh start
$INSTALL_FOLDER/rserve/rserve.sh start
#yes | $INSTALL_FOLDER/deployr/tools/setWebContext.sh -ip 192.168.99.100 -disableauto
$INSTALL_FOLDER/tomcat/tomcat7/bin/catalina.sh run > $INSTALL_FOLDER/tomcat/tomcat7/logs/tomcat.log 2>&1
