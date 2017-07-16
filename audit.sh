#!/bin/bash
# Audit Script for RHEL 7 based on CIS BenchMarks
trap '' 2 20
echo "##########################################################"
echo "Audit Script"
echo "RHEL 7"
echo "##########################################################"

datetime=`date +"%m%d%y-%H%M"`
exec > >(tee "/root/audit-"$datetime".txt") 2>&1


# File System Configuration


# 1.14 Set Sticky Bit on All World-Writable Directories
echo "df --local -P | awk {'if (NR!=1) print $6'} | xargs -I '{}' find '{}' -xdev -type d \( -perm -0002 -a ! -perm -1000 \) 2>/dev/null"
df --local -P | awk {'if (NR!=1) print $6'} | xargs -I '{}' find '{}' -xdev -type d \( -perm -0002 -a ! -perm -1000 \) 2>/dev/null
