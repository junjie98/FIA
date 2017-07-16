#!/bin/bash
# Remedy Script for RHEL 7 based on CIS BenchMarks
trap '' 2 20
echo "##########################################################"
echo "Remedy Script"
echo "RHEL 7"
echo "##########################################################"

datetime=`date +"%m%d%y-%H%M"`
exec > >(tee "/root/remedy-"$datetime".txt") 2>&1

echo "File System Configuration"


echo "1.14 Set Sticky Bit on All World-Writable Directories"
echo "$ df --local -P | awk {'if (NR!=1) print $6'} | xargs -I '{}' find '{}' -xdev -type d -perm -0002 2>/dev/null | xargs chmod a+t"
df --local -P | awk {'if (NR!=1) print $6'} | xargs -I '{}' find '{}' -xdev -type d -perm -0002 2>/dev/null | xargs chmod a+t

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
