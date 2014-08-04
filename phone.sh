#!/bin/bash

#########################
## variables to update ##
#########################

USERURL="http://www2011.mpe.mpg.de/interna/rumwusler-internal.php"
LOCALCACHE=/tmp/mpeuserdb.txt

#############################################
## there should be nothing to change below ##
#############################################    

# usage blurb 
[ $# -eq 0 ] && { echo " This scripts provides office phone number for MPE employees"; echo " Usage: $0 name/string"; exit 1; }  

# check for links text browser availability 
command -v links &> /dev/null
[ $? -gt 0  ] && { printf "Command links not found, please install with:\n 'sudo apt-get install links' (for Debian/Ubuntu)\n 'sudo yum install links' (for Fedora/RHEL)\n 'brew install wget' (for OSX, using http://brew.sh/)\n"; exit 1; }

# check for user DB online availability, else use local cache, else fail and exit.
HTTP_RETURN=$(curl -o /dev/null --silent --head --write-out '%{http_code}\n' $USERURL)

if (( $HTTP_RETURN == 200 )); then
	# dump the user data, write out new cache file and return match ...
	echo
	echo "Using online user DB"
	echo 
	echo "             name           |  phone           |  email               |  office       "
	echo "======================================================================================"
	links -width 140 -dump $USERURL | grep mpe.mpg.de | awk -F '|' '{print $2,$3,$5,$7,$8}' | tee $LOCALCACHE |  grep -i $1
	# ... else return message
	[ $? -gt 0  ] && { echo "User not found or user has no valid MPE email address"; exit 1; }

else
	if [[ -f $LOCALCACHE ]] ; then
		echo
		echo "Online user DB unavailable, using local cache user DB."
		echo 
		echo "             name           |  phone           |  email               |  office       "
		echo "======================================================================================"
		grep mpe.mpg.de $LOCALCACHE | grep -i $1
		# ... else return message
		[ $? -gt 0  ] && { echo "User not found or user has no valid MPE email address"; exit 1; }
	else
		echo "Online user DB unavailable, local cache user DB unavailable"
		echo "Run this script at least once when online user DB is available to cache results"
		echo "Exiting ..."
		exit 1
	fi
fi
