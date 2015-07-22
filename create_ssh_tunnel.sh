#!/bin/bash

#########################
## variables to update ##
#########################

REMOTE_HOST=supporthost.example.com
REVERSE_PORT=3310

#############################################
## there should be nothing to change below ##
#############################################    

TUNNEL_PID=$(pgrep -f "ssh -f -N -R $REVERSE_PORT:localhost:22")

if [[ -z $TUNNEL_PID ]]; then
        echo "starting tunnel .."
        ssh -f -N -R $REVERSE_PORT:localhost:22 $REMOTE_HOST
else
        echo "tunnel already running (PID $TUNNEL_PID), exiting."
        exit 1
fi
