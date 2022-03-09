# IP-Geo-Information
Display Geo information for IP address

This is a project to replace the geoiplookup program that is out there, as for DB format has changed

It requires 3 Geo IP data sources, include a City and Country for each, a total of 6 files
	1) https://dev.maxmind.com/geoip/geoip2/geolite2/ (City and Country files)
	2) https://lite.ip2location.com/database (DB1 and DB3)
	3) https://db-ip.com/db/lite.php (City and Country files)
Please read and follow each of their rules for usage

Why 3 data sources, since I am using the "free" versions, they are not complete. Maybe add more in the future.
Using multiple sources helps to make the results to be more accurate, results are in the following order
	1) return the results when at least 2 of the DB matches at a country level.
	2) If not of the results matches, return the first of the 3 that has data

The primary program "ipgeoinfo.pl"

To use, create the directory "/usr/local/IPGEOInfo"
Place the file "ipgeoinfo.pl" into "usr/local/IPGEOInfo/bin"
Next are the data files
	GeoLite2 files
		/usr/local/OPGEOInfo/GeoLite2-City
		/usr/local/OPGEOInfo/GeoLite2-Country
			Note: The default files will extract into a name like "GeoLite2-City-CSV_20200421", you can create a link like
				GeoLite2-City -> GeoLite2-City-CSV_20200421
	IP2GEO files
		/usr/local/OPGEOInfo/IP2GEO-City/IP2LOCATION-LITE-DB3.CSV
		/usr/local/OPGEOInfo/IP2GEO-Country/IP2LOCATION-LITE-DB1.CSV
	DB-IP files
		/usr/local/IPGEOInfo/DBIP-City/dbip-city-lite.csv
			(this can be a link to something like "dbip-city-lite-2020-05.csv")
		/usr/local/IPGEOInfo/DBIP-Country/dbip-country-lite.csv
			(this can be a link to something like "dbip-country-lite-2020-05.csv")
		
	The final directory structure should look something like
		/usr/local/OPGEOInfo/
			bin/ipgeoinfo.pl
			GeoLite2-City/
				GeoLite2-City-Blocks-IPv4.csv
				GeoLite2-City-Locations-en.csv
			GeoLite2-Country/
				GeoLite2-Country-Blocks-IPv4.csv
				GeoLite2-Country-Locations-en.csv
			IP2GEO-City/IP2LOCATION-LITE-DB3.CSV
			IP2GEO-Country/IP2LOCATION-LITE-DB1.CSV
			DBIP-City/dbip-city-lite.csv
			DBIP-Country/dbip-country-lite.csv
			
To run the program
	Local IP 127.0.0.1
		ipgeoinfo.pl 127.0.0.1
		IP Geo Info - Country (127.0.0.1): -, -
	or 8.8.8.8
		ipgeoinfo.pl 8.8.8.8
		IP Geo Info - Country (8.8.8.8): US, United States of America

To get data at a city level
		ipgeoinfo.pl -city 8.8.8.8
		IP Geo Info - City (8.8.8.8): US, United States of America/California/Mountain View
		
Integration with geofilter and TCP Wrapper (there are many examples of this code on the internet, an example is available here)
Usually, it looks for a two letter code for filter.
Note, the one difference is that this program will return "RFC" for RFC1819 internal IP addresses.

