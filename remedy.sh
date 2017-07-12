#!/bin/bash
# Remedy Script for RHEL 7 based on CIS BenchMarks
##########################################################
# File System Configuration


# 1.14 Set Sticky Bit on All World-Writable Directories
df --local -P | awk {'if (NR!=1) print $6'} | xargs -I '{}' find '{}' -xdev -type d \( -perm -0002 -a ! -perm -1000 \) 2>/dev/null | xargs chmod a+t

# 1.15 Disable Mounting of Legacy Filesystems
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
