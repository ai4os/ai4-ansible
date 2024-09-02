#!/bin/bash

docker pull registry.services.ai4os.eu/ai4os/deepaas_ui:latest

# Get API modules
response=$(curl -s -X 'GET' \
  'https://api.cloud.ai4eosc.eu/v1/catalog/modules/' \
  -H 'accept: application/json')

# Check response
if [ $? -ne 0 ]; then
  echo "API request error."
  exit 1
fi

# Parse response as a list
items=$(echo "$response" | jq -r '.[]')

# Obtain docker image of each module
for item in $items; do

  # API request for each module
  metadata_response=$(curl -s -X 'GET' \
    "https://api.cloud.ai4eosc.eu/v1/catalog/modules/${item}/metadata" \
    -H 'accept: application/json')

  # Check response
  if [ $? -ne 0 ]; then
    echo "Request for item $item has failed."
    continue
  fi

  # Get the value of field docker_registry_repo
  docker_registry_repo=$(echo "$metadata_response" | jq -r '.sources.docker_registry_repo')

  # Download docker image
  if [ "$docker_registry_repo" != "null" ]; then	  
    docker pull "$docker_registry_repo"
  else
    echo "Field docker_registry_repo of item $item does not exist."
  fi
done


