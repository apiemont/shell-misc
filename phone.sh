#!/bin/bash

#########################
## variables to update ##
#########################

USERURL="http://www2011.mpe.mpg.de/interna/rumwusler-internal.php"

#############################################
## there should be nothing to change below ##
#############################################    

# usage blurb 
[ $# -eq 0 ] && { echo " This scripts provides office phone number for MPE employees"; echo " Usage: $0 name/string"; exit 1; }  

 # check for links availability using builtin bash command
 command -v links &> /dev/null
 [ $? -gt 0  ] && { printf "Command links not found, please install with:\n 'sudo apt-get install links' (for Debian/Ubuntu)\n 'sudo  yum install links' (for Fedora/RHEL)\n 'brew install wget' (for OSX, using http://brew.sh/)\n"; exit 1; }

# dump the user data and return match ...
links -dump $USERURL | grep mpe.mpg.de | awk -F '|' '{print $2,$3,$5}' |  grep -i $1
# ... else return message
[ $? -gt 0  ] && { echo "User not found or user has no valid MPE email address"; exit 1; }
