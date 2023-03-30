#!/bin/bash

source ~/.bash_profile

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

CSV2SHAPE_PATH=${VISIR2_BASE_PATH}/
CSV2SHAPE_EXE=${CSV2SHAPE_PATH}/csv2shape.sh

LOCALLINK_PATH=${VISIR2_BASE_PATH}/
LOCALLINK_EXE=${LOCALLINK_PATH}/localLink.sh

POSTPROC_PATH=${VISIR2_BASE_PATH}/PostProc/
POSTPROC_EXE=${POSTPROC_PATH}/MAIN_PostProc.py


echo "_---------------------"
echo "$APPNAME --- Inputs To add after "
echo "_---------------------"


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
source ~/.bash_profile

# module load
source ~/.bash_anaconda_3.7 

# activate conda environment
conda activate visir

# set the python path
export PYTHONPATH="${VISIR2_BASE_PATH}"

# read args
RUNDATE=$1  #"20230202_04"
COMP=$2

APPNAME="[FrameSport]"


##########################################
#
# Campi
#
########################################## 

if [[ -z $COMP ]] || [[ $COMP == "Campi" ]]; then

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

if [[ -z $COMP ]] || [[ $COMP == "Pesi" ]]; then

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

if [[ -z $COMP ]] || [[ $COMP == "Tracce" ]]; then

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


##########################################
#
# Visualizzazioni
#
##########################################

if [[ -z $COMP ]] || [[ $COMP == "Visualizzazioni" ]]; then

    echo -e "\n\n===== Visualizzazioni [requested on $(date)] ====="
    comp_name="visual"
    VISUAL_SEQ=44 #44
    cd $VISUAL_PATH
    
    if [[ $COMP == "Visualizzazioni" ]]; then
	    echo "$APPNAME ---  Component $COMP launched alone, without job dependency"
	    VISUAL_JOBID=$(bsub -R "rusage[mem=16G]" -ptl 720 -q s_long -P 0338  -J "FRM_Vis[1-${VISUAL_SEQ}]" -o ${LOGS_PATH}/out/${comp_name}_$(date +%Y%m%d-%H%M)_%J.log -e ${LOGS_PATH}/err/${comp_name}_$(date +%Y%m%d-%H%M)_%J.err  "configfile=${CONF_PATH} python $VISUAL_EXE $RUNDATE ${LSB_JOBINDEX}" &)
	
    else
	   
        echo "$APPNAME ---  Component ${comp_name} launched with job dependency after TRACCE"
        echo "bsub  -ptl 720 -q s_long -P 0338  -w \"done(${TRACCE_JOBID})\" -J \"FRM_Vis[1-${VISUAL_SEQ}]\" -o ${LOGS_PATH}/out/visual_$(date +%Y%m%d-%H%M)_%J.log -e ${LOGS_PATH}/err/visual_$(date +%Y%m%d-%H%M)_%J.err  \"configfile=${CONF_PATH} python $VISUAL_EXE $RUNDATE  ${LSB_JOBINDEX}\""
	    VISUAL_JOBID=$(bsub -R "rusage[mem=16G]" -ptl 720 -q s_long -P 0338  -w "done(${TRACCE_JOBID})" -J "FRM_Vis[1-${VISUAL_SEQ}]" -o ${LOGS_PATH}/out/${comp_name}_$(date +%Y%m%d-%H%M)_%J.log -e ${LOGS_PATH}/err/${comp_name}_$(date +%Y%m%d-%H%M)_%J.err  "configfile=${CONF_PATH} python $VISUAL_EXE $RUNDATE  ${LSB_JOBINDEX}" &)

    fi    
    
fi

##########################################
#
# Altro script di lorello 
#
##########################################

if [[ -z $COMP ]] || [[ $COMP == "Postproc" ]]; then

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


##########################################
#
# Local link to latestProduction
#
##########################################

if [[ -z $COMP ]] || [[ $COMP == "localLink.sh" ]]; then
    
    echo "===== localLink [requested on $(date)] ====="
    cd $LOCALLINK_PATH/
    
    # Linking to latest production
    if [[ $COMP == "localLink.sh" ]]; then
	
	# submit the job without job dependency since
	# we only want to run localLink.sh
	LOCALLINK_JOBID=$(bsub -ptl 720 -R "span[ptile=1]" -q s_medium -P 0338 -o ${OP_PATH}/logs/out/localLink_$(date +%Y%m%d-%H%M)_%J.out -e ${OP_PATH}/logs/err/localLink_$(date +%Y%m%d-%H%M)_%J.err -J 'FRM_localLink' "sh ${LOCALLINK_EXE} ${RUNDATE}" &)	
	
    else
	
	# invoke the job
	LOCALLINK_JOBID=$(bsub -ptl 720 -R "span[ptile=1]" -q s_medium -P 0338 -w "done($VISUAL_JOBID)" -o ${OP_PATH}/logs/out/localLink_$(date +%Y%m%d-%H%M)_%J.out -e ${OP_PATH}/logs/err/localLink_$(date +%Y%m%d-%H%M)_%J.err -J 'FRM_localLink' "sh ${LOCALLINK_EXE} ${RUNDATE}" &)	
	
    fi
fi


##########################################
#
# Csv 2 shape
#
##########################################

if [[ -z $COMP ]] || [[ $COMP == "csv2shape.sh" ]]; then

    echo "===== csv2shape [requested on $(date)] ====="
    cd $CSV2SHAPE_PATH/

    if [[ $COMP == "csv2shape.sh" ]]; then
    
	# Submit csv2shape job array without job dependencies
	# since we only want csv2shape 
	CSV_JOBID=$(bsub -ptl 720 -R "span[ptile=1]" -q s_long -P 0338 -J 'FRM_csv2shape' -o ${OP_PATH}/logs/out/csv2shape_$(date +%Y%m%d-%H%M)_%J.log -e ${OP_PATH}/logs/err/csv2shape_$(date +%Y%m%d-%H%M)_%J.err "sh ${CSV2SHAPE_EXE} $RUNDATE" &)
	
    else

	# Submit csv2shape job array
	CSV_JOBID=$(bsub -ptl 720 -R "span[ptile=1]" -q s_long -P 0338 -w "done($LOCALLINK_JOBID)" -J 'FRM_csv2shape' -o ${OP_PATH}/logs/out/csv2shape_$(date +%Y%m%d-%H%M)_%J.log -e ${OP_PATH}/logs/err/csv2shape_$(date +%Y%m%d-%H%M)_%J.err "sh ${CSV2SHAPE_EXE} $RUNDATE" &)

    fi
fi


##########################################
#
# The End.
#
##########################################

echo "$APPNAME --- Script end." 
