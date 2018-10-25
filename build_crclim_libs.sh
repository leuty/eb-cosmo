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

showUsage()
{
    echo "Usage: $(basename $0) -p project -t target -i path [-z]"
    echo ""
    echo "Arguments:"
    echo "-h           show this help message and exit"
    echo "-p project   build project: master, crclim or cordex"
    echo "-t target    build target: cpu or gpu"
    echo "-i path      install path for the modules (EB prefix, the directory must exist)"
    echo "-z           clean any existing repository, reclone it, and create new source archive"
}

showConfig()
{
    echo "==========================================================="
    echo "Compiling STELLA and the C++ DyCore as modules"
    echo "==========================================================="
    echo "Date             : $(date)"
    echo "Machine          : ${HOSTNAME}"
    echo "User             : $(whoami)"
    echo "Architecture"
    echo "   CPU           : ${CPU}"
    echo "   GPU           : ${GPU}"
    echo "Project"
    echo "   master        : ${MASTER}"
    echo "   crCRLIM       : ${CRCLIM}"
    echo "   Cordex        : ${CORDEX}"
    echo "Cleanup          : ${CLEANUP}"
    echo "Install path     : ${INSTPATH}"
    echo "==========================================================="
}

parseOptions()
{
    # set defaults
    PROJECT=OFF
    CRCLIM=OFF
    CORDEX=OFF
    MASTER=OFF
    TARGET=OFF
    INSTPATH=OFF
    GPU=OFF
    CPU=OFF
    CLEANUP=OFF
    
    while getopts ":p:t:i:hz" opt; do
        case $opt in
        p)
            PROJECT=$OPTARG
            ;;
        t)
            TARGET=$OPTARG
            ;;
        i)
            INSTPATH=$OPTARG
            ;;
        h)
            showUsage
            exit 0
            ;;
        z)
            CLEANUP=ON
            ;;
        \?)
            showUsage
            exit 1
            ;;
        :)
            showUsage
            exit 1
            ;;
        esac
    done

    if [ "${TARGET,,}" = "cpu" ]
    then
        CPU=ON
    elif [ "${TARGET,,}" = "gpu" ]
    then
        GPU=ON
    else
        pErr "Incorrect target provided: ${TARGET}"
        pErr "Target can only be CPU or GPU"
        showUsage
        exit 1
    fi

    if [ "${PROJECT,,}" = "crclim" ]
    then
        CRCLIM=ON
    elif [ "${PROJECT,,}" = "cordex" ]
    then
        CORDEX=ON
    elif [ "${PROJECT,,}" = "master" ]
    then
        MASTER=ON
    else
        pErr "Incorrect target provided: ${PROJECT}"
        pErr "Project can only be master, crclim or cordex"
        showUsage
        exit 1
    fi

    if [ ! -d "${INSTPATH}" ]
    then
        pErr "Incorrect path provided: ${INSTPATH}"
        pErr "Please create the install directory BEFORE installing the libs"
    fi
}

loadModule() 
{
    module load daint-gpu
    module load EasyBuild-custom
}

exportVar()
{
    local instPath=$1
    export EASYBUILD_PREFIX=$instPath
    export EASYBUILD_BUILDPATH=/tmp/$USER/easybuild
}

getStella()
{
    local br=$1
    local org=$2
    local targz="stella.tar.gz"
    local stellaDir="stella/"

    if [ -d "${stellaDir}" ] && [ "${CLEANUP}" == "ON" ]
    then
        rm -rf "${stellaDir}"
    fi

    if [ ! -d "$stellaDir" ]
    then
        git clone -b "${br}" --single-branch  git@github.com:"${org}"/stella.git
    fi

    rm -f "${targz}"
    tar -zcf "${targz}" stella
}

getDycore()
{
    local br=$1
    local org=$2
    local targz="dycore.tar.gz"
    local cosmoDir="cosmo-pompa/"

    if [ -d "${cosmoDir}" ] && [ "${CLEANUP}" == "ON" ]
    then 
        rm -f "${targz}"
    fi

    if [ ! -d "$cosmoDir" ]
    then
        git clone -b "${br}" --single-branch git@github.com:"${org}"/cosmo-pompa.git
    fi

    rm -rf "${targz}"
    tar -zcf "${targz}" -C "${cosmoDir}" dycore VERSION STELLA_VERSION
}

parseOptions "$@"
showConfig

pInfo "Exporting variables and load modules"
#installPath="/scratch/snx1600/charpill/post-update/install/"
exportVar "${INSTPATH}"
loadModule

# get crclim branch reprositories and  
# create corresponding source archives
pInfo "Getting source code and creating archives"
if [ "${MASTER}" == "ON" ]
then
  getStella "master" "C2SM-RCM"
  getDycore "master" "C2SM-RCM"
else
  getStella "crclim" "C2SM-RCM"
  getDycore "crclim" "C2SM-RCM"
fi

pInfo "Compiling and installing grib libraries (CSCS EB config)"
eb grib_api-1.13.1-CrayCCE-18.08.eb -r
eb libgrib1_crclim-a1e4271-CrayCCE-18.08.eb -r

if [ "${CRCLIM}" == "ON" ]
then
    pInfo "Compiling and installing crCLIM Stella"
    eb STELLA_CRCLIM-CrayGNU-18.08-double.eb -r
    if [ "${CPU}" == "ON" ]
    then
        pInfo "Compiling and installing crCLIM CPU Dycore"
        eb DYCORE_CRCLIM_CPU-CrayGNU-18.08-double.eb -r
    else
        pInfo "Compiling and installing crCLIM GPU Dycore"
        eb DYCORE_CRCLIM_GPU-CrayGNU-18.08-double.eb -r
    fi
elif [ "${MASTER}" == "ON" ]
then 
    pInfo "Compiling and installing master Stella"
    eb STELLA_MASTER-CrayGNU-18.08-double.eb -r
    if [ "${CPU}" == "ON" ]
    then
        pInfo "Compiling and installing master CPU Dycore"
        eb DYCORE_MASTER_CPU-CrayGNU-18.08-double.eb -r
    else
        pInfo "Compiling and installing master GPU Dycore"
        eb DYCORE_MASTER_GPU-CrayGNU-18.08-double.eb -r
    fi
else
    pInfo "Compiling and installing Cordex Stella"
    eb STELLA_CORDEX-CrayGNU-18.08-double.eb -r
    if [ "${CPU}" == "ON" ]
    then
        pInfo "Compiling and installing Cordex CPU Dycore"
        eb DYCORE_CORDEX_CPU-CrayGNU-18.08-double.eb -r
    else
        pInfo "Compiling and installing Cordex GPU Dycore"
        eb DYCORE_CORDEX_GPU-CrayGNU-18.08-double.eb -r
    fi
fi

echo ""
echo "# EXECUTE THE FOLLOWING COMMANDS IN YOUR TERMINAL #"
echo "# BEFORE INSTALLING COSMO                         #"
echo ""
echo "export EASYBUILD_PREFIX=${INSTPATH}"
echo "export EASYBUILD_BUILDPATH=/tmp/${USER}/easybuild"
echo "module load daint-gpu"
echo "module load EasyBuild-custom"
echo ""
