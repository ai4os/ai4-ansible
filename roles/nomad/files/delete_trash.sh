#!/bin/bash

host_ip=$(/sbin/ip -4 -o addr list | grep 172.16 | awk '{print $4}' | cut -d/ -f1 | cut -d. -f1-3)

mapfile -t machines < <(nomad node status -verbose | awk '{ for (i=1; i<=NF; i++) { if ($i ~ /^'"$host_ip"'\./) { print "ubuntu@"$i} } }')

for machine in "${machines[@]}"; do
    while read -r container_id; do        
        echo "$machine $container_id"
        ssh -n "$machine" "sudo docker exec $container_id sh -c 'rm -r /root/.local/share/Trash/files/*'"
    done < <(ssh -n "$machine" "sudo docker ps --size --format 'table{{.ID}}' | tail -n +2")
done
