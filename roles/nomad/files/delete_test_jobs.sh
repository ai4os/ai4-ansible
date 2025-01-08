#!/bin/bash

EXPECTED_OWNER="141741aeae18696c21292b82efd230a220afc35a9800f185bc998d435037c262@egi.eu"
EXPECTED_OWNER_NAME="Test AI4EOSC"
EXPECTED_OWNER_EMAIL="ai4os-cy-test@hotmail.com"

job_ids=$(nomad job status -namespace=* | awk 'NR > 1 {print $1}')

for job_id in $job_ids; do
    output=$(nomad job inspect -namespace=* "$job_id" | grep -E '"owner":|"owner_name":|"owner_email":')
    
    owner=$(echo "$output" | grep '"owner":' | awk -F'"' '{print $4}')
    owner_name=$(echo "$output" | grep '"owner_name":' | awk -F'"' '{print $4}')
    owner_email=$(echo "$output" | grep '"owner_email":' | awk -F'"' '{print $4}')
    
    if [[ "$owner" == "$EXPECTED_OWNER" && "$owner_name" == "$EXPECTED_OWNER_NAME" && "$owner_email" == "$EXPECTED_OWNER_EMAIL" ]]; then
    	nomad job stop -purge -namespace=* "$job_id"
    fi
done

