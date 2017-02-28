#!/usr/bin/env bash
# This is an example of a simple task runner for Laravel, similar to supervisor.
#
# By default only one worker will run per server instance.
# To increase this number, set the environment variable "WORKER_COUNT" to the count you desire.
# Each instance (if EBS) will spin up (or down) to that count.
#
# This allows you to let your worker count scale up to match demand along with the web application.
# Optionally you can specify the delay between worker jobs with "WORKER_DELAY"
# otherwise this will default to 10 seconds.
#
# All output will be logged to storage/logs/worker.log

# Check dependencies.
if [ -z $( which ps ) ]
then
    echo "ps is required to run this script."
    exit 1
fi
if [ -z $( which grep ) ]
then
    echo "grep is required to run this script."
    exit 1
fi
if [ -z $( which nohup ) ]
then
    echo "nohup is required to run this script."
    exit 1
fi

# Discern if we are running in Elastic Beanstalk, or on a standard EC2.
if [ -d "/opt/elasticbeanstalk" ]
then
    # Elastic Beanstalk
    appfolder="/var/app/current"
    appuser="webapp"
else
    # Standard EC2 instance
    appfolder="/var/www/html"
    appuser="www-data"
fi

logfile="/var/log/httpd/worker.log"
scriptname=$( basename "$0" )
scriptpath=$( cd $(dirname $0) ; pwd -P )
workerfile="$scriptpath/$scriptname"
date=$( date "+%Y-%m-%d %H:%M:%S" )

if [ "$1" == "kill" ]
then
    workercount=$( ps aux --no-headers 2>&1 | grep -c "[n]ohup bash $workerfile" 2>&1 )
    if [ "$workercount" > 0 ]
    then
        echo "$date Killing previous $workercount workers." > $logfile
        sudo killall "nohup bash $workerfile" > /dev/null 2>&1
    else
        echo "Nothing to kill."
    fi
    exit
fi

cd $appfolder
while true
do
    # Load environment variables (which may change during execution).
    if [ -f "/opt/elasticbeanstalk/support/envvars" ]
    then
        . /opt/elasticbeanstalk/support/envvars
    fi

    # Establish the current worker count based on environment variables.
    if [ -z "$WORKER_COUNT" ]
    then
        workerlimit=1
    else
        workerlimit=$WORKER_COUNT
    fi

    # Establish delay between jobs.
    if [ -z "$WORKER_DELAY" ]
    then
        workerdelay=10
    else
        workerdelay=$WORKER_DELAY
    fi

    # Get the count of instances running this script (including the current one).
    workercount=$( ps aux --no-headers 2>&1 | grep -c "[n]ohup bash $workerfile" 2>&1 )
    if [ "$workercount" -lt "$workerlimit" ]
    then
        # We have less workers than desired.
        echo "$date Not enough workers running ($workercount of $workerlimit). Starting another."
        sudo nohup bash $workerfile >> $logfile 2>&1 &
        sleep 1
    fi
    if [ "$workercount" -gt "$workerlimit" ]
    then
        # We have too many workers running.
        echo "$date Too many workers running ($workercount of $workerlimit). Terminating myself."
        exit
    fi
    if [[ "$1" == "firstrun" ]]
    then
        echo "Worker count: $workercount of $workerlimit"
        echo "Nohup processes will take it from here."
        exit
    fi

    sleep $workerdelay

    # Fire off a worker task as the app user.
    if [ -f "$appfolder/artisan-all" ]
    then
        # An artisan-all bash script is present to handle artisan commands for all sites.
        sudo bash artisan-all queue:work
    else
        sudo -u $appuser bash -c ". /opt/elasticbeanstalk/support/envvars ; /usr/bin/php artisan queue:work"
    fi

done
echo "$date Done."