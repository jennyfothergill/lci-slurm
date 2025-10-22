#!/bin/bash

thisfile="$(readlink -f "${BASH_SOURCE}")"
thisdir="$(dirname "$thisfile")"
starttime=$1
endtime=$2

if [ -z $starttime ]
then
    echo "no starttime provided--start in 5 minutes"
    starttime=$(date -d "+5 minutes" +%Y-%m-%dT%H:%M:%S)
fi
echo $starttime
if [ -z $endtime ]
then
    echo "no endtime provided--end 5 days after start"
    startd=$(date --iso-8601=n -d "$starttime")
    endtime=$(date -d "$startd + 5 days" +%Y-%m-%dT%H:%M:%S)
fi
echo $endtime

#if [[ "$starttime" =~ "^[0-9]{4}-(0[1-9]|1[0-2])-(0[1-9]|[1-2][0-9]|3[0-1])T(0[1-9]|1[0-9]|2[0-3]):[0-5][1-9]:[0-5][0-9]$" ]]
if [[ "$starttime" == $(date -d $starttime +%Y-%m-%dT%H:%M:%S) ]]
then
    echo "starttime OK"
else
    echo "starttime bad"
fi
if [[ "$endtime" == $(date -d $endtime +%Y-%m-%dT%H:%M:%S) ]]
then
    echo "endtime OK"
else
    echo "endtime bad"
fi

maintenance=$(<"$thisdir/maintenance.txt")
maintenance=$( eval echo "\"$maintenance\"" )
echo "$maintenance" > "/etc/slurm/maintenance.lua"

scontrol create res starttime=$starttime endtime=$endtime user=root flags=maint,ignore_jobs nodes=ALL
