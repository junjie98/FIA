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
checkowner=`stat -L -c "owner=%U group=%G" /boot/grub2/grub.cfg`
if [ "$checkowner" == "owner=root group=root" ]
then
	#If owner and group is configured CORRECTLY
	echo "Both owner and group belong to ROOT user : PASSED"
	echo "$checkowner"
else
	#If owner ang group is configured INCORRECTLY
	chown root:root /boot/grub2/grub.cfg
	echo "Both owner and group belong to ROOT user : FAILED"
	echo "Changing the owner and group..."
	echo "Done, Change SUCCESSFUL\n"
fi

# 4.2 Set Permissions on /boot/grub2/grub.cfg
checkpermission=`stat -L -c "%a" /boot/grub2/grub.cfg | cut -c 2,3`
if [ "$checkpermission" == 00 ]
then
	#If the permission is configured CORRECTLY
	echo "Configuration of Permission: PASSED"
else
	#If the permission is configured INCORRECTLY
	echo "Configuration of Permission: FAIlED"
	echo "Changing configuration..."
	chmod og-rwx /boot/grub2/grub.cfg
	echo "Done, Change SUCCESSFUL"
fi

# 4.3 Set Boot Loader Password
checkboot=`grep "set superusers" /boot/grub2/grub.cfg | sort | head -1 | awk -F '=' '{print $2}' | tr -d '"'`
user=`grep "set superusers" /boot/grub2/grub.cfg | sort | head -1 | awk -F '=' '{print $2}'`
if [ "$checkboot" == "root" ]
then
	#If the configuration is CORRECT
	echo "Boot Loader Settings : PASSED"
	echo "The following are the superusers: "
	echo "$user"
else
	#If the configuration is INCORRECT
	echo "Boot Loader Settings : FAILED"
	echo "Configuring Boot Loader Settings..."
	touch /etc/bootloader.txt
	printf "password\npassword" > /etc/bootloader.txt
	grub2-mkpasswd-pbkdf2 < /etc/bootloader.txt > boot.md5
	printf "\n" >> /etc/grub.d/00_header
	printf "cat<<EOF\n" >> /etc/grub.d/00_header
	printf "set superusers=\"root\"\n" >> /etc/grub.d/00_header
	printf "password_pbkdf2 root " >> /etc/grub.d/00_header
	ans=`cat boot.md5 | grep "grub" | awk -F ' ' '{print $7}'`
	printf "$ans\n" >> /etc/grub.d/00_header
	printf "EOF" >> /etc/grub.d/00_header
	grub2-mkconfig -o /boot/grub2/grub.cfg
	echo "Done, Change SUCCESSFUL"
	newuser=`grep "set superusers" /boot/grub2/grub.cfg | sort | head -1 | awk -F '=' '{print $2}'`

	echo "The following are the superusers: $newuser"
fi

# 5.1 Restrict Core Dumps
checkcoredump=`grep "hard core" /etc/security/limits.conf`
if [ -z "$checkcoredump" ]
then
	#If it is configured INCORRECTLY
	echo "Hard Limit Settings : FAILED"
	echo "* hard core 0" >> /etc/security/limits.conf
	echo "fd.suid_dumpable = 0" >> /etc/sysctl.conf
	echo "Configuring settings...."
	echo "Done, Change SUCCESSFUL"
else
	#If it is configured CORRECTLY
	echo "Hard Limit Settings : PASSED"
fi

# 5.2 Enable Randomized Virtual Memory Region Placement
checkkernel=`sysctl kernel.randomize_va_space`
checkkerneldeep=`sysctl kernel.randomize_va_space | awk -F ' ' '{print $3}'`
if [ "$checkkerneldeep" == 2 ]
then
	#If the configurations are CORRECT
	echo "Virtual Memory Randomization Settings : PASSED"
	echo "Randomization of Virtual Memory : $checkkernel"
else
	#If the configuratiions are INCORRECT
	echo "Virtual Memory Randomization Settings : FAILED"
	echo 2 > /proc/sys/kernel/randomize_va_space
	echo "Configuring settings...."
	echo "Done, Change SUCCESSFUL"
	newcheckkernel=`sysctl kernel.randomize_va_space`
	echo "New Randomization of Virtual Memory : $newcheckkernel"
fi

# 6.1.1 Install the rsyslog package
# 6.1.2 Activate the rsyslog Service
checkrsyslog=`rpm -q rsyslog`
if [ "$checkrsyslog" == rsyslog-7.4.7-16.el7.x86_64 ]
then
	echo "rsyslog installed"
else
	echo "Not installed, installing now"
	yum install -y rsyslog
	systemctl enable rsyslog
	systemctl start rsyslog
fi

# 6.1.3 Configure /etc/rsyslog.conf
checkmessages=`cat /etc/rsyslog.conf | grep "/var/log/messages" | awk -F ' ' '{print $1}'`
if [ "$checkmessages" != "auth,user.*" ]
then
	#Change it here (If it is not a null)
	if [ -n "$checkmessages" ]
	then
		sed -i /$checkmessages/d /etc/rsyslog.conf
	fi
		printf "\nauth,user.*	/var/log/messages" >> /etc/rsyslog.conf
		systemctl restart rsyslog
		echo "Change SUCCESS"
else
	#Correct
	echo "/var/log/messages : Exists"
fi 

checkkern=`cat /etc/rsyslog.conf | grep "/var/log/kern.log" | awk -F ' ' '{print $1}'`
if [ "$checkkern" != "kern.*" ]
then
        #Change it here
	if [ -n "$checkkern" ]
	then
        	sed -i /$checkkern/d /etc/rsyslog.conf
	fi
		printf "\nkern.*   /var/log/kern.log" >> /etc/rsyslog.conf
		systemctl restart rsyslog
		echo "Change SUCCESS"
else
        #Correct
        echo "/var/log/kern.log : Exists"
fi 

checkdaemon=`cat /etc/rsyslog.conf | grep "/var/log/daemon.log" | awk -F ' ' '{print $1}'`
if [ "$checkdaemon" != "daemon.*" ]
then
        #Change it here
	if [ -n "$checkdaemon" ]
	then
        	sed -i /$checkdaemon/d /etc/rsyslog.conf
        fi
		printf "\ndaemon.*   /var/log/daemon.log" >> /etc/rsyslog.conf
		systemctl restart rsyslog
		echo "Change SUCCESS"
else
        #Correct
        echo "/var/log/daemon.log : Exists"
fi 

checksyslog=`cat /etc/rsyslog.conf | grep "/var/log/syslog.log" | awk -F ' ' '{print $1}'`
if [ "$checksyslog" != "syslog.*" ]
then
        #Change it here
	if [ -n "$checksyslog" ]
	then
        	sed -i /$checksyslog/d /etc/rsyslog.conf
	fi
		printf "\nsyslog.*   /var/log/syslog.log" >> /etc/rsyslog.conf
		systemctl restart rsyslog
		echo "Change SUCCESS"
else
        #Correct
        echo "/var/log/syslog.log : Exists"
fi 

checkunused=`cat /etc/rsyslog.conf | grep "/var/log/unused.log" | awk -F ' ' '{print $1}'`
if [ "$checkunused" != "lpr,news,uucp,local0,local1,local2,local3,local4,local5,local6.*" ]
then
        #Change it here
	if [ -n "$checkunused" ]
	then
        	sed -i /$checkunused/d /etc/rsyslog.conf
        fi
		printf "\nlpr,news,uucp,local0,local1,local2,local3,local4,local5,local6.*   /var/log/unused.log" >> /etc/rsyslog.conf
		systemctl restart rsyslog
		echo "Change SUCCESS"
else
        #Correct
        echo "/var/log/unused.log : Exists"
fi 

# 6.1.4 Create and Set Permissions on rsyslog Log Files
names=`cat /etc/rsyslog.conf | grep "/var/log" | awk -F ' ' '{print $2}'`
for dir in "$names"
do
	if [ -d "$dir" ]
	then
		#Create the directory
		touch "$dir"
	fi
		check=`ls -l /var/log/messages | awk -F ' ' '{print $3,$4}'`
	if [ "$check" == "root root" ]
	then
		#Configured correctly
		echo "Directory has been correctly configured"
	else
		#Configured wrongly
		echo "Directory has been configured wrongly"
		chown root:root "$dir"
                chmod og-rwx "$dir"
		echo "Changing configurations..."
		echo "Done, Change is SUCCESSFUL"
	fi
done

