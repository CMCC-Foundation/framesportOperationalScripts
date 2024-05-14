#!/bin/bash

##########################################
#
# Paths and routes
#
########################################## 

# paths and conf
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

# set folder for copy
SRC=$SRCLINK/${1}/$SRCAPPEND
echo "SOURCE PATH: $SRC" 

##########################################
#
# Link
#
##########################################

# create a local link
echo "Moving to $DATAPRODUCTS"
cd ${DATAPRODUCTS}
echo "I'm in ${DATAPRODUCTS}"

echo "Removing link..."
rm ${DATAPRODUCTS}/latestProduction

echo "Creating link..."
ln -sf ${1} latestProduction -v

