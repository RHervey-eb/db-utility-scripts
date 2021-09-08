#!/bin/bash

# Script used to be able to login to a particular database in a particular environment using the info in the pgpass file

pgPassFile="${HOME}/.pgpass"

[[ -f "${pgPassFile}" ]] || { echo >&2 "The required pgpass file at location \"${pgPassFile}\" doesn't exist."; exit 1; }

function printAvailableDbs() {
  cat "${pgPassFile}" | cut -d ':' -f -4 | while read -r line; do 
    dbNameInFile="$(echo "${line}" | cut -d ':' -f 3)"; 
    usernameInFile="$(echo "${line}" | cut -d ':' -f 4)"; 
    environmentInFile="$(echo "${line}" | cut -d ':' -f 1 | cut -d '.' -f 1 | awk -F '-' '{print $NF}')"; 
    echo "dbName: \"${dbNameInFile}\" username: \"${usernameInFile}\" environmentName: \"${environmentInFile}\""; 
  done
}

function usage() {
  cat >&2 <<EOF
  
  Usage: $(basename $0) <dbName> <username> <environmentName>

  This is a utility for reading the db login possiblities from the ~/.pgpass file and making login lookups possible by
    passing in the database name and environment name

  combos available:

$(printAvailableDbs)

EOF
}

if [[ $# != 3 ]]; then
  usage
  exit 1
fi

dbNamePassedIn="${1}"
usernamePassedIn="${2}"
envPassedIn="${3}"

selectedString="$(cat "${pgPassFile}" | grep "${dbNamePassedIn}" | grep "${usernamePassedIn}"| grep "${envPassedIn}")"

if [[ $(echo "${selectedString}" | wc -l) -ne 1 ]]; then
  echo >&2 "The slected string didn't match one line, can't connect to db: \"${dbNamePassedIn}\" for environment: \"${envPassedIn}\""
  exit 1;
else
  echo "Selected line: $(echo "${selectedString}" | cut -d ':' -f -4)"
fi


THE_PG_HOST="$(echo "${selectedString}" | cut -d ':' -f 1)"
THE_PG_PORT="$(echo "${selectedString}" | cut -d ':' -f 2)"
THE_PG_DB="$(echo "${selectedString}" | cut -d ':' -f 3)"
THE_PG_USER="$(echo "${selectedString}" | cut -d ':' -f 4)"

connectionString="psql -h ${THE_PG_HOST} -p ${THE_PG_PORT} -U ${THE_PG_USER}  -d ${THE_PG_DB}"
echo "Running with connection: ${connectionString}"
$connectionString
