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

# 3.9 Remove DNS, FTP, HTTP, HTTP-Proxy, SNMP
checkyumdns=`yum list bind | grep "Available Packages"`
checkdns=`systemctl status named | grep inactive`
checkdns1=`systemctl status named | grep disabled`
if [ -z "$checkyumdns" ]
then
	if [ -z "$checkdns" -o -z "$checkdns1" ]
	then
		systemctl stop named
		systemctl disable named
	fi
fi

checkyumftp=`yum list vsftpd | grep "Available Packages"`
checkftp=`systemctl status vsftpd | grep inactive`
checkftp1=`systemctl status vsftpd | grep disabled`
if [ -z "$checkyumftp" ]
then
	if [ -z "$checkftp" -o -z "$checkftp1" ]
	then
		systemctl stop vsftpd
		systemctl disable vsftpd
	fi
fi

checkyumhttp=`yum list httpd | grep "Available Packages"`
checkhttp=`systemctl status httpd | grep inactive`
checkhttp1=`systemctl status httpd | grep disabled`
if [ -z "$checkyumhttp" ]
then
	if [ -z "$checkhttp" -o -z "$checkhttp1" ]
	then
		systemctl stop httpd
		systemctl disable httpd
	fi
fi

checkyumsquid=`yum list squid | grep "Available Packages"`
checksquid=`systemctl status squid | grep inactive`
checksquid1=`systemctl status squid | grep disabled`
if [ -z "$checkyumsquid" ]
then
	if [ -z "$checksquid" -o -z "$checksquid1" ]
	then
		systemctl stop squid
		systemctl disable squid
	fi
fi

checkyumsnmp=`yum list net-snmp | grep "Available Packages"`
checksnmp=`systemctl status snmpd | grep inactive`
checksnmp1=`systemctl status snmpd | grep disabled`
if [ -z "$checkyumsnmp" ]
	then
	if [ -z "$checksnmp" -o -z "$checsnmp1" ]
	then
		systemctl stop snmpd
		systemctl disable snmpd
	fi
fi

# 3.10 MTA
checkmta=`netstat -an | grep LIST | grep "127.0.0.1:25[[:space:]]"`

if [ -z "$checkmta" ]
then
	sed -ie '116iinet_interfaces = localhost' /etc/postfix/main.cf
	systemctl restart postfix
fi

# 4.1 Set User/Group Owner on /boot/grub2/grub.cfg
checkowner=$(stat -L -c "owner=%U group=%G" /boot/grub2/grub.cfg)
if [ "$checkowner" == "owner=root group=root" ]
then
	#If owner and group is configured CORRECTLY
	printf "\nBoth owner and group belong to ROOT user : PASSED"
	printf "\n$checkowner"
else
	#If owner ang group is configured INCORRECTLY
	chown root:root /boot/grub2/grub.cfg
	printf "\nBoth owner and group belong to ROOT user : FAILED"
	printf "\nChanging the owner and group..."
	printf "\nDone, Change SUCCESSFUL\n"
fi

# 4.2 Set Permissions on /boot/grub2/grub.cfg
checkpermission=$(stat -L -c "%a" /boot/grub2/grub.cfg | cut -c 2,3)
if [ "$checkpermission" == 00 ]
then
	#If the permission is configured CORRECTLY
	printf "\nConfiguration of Permission: PASSED"
else
	#If the permission is configured INCORRECTLY
	printf "\nConfiguration of Permission: FAIlED"
	printf "\nChanging configuration..."
	chmod og-rwx /boot/grub2/grub.cfg
	printf "\nDone, Change SUCCESSFUL\n"
fi

