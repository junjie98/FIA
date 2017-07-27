#!/bin/bash
# Audit Script for RHEL 7 based on CIS BenchMarks
# Script misc. section
trap '' 2 20
# Check if script is executed by root
if [ "$EUID" -ne 0 ]
	then echo "Please run this script as root"
	exit
fi

# 3.6 Configure NTP
checkntp=`yum list ntp | grep "Installed Packages"`
checkntp1=`grep "^restrict default kod nomodify notrap nopeer noquery" /etc/ntp.conf`
checkntp2=`grep "^restrict -6 default kod nomodify notrap nopeer noquery" /etc/ntp.conf` 
checkntp3=`grep "^server" /etc/ntp.conf | grep server`
checkntp4=`grep 'OPTIONS="-u ntp:ntp -p /var/run/ntpd.pid"' /etc/sysconfig/ntpd`
if [ -n "$checkntp" ]
then
if [ -n "$checkntp1" ]
then 
	if [ -n "$checkntp2" ]
	then 
		if [ -n "$checkntp3" ]
			then 
				if [ -n "$checkntp4" ]
				then
					echo "$count. NTP - PASSED (NTP has been properly configured)"
					((count++))
				else 
					echo "$count. NTP - FAILED (Option has not been configured in /etc/sysconfig/ntpd)" 
					((count++))
				fi
		else
			echo "$count. NTP - FAILED (Failed to list down NTP servers)"
			((count++))
		fi
	else 
		echo "$count. NTP - FAILED (Failed to implement restrict -6 default kod nomodify notrap nopeer noquery)"
		((count++))
	fi
else 
	echo "$count. NTP - FAILED (Failed to implement restrict default kod nomodify notrap nopeer noquery)"
	((count++))
fi 
else 
	echo "$count. NTP - FAILED (NTP is not installed)"
	((count++))
fi

# 3.7 Remove LDAP
checkldapclients=`yum list openldap-clients | grep 'Available Packages'`
checkldapservers=`yum list openldap-servers | grep 'Available Packages'`

if [ -n "checkldapclients" -a -n "checkldapservers" ]
then 
	echo "$count. LDAP - PASSED (LDAP server and client are both not installed)"
	((count++))
elif [ -n "checkldapclients" -a -z "checkldapservers" ]
then
	echo "$count. LDAP - FAILED (LDAP server is installed)"
	((count++))
elif [ -z "checkldapclients" -a -n "checkldapservers" ]
then
	echo "$count. LDAP - FAILED (LDAP client is installed)"
	((count++))
else 
	echo "$count. LDAP - FAILED (Both LDAP client and server are installed)"
	((count++))
fi 

