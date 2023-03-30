#!/bin/bash

# read configuration file
source $HOME/.telegramrc


####################################################
#
# Local conf
#
####################################################

TELEGRAM_ENABLED=1


####################################################
#
# Console/Telegram handler function: Notify
#
####################################################

Notify() {
    
    local msgType=$1
    local app=$2
    local msg=$3

    echo "[$APPNAME] $msg" 2>&1 | tee -a $LOGFILE
    if [[ $msgType -eq 0 ]]; then
	if [[ ${TELEGRAM_ENABLED} ]]; then
            sh ${TELEGRAM_EXE} -t ${TELEGRAM_TOKEN} -c ${TELEGRAM_CHANNEL} "[$app] $(echo -e '\U0000274C') $msg"
	fi
    elif [[ $msgType -eq 1 ]]; then
	if [[ ${TELEGRAM_ENABLED} ]]; then
            sh ${TELEGRAM_EXE} -t ${TELEGRAM_TOKEN} -c ${TELEGRAM_CHANNEL} "[$app]  $(echo -e '\U0001F7E2') $msg"        
	fi
    elif [[ $msgType -eq 2 ]]; then
	if [[ ${TELEGRAM_ENABLED} ]]; then
            sh ${TELEGRAM_EXE} -t ${TELEGRAM_TOKEN} -c ${TELEGRAM_CHANNEL} "[$app]  $(echo -e '\U00002699') $msg"        
	fi	
    fi

}
