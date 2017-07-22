#!/bin/bash
# Audit Script for RHEL 7 based on CIS BenchMarks
# Script misc. section
trap '' 2 20
# Check if script is executed by root
if [ "$EUID" -ne 0 ]
	then echo "Please run this script as root"
	exit
fi
# Functions
function output () {
        if [[ $2 ]]; then
                echo "$1, RESULT: PASS" >> $filename
        else
                echo "$1, RESULT: FAIL" >> $filename
        fi
}
function no_output () {
        if [[ $2 ]]; then
                echo "$1, RESULT: FAIL" >> $filename
        else
                echo "$1, RESULT: PASS" >> $filename
        fi
}
function manual () {
        echo "$1, RESULT: Manually Test Again" >> $filename
}
datetime=`date +"%m%d%y-%H%M"`
filename="FIA_Audit_Results-"$datetime".txt"
touch $filename
echo "##########################################################"
echo "FIA Audit Script"
echo "Red Hat Enterprise Linux 7"
echo "##########################################################"

echo "##########################################################"
# File System Configuration
echo "File System Configuration"


echo "##########################################################"
# 1.14 Set Sticky Bit on All World-Writable Directories
echo "1.14 Set Sticky Bit on All World-Writable Directories"
echo "$ df --local -P | awk {'if (NR!=1) print $6'} | xargs -I '{}' find '{}' -xdev -type d \( -perm -0002 -a ! -perm -1000 \) 2>/dev/null"
df --local -P | awk {'if (NR!=1) print $6'} | xargs -I '{}' find '{}' -xdev -type d \( -perm -0002 -a ! -perm -1000 \) 2>/dev/null

echo "##########################################################"
# 1.15 Disable Mounting of Legacy Filesystem
echo "1.15 Disable Mounting of Legacy Filesystem"
# cramfs Filesystem
echo "cramfs Filesystem"
echo "$ /sbin/modprobe -n -v cramfs"
/sbin/modprobe -n -v cramfs
echo "$ /sbin/lsmod | grep cramfs"
/sbin/lsmod | grep cramfs

echo "##########################################################"
# freevxfs Filesystem
echo "freevxfs Filesystem"
echo "$ /sbin/modprobe -n -v freevxfs"
/sbin/modprobe -n -v freevxfs
echo "$ /sbin/lsmod | grep freevxfs"
/sbin/lsmod | grep freevxfs

echo "##########################################################"
# jffs2 Filesystem
echo "jffs2 Filesystem"
echo "$ /sbin/modprobe -n -v jffs2"
/sbin/modprobe -n -v jffs2
echo "$ /sbin/lsmod | grep jffs2"
/sbin/lsmod | grep jffs2

echo "##########################################################"
# hfs Filesystem
echo "hfs Filesystem"
echo "$ /sbin/modprobe -n -v hfs"
/sbin/modprobe -n -v hfs
echo "$ /sbin/lsmod | grep hfs"
/sbin/lsmod | grep hfs

echo "##########################################################"
# hfsplus Filesystem
echo "hfsplus Filesystem"
echo "$ /sbin/modprobe -n -v hfsplus"
/sbin/modprobe -n -v hfsplus
echo "$ /sbin/lsmod | grep hfsplus"
/sbin/lsmod | grep hfsplus

echo "##########################################################"
# squashfs Filesystem
echo "squashfs Filesystem"
echo "$ /sbin/modprobe -n -v squashfs"
/sbin/modprobe -n -v squashfs
echo "$ /sbin/lsmod | grep squashfs"
/sbin/lsmod | grep squashfs

echo "##########################################################"
# udf Filesystem
echo "udf Filesystem"
echo "$ /sbin/modprobe -n -v udf"
/sbin/modprobe -n -v udf
echo "$ /sbin/lsmod | grep udf"
/sbin/lsmod | grep udf

echo "##########################################################"
# Patching the Linux System

echo "##########################################################"
# Verify Package Integrity Using RPM

echo "##########################################################"
# Removing Legacy Services
echo "2.1 Removing Legacy Services"
# Remove telnet clients & servers
echo "2.1 Remove telnet clients & servers"
echo "$ rpm -q telnet"
rpm -q telnet
echo "$ rpm -q telnet-server"
rpm -q telnet-server

echo "##########################################################"
# Remove rsh clients & servers
echo "Remove rsh clients & servers"
echo "$ rpm -q rsh"
rpm -q rsh
echo "$ rpm -q rsh-server"
rpm -q rsh-server
