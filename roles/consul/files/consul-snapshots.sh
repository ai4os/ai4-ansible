#!/bin/bash

source /home/ubuntu/.bashrc
consul snapshot save /home/ubuntu/consul-snapshots/$(date +%Y%m%d%H%M%S).snap
