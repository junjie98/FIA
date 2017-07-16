#!/bin/bash
# Audit Script for RHEL 7 based on CIS BenchMarks
# Script misc. section
trap '' 2 20
datetime=`date +"%m%d%y-%H%M"`
exec > >(tee "/root/audit-"$datetime".txt") 2>&1
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





