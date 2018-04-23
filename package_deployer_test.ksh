#!/bin/bash
#-----------------------------------------------------------------------------
# @(#) package_deployer.ksh
# Name :package_deployer.ksh
# Type :job shell (UNIX)
# Aim : 
# Author: Shifali Raina
# date creation:  31/08/16
# date lastupdated:1/09/16
#-----------------------------------------------------------------------------/
set -e

log() {
    date_str=`date`
    echo -e "[$date_str] $1" >> $2
}

usage() {
  echo "4 arguments need to be provisioned."
  echo "First argument: Package version name"
  echo "Second argument: Target environment"
  echo "Third argument: Deployment path"
  echo "Fourth argument: Environment password"
  exit 1
}

update_permissions() {
    #dos2unix ${2}/package/${1}/*.ksh 2>/dev/null
    chmod -R 775 ${2}/package/${1}/* 2>/dev/null
    log "Updated permissions" ${3}
}

launch_scripts() {
     APP=`echo "${3}" | cut -f4 -d'/'`
    cat ../seq.txt | while read line; do
	cd  ${3}/package/${1} >> ${4}
	echo "-----Executing $line-----" >> ${4}
	bash ${line} ${1} ${2} $3 >> ${4} 
      EXIT_CODE=$?
      if [ ${EXIT_CODE} -ne 0 ]; then
      echo -e "\n $line failed.\n"
	  shred -u ${3}/package/$1/${APP}.env
      exit ${EXIT_CODE}
      fi
    done
	shred -u ${3}/package/$1/${APP}.env
}

#function to untar package
untar_package(){
mkdir -p ${1} >> $2
mv ${1}.tar.gz ${1} >> $2
cd ${1} >> $2
tar -xvzf ${1}.tar.gz >> $2
}

generate_env(){
#if [ -f ${3}/password_propagaties/password.txt.gpg ]; then
 #cat ${3}/password_propagaties/password.txt >> ${3}/package/$1/data/config/*.${2}.env
# APP=`echo "${1}" | cut -f1 -d'_' | tr '[:upper:]' '[:lower:]'`
# cd ${3}/password_propagaties
 #gpg --batch --yes --passphrase "${4}" -o password.txt --decrypt password.txt.gpg
 APP=`echo "${3}" | cut -f4 -d'/'`
 #cat ${3}/password_propagaties/password.txt >> ${3}/package/$1/data/config/${APP}.${2}.env
 cp ${3}/package/$1/data/config/${APP}.${2}.env  ${3}/package/$1/${APP}.env >> $5
 echo "---env file generated ----" >> $5
# shred -u password.txt
 #cd -
#fi
}

# Check for number of arguments passed
if [ "$#" -ne 4 ]; then
 
        usage
    fi


# Create the log file name
date_log=`date +%Y%m%d`
logfile="${3}/logs/package_deployer_${1}_${date_log}.log"

#Change directory to the deployment path
cd ${3}/package >> ${logfile}

# Untar the package
untar_package $1 ${logfile}

# update permissions for all scripts before execution
update_permissions ${1} ${3} ${logfile}

#populate passwords and generate .env file

generate_env ${1} ${2} ${3} ${4} ${logfile}


# launch jobs indicated from the sequence file
launch_scripts ${1} ${2} ${3} ${logfile}
