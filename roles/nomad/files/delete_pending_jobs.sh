#!/bin/bash

#
# Author: Saúl Fernández
# Contact: sftobias@ifca.unican.es
#
# Description:
# This script is intended to be executed daily. It focuses on removing Nomad jobs in the 'Pending' state
# that do not have any associated tasks in states 'Queued,' 'Starting,' or 'Unknown.'
#
# It is necessary to import the nomad certificates as there are no environment variables in cron
#

export NOMAD_ADDR=https://publicip:4646
export NOMAD_CACERT=/home/ubuntu/nomad-ca.pem
export NOMAD_CLIENT_CERT=/home/ubuntu/cli.pem
export NOMAD_CLIENT_KEY=/home/ubuntu/cli-key.pem

nomad_output=$(nomad job status -verbose -namespace=* f1233bd0-c592-11ee-9fe5-756e98b92617)

num_taskgroups=$(echo "$nomad_output" | awk '/Summary/,/Evaluations/' | wc -l | awk '{print $1 - 3}')

ids=$(nomad job status -verbose -namespace=* | grep pending | awk '{print $1}')

for id in $ids; do

    state=$(nomad job status -verbose -namespace=* $id | grep Summary -A "$num_taskgroups" | sed -n '3,'"$((3 + num_taskgroups - 1))"'p' | awk '{print $2,$3,$8}')

    sum_queued=0
    sum_starting=0
    sum_unknown=0

    while read -r queued starting unknown; do
        sum_queued=$((sum_queued + queued))
        sum_starting=$((sum_starting + starting))
        sum_unknown=$((sum_unknown + unknown))
    done <<< "$state"

    if [ "$sum_queued" -eq 0 ] && [ "$sum_starting" -eq 0 ] && [ "$sum_unknown" -eq 0 ]; then
        echo "Se borra el job: $id"
        nomad job stop -namespace=* --purge "$id"
    fi

done
