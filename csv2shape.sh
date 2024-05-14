#!/bin/bash

##########################################
#
# Paths and routes
#
########################################## 

# paths
source $HOME/frame_JUNO.conf


##########################################
#
# Load utils
#
########################################## 

source ${OP_PATH}/utils.sh


##########################################
#
# Start doing things...
#
########################################## 

RUNDATE=$1

# load anaconda conf
source ~/.bash_anaconda_3.7

# activate environment
conda activate csv2shape

# process csv files
echo "find ${DATAPRODUCTS}/${RUNDATE}/${SRCAPPEND}/ -iname \*csv -not -name Performance.csv -exec python csv2shape.py -i {} \;"
find ${DATAPRODUCTS}/${RUNDATE}/${SRCAPPEND}/ -iname \*csv -not -name Performance.csv -not -name \*Fwi\* -exec python csv2shape.py -i {} \;

# deactivate environment
conda deactivate
