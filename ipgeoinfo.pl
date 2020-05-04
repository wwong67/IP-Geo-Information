#!/usr/bin/perl -w

# Author:	Wai Wong (wwong@mmnet.com)
# Version: 	1.0.0
# Date:		May 4, 2020

# IP to Geo information
# GitHub:	https://github.com/wwong67/IP-Geo-Information

# Perl includes needed
use strict;
use Socket;

# Set the type of data to display, City/Country
my $type = "Country";
if ( @ARGV and $ARGV[0] eq "-city" ) { $type = shift @ARGV; $type = "City"; }

my $time = time ();
my $basedir = "/usr/local/IPGEOInfo";
my $tmpfile = "/tmp/ipgeoinfo.$time";
my $loaddata = 0;
my $usehash = 1;
my %dbhash = ();

# Start the search
main ( @ARGV );

#
sub isRFCInternalIP
{
	# 192.168.0.0/16", "172.16.0.0/12", "10.0.0.0/8"
	my $ip = shift @_;

	my @check = split ( /\./, $ip );

	if ( $check[0] eq "10" ) { return ( 1 ); }
	if ( $check[0] eq "172" and $check[1] eq "16" ) { return ( 1 ); }
	if ( $check[0] eq "192" and $check[1] eq "168" ) { return ( 1 ); }
	return;
}

# GeoIP sub routines

sub checkIPRange
{
	my $ip = shift @_;
	my $line = shift @_;
	my @temp = split ( ',', $line );

	@temp = split ( '/', $temp[0] );

	my @baseip = split ( '\.', $ip );
	my @checkip = split ( '\.', $temp[0] );
	my $range = $temp[1];
	my $top;
	my $log;

	# Start the checks

	# start by matching the "a"

	if ( $range >= 8 )
	   {
		if ( $range <= 8 )
		   {
			$log = ( 8 - $range );
			$top = 2 ** $log;
			if ( $baseip[0] >= $checkip[0] and $baseip[0] <= ( $checkip[0] + $top ) )
			   { return ( $line ); }
		   }

		# this test the "b"
		if ( $range > 8  and $range <= 16 )
		   {
			$log = ( 16 - $range );
			$top = 2 ** $log;
			if ( "$baseip[0]" ne "$checkip[0]" ) { return (); }
			if ( $baseip[1] >= $checkip[1] and $baseip[1] <= ( $checkip[1] + $top ) )
			   { return ( $line ); }
		   }

		# this test the "c"
		if ( $range > 16  and $range <= 24 )
		   {
			if ( "$baseip[0]" ne "$checkip[0]" ) { return (); }
			if ( "$baseip[1]" ne "$checkip[1]" ) { return (); }
			$log = ( 24 - $range );
			$top = ( 2 ** $log ) - 1;
			if ( $baseip[2] >= $checkip[2] and $baseip[2] <= ( $checkip[2] + $top ) )
			   { return ( $line ); }
		   }

		# this test the "d"
		if ( $range > 24  and $range <= 32 )
		   {
			if ( "$baseip[0]" ne "$checkip[0]" ) { return (); }
			if ( "$baseip[1]" ne "$checkip[1]" ) { return (); }
			if ( "$baseip[2]" ne "$checkip[2]" ) { return (); }
			$log = ( 32 - $range );
			$top = ( 2 ** $log ) - 1;
			if ( $baseip[3] >= $checkip[3] and $baseip[3] <= ( $checkip[3] + $top ) )
			   { return ( $line ); }
		   }
	   }

	# Whatever reason we are here... this should not match
	return ();
}

sub IPSearch
{
	my $ip = shift @_;
	my $checkip = shift @_;
	my $dbfile = shift @_;
	my $line;
	my $output;

	my @temp = split ( '\.', $ip );
	my $key;
	my $data;
	my $extra;

	if ( ! $loaddata )
	   {
		@temp = split ( '\.', $ip );
		if ( $usehash )
		   {
			for $line ( `grep "^$temp[0]." $dbfile` )
			   {
				chomp ( $line );
				( $key, $extra ) = split ( '/', $line, 2 );
				$dbhash{$key} = $line;
			   }
		   } else { `grep "^$temp[0]." $dbfile > $tmpfile`; }
		$loaddata = 1;
	}

        if ( $usehash )
           { if ( $dbhash{$checkip} ) { $output = $dbhash{$checkip}; } }
           else { $output = `grep "^${checkip}/" $tmpfile`; }

	if ( $output )
	   {
		chomp ( $output );
		$output = checkIPRange ( $ip, $output );
		return ( $output );
	   }
	return ();
}

sub LocationLookup
{
	my $line = shift @_;
	my $locationfile = shift @_;

	my $network;
	my $geoname_id;
	my $registered_country_geoname_id;
	my $represented_country_geoname_id;
	my $is_anonymous_proxy;
	my $is_satellite_provider;
	my @temp;
	( $network, $geoname_id, $registered_country_geoname_id, $represented_country_geoname_id, $is_anonymous_proxy, $is_satellite_provider ) = split ( ',', $line );

	my $CountryLine = `grep "^${geoname_id}," $locationfile`;

	my $local_code;
	my $continent_code;
	my $continent_name;
	my $country_name;
	my $city;
	my $junk;
	my $is_in_european_union;

	@temp = split ( ',', $CountryLine );
	$geoname_id = $temp[0];
	my $locale_code = $temp[1];
	$continent_code = $temp[2];
	$continent_name = $temp[3];
	my $country_iso_code = $temp[4];
	$country_name = $temp[5];
	$country_name =~ s/\"//g;
	$is_in_european_union = $temp[6];

	if ( $type eq "City" )
	   {
		$junk = $temp[12];
		( $junk, $city ) = split ( "/", $junk );
	   }

	if ( !$country_iso_code ) { $country_iso_code = uc ($locale_code); }
	if ( !$country_name ) { $country_name = $continent_name; }

	if ( $city ) 
	   { return ( $country_iso_code, $country_name, $city ); }
	return ( $country_iso_code, $country_name );
}

sub searchGeoIPLite
{
	my $ip = shift @_;
	my $a;
	my $b;
	my $c;
	my $d;
	my $output;
	my $checkip; 
	my $country;
	my $countryCode;
	my $city;

	# GeoIP DB Country files
	my $countrydir = "GeoLite2-Country";
	my $countrydb = "GeoLite2-Country-Blocks-IPv4.csv";
	my $locationdb = "GeoLite2-Country-Locations-en.csv";

	my $countryfile = "$basedir/$countrydir/$countrydb";
	my $locationfile = "$basedir/$countrydir/$locationdb";

	if ( $type eq "City" )
	   {
		# GeoIP DB Country files
		$countrydir = "GeoLite2-City";
		$countrydb = "GeoLite2-City-Blocks-IPv4.csv";
		$locationdb = "GeoLite2-City-Locations-en.csv";

		$countryfile = "$basedir/$countrydir/$countrydb";
		$locationfile = "$basedir/$countrydir/$locationdb";
	   }

	# Look for /32
	$output = IPSearch ( $ip, $ip, $countryfile );
	if ( $output )
	   {
		( $countryCode, $country, $city) = LocationLookup ( $output, $locationfile );
		goto EndCheck;
	   }

	# Look for /24
	( $a, $b, $c, $d ) = split ( '\.', $ip );
	$d = 0;
	$checkip = "${a}.${b}.${c}.${d}";
	$output = IPSearch ( $ip, $checkip, $countryfile );
	if ( $output )
	   {
		( $countryCode, $country, $city) = LocationLookup ( $output, $locationfile );
		goto EndCheck;
	   }

	# Look for /25 to /32
	( $a, $b, $c, $d ) = split ( '\.', $ip );
	while ( $d >= 0 )
	   {
		$checkip = "${a}.${b}.${c}.${d}";
		$output = IPSearch ( $ip, $checkip, $countryfile );
		if ( $output )
		   {
			( $countryCode, $country, $city) = LocationLookup ( $output, $locationfile );
			goto EndCheck;
		   }
		$d--;
	   }

	# Look for /17 to /24
	( $a, $b, $c, $d ) = split ( '\.', $ip );
	$d = 0;
	while ( $c >= 0 )
	   {
		$checkip = "${a}.${b}.${c}.${d}";
		$output = IPSearch ( $ip, $checkip, $countryfile );
		if ( $output )
		   {
			( $countryCode, $country, $city) = LocationLookup ( $output, $locationfile );
			goto EndCheck;
		   }
		$c--;
	   }

	# Look for /9 to /16
	( $a, $b, $c, $d ) = split ( '\.', $ip );
	$d = 0;
	$c = 0;
	while ( $b >= 0 )
	   {
		$checkip = "${a}.${b}.${c}.${d}";
		$output = IPSearch ( $ip, $checkip, $countryfile );
		if ( $output )
		   {
			( $countryCode, $country, $city) = LocationLookup ( $output, $locationfile );
			goto EndCheck;
		   }
		$b--;
	   }

	return ( );
	EndCheck:

	if ( $type eq "City" )
	   { return ( $countryCode, $country, '', $city) }
	   else { return ( $countryCode, $country ) }
}

# IP2GEO sub routines

sub searchIP2GEO
{
	my $ip = shift @_;

	my $inet = unpack("N",inet_aton($ip));
	my $short = int ( $inet / 100000 );
	my $dbfile = "${basedir}/IP2GEO-${type}/IP2LOCATION-LITE-DB1.CSV";
	if ( $type eq "City" ) { $dbfile = "${basedir}/IP2GEO-${type}/IP2LOCATION-LITE-DB3.CSV" }

	my $line = `grep '^"$short' $dbfile | tr -d '\"' | awk -F , '{ if ( \$1 <= $inet && \$2 >= $inet ) print \$0 }'`;
	chomp ( $line );

	if ( $line )
	   {
		my @temp = split ( ",", $line );

		my $country_code = $temp[2];
		my $country = $temp[3];
		if ( $type eq "City" )
		   {
			my $locale = $temp[4];
			my $city = $temp[5];
			return ( $country_code, $country, $locale, $city )
		   }
		return ( $country_code, $country );
	   }
	return ();
}

sub searchDBIP
{
	my $ip = shift @_;
	my $line;
	my @temp;
	my $start;
	my $end;
	my @octet = split ( '\.', $ip );

	my $inet = unpack("N",inet_aton($ip));
	my $dbfile = "${basedir}/DBIP-${type}/dbip-country-lite.csv";
	my $command = "grep '^$octet[0]\.' $dbfile";

	if ( $type eq "City" )
	   {
		$dbfile = "${basedir}/DBIP-${type}/dbip-city-lite.csv";
		$command = "grep '^$octet[0]\.$octet[1]\.' $dbfile";
	   }

	for $line ( `$command` )
	   {
		chomp ( $line );
		@temp = split ( ',', $line );
		$start = unpack("N",inet_aton($temp[0]));
		if ( $start <= $inet )
		   {
			$end = unpack("N",inet_aton($temp[1]));
			if ( $inet <= $end  )
			   {
				if ( $type eq "City" )
				   {
					$temp[5] =~ s/\"//g;
					return ( $temp[3], $temp[3], $temp[4], $temp[5] );
				   }
				return ( $temp[2], $temp[2] );
			   }
		   }
	   }
	return;
}

sub isIPv4
{
	my $ip = shift @_;
	my @octet = split ( '\.', $ip );
	my $size = @octet;

	if ( $size != 4 ) { return () };

	if ( $octet[0] <= 255 and $octet[1] <= 255 and $octet[2] <= 255 and $octet[3] <= 255 ) { return ( 1 ); }
}

sub getGeoInfoCompare
{
	my $ip = shift @_;
	my $country_code;
	my $country;
	my $locale;
	my $city;
	my %found;

	# Check to see if it is an IPv4 format
	if ( !isIPv4 ( $ip ) ) { return }

	# Check for RFC 1918 internal IP
	if ( isRFCInternalIP ( $ip ) ) { return ( "RFC", "RFC1918 INTERNAL IP", "RFC", "RFC" ) };

	# Try IP2GEO first, it is the fastest
	if ( $type eq "City" )
	   {
		( $country_code, $country, $locale, $city ) = searchIP2GEO ( $ip );
		if ( $country_code )
		   {
			$found{IP2GEO}->{code} = $country_code;
			$found{IP2GEO}->{country} = $country;
			$found{IP2GEO}->{locale} = $locale;
			$found{IP2GEO}->{city} = $city;
		   }

		( $country_code, $country, $locale, $city ) = searchGeoIPLite ( $ip );
		if ( $country_code )
		   {
			$found{GeoIP}->{code} = $country_code;
			$found{GeoIP}->{country} = $country;
			$found{GeoIP}->{locale} = $locale;
			$found{GeoIP}->{city} = $city;
		   }

		# If IP2GEO and GeoIP country matches
		if ( ( $found{IP2GEO}->{code} and $found{GeoIP}->{code} ) and $found{IP2GEO}->{code} eq $found{GeoIP}->{code} )
		   { return ( $found{IP2GEO}->{code}, $found{IP2GEO}->{country}, $found{IP2GEO}->{locale}, $found{IP2GEO}->{city} ) }

		# No match yet, trying the 3rd DB
		( $country_code, $country, $locale, $city ) = searchDBIP ( $ip );
		if ( $country_code )
		   {
			$found{DBIP}->{code} = $country_code;
			$found{DBIP}->{country} = $country;
			$found{DBIP}->{locale} = $locale;
			$found{DBIP}->{city} = $city;
		   }

		# If IP2GEO and DBIP is the same, return the information from IP2GEO
		if ( ( $found{IP2GEO}->{code} and $found{GeoIP}->{code} ) and $found{IP2GEO}->{code} eq $found{GeoIP}->{code} )
		   { return ( $found{IP2GEO}->{code}, $found{IP2GEO}->{country}, $found{IP2GEO}->{locale}, $found{IP2GEO}->{city} ) }

		# If GeoIP and DBIP is the same, return the information from GeoIP
		if ( ( $found{GeoIP}->{code} and $found{DBIP}->{code} ) and $found{GeoIP}->{code} eq $found{DBIP}->{code} )
		   { return ( $found{GeoIP}->{code}, $found{GeoIP}->{country}, $found{GeoIP}->{locale}, $found{GeoIP}->{city} ) }

		# The following when all 3 do not match
		# If There is information for IP2Geo
		if ( $found{IP2GEO}->{code} )
		   { return ( $found{IP2GEO}->{code}, $found{IP2GEO}->{country}, $found{IP2GEO}->{locale}, $found{IP2GEO}->{city} ) }

		# If There is information for GeoIP
		if ( $found{GeoIP}->{code} )
		   { return ( $found{GeoIP}->{code}, $found{GeoIP}->{country}, $found{GeoIP}->{locale}, $found{GeoIP}->{city} ) }

		if ( $found{DBIP}->{code} )
		   { return ( $found{DBIP}->{code}, $found{DBIP}->{country}, $found{DBIP}->{locale}, $found{DBIP}->{city} ) }

		if ( $country_code eq "-" ) { return () };
		return;
	   }
	   else
	   {
		( $country_code, $country ) = searchIP2GEO ( $ip );
		if ( $country_code )
		   {
			$found{IP2GEO}->{code} = $country_code;
			$found{IP2GEO}->{country} = $country;
		   }

		( $country_code, $country ) = searchGeoIPLite ( $ip );
		if ( $country_code )
		   {
			$found{GeoIP}->{code} = $country_code;
			$found{GeoIP}->{country} = $country;
		   }

		# If IP2GEO and GeoIP country matches
		if ( ( $found{IP2GEO}->{code} and $found{GeoIP}->{code} ) and $found{IP2GEO}->{code} eq $found{GeoIP}->{code} )
		   { return ( $found{IP2GEO}->{code}, $found{IP2GEO}->{country} ) }

		( $country_code, $country ) = searchDBIP ( $ip );
		if ( $country_code )
		   {
			$found{DBIP}->{code} = $country_code;
			$found{DBIP}->{country} = $country;
		   }

		# If IP2GEO and DBIP is the same, return the information from IP2GEO
		if ( ( $found{IP2GEO}->{code} and $found{DBIP}->{code} ) and $found{IP2GEO}->{code} eq $found{DBIP}->{code} )
		   { return ( $found{IP2GEO}->{code}, $found{IP2GEO}->{country} ) }

		# If GeoIP and DBIP is the same, return the information from GeoIP
		if ( ( $found{GeoIP}->{code} and $found{DBIP}->{code} ) and $found{GeoIP}->{code} eq $found{DBIP}->{code} )
		   { return ( $found{GeoIP}->{code}, $found{GeoIP}->{country} ) }

		# The following when all 3 do not match
		# If There is information for IP2Geo
		if ( $found{IP2GEO}->{code} )
		   { return ( $found{IP2GEO}->{code}, $found{IP2GEO}->{country} ) }

		# If There is information for GeoIP
		if ( $found{GeoIP}->{code} )
		   { return ( $found{GeoIP}->{code}, $found{GeoIP}->{country} ) }

		if ( $found{DBIP}->{code} )
		   { return ( $found{DBIP}->{code}, $found{DBIP}->{country} ) }

		if ( $country_code eq "-" ) { return () };
		return;
	   }
	return;
}

sub getGeoInfo
{
	my $ip = shift @_;
	my $country_code;
	my $country;
	my $locale;
	my $city;

	# Check to see if it is an IPv4 format
	if ( !isIPv4 ( $ip ) ) { return }

	# Check for RFC 1918 internal IP
	if ( isRFCInternalIP ( $ip ) ) { return ( "RFC", "RFC1918 INTERNAL IP", "RFC", "RFC" ) };

	# Try IP2GEO first, it is the fastest
	if ( $type eq "City" )
	   {
		( $country_code, $country, $locale, $city ) = searchIP2GEO ( $ip );
		if ( !$country_code ) { ( $country_code, $country, $locale, $city ) = searchGeoIPLite ( $ip ); }
		if ( !$country_code ) { ( $country_code, $country, $locale, $city ) = searchDBIP ( $ip ); }
		if ( $country_code eq "-" ) { return () };
		return ( $country_code, $country, $locale, $city );
	   }
	   else
	   {
		( $country_code, $country ) = searchIP2GEO ( $ip );
		if ( !$country_code ) { ( $country_code, $country ) = searchGeoIPLite ( $ip ); }
		if ( !$country_code ) { ( $country_code, $country ) = searchDBIP ( $ip ); }
		if ( $country_code eq "-" ) { return () };
		return ( $country_code, $country, $locale, $city );
	   }
}

sub main
{
	my $ip;
	my $country_code;
	my $country;
	my $locale;
	my $city;

	for $ip ( @_ )
	   {
		$loaddata = 0;
		( $country_code, $country, $locale, $city ) = getGeoInfoCompare ( $ip );
		print "IP Geo Info - $type ($ip): ";
		if ( $country_code )
		   {
			print "$country_code, $country";
			if ( $type eq "City" )
			   { print "/$locale/$city"; }
			print "\n";
		   } else { print "NONE, IP Address not found\n"; }
	   }
}

