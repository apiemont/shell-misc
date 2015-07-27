#!/bin/bash                                                                                                                                                                                                                                                   
                                                                                                                                                                                                                                                              
###################################                                                                                                                                                                                                                           
## variables to update if needed ##                                                                                                                                                                                                                           
###################################                                                                                                                                                                                                                           
                                                                                                                                                                                                                                                              
REMOTE_HOST=ex-sol.mpe.mpg.de                                                                                                                                                                                                                                 
SUPPORT_USER=apiemont                                                                                                                                                                                                                                         
SUPPORT_EMAIL=apiemont@gmail.com                                                                                                                                                                                                                             
SUPPORT_PUBKEY="ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQCagVrIqctHf6lij69uTun2UmZ7qgAtY/2FCy39yir0GZbp/RZfOy0+9qm7KHn9G2PGM6ygY5bscMObKWXxJn+ZbctJkP9wpvprO9oIiRNWkDk7HPGDaIFq/E1N3PD6A7Ue/6/DvzETNIwJc1BgFfVlU19W4/dXPjR+1QO/RFtuh/LXmSWMG/G+jd4FCQHIXHun98g72VEB92X2WhNXFvAieWYCQjMwlLlPdedUavQBKDxtV/rdboFeDJ3GfKcWN/4AKg7uwmSkZAlgvMJPeGMT9bTpKv48eUd6REKEp1kwYqrQ+GxiPvpXCqVapC2PGUbr7aJIFeE/KQ9kF5a/z3/5 apiemont@ex-sol2"                                                                                              
                                                                                                                                                                                                                                                              
#############################################                                                                                                                                                                                                                 
## there should be nothing to change below ##                                                                                                                                                                                                                 
#############################################                                                                                                                                                                                                                 
                                                                                                                                                                                                                                                              
LOCK_FILE=~/.tunnel.lock                                                                                                                                                                                                                                      
TUNNEL_PUBKEY=~/.ssh/id_rsa_tunnel.pub                                                                                                                                                                                                                        
TUNNEL_PRIVKEY=~/.ssh/id_rsa_tunnel
TUNNEL_PID=$(pgrep -f "$localhost:22" | paste -s) # paste, in case there are multiple pids ..)

function tunnel_reset {
        [[ -r $LOCK_FILE ]] && { echo "Clearing tunnel lock file"; rm $LOCK_FILE; } || { echo "Tunnel lock file not found"; }
        [[ -r $TUNNEL_PUBKEY && -r $TUNNEL_PRIVKEY ]] && { echo "clearing tunnel keypair"; rm $TUNNEL_PUBKEY $TUNNEL_PRIVKEY; } || { echo "Tunnel keypair not found"; }
        [[ -r ~/.ssh/authorized_keys ]] && { echo "Removing support public key from user account .. done"; sed -i.old  "/$SUPPORT_USER/d" ~/.ssh/authorized_keys; }
}

function tunnel_init {
        if [[ -r $LOCK_FILE ]]; then
                echo "Tunnel already initialized, wait for email confirmation from support before starting it (with --start), bye."
                exit 0
        else
                echo "Requesting tunnel setup (initialization) for first time .."
                touch $LOCK_FILE
                if [[ -r $TUNNEL_PUBKEY && -r $TUNNEL_PRIVKEY ]]; then
                        echo "Found tunnel keypair .."
                else
                        echo "No tunnel keypair found, creating new one .."
                        ssh-keygen -f $TUNNEL_PRIVKEY -q -N ""
                fi
		
		if [[ $(command -v mailx) ]]; then
	                # send email to support about tunnel init request
        	        read -p "Please enter your email address: " USER_EMAIL
                	mailx -s "Tunnel init request from $USER@$HOSTNAME" -r $USER_EMAIL $SUPPORT_EMAIL < $TUNNEL_PUBKEY
		else
			printf "\n\nMail this message to $SUPPORT_EMAIL:\n\n=========\nRequesting tunnel from $USER@$HOSTNAME using this ssh public key:\n\n$(cat $TUNNEL_PUBKEY)\n=========\n\n"
		fi

                # finally append support pub key to the requesting account, if not there already ..
                if grep $SUPPORT_USER ~/.ssh/authorized_keys > /dev/null 2>&1; then
                                :
                        else
                                printf "Adding support pub key to your account .. \nDone.\n\nWait for email confirmation from support that the tunnel is ready for usage before starting it (with --start)\n"
                                echo $SUPPORT_PUBKEY >> ~/.ssh/authorized_keys
                                chmod 600 ~/.ssh/authorized_keys
                fi
        fi
}

function tunnel_start {
        [[ ! -r $LOCK_FILE ]] && { echo "Tunnel not yet initialized, run \"$0 --init\" first."; exit 1; }
        if [[ -z $TUNNEL_PID ]]; then
                echo "Starting tunnel .."
                REVERSE_PORT=$((RANDOM%100+4000)) # random, within a range ..
                ssh -i $TUNNEL_PRIVKEY -f -N -R $REVERSE_PORT:localhost:22 $SUPPORT_USER@$REMOTE_HOST
			if [[ $(command -v mailx) ]]; then
		                mailx -s "Tunnel started from $USER@$HOSTNAME" $SUPPORT_EMAIL <<< "Connect with 'ssh -p $REVERSE_PORT $USER@localhost'"
			else
				printf "\nPlease inform support that you have started a tunnel by sending this message to $SUPPORT_EMAIL:\n\n=========\nTunnel started from $USER@$HOSTNAME. Please connect with\n \n\$ ssh -p $REVERSE_PORT $USER@localhost\n=========\n\n"
			fi
        else
                echo "Can't start tunnel, one is already running (PID $TUNNEL_PID), bye."
                exit 1
        fi
}

function tunnel_status {
        [[ ! -z $TUNNEL_PID ]] && { printf "\nTunnel is up and running (PID $TUNNEL_PID). Tunnel detailed command is:\n\n $(pgrep -a -f localhost:22)\n\n"; exit 0; } || { echo "No tunnel available."; exit 1; }
}
function tunnel_stop {
        [[ ! -z $TUNNEL_PID ]] && { echo "Stopping tunnel .."; kill $TUNNEL_PID; exit 0; } || { echo "No tunnel available."; exit 1; }
}
function tunnel_help {
        printf "\nUsage: $0 [option]\n"
cat <<DONE

where [option] is one of:
        --init   - To configure the tunnel, only done once if you have never used a tunnel from this machine.
                   Wait for email confirmation from support before starting it (with --start).
        --start  - To start a tunnel.
        --stop   - To stop an active/running tunnel.
        --status - To verify status and list the process ID of running tunnel.
        --reset  - Only used for debugging purposes: it will clear up all tunnel configuration.
                   After using this option, a new configuration needs to be set up (e.g. use --init).
DONE
}
function tunnel_usage {
        echo "Usage: $0 [--reset | --init | --start | --status | --stop | --help]"
}

# if we get zero or more than one input param, return short usage and exit
[ $# -gt 1 ] || [ $# -eq 0 ] && { tunnel_usage; exit 1; }

# main body dealing with the expected single input param
case $1 in
        --init) tunnel_init ;;
        --start) tunnel_start;;
        --stop) tunnel_stop;;
        --status) tunnel_status;;
        --reset) tunnel_reset;;
        --help|-h) tunnel_help;;
        *) tunnel_usage;;
esac
