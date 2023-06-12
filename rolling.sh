#!/bin/bash
#############################
#
# ROLLING SCRIPT  
#
#############################

#HOW TO RUN : 
# /work/opa/visir-dev/frame/operationalScript/rolling.sh > /work/opa/visir-dev/frame/operationalScript/logs/out/rolling_$(date +"%Y%m%d_%H%M").log 2> /work/opa/visir-dev/frame/operationalScript/logs/out/rolling_$(date +"%Y%m%d_%H%M").err  &

# Rolling Frame-fisir crontab 
#00 00 * * * /work/opa/visir-dev/frame/operationalScript/rolling.sh > /work/opa/visir-dev/frame/operationalScript/logs/out/rolling_$(date +"\%Y\%m\%d").log 2> /work/opa/visir-dev/frame/operationalScript/logs/err/rolling_$(date +"\%Y\%m\%d").err  &

# paths
source $HOME/frame.conf

# load utils
# source ${OP_PATH}/utils.sh

# determine today's date
TODAY=$(date +"%Y%m%d")


# path - PROD

# BASEPATH=/work/opa/visir-dev/frame/operationalScript/
LOGFOLDER=${OP_PATH}/logs
OUT_LOGS_DIR=${LOGFOLDER}/out
ERR_LOGS_DIR=${LOGFOLDER}/err
CHECK_LOGS_DIR=${LOGFOLDER}/check


DYNAMIC_DATA=${DATAPRODUCTS} 


# debug print
echo "============================================"
echo "Rolling script is starting... Now is $(date)"
echo "============================================"

DAYS_TO_PRESERVE=30

###############################
#
# Logs 
#
###############################
echo "=== Rolling logs file ==="

# init preserve list
CAMIDDLE=""

# Preserve from delete the file last_job_notified.log
PRESERVE_FILE="last_job_notified.log"


# preserve log files
for D in $(seq ${DAYS_TO_PRESERVE} -1 0); do

    # determine PROD date to preserve
    WDATE=$(date -d "${TODAY} -${D}days" +"%Y%m%d")
    echo " - Preserving files with date PRODUCTION DATE=$WDATE"

    # file that contain PRODUCTION_DATE (long version) inside the filename
    CAMIDDLE="${CAMIDDLE} -not -name '*_${WDATE}*.*'"
    echo "file to preserve will be : $CAMIDDLE "
done

if [[ ! -z ${OUT_LOGS_DIR} ]] && [[ ! -z ${ERR_LOGS_DIR} ]] ; then 
    # if the paths  exist and are all defined rolling logs 
    echo "OUT_LOGS_DIR=${OUT_LOGS_DIR}, ERR_LOGS_DIR=${ERR_LOGS_DIR} are defined."
    LOGS_REM="find ${OUT_LOGS_DIR} ${ERR_LOGS_DIR}  ${CAMIDDLE} -not -name .keep  -not -name ${PRESERVE_FILE} -type f -exec echo -v {} \; "  # rm -rf or echo 
    echo "READING files..."
    eval $LOGS_REM

else 
    echo "OUT_LOGS_DIR, ERR_LOGS_DIR and CHECK_LOGS_DIR is not defined. Exiting... "
fi


# check 
if [[ ! -z ${CHECK_LOGS_DIR} ]] ; then 
    # if the paths  exist and are all defined rolling logs 
    echo "CHECK_LOGS_DIR=${CHECK_LOGS_DIR} defined."
    LOGS_REM="find ${CHECK_LOGS_DIR}  -not -name .keep  -mtime +1 -type f -exec echo -v {} \; "  # rm -rf
    echo "READING files..."
    eval $LOGS_REM

else 
    echo "CHECK_LOGS_DIR is not defined. Exiting... "
fi



##############################################################
#
# DATA PRODUCTS on _dynamic
# -- delete /data/products/FRAME-VISIR/_products/dynamic/<REF_DATE>_<hh>/AdriaticSea_nu04_inv012_T07/Campi
# -- delete /data/products/FRAME-VISIR/_products/dynamic/<REF_DATE>_<hh>/AdriaticSea_nu04_inv012_T07/Visualizzazioni
#
##############################################################
echo "=== Rolling ${DYNAMIC_DATA} ==="

echo "Find Campi and Visualizzazioni folder in ${DYNAMIC_DATA} older than $DAYS_TO_PRESERVE days"
DATA_DIR_REM="find ${DYNAMIC_DATA} -maxdepth 3  -mindepth 3  -not -name 'Tracce' -mtime +31 -type d -exec echo -v {} \; "   # rm -rf or echo
#DATA_DIR_REM="find ${DYNAMIC_DATA} -maxdepth 3  -mindepth 3  -not -name 'Tracce' -mtime +31 -type d  | xargs rm -r"
echo "and delete ..."
eval $DATA_DIR_REM


echo "==============================================="
echo "Rolling script is completed at $(date)"
echo "==============================================="
