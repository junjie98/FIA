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
exec > >(tee "/root/remedy-"$datetime".txt") 2>&1
echo "##########################################################"
echo "FIA Remedy Script"
echo "Red Hat Enterprise Linux 7"

echo "##########################################################"
echo "File System Configuration"

echo "Set Sticky Bit on All World-Writable Directories"
df --local -P | awk {'if (NR!=1) print $6'} | xargs -I '{}' find '{}' -xdev -type d -perm -0002 2>/dev/null | xargs chmod a+t

echo "Disable Mounting of Legacy Filesystems"
touch /etc/modprobe.d/CIS.conf
/bin/cat << EOM > /etc/modprobe.d/CIS.conf
install cramfs /bin/true
install freevxfs /bin/true
install jffs2 /bin/true
install hfs /bin/true
install hfsplus /bin/true
install squashfs /bin/true
install udf /bin/true
EOM

echo "Patching the Linux System"
cat /etc/redhat-release

echo "Remove Legacy Service"
yum -y erase telnet-server
yum -y erase telnet
yum -y erase rsh-server	
yum -y erase rsh
yum -y erase ypbind	
yum -y erase ypserv	
yum -y erase tftp
yum -y erase tftp-server
yum -y erase xinetd
chkconfig chargen-dgram off
chkconfig chargen-stream off	
chkconfig daytime-dgram off
chkconfig daytime-stream off	
chkconfig echo-dgram off	
chkconfig echo-stream off	
chkconfig tcpmux-server off

echo "Special Services"
