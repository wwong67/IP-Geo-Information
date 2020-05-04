#!/bin/bash

# UPPERCASE space-separated country codes to ACCEPT
ALLOW_COUNTRIES="RFC US FI CA"
DISALLOW_COUNTRIES="CN VN KR KP RU BR"
ALLOW="default imaps sshd"
DISALLOW="smtp sendmail"

if [ $# -lt 1 ]; then
  echo "Usage:  `basename $0` <ip>" 1>&2
  exit 0 # return true in case of config issue
fi

if [ $# -eq 1 ]
   then
   	IP=$1
	TYPE=default
   else
	TYPE=$1
	IP=$2
fi

# Look for matches in hosts.deny
FOUND=`grep -w $IP /etc/hosts.deny`

GEOIP=/usr/local/IPGEOInfo/bin/ipgeoinfo.pl

COUNTRY=`$GEOIP $IP | awk -F ": " '{ print $2 }' | awk -F "," '{ print $1 }' | head -n 1`
if [ "$FOUND" ]
then
	COUNTRY="$COUNTRY: DENY"
fi

if [[ $DISALLOW =~ $TYPE ]]
then
	[[ $DISALLOW_COUNTRIES =~ $COUNTRY ]] && RESPONSE="DENY" || RESPONSE="ALLOW"
fi

if [[ $ALLOW =~ $TYPE ]]
then
	[[ $COUNTRY = "IP Address not found" || $ALLOW_COUNTRIES =~ $COUNTRY ]] && RESPONSE="ALLOW" || RESPONSE="DENY"
fi

if [ $RESPONSE = "ALLOW" ]
then
#  Probably no resaon to log
#  logger "$RESPONSE $TYPE connection from $IP (Country: $COUNTRY)"
  exit 0
else
  logger "$RESPONSE $TYPE connection from $IP (Country: $COUNTRY)"
  exit 1
fi
