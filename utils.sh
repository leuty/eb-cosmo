#!/bin/bash

pWarning()
{
  msg=$1
  YELLOW='\033[1;33m'
  NC='\033[0m'
  echo -e "${YELLOW}[WARNING]${NC} ${msg}"
}

pInfo()
{
  msg=$1
  BLUE='\033[1;34m'
  NC='\033[0m'
  echo -e "${BLUE}[INFO]${NC} ${msg}"
}

pOk()
{
  msg=$1
  GREEN='\033[1;32m'
  NC='\033[0m'
  echo -e "${GREEN}[OK]${NC} ${msg}"
}

pErr()
{
    msg=$1
    RED='\033[0;31m'
    NC='\033[0m'
	echo -e "${RED}[ERROR]${NC} ${msg}"
}

exitError()
{
    RED='\033[0;31m'
    NC='\033[0m'
	echo -e "${RED}EXIT WITH ERROR${NC}"
	echo "ERROR $1: $3" 1>&2
	echo "ERROR     LOCATION=$0" 1>&2
	echo "ERROR     LINE=$2" 1>&2
	exit "$1"
}

contOrExit()
{
    info=$1
    status=$2
    if [ "${status}" -eq 0 ]
    then
        pOk "Success ${info}"
    else
        pErr "Failure ${info}"
        exit 1
    fi
}
