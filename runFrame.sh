#!/bin/bash

##########################################
#
# Help message
#
########################################## 

if [[ $1 == "--help" ]]; then
    echo "The standard way of invoking FRAMESPORT is:"
    echo "   $ sh runFrame.sh <YYYYMMDD_HH>"
    echo
    echo "...but it is possible to execute a single component of the chain:"
    echo "   $ sh runFrame.sh <YYYYMMDD_HH> <component>"
    echo "where component is one of:"
    echo "Campi / Pesi / Tracce / Visualizzazioni "
    echo
    exit
fi


##########################################
#
# Paths and routes
#
########################################## 

# paths
VISIR2_BASE_PATH="/work/opa/visir-dev/frame/visir-2/"
OPERATIONAL_SCRIPT_PATH="/work/opa/visir-dev/frame/operationalScript/"

LOGS_PATH=${OPERATIONAL_SCRIPT_PATH}/logs/

CONF_PATH=${VISIR2_BASE_PATH}/config/DirPaths_DEV.yaml

CAMPI_PATH=${VISIR2_BASE_PATH}/Campi
CAMPI_EXE=${CAMPI_PATH}/MAIN_Campi.py

TRACCE_PATH=${VISIR2_BASE_PATH}/Tracce
TRACCE_EXE=${TRACCE_PATH}/MAIN_Tracce.py

PESI_PATH=${VISIR2_BASE_PATH}/Pesi
PESI_EXE=${PESI_PATH}/MAIN_Pesi.py

VISUAL_PATH=${VISIR2_BASE_PATH}/Visualizzazioni
VISUAL_EXE=${VISUAL_PATH}/MAIN_OP.py



POSTPROC_PATH=${VISIR2_BASE_PATH}/PostProc/
POSTPROC_EXE=${POSTPROC_PATH}/MAIN_PostProc.py


echo "_---------------------"
echo "$APPNAME --- Inputs To add after "
# echo $1
# echo $2
echo "_---------------------"

# define the routes
# ROUTES=('ALDRZ_ITBDS' 'ALDRZ_ITBRI' 'GRGPA_ITBDS' 'GRIGO_ITBDS' 'HRDBV_ITAOI' 'HRDBV_ITBDS' 'HRDBV_ITBRI' 'HRRJK_ITAOI' 'HRSPU_ITAOI' 'HRSPU_ITBRI' 'HRZAD_ITAOI' 'HRZAD_ITBLT' 'HRZAD_ITRAN' 'ITAOI_HRDBV' 'ITAOI_HRRJK' 'ITAOI_HRSPU' 'ITAOI_HRZAD' 'ITBDS_ALDRZ' 'ITBDS_GRGPA' 'ITBDS_GRIGO' 'ITBDS_HRDBV' 'ITBDS_MEBAR' 'ITBLT_HRZAD' 'ITBRI_ALDRZ' 'ITBRI_HRDBV' 'ITBRI_HRSPU' 'ITBRI_MEBAR' 'ITRAN_HRZAD' 'MEBAR_ITBDS' 'MEBAR_ITBRI')


##########################################
#
# Load utils
#
########################################## 

source /work/opa/visir-dev/frame/operationalScript/utils.sh


##########################################
#
# bsub command re-definition
#
########################################## 

# redefining bsub
bsub () {
    echo bsub $* >&2
    command bsub $* | head -n1 | cut -d'<' -f2 | cut -d'>' -f1
}   


##########################################
#
# Initialisation
#
########################################## 

# source profile
# source ~/.bash_profile

# module load
source ~/.bash_anaconda_3.7 

# activate conda environment
conda activate visir

# set the python path
export PYTHONPATH="${VISIR2_BASE_PATH}"

# read args
RUNDATE=$1  #"20230202_04"
COMP=$2

APPNAME="[Run FrameSport]"


##########################################
#
# Campi
#
########################################## 

if [[ $COMP == "" ]] || [[ $COMP == "Campi" ]]; then

    echo -e "\n===== Campi [requested on $(date)] ====="
    
    # DATE=$(LANG=en_gb date +"%d%b%y")   

    comp_name="campi"
    CAMPI_SEQ=3  # 3 run totali
    # invoke the job
    cd ${VISIR2_BASE_PATH}
    
    echo "$APPNAME ---  ${comp_name} launched"
    CAMPI_JOBID=$(bsub -ptl 720 -q s_medium -P 0338 -J "FRM_Campi[1-${CAMPI_SEQ}]" -o ${LOGS_PATH}/out/${comp_name}_$(date +%Y%m%d-%H%M)_%J.log -e ${LOGS_PATH}/err/${comp_name}_$(date +%Y%m%d-%H%M)_%J.err "configfile=${CONF_PATH} python $CAMPI_EXE $RUNDATE ${LSB_JOBINDEX}" &)

fi


##########################################
#
# Pesi
#
########################################## 

if [[ $COMP == "" ]] || [[ $COMP == "Pesi" ]]; then

    echo -e "\n\n===== Pesi [requested on $(date)] ====="
    
    # DATE=$(LANG=en_gb date +"%d%b%y")
    comp_name="pesi"
    PESI_SEQ=9 #9

    cd $PESI_PATH

    if [[ $COMP == "Pesi" ]]; then
        echo "$APPNAME ---  Component ${comp_name} launched alone, without job dependency"
        # invoke the job
        PESI_JOBID=$(bsub -ptl 720 -R "rusage[mem=6G]" -q s_medium -P 0338 -J "FRM_Pesi[1-${PESI_SEQ}]"  -o ${LOGS_PATH}/out/${comp_name}_$(date +%Y%m%d-%H%M)_%J.log -e ${LOGS_PATH}/err/${comp_name}_$(date +%Y%m%d-%H%M)_%J.err "configfile=${CONF_PATH} python $PESI_EXE $RUNDATE ${LSB_JOBINDEX}" &)

    else 
        # invoke the job
        echo "$APPNAME ---  Component ${comp_name} launched with job dependency after CAMPI"
        echo "bsub -ptl 720 -R \"rusage[mem=6G]\" -q s_medium -P 0338 -J \"FRM_Pesi[1-${PESI_SEQ}]\" -o ${LOGS_PATH}/out/${comp_name}_$(date +%Y%m%d-%H%M)_%J.log -e ${LOGS_PATH}/err/${comp_name}_$(date +%Y%m%d-%H%M)_%J.err \"configfile=${CONF_PATH} python $PESI_EXE $RUNDATE ${LSB_JOBINDEX}\""

        PESI_JOBID=$(bsub -ptl 720 -R "rusage[mem=6G]" -q s_medium -P 0338 -J "FRM_Pesi[1-${PESI_SEQ}]" -w "done(${CAMPI_JOBID})" -o ${LOGS_PATH}/out/${comp_name}_$(date +%Y%m%d-%H%M)_%J.log -e ${LOGS_PATH}/err/${comp_name}_$(date +%Y%m%d-%H%M)_%J.err "configfile=${CONF_PATH} python $PESI_EXE $RUNDATE ${LSB_JOBINDEX}" &)

    fi 
fi


##########################################
#
# Tracce
#
##########################################

if [[ $COMP == "" ]] || [[ $COMP == "Tracce" ]]; then

    echo -e "\n\n===== Tracce [requested on $(date)] ====="
    comp_name="tracce"

    TRACCE_SEQ=44 #44
    cd $TRACCE_PATH
    
    if [[ $COMP == "Tracce" ]]; then
	    echo "$APPNAME ---  Component $COMP launched alone, without job dependency"
        # echo "bsub  -R \"rusage[mem=16G]\" -ptl 720 -q s_medium -P 0338 -J \"FRM_Tracce[1-${TRACCE_SEQ}]\" -o ${LOGS_PATH}/out/${comp_name}_$(date +%Y%m%d-%H%M)_%J.log -e ${LOGS_PATH}/err/${comp_name}_$(date +%Y%m%d-%H%M)_%J.err  \"configfile=${CONF_PATH} python $TRACCE_EXE $RUNDATE ${LSB_JOBINDEX}\" &"
	    
        # serial 
        # TRACCE_JOBID=$(bsub  -R "rusage[mem=16G]" -q s_medium -P 0338 -J FRM_Tracce -o ${LOGS_PATH}/out/${comp_name}_$(date +%Y%m%d-%H%M).log -e ${LOGS_PATH}/err/${comp_name}_$(date +%Y%m%d-%H%M).err  "configfile=${CONF_PATH} python $TRACCE_EXE $RUNDATE 0" &)

        # parallel
        TRACCE_JOBID=$(bsub  -R "rusage[mem=16G]" -ptl 720 -q s_medium -P 0338 -J "FRM_Tracce[1-${TRACCE_SEQ}]" -o ${LOGS_PATH}/out/${comp_name}_$(date +%Y%m%d-%H%M)_%J.log -e ${LOGS_PATH}/err/${comp_name}_$(date +%Y%m%d-%H%M)_%J.err  "configfile=${CONF_PATH} python $TRACCE_EXE $RUNDATE ${LSB_JOBINDEX}" &)
    
    else
	   
        echo "$APPNAME ---  Component ${comp_name} launched with job dependency after PESI"
        echo "bsub -R rusage[mem=16G] -Is -q s_medium -ptl 720 -P 0338  -w \"done(${PESI_JOBID})\" -J \"FRM_Tracce[1-${TRACCE_SEQ}]\" -o ${LOGS_PATH}/out/${comp_name}_$(date +%Y%m%d-%H%M)_%J.log -e ${LOGS_PATH}/err/${comp_name}_$(date +%Y%m%d-%H%M)_%J.err  \"configfile=${CONF_PATH} python $TRACCE_EXE $RUNDATE  ${LSB_JOBINDEX}\""
	    TRACCE_JOBID=$(bsub  -R "rusage[mem=16G]" -ptl 720 -q s_medium -P 0338  -w "done(${PESI_JOBID})" -J "FRM_Tracce[1-${TRACCE_SEQ}]" -o ${LOGS_PATH}/out/${comp_name}_$(date +%Y%m%d-%H%M)_%J.log -e ${LOGS_PATH}/err/${comp_name}_$(date +%Y%m%d-%H%M)_%J.err  "configfile=${CONF_PATH} python $TRACCE_EXE $RUNDATE  ${LSB_JOBINDEX}" &)

    fi    
    
fi


# ##########################################
# #
# # Visualizzazioni
# #
# ##########################################

# if [[ $COMP == "" ]] || [[ $COMP == "Visualizzazioni" ]]; then

#     echo -e "\n\n===== Visualizzazioni [requested on $(date)] ====="
#     comp_name="visual"
#     VISUAL_SEQ=44 #44
#     cd $VISUAL_PATH
    
#     if [[ $COMP == "Visualizzazioni" ]]; then
# 	    echo "$APPNAME ---  Component $COMP launched alone, without job dependency"
# 	    VISUAL_JOBID=$(bsub -R "rusage[mem=16G]" -ptl 720 -q s_long -P 0338  -J "FRM_Vis[1-${VISUAL_SEQ}]" -o ${LOGS_PATH}/out/${comp_name}_$(date +%Y%m%d-%H%M)_%J.log -e ${LOGS_PATH}/err/${comp_name}_$(date +%Y%m%d-%H%M)_%J.err  "configfile=${CONF_PATH} python $VISUAL_EXE $RUNDATE ${LSB_JOBINDEX}" &)
	
#     else
	   
#         echo "$APPNAME ---  Component ${comp_name} launched with job dependency after TRACCE"
#         echo "bsub  -ptl 720 -q s_long -P 0338  -w \"done(${TRACCE_JOBID})\" -J \"FRM_Vis[1-${VISUAL_SEQ}]\" -o ${LOGS_PATH}/out/visual_$(date +%Y%m%d-%H%M)_%J.log -e ${LOGS_PATH}/err/visual_$(date +%Y%m%d-%H%M)_%J.err  \"configfile=${CONF_PATH} python $VISUAL_EXE $RUNDATE  ${LSB_JOBINDEX}\""
# 	    VISUAL_JOBID=$(bsub -R "rusage[mem=16G]" -ptl 720 -q s_long -P 0338  -w "done(${TRACCE_JOBID})" -J "FRM_Vis[1-${VISUAL_SEQ}]" -o ${LOGS_PATH}/out/${comp_name}_$(date +%Y%m%d-%H%M)_%J.log -e ${LOGS_PATH}/err/${comp_name}_$(date +%Y%m%d-%H%M)_%J.err  "configfile=${CONF_PATH} python $VISUAL_EXE $RUNDATE  ${LSB_JOBINDEX}" &)

#     fi    
    
# fi

##########################################
#
# Altro script di lorello 
#
##########################################



if [[ $COMP == "" ]] || [[ $COMP == "Postproc" ]]; then

    echo -e "\n\n===== Postproc [requested on $(date)] ====="
    comp_name="Postproc"
    
    cd $POSTPROC_PATH
    
    if [[ $COMP == "Postproc" ]]; then
	    echo "$APPNAME ---  Component $COMP launched alone, without job dependency"
	    POSTPROC_JOBID=$(bsub -ptl 720 -q s_short -P 0338  -J FRM_post -o ${LOGS_PATH}/out/${comp_name}_$(date +%Y%m%d-%H%M).log -e ${LOGS_PATH}/err/${comp_name}_$(date +%Y%m%d-%H%M).err  "configfile=${CONF_PATH} python $POSTPROC_EXE $RUNDATE" &)
	
    else
	   
        echo "$APPNAME ---  Component ${comp_name} launched with job dependency after TRACCE"
        echo "bsub  -ptl 720 -q s_short -P 0338  -w \"done(${TRACCE_JOBID})\" -J FRM_post -o ${LOGS_PATH}/out/${comp_name}_$(date +%Y%m%d-%H%M).log -e ${LOGS_PATH}/err/${comp_name}_$(date +%Y%m%d-%H%M).err  \"configfile=${CONF_PATH} python $POSTPROC_EXE $RUNDATE \""
	    POSTPROC_JOBID=$(bsub -ptl 720 -q s_short -P 0338  -w "done(${TRACCE_JOBID})" -J FRM_post -o ${LOGS_PATH}/out/${comp_name}_$(date +%Y%m%d-%H%M).log -e ${LOGS_PATH}/err/${comp_name}_$(date +%Y%m%d-%H%M).err  "configfile=${CONF_PATH} python $POSTPROC_EXE $RUNDATE" &)

    fi    
    
fi




# ##########################################
# #
# # Create link on N08
# #
# ##########################################

echo "$APPNAME --- Script end." 

# How to launch:
# bash /work/opa/visir-dev/frame/operationalScript/runFrame.sh 20230214_04 Tracce > /work/opa/visir-dev/frame/operationalScript/logs/out/runFrame_$(date +"%Y%m%d_%H%M").out 2> /work/opa/visir-dev/frame/operationalScript/logs/err/runFrame_$(date +"%Y%m%d_%H%M").err &
