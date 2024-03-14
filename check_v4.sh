#!/bin/bash

source ~/.bash_profile
##########################################
#
# Paths and routes
#
########################################## 

# paths
# source $HOME/frame.conf
OP_PATH=/work/opa/visir-dev/frame/operationalScript/
LOG_PATH=$OP_PATH/logs/out
ERR_PATH=$OP_PATH/logs/err


##########################################
#
# Telegram configuration file
#
########################################## 
# Notify 0 "Check" "2 message" # error message
# Notify 1 "Check" "3 message" # good message

##########################################
#
# Load utils
#
########################################## 
echo "source ${OP_PATH}/utils.sh"
source ${OP_PATH}/utils.sh



# Find the last run
LASTRUN_LOGFILE=$(ls $LOG_PATH/runFrame*out -tr | tail -1)
LASTRUN=$(basename $LASTRUN_LOGFILE | cut -f 2 -d "_" | cut -f 1 -d ".")
echo " - Last run identified is : $LASTRUN"

##########################################
#
# Checks
#
########################################## 

echo "Check script started now $(date)"
# Notify 2 "Check" "Script started now" 

COMPONENTS=(campi pesi tracce visual csv2shape localLink Postproc)

# check if we already notified this job
if [[ -e ${LOG_PATH}/last_job_notified.log ]] ; then 
	LAST_NOTIFIED_JOB=$(cat ${LOG_PATH}/last_job_notified.log)
	if [[ $LAST_NOTIFIED_JOB = $LASTRUN ]] ; then
		echo " -- Job already notified"
		exit    
	fi
fi

# check if all the components stopped running
for COMP in ${COMPONENTS[@]}; do
	echo "Analyzing $COMP ..."
    # log/err file names
	LOG=$(find ${LOG_PATH} -name ${COMP}_${LASTRUN}-\* | head -n 1)
    ERR=$(find ${ERR_PATH} -name ${COMP}_${LASTRUN}-\* | head -n 1)

	echo "LOG file is $LOG"
	echo "ERR file is $ERR"	

	if [[ ! -z "$LOG"  ]] ; then
		# get termination signals for the component
		TermSig=$(grep "Terminated" $LOG | wc -l)
		
		case $COMP in
		
		"campi")
			if [[ $TermSig -eq 3 ]]; then
				echo "$COMP terminated"
			else
				echo "$COMP still to complete! Exiting..."
				exit
			fi	    
			;;
		"pesi")
			if [[ $TermSig -eq 9 ]]; then
				echo "$COMP terminated"
			else
				echo "$COMP still to complete! Exiting..."
				exit
			fi	    
			;;	
		"tracce")
			if [[ $TermSig -eq 44 ]]; then
				echo "$COMP terminated"
			else
				echo "$COMP still to complete! Exiting..."
				exit
			fi
			;;
		"visual")
			if [[ $TermSig -eq 44 ]]; then
				echo "$COMP terminated"
			else
				echo "$COMP still to complete! Exiting..."
				exit
			fi
			;;
		"csv2shape")
			if [[ $TermSig -eq 1 ]]; then
				echo "$COMP terminated"
			else
				echo "$COMP still to complete! Exiting..."
				exit
			fi
			;;
		"localLink")
			if [[ $TermSig -eq 1 ]]; then
				echo "$COMP terminated"
			else
				echo "$COMP still to complete! Exiting..."
				exit
			fi
			;;
		"Postproc")
			if [[ $TermSig -eq 1 ]]; then
				echo "$COMP terminated"
			else
				echo "$COMP still to complete! Exiting..."
				exit
			fi
			;;
		*)
			echo "ELSE"
			;;
		esac
	else 

		echo "LOG file not ready."
		# JOBS=$(bjobs )#| wc -l)


		JOBS=$(bjobs -o "JOB_NAME" -noheader | grep -v grep | wc -l )
		JOBS_RUN=$(bjobs -o "STAT" -noheader | grep RUN | wc -l )
		JOBS_PEND=$(bjobs -o "STAT" -noheader | grep PEND | wc -l ) 
		echo "JOBS are $JOBS"
		echo "Running jobs are $JOBS_RUN"
		echo "Pending jobs are $JOBS_PEND"

		if [[ "$JOBS_RUN" -ge "1" ]] ; then
			echo " -- Because job still in progress ($JOBS_RUN)"
			exit
		else
			# if [[ "$JOBS_PEND" -ge "1" ]]; then 
			# 	echo " -- Because jobs are in PENDING."
			# 	echo "Let's see the components."
			# else 
			# 	echo " -- Because no jobs in the crontab"			
			# 	exit
			# fi  

			# if there are pending jobs, see the previous job if end SUCCESFULLY or NOT. 
			# IF PREV JOB END SUCCES -> wait 
			# IF PREV JOB END WITH EXIT -> send notify

			if [[ "$JOBS_PEND" -ge "1" ]]; then 

				PREV_JOB=$(bjobs -a | tail -n 1 | grep "DONE" | wc -l)
				if [[ "$PREV_JOB" -ge "1"   ]] ; then
					echo " -- Previous job ended succesfully, waiting the end of the pending jobs ($JOBS_PEND)."			
					exit
				else
					echo " -- Previous job ended with an error. Send notify."
					echo "Let's see the components."
				fi
				
			else 
				echo " -- Because there are no jobs to do"			
				exit
			fi  
			
		fi

	fi

done

# check if all the components stopped running
for COMP in ${COMPONENTS[@]}; do

    # log/err file names
    LOG=$(find ${LOG_PATH} -name ${COMP}_${LASTRUN}\* | head -n 1)
    ERR=$(find ${ERR_PATH} -name ${COMP}_${LASTRUN}\* | head -n 1)
	
	echo "========"
    echo "Parsing log files:"
    echo $LOG
    echo $ERR
    
	echo "update ${LOG_PATH}/last_job_notified.log with $LASTRUN"
	echo $LASTRUN > ${LOG_PATH}/last_job_notified.log
    
    # do the analysis
    echo " - Analysing component $COMP"    
    ERRORS_LINE=$(wc -l $ERR | cut -f 1 -d " ")
    echo " - $COMP has $ERRORS_LINE lines in the file $ERR."
    if [[ ! -z $ERRORS_LINE ]]; then
        if [[ $ERRORS_LINE -gt 0 ]]; then
			
			if [[ "$COMP"=="visual" ]] ; then 
				ERRORS=$(grep -i "error" $ERR | wc -l)
				echo " -- Found $ERRORS errors in $ERR in $COMP. The other lines are warning..."
				
				if [[ $ERRORS -gt 0 ]] ; then
					echo "Send notification on telegram channel"
					Notify 0 "Check" "Found $ERRORS errors in $COMP error logs. Have a look!"
				fi

			
			elif [[ "$COMP"=="Postproc" ]] ; then 
				ERRORS=$(grep -i "error" $ERR | wc -l)
				echo " -- Found $ERRORS errors in $ERR in $COMP. The other lines are warning..."

				if [[ $ERRORS -gt 0 ]] ; then
					echo "Send notification on telegram channel"
					Notify 0 "Check" "Found $ERRORS errors in $COMP error logs. Have a look!"
					echo "update ${LOG_PATH}/last_job_notified.log with $LASTRUN"
					echo $LASTRUN > ${LOG_PATH}/last_job_notified.log
				fi

				echo "update ${LOG_PATH}/last_job_notified.log with $LASTRUN"
				echo $LASTRUN > ${LOG_PATH}/last_job_notified.log
			else
				echo " -- errors are real! MUST BE NOTIFIED"
				echo "update ${LOG_PATH}/last_job_notified.log with $LASTRUN"
				echo $LASTRUN > ${LOG_PATH}/last_job_notified.log
            	Notify 0 "Check" "${COMP} has ${ERRORS_LINE} error lines [run: $LASTRUN]. Have a look!"

			fi 

		fi
    fi

done


echo "Finish check now $(date)"