#!/bin/bash
# Remedy Script for RHEL 7 based on CIS BenchMarks
# Script misc. section
trap '' 2 20
# Check if script is executed by root
if [ "$EUID" -ne 0 ]
  then echo "Please run this script as root"
  exit
fi
datetime=`date +"%m%d%y-%H%M"`

# 3.6 Configure NTP
checkntpinstalled=`yum list ntp | grep "Installed"`

if [ -z "$checkntpinstalled" ]
then
	yum install -y ntp
fi

checkyumntp=`yum list ntp | grep "Available Packages"`
checkntp1=`grep "^restrict default" /etc/ntp.conf`
checkntp2=`grep "^restrict -6 default" /etc/ntp.conf`
checkntp3=`grep "^server" /etc/ntp.conf`
checkntp4=`grep "ntp:ntp" /etc/sysconfig/ntpd`

if [ -n "$checkyumntp" ]
then
	yum install -y ntp
fi
	
if [ "$checkntp1" != "restrict default kod nomodify notrap nopeer noquery" ]
then
	sed -ie '8d' /etc/ntp.conf
	sed -ie '8irestrict default kod nomodify notrap nopeer noquery' /etc/ntp.conf
fi

if [ "$checkntp2" != "restrict -6 default kod nomodify notrap nopeer noquery" ]
then
	sed -ie '9irestrict -6 default kod nomodify notrap nopeer noquery' /etc/ntp.conf
fi

if [ -z "$checkntp3" ]
then
	sed -ie '21iserver 10.10.10.10' /etc/ntp.conf #Assume 10.10.10.10 is NTP server
fi

if [ -z "$checkntp4" ]
then
	sed -ie '2d' /etc/sysconfig/ntpd
	echo "1iOPTIONS=\"-u ntp:ntp -p /var/run/ntpd.pid\" " >> /etc/sysconfig/ntpd
fi

# 3.7 Remove LDAP
checkldapclientinstalled=`yum list openldap-clients | grep "Available Packages"`
checkldapserverinstalled=`yum list openldap-servers | grep "Available Packages"`

if [ -z "$checkldapclientinstalled" ]
then
	yum  -y erase openldap-clients
fi

if [ -z "$checkldapserverinstalled" ]
then
	yum -y erase openldap-servers
fi

# 3.8 Disable NFS & RPC
checknfslock=`systemctl is-enabled nfs-lock | grep "disabled"`
checknfssecure=`systemctl is-enabled nfs-secure | grep "disabled"`
checkrpcbind=`systemctl is-enabled rpcbind | grep "disabled"`
checknfsidmap=`systemctl is-enabled nfs-idmap | grep "disabled"`
checknfssecureserver=`systemctl is-enabled nfs-secure-server | grep "disabled"`

if [ -z "$checknfslock" ]
then
	systemctl disable nfs-lock
fi

if [ -z "$checknfssecure" ]
then
	systemctl disable nfs-secure
fi

if [ -z "$checkrpcbind" ]
then
	systemctl disable rpcbind
fi

if [ -z "$checknfsidmap" ]
then
	systemctl disable nfs-idmap
fi

if [ -z "$checknfssecureserver" ]
then
	systemctl disable nfs-secure-server
fi


