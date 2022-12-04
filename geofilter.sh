#!/bin/bash

# UPPERCASE space-separated country codes to ACCEPT
ALLOW_COUNTRIES="RFC US FI CA GB FR AU"
DISALLOW_COUNTRIES="CN VN KR KP TH NC LA BG IN RU PL IR CZ CL AR MD BA ES AL RS BW NP LT CO RE KH BZ UA ID HN ZA LB SK MY PA HU KW KZ ID MY HU IQ CY GT DZ MN MZ TZ GH BD BB SD UG RO IS LVBN NW KE ET PE OA OM LY SI MW KG ECi PT BR TR"
ALLOW="default imaps sshd"
DISALLOW="smtp sendmail"
GEOIP=/usr/local/GeoLite2/bin/geoip2lookup.pl

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

# logger "$TYPE connection from $IP"

# Look for matches in hosts.deny
FOUND=`grep -w $IP /etc/hosts.deny`

if [ -z "$FOUND" ]
then
	SLASH=`echo $IP|cut -d'.' -f1-3`
	FOUND=`grep "$SLASH.0/24" /etc/hosts.deny`

	if [ -z "$FOUND" ]
	then
		SLASH=`echo $IP|cut -d'.' -f1-2`
	        FOUND=`grep "$SLASH.0.0/16" /etc/hosts.deny`
	fi
fi

if [ "$FOUND" ]
then
	COUNTRY=`$GEOIP $IP | awk -F ": " '{ print $2 }' | awk -F "," '{ print $1 }' | head -n 1`
	logger "Existing IP block - $TYPE connection from $IP (Country: $COUNTRY)"
  exit 1
fi

COUNTRY=`$GEOIP $IP | awk -F ": " '{ print $2 }' | awk -F "," '{ print $1 }' | head -n 1`
if [[ $DISALLOW =~ $TYPE ]]
then
	[[ $DISALLOW_COUNTRIES =~ $COUNTRY ]] && RESPONSE="DENY" || RESPONSE="ALLOW"
fi

if [[ $ALLOW =~ $TYPE ]]
then
	[[ $COUNTRY = "IP Address not found" || $ALLOW_COUNTRIES =~ $COUNTRY ]] && RESPONSE="ALLOW" || RESPONSE="DENY"
fi

#if [[ $TYPE =~ "sendmail" ]]
#then
#	
#fi

if [ $RESPONSE = "ALLOW" ]
then
#  logger "$RESPONSE $TYPE connection from $IP (Country: $COUNTRY)"
	echo "IP: $IP allowed";
  exit 0
else
  logger "Country block - $RESPONSE $TYPE connection from $IP (Country: $COUNTRY)"
	echo "IP: $IP ($COUNTRY) blocked";
  exit 1
fi
