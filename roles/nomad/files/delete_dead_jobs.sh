#!/bin/bash
#
# Author: Saúl Fernández
# Contact: sftobias@ifca.unican.es
#
# Description:
# This script is designed to remove jobs that have been in a 'dead' state for a certain period.
# Due to the lack of information about the duration in a 'dead' state provided by Nomad,
# jobs in the 'Dead' state are compared between script executions using a text file.
# To control the script's periodicity, the script's scheduling is managed through cron.
# It is important to set the cron schedule to be greater than the frequency of the accounting task.
#
# It is necessary to import the nomad certificates as there are no environment variables in cron
#

export NOMAD_ADDR=https://publicip:4646
export NOMAD_CACERT=/home/ubuntu/nomad-ca.pem
export NOMAD_CLIENT_CERT=/home/ubuntu/cli.pem
export NOMAD_CLIENT_KEY=/home/ubuntu/cli-key.pem

touch new_blacklist.txt

while IFS= read -r id; do
        
    if grep -q "$id" blacklist.txt; then
        nomad job stop -namespace=* --purge "$id"
    else
        echo "$id" >> new_blacklist.txt
    fi
done < <(nomad job status -namespace=* | grep dead | awk '{print $1}')

rm blacklist.txt
mv ./new_blacklist.txt ./blacklist.txt
