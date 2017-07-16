#!/bin/bash
# Remedy Script for RHEL 7 based on CIS BenchMarks
# Script misc. section
trap '' 2 20
datetime=`date +"%m%d%y-%H%M"`
exec > >(tee "/root/remedy-"$datetime".txt") 2>&1
echo "##########################################################"
echo "FIA Remedy Script"
echo "Red Hat Enterprise Linux 7"
echo "##########################################################"

echo "##########################################################"
# File System Configuration
echo "File System Configuration"

echo "##########################################################"
# 1.14 Set Sticky Bit on All World-Writable Directories
echo "1.14 Set Sticky Bit on All World-Writable Directories"
echo "$ df --local -P | awk {'if (NR!=1) print $6'} | xargs -I '{}' find '{}' -xdev -type d -perm -0002 2>/dev/null | xargs chmod a+t"
df --local -P | awk {'if (NR!=1) print $6'} | xargs -I '{}' find '{}' -xdev -type d -perm -0002 2>/dev/null | xargs chmod a+t

echo "##########################################################"
# 1.15 Disable Mounting of Legacy Filesystems"
echo "1.15 Disable Mounting of Legacy Filesystems"
echo "$ touch /etc/modprobe.d/CIS.conf"
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

echo "##########################################################"
# Patching the Linux System
echo "Patching the Linux System"
echo "$ cat /etc/redhat-release"
cat /etc/redhat-release

echo "##########################################################"
# 2. Remove Legacy Services
echo "2. Remove Legacy Service"
# 2.1 Remove telnet clients & server
echo "$ yum -y erase telnet-server"
yum -y erase telnet-server
echo "$ yum -y erase telnet"
yum -y erase telnet

echo "##########################################################"
