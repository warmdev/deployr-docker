#!/bin/bash
EDITION=community
RETVAL=0
NOASK="false"
DEBUG_LOGS="false"
NOLICENSE="false"
NODE=0
DATABASE_SERVER_NAME="localhost"
DATABASE_PORT="7403"
REMOTE_DATA_BASE=local
INSTALL_FOLDER=""
ERROR_OK=0
SILENT_MODE=0
IP=""
REDHAT_VERSION=64
VERSION=7.4
MINOR_VERSION=1
REVO_VERSION=7.4.1
REVO_BIN_STRING=Revo-$VERSION
R_VERSION=R-3.1.2
LINUX_VERSION=5
TOMCAT_VERSION=7.0.34
TOMCAT_SSL_PORT=7401
TOMCAT_PORT=7400
TOMCAT_SHUTDOWN_PORT=7402
RSERVE_PORT=7404
RSERVE_CANCEL_PORT=7405
USER=`whoami`
GROUP=`id -g -n $USER`
IS_ROOT=0
R=1
RBIN="/usr/bin/R"
R_HOME=/usr/lib64/R
LINUX=redhat
DB_PATH=""
##HOST_NAME=`/sbin/ifconfig  | grep --max-count=1 'inet'| grep --max-count=1 -v '127.0.0.1' | cut -d: -f2 | awk '{ print $1}'`
##HOST_NAME=`/sbin/ifconfig | grep --max-count=1 'inet'| grep --max-count=1 -v '127.0.0.1' | cut -d: -f2 | awk '{ print $1}'`
HOST_NAME=localhost

checkRoot() {
        uid=`id -u`
        if [ 0 -eq $uid ] ; then
            IS_ROOT=1
            USER=apache
            GROUP=apache
            grepout=`grep -i "^apache" /etc/passwd`
	    if [ 0 -eq ${#grepout} ] ; then
               useradd apache >>/dev/null 2>&1
               usermod -s /sbin/nologin apache  >> $PWDD/install_log.txt 2>&1
            fi
            grepout=`grep -i "^apache" /etc/group`
	    if [ 0 -eq ${#grepout} ] ; then
               groupadd apache >>/dev/null 2>&1
            fi
            INSTALL_FOLDER=/opt/deployr/$VERSION.$MINOR_VERSION
        else
            IS_ROOT=0
            INSTALL_FOLDER=$HOME/deployr/$VERSION.$MINOR_VERSION
        fi
}

start() {
# check arguments
    for var in "$@"
    do
        #  check for unattended install
        if [ "--no-ask" = $var ] ; then
           NOASK="true"
        elif [ "--debuglogs" = $var ] ; then
           DEBUG_LOGS="true"
        elif [ "--nolicense" = $var ] ; then
           NOLICENSE="true"
        fi
    done
    
        if [ $NOASK = "true" ] ; then
            checkRelease
            checkRoot
            checkPrerequisites
            mkdir -p $INSTALL_FOLDER
            getMongodbpath
            installServer
        else 
            if [ $NOLICENSE = "false" ] ; then
                  confirmLicense
            fi
            checkRelease
            checkRoot 
            getInstallOption
        fi
}

installServer() {
        configureRserve
        installMongo	        
	installTomcat
	configureDeployrServer
        installShellScripts       
	exitCode=$?
	exitProgram $exitCode
}

installDatabase() {       
        installMongo
        exitCode=$?
        exitProgram $exitCode
}

checkRelease() {
        if [ -e /etc/redhat-release ]; then
	    rel=`cat /etc/redhat-release`
	    x=${rel#*release}
	    major=${x:1:1}
            LINUX_VERSION=RHEL$major
            
	    minor=${x:3:2}
            REDHAT_VERSION=$major$minor
	    if [ $major -eq 5 ]; then
		if [ $minor -lt 4 ]; then
			releaseError
		fi
	    else
		if [ $major -lt 5 ]; then
			releaseError
		fi
	    fi
        elif [ -e /etc/SuSE-release ]; then
            rel=`cat /etc/SuSE-release`
            grepout=`echo $rel | grep -c openSUSE`
            if [ 1 -eq ${#grepout} ] ; then
                LINUX=sles
            else
	    x=${rel#*VERSION}
	    major=${x:3:2}
            LINUX_VERSION=SLES$major
	    minor=${x:19:1}
	    if [ $major -eq 11 ]; then
		if [ $minor -lt 2 ]; then
			SLESreleaseError
		fi
	    else
		SLESreleaseError
	    fi
            LINUX=sles
            fi
        else
            LINUX=ubuntu
        fi

}

checkPrerequisites() {
    analyzeJava
if [ $? != 0 ] ; then
    exitWithError -1
fi


analyzeR open $NOASK
if [ $? != 0 ] ; then
    exitWithError -1
fi

analyzeRserve $PWDD/installFiles/rserve
if [ $? != 0 ] ; then
    exitWithError -1
fi
    
}

checkPrerequisitesForNode() {
analyzeR
if [ $? != 0 ] ; then
    exitWithError -1
fi

analyzeRserve $PWDD/installFiles/rserve
if [ $? != 0 ] ; then
    exitWithError -1
fi
}

releaseError() {
	printAttentionMsg "version 5.4 or greater is required to install this software "
        echo "version 5.4 or greater is required to install this software " >> $PWDD/install_log.txt 2>&1
	exitWithError -1
}

SLESreleaseError() {
	printAttentionMsg "version 11.2 or greater is required to install this software "
        echo "version 11.2 or greater is required to install this software " >> $PWDD/install_log.txt 2>&1
	exitWithError -1
}

exitProgram() {
        exit $1
}

out() {

        if [ -n "$OUTPUT_FILE" ] ; then
                printf "%s\n" "$@" >> "$OUTPUT_FILE"
        elif [ 0 -eq $SILENT_MODE ] ; then
                printf "%s\n" "$@"
        fi
}

installShellScripts() {
cd $PWDD/installFiles
tools/installShellScripts.sh $PWDD $INSTALL_FOLDER $REMOTE_DATA_BASE $NODE
RETVAL=$?
if [ $RETVAL -ne 0 ] ; then
    echo "Error in installShellScripts"  | tee -a $PWDD/install_log.txt 2>&1
    exitWithError $RETVAL
fi
echo "Startup/Shutdown shell scripts installed" >> $PWDD/install_log.txt 2>&1
}

installMongo() {
cd $PWDD/installFiles
mongo/install.sh $LINUX $PWDD $INSTALL_FOLDER $DB_PATH $USER $GROUP $HOST_NAME  $DATABASE_SERVER_NAME $REMOTE_DATA_BASE $TOMCAT_PORT $DATABASE_PORT $IS_ROOT
RETVAL=$?
if [ $RETVAL -ne 0 ] ; then
    echo "Error in installMongo" | tee -a $PWDD/install_log.txt 2>&1
    exitWithError $RETVAL
fi
echo "Mongo installed" >> $PWDD/install_log.txt 2>&1	
}

configureRserve() {
cd $PWDD/installFiles
rserve/configure.sh $LINUX $PWDD $INSTALL_FOLDER $USER $GROUP $RRE_PATH $RSERVE_PATH $IS_ROOT $VERSION
RETVAL=$?
if [ $RETVAL -ne 0 ] ; then
    exitWithError $RETVAL
fi
echo "Rserve installed" >> $PWDD/install_log.txt 2>&1
}

installTomcat() {
cd $PWDD/installFiles
tomcat/install.sh $LINUX $PWDD $INSTALL_FOLDER $TOMCAT_PORT $TOMCAT_SSL_PORT $TOMCAT_SHUTDOWN_PORT $IS_ROOT $USER $EDITION
RETVAL=$?
if [ $RETVAL -ne 0 ] ; then
echo "Error in installTomcat"
exitWithError $RETVAL
fi
echo "tomcat configured" >> $PWDD/install_log.txt 2>&1
}

configureDeployrServer() {
cd $PWDD/installFiles
config/configure.sh $PWDD $INSTALL_FOLDER $RBIN $NODE $REMOTE_DATA_BASE $DATABASE_SERVER_NAME $DEBUG_LOGS $EDITION $IS_ROOT $HOST_NAME
RETVAL=$?
if [ $RETVAL -ne 0 ] ; then
echo "Error in configureDeployrServer"
exitWithError $RETVAL
fi
echo "DeployR server configured" >> $PWDD/install_log.txt 2>&1
}

installDeployrDatabase() {
##                mkdir $INSTALL_FOLDER/deployr/database >> $PWDD/install_log.txt 2>&1
                if [ $IS_ROOT -eq 1 ] ; then
              	    chown -R $USER.$GROUP $INSTALL_FOLDER
                    chmod -R 775 $INSTALL_FOLDER
        	fi
# start mongo database
                $INSTALL_FOLDER/mongo/mongod.sh start >> $PWDD/install_log.txt 2>&1
                RETVAL=$?
		if [ $RETVAL -ne 0 ] ; then
                    echo "Error in starting Mongo"  | tee -a $PWDD/install_log.txt 2>&1
		    exitWithError $RETVAL
		fi
                sleep 5
                $PWDD/installFiles/installDeployrTables.sh $PWDD $INSTALL_FOLDER $PWDD/install_log.txt
                RETVAL=$?
		if [ $RETVAL -ne 0 ] ; then
		    echo "Error in installDeployrTables"  | tee -a $PWDD/install_log.txt 2>&1
		    exitWithError $RETVAL
		fi
                echo "MongoDB database configured"  | tee -a $PWDD/install_log.txt 2>&1
}

#restart() {
#	out "Now starting Rserve and Tomcat. Please wait as this may take a moment." | tee -a $PWDD/install_log.txt 2>&1

#	$INSTALL_FOLDER/tomcat/tomcat7.sh start >> $PWDD/install_log.txt 2>&1
#        cd $INSTALL_FOLDER
#        $INSTALL_FOLDER/rserve/rserve.sh start >> $PWDD/install_log.txt 2>&1
#	printURL
#}

restartNode() {
	out "Now restarting Rserve. Please wait as this may take a moment." | tee -a $PWDD/install_log.txt 2>&1
        $INSTALL_FOLDER/rserve/rserve.sh restart >> $PWDD/install_log.txt 2>&1
}

acknowledgeInuts() {

    echo "**********************************************************************"
    echo "*"
    echo "*     DEPLOYR INSTALLATION/CONFIGURATION CONFIRMATION"
    echo "*"  
    echo "*"
    echo "*     DeployR will be installed using the following paths and ports:"
    echo "*"
    echo "*         Install DeployR under:       $INSTALL_FOLDER"
    echo "*" 
    echo "*         MongoDB data folder:         $DB_PATH"
    echo "*"
    echo "*         Port specified for Tomcat:   $TOMCAT_PORT"
    echo "*"
    echo "*"
    echo "*     Proceed with installation?  y or n"
    echo "*"
    echo "**********************************************************************"
    read ans
    if [[ ! $ans =~ ^[Yy]$ ]] ; then
	echo "installation terminated"
        rm -rf $INSTALL_FOLDER >> $PWDD/install_log.txt 2>&1
        exit 0
    fi
}

printURL() {
        echo "**********************************************************************" | tee -a $PWDD/install_log.txt 2>&1
        echo "*" | tee -a $PWDD/install_log.txt 2>&1
        echo "*     The installation is complete." | tee -a $PWDD/install_log.txt 2>&1
        echo "*" | tee -a $PWDD/install_log.txt 2>&1
        echo "*     If you are using the IPTABLES firewall, use the iptables command" | tee -a $PWDD/install_log.txt 2>&1
        echo "*     to open the ports listed in the 'Configuring DeployR' section of" | tee -a $PWDD/install_log.txt 2>&1
        echo "*     installation documentation." | tee -a $PWDD/install_log.txt 2>&1
        echo "*" | tee -a $PWDD/install_log.txt 2>&1
        echo "*     Open the following URL in your browser to access DeployR's landing page:" | tee -a $PWDD/install_log.txt 2>&1
        echo "*" | tee -a $PWDD/install_log.txt 2>&1
        echo "*     http://$HOST_NAME:$TOMCAT_PORT/revolution" | tee -a $PWDD/install_log.txt 2>&1
        echo "*" | tee -a $PWDD/install_log.txt 2>&1
        echo "*     Please log in as 'admin'. For your security, you must set a new password for that account." | tee -a $PWDD/install_log.txt 2>&1
        echo "*     Note: The default password for the 'admin' and 'testuser' accounts is 'changeme'." | tee -a $PWDD/install_log.txt 2>&1
        echo "*" | tee -a $PWDD/install_log.txt 2>&1
	echo "*     From there, you can access:" | tee -a $PWDD/install_log.txt 2>&1
        echo "*     - DeployR Administration Console" | tee -a $PWDD/install_log.txt 2>&1
        echo "*     - DeployR Repository Manager" | tee -a $PWDD/install_log.txt 2>&1
        echo "*     - Product Documentation" | tee -a $PWDD/install_log.txt 2>&1
        echo "*     - Server status information and Diagnostic tools" | tee -a $PWDD/install_log.txt 2>&1
        echo "*     - DeployR API Explorer" | tee -a $PWDD/install_log.txt 2>&1
        echo "*" | tee -a $PWDD/install_log.txt 2>&1
        echo "*      For DeployR on an AWS EC2 instance, run $INSTALL_FOLDER/deployr/tools/setWebContext.sh -aws" | tee -a $PWDD/install_log.txt 2>&1
        echo "*      to set the server web context to your external IP for AWS. Until you do so, you will not" | tee -a $PWDD/install_log.txt 2>&1
        echo "*      be able to access the DeployR landing page or other components." | tee -a $PWDD/install_log.txt 2>&1
        echo "*" | tee -a $PWDD/install_log.txt 2>&1
        echo "**********************************************************************" | tee -a $PWDD/install_log.txt 2>&1
}

printAttentionMsg() {
	echo "**********************************************************************"
	echo "*"
	echo "*"
	echo "*     $@"
	echo "*"
	echo "*"
	echo "**********************************************************************"
}

printKeystoreMsg() {
	echo "**********************************************************************"
	echo "*"
	echo "*"
        echo "*     A certificate is needed to secure the server."
        echo "*     If you have a registered certificate (recommended),"
        echo "*     do *not* create a temporary one now."
        echo "*     If you do not create a temporary certificate now, you"
        echo "*     will be prompted for the location of your certificate."
        echo "*"
        echo "*     Create temporary keystore ?  (y or n)"
	echo "*"
	echo "*"
	echo "**********************************************************************"
}

printInstallMsg() {
	echo "**********************************************************************"
	echo "*"
        echo "*     Install DeployR ${VERSION}.${MINOR_VERSION} Server Options"
        echo "*"
        echo "*     1. Install DeployR ${VERSION}.${MINOR_VERSION} Server & Database Server (single host)"
        echo "*     2. Exit installation"
        echo "*"
        echo "*"
        echo "*     Please Select Option.  (1, 2)"
	echo "*"
	echo "**********************************************************************"
}

doInstallOptionOneorThree() {  
         	     
    checkPrerequisites
    getInstallDirectory
    getMongodbpath

    getTomcatPort
    acknowledgeInuts
    installServer
}

getInstallOption() {
        while [ 1 ]
        do
	        printInstallMsg
	        read ans
		if [ "1" = $ans ] ; then
                    doInstallOptionOneorThree
	            break
                elif [ "2" = $ans ] ; then
                    exitProgram 1
	        else
	            echo "Illegal input, Please enter 1, 2"
	            continue
	        fi
        done
}

getInstallDirectory() {

	printAttentionMsg "Please enter the folder name where DeployR ${VERSION}.${MINOR_VERSION} will be installed"
	echo " "
        echo "Hit return for default folder = ${INSTALL_FOLDER}"        
        while [ 1 ]
	do
		read ans
                if [ -z "${ans}" ] ; then                   
                   break
                fi
                echo "Is this the correct folder ?  ${ans}"
                echo "Enter y or n"
		read ans2
		if [[ $ans2 =~ ^[Yy]$ ]] ; then
                     INSTALL_FOLDER=$ans
		     break
		else
		    echo "Please re-enter folder name"
		    continue
                fi
        done

        if [ ! -e $INSTALL_FOLDER ];
        then
           mkdir -p $INSTALL_FOLDER >> $PWDD/install_log.txt 2>&1
           if [ $? -ne 0 ]
            then
                printAttentionMsg "Unable to create ${INSTALL_FOLDER}"
                echo "Unable to create ${INSTALL_FOLDER}" >> $PWDD/install_log.txt 2>&1
                exit -1
            fi
        
#  check for write permissions
        touch $INSTALL_FOLDER/deployr_temp >> $PWDD/install_log.txt 2>&1
        if [ $? -ne 0 ]
        then
            printAttentionMsg "You do not have write permissions in ${INSTALL_FOLDER}"
            exho "You do not have write permissions in ${INSTALL_FOLDER}" >> $PWDD/install_log.txt 2>&1
            exit -1
        else
            rm -f $INSTALL_FOLDER/deployr_temp >> $PWDD/install_log.txt 2>&1
        fi
        else
           echo "DeployR installed at $INSTALL_FOLDER. Please un-install before re-installing" | tee -a $PWDD/install_log.txt 2>&1
           exit -1 
        fi
## get full path in case it's a relative path
        INSTALL_FOLDER=`cd "$INSTALL_FOLDER"; pwd`
}

getUser() {

	printAttentionMsg "Please enter the user name."
	        
        while [ 1 ]
	do
		read ans
                echo "Is this the correct user ?  ${ans}"
                echo "Enter y or n"
		read ans2
		if [[ $ans2 =~ ^[Yy]$ ]] ; then
                     user=$ans
                     group=$ans2
		     break
		else
		    echo "Please re-enter user name."
		    continue
                fi
        done

}

getTomcatPort() {

	printAttentionMsg "Please enter the port for Tomcat.  Hit return for default port = ${TOMCAT_PORT}"
	        
        while [ 1 ]
	do
		read ans
                if [ -z "${ans}" ] ; then                   
                   break
                fi
                echo "Is this the correct port ?  ${ans}"
                echo "Enter y or n"
		read ans2
		if [[ $ans2 =~ ^[Yy]$ ]] ; then
                     TOMCAT_PORT=$ans
		     if [ $TOMCAT_PORT -eq $TOMCAT_PORT 2> /dev/null ]; then
                        break
                     else
                       echo "Port must be an integer. Please re-enter Tomcat port"
                       continue
                     fi

		else
		    echo "Please re-enter Tomcat port"
		    continue
                fi
        done
}

confirmLicense() {


more ../mongoLicense.txt

echo ""
read -p "I Accept the terms in the license agreement. y or n "
if [[ ! $REPLY =~ ^[Yy]$ ]]
then
    echo "license NOT accepted"
    exitWithError 0
fi

}

getMongodbpath() {
        DB_PATH=${INSTALL_FOLDER}/deployr/database
        if [ $NOASK = "false" ] ; then
        echo "**********************************************************************"
	echo "*"
	echo "*"
	echo "*     Please enter the path to the data directory (dbpath) for the MongoDB database."
        echo "*     Hit return for default dbpath = ${INSTALL_FOLDER}/deployr/database"
	echo "*"
	echo "*"
	echo "**********************************************************************"
	        
        while [ 1 ]
	do
		read ans
                if [ -z "${ans}" ] ; then                   
                   break
                fi
                echo "Is this the correct dbpath ?  ${ans}"
                echo "Enter y or n"
		read ans2
		if [[ $ans2 =~ ^[Yy]$ ]] ; then
                     DB_PATH=$ans
		     break
		else
		    echo "Please re-enter the dbpath for Mongo"
		    continue
                fi
        done
        fi
## check user has permissions to write to dbpath
        mkdir -p $DB_PATH >> $PWDD/install_log.txt 2>&1
        if [ $? -ne 0 ]
        then
            printAttentionMsg "Unable to create ${DB_PATH}"
            echo "Unable to create ${DB_PATH}" >> $PWDD/install_log.txt 2>&1
            exit -1
        fi
        if [ $IS_ROOT -eq 1 ] ; then
                    cd $DB_PATH
                    cd ..
              	    chown -R $USER.$GROUP *
                    chmod -R 775 *
        fi
## get full path in case it's a relative path
        DB_PATH=`cd "$DB_PATH"; pwd`
}

exitWithError() {
    killall -9 $INSTALL_FOLDER/mongo/mongo/bin/mongod
    cd $PWDD
    rm -rf $INSTALL_FOLDER >> $PWDD/install_log.txt 2>&1
    echo "refer to ${PWDD}/install_log.txt for details"
    exit $1 
}

cd ../
PWDD=`pwd`
source $PWDD/installFiles/properties.sh
source $PWDD/installFiles/java/java.sh $PWDD/installFiles/java
source $PWDD/installFiles/R/findR.sh $PWDD/installFiles/R
source $PWDD/installFiles/rserve/findRserve.sh $PWDD/installFiles/rserve
 
rm $PWDD/install_log.txt
cd installFiles >> $PWDD/install_log.txt 2>&1
if [ "$HOST_NAME" == " " -o "$HOST_NAME" == "" ]; then
        echo "Unable to acquire IP address"  | tee -a $PWDD/install_log.txt 2>&1
        exit -1
fi
start "$@"

