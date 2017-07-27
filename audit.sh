#!/bin/bash
# Audit Script for RHEL 7 based on CIS BenchMarks
# Script misc. section
trap '' 2 20
# Check if script is executed by root
if [ "$EUID" -ne 0 ]
	then echo "Please run this script as root"
	exit
fi

# 3.6 Configure NTP
checkntp=`yum list ntp | grep "Installed Packages"`
checkntp1=`grep "^restrict default kod nomodify notrap nopeer noquery" /etc/ntp.conf`
checkntp2=`grep "^restrict -6 default kod nomodify notrap nopeer noquery" /etc/ntp.conf` 
checkntp3=`grep "^server" /etc/ntp.conf | grep server`
checkntp4=`grep 'OPTIONS="-u ntp:ntp -p /var/run/ntpd.pid"' /etc/sysconfig/ntpd`
if [ -n "$checkntp" ]
then
if [ -n "$checkntp1" ]
then 
	if [ -n "$checkntp2" ]
	then
		if [ -n "$checkntp3" ]
			then
				if [ -n "$checkntp4" ]
				then
					echo "$count. NTP - PASSED (NTP has been properly configured)"
					((count++))
				else
					echo "$count. NTP - FAILED (Option has not been configured in /etc/sysconfig/ntpd)" 
					((count++))
				fi
		else
			echo "$count. NTP - FAILED (Failed to list down NTP servers)"
			((count++))
		fi
	else
		echo "$count. NTP - FAILED (Failed to implement restrict -6 default kod nomodify notrap nopeer noquery)"
		((count++))
	fi
else
	echo "$count. NTP - FAILED (Failed to implement restrict default kod nomodify notrap nopeer noquery)"
	((count++))
fi
else
	echo "$count. NTP - FAILED (NTP is not installed)"
	((count++))
fi

# 3.7 Remove LDAP
checkldapclients=`yum list openldap-clients | grep 'Available Packages'`
checkldapservers=`yum list openldap-servers | grep 'Available Packages'`

if [ -n "checkldapclients" -a -n "checkldapservers" ]
then 
	echo "$count. LDAP - PASSED (LDAP server and client are both not installed)"
	((count++))
elif [ -n "checkldapclients" -a -z "checkldapservers" ]
then
	echo "$count. LDAP - FAILED (LDAP server is installed)"
	((count++))
elif [ -z "checkldapclients" -a -n "checkldapservers" ]
then
	echo "$count. LDAP - FAILED (LDAP client is installed)"
	((count++))
else
	echo "$count. LDAP - FAILED (Both LDAP client and server are installed)"
	((count++))
fi

# 3.8 Disable NFS & RPC
nfsservices=( "nfs-lock" "nfs-secure" "rpcbind" "nfs-idmap" "nfs-secure-server" )

for eachnfsservice in ${nfsservices[*]}
do
	checknfsservices=`systemctl is-enabled $eachnfsservice | grep enabled`
	if [ -z "$checknfsservices" ]
	then 
		echo "$count. $eachnfsservice - PASSED ($eachnfsservice is disabled)"
		((count++))
	else 
		echo "$count. $eachnfsservice - FAILED ($eachnfsservice is enabled)"
		((count++))
	fi
done

# 3.9 Remove DNS, FTP, HTTP, HTTP-Proxy, SNMP
standardservices=( "named" "vsftpd" "httpd" "squid.service" "snmpd" ) 

for eachstandardservice in ${standardservices[*]}
do
	checkserviceexist=`systemctl status $eachstandardservice | grep not-found`
	if [ -n "$checkserviceexist" ]
	then
		echo "$count. $eachstandardservice - PASSED ($eachstandardservice does not exist in the system)"
		((count++))
	else
		checkstandardservices=`systemctl status $eachstandardservice | grep disabled`
		checkstandardservices1=`systemctl status $eachstandardservice | grep inactive`
		if [ -z "$checkstandardservices" -a -z "$checkstandardservices1" ]
		then
			echo "$count. $eachstandardservice - FAILED ($eachstandardservice is active and enabled)"
			((count++))
		elif [ -z "$checkstandardservices" -a -n "$checkstandardservices1" ]
		then
			echo "$count. $eachstandardservice - FAILED ($eachstandardservice is inactive but enabled)"
			((count++))
		elif [ -n "$checkstandardservices" -a -z "$checkstandardservices1" ]
		then
			echo "$count. $eachstandardservice - FAILED ($eachstandardservice is disabled but active)"
			((count++))
		else
			echo "$count. $eachstandardservice - PASSED ($eachstandardservice is disabled and inactive)"
			((count++))
		fi
	fi
done

# 3.10 Configure Mail Transfer Agent for LocalOnly Mode
checkmailtransferagent=`netstat -an | grep ":25[[:space:]]"`

if [ -n "$checkmailtransferagent" ]
then
	checklistening=`netstat -an | grep LISTEN`
	if [ -n "$checklistening" ]
	then
		checklocaladdress=`netstat -an | grep [[:space:]]127.0.0.1:25[[:space:]] | grep LISTEN`
		if [ -n "$checklocaladdress" ]
		then
			echo "$count. MTA - PASSED (Mail Transfer Agent is listening on the loopback address)"
			((count++))
		else
			echo "$count. MTA - FAILED (Mail Transfer Agent is not listening on the loopback address)"
			((count++))
		fi
	else
		echo "$count. MTA - FAILED (Mail Transfer Agent is not in listening mode)"
		((count++))
	fi
else
	echo "$count. MTA - FAILED (Mail Transfer Agent is not configured/installed)"
	((count++))
fi

# 4.1 & 4.2 Set User/Group Owner on /boot/grub2/grub.cfg & Set Permissions on /boot/grub2/grub.cfg
checkgrubowner=`stat -L -c "owner=%U group=%G" /boot/grub2/grub.cfg`

if  [ "$checkgrubowner" == "owner=root group=root" ]
then
	checkgrubpermission=`stat -L -c "%a" /boot/grub2/grub.cfg | cut -b 2,3`

	if [ "$checkgrubpermission" == "00" ]
	then
		echo "$count. /boot/grub2/grub.cfg - PASSED (Owner, group owner and permission of file is configured correctly)"
		((count++))
	else
		echo "$count. /boot/grub2/grub.cfg - FAILED (Permission of file is configured incorrectly"
		((count++))
	fi
else
	echo "$count. /boot/grub2/grub.cfg - FAILED (Owner and group owner of file is configured incorrectly)"
	((count++))
fi 

# 4.3 Set Boot Loader Password
checkbootloaderuser=`grep "^set superusers" /boot/grub2/grub.cfg`

if [ -z "$checkbootloaderuser" ]
then
	echo "$count. Boot Loader Password - FAILED (Boot loader is not configured with any superuser)"
	((count++))
else
	checkbootloaderpassword=`grep "^password" /boot/grub2/grub.cfg`

	if [ -z "$checkbootloaderpassword" ]
	then
		echo "$count. Boot Loader Password - FAILED (Boot loader is not configured with a password)"
		((count++))

	else
		echo "$count. Boot Loader Password - PASSED (Boot loader is configured with a superuser and password)"
		((count++))
	fi
fi

# 5.1 Restrict Core Dumps
checkcoredump=`grep "hard core" /etc/security/limits.conf`
coredumpval="* hard core 0"

if [ "$checkcoredump" == "$coredumpval" ]
then
	checksetuid=`sysctl fs.suid_dumpable`
	setuidval="fs.suid_dumpable = 0"

	if [ "$checksetuid" == "$setuidval" ]
	then
		echo "$count. Core Dump - PASSED (Core dumps are restricted and setuid programs are prevented from dumping core)"
		((count++))
	else
		echo "$count. Core Dump - FAILED (Setuid programs are not prevented from dumping core)"
		((count++))
	fi

else
	echo "$count. Core Dump - FAILED (Core dumps are not restricted)"
	((count++))
fi

# 5.2 Enable Randomized Virtual Memory Region Placement
checkvirtualran=`sysctl kernel.randomize_va_space`
virtualranval="kernel.randomize_va_space = 2"

if [ "$checkvirtualran" == "$virtualranval" ]
then
	echo "$count. Randomized Virtual Memory Region Placement - PASSED (Virtual memory is randomized)"
	((count++))
else
	echo "$count. Randomized Virtual Memory Region Placement - FAILED (Virtual memory is not randomized)"
	((count++))
fi

# 6.1.1 Install the rsyslog package
# 6.1.2 Activate the rsyslog service
checkrsyslog=`rpm -q rsyslog | grep "^rsyslog"`

if [ -n "$checkrsyslog" ]
then
	checkrsysenable=`systemctl is-enabled rsyslog`

	if [ "$checkrsysenable" == "enabled" ]
	then
		echo "$count. rsyslog - PASSED (Rsyslog is installed and enabled)"
		((count++))
	else
		echo "$count. rsyslog - FAILED (Rsyslog is disabled)"
		((count++))
	fi
else
	echo "$count. rsyslog - FAILED (Rsyslog is not installed)"
	((count++))
fi

# 6.1.3 Configure /etc/rsyslog.conf
# 6.1.4 Create and Set Permissions on rsyslog Log Files
checkvarlogmessageexist=`ls -l /var/log/ | grep messages`

if [ -n "$checkvarlogmessageexist" ]
then
	checkvarlogmessageown=`ls -l /var/log/messages | cut -d ' ' -f3,4`

	if [ "$checkvarlogmessageown" == "root root" ]
	then
		checkvarlogmessagepermit=`ls -l /var/log/messages | cut -d ' ' -f1`

		if [ "$checkvarlogmessagepermit" == "-rw-------." ]
		then
			checkvarlogmessage=`grep /var/log/messages /etc/rsyslog.conf`

			if [ -n "$checkvarlogmessage" ]
			then
				checkusermessage=`grep /var/log/messages /etc/rsyslog.conf | grep "^auth,user.*"`

				if [ -n "$checkusermessage" ]
				then
					echo "$count. /var/log/messages - PASSED (Owner, group owner, permissions, facility are configured correctly; messages logging is set)"
					((count++))
				else
					echo "$count. /var/log/messages - FAILED (Facility is not configured correctly)"
					((count++))
				fi
			else
				echo "$count. /var/log/messages - FAILED (messages logging is not set)"
				((count++))
			fi

		else
			echo "$count. /var/log/messages - FAILED (Permissions of file is configured incorrectly)"
			((count++))
		fi
	else
		echo "$count. /var/log/messages - FAILED (Owner and group owner of file is configured incorrectly)"
		((count++))
	fi
else
	echo "$count. /var/log/messages - FAILED (/var/log/messages file does not exist)"
	((count++))
fi

checkvarlogkernexist=`ls -l /var/log/ | grep kern.log`

if [ -n "$checkvarlogkernexist" ]
then
	checkvarlogkernown=`ls -l /var/log/kern.log | cut -d ' ' -f3,4`

	if [ "$checkvarlogkernown" == "root root" ]
	then
		checkvarlogkernpermit=`ls -l /var/log/kern.log | cut -d ' ' -f1`

		if [ "$checkvarlogkernpermit" == "-rw-------." ]
		then
			checkvarlogkern=`grep /var/log/kern.log /etc/rsyslog.conf`

			if [ -n "$checkvarlogkern" ]
			then
				checkuserkern=`grep /var/log/kern.log /etc/rsyslog.conf | grep "^kern.*"`

				if [ -n "$checkuserkern" ]
				then
					echo "$count. /var/log/kern.log - PASSED (Owner, group owner, permissions, facility are configured correctly; kern.log logging is set)"
					((count++))
				else
					echo "$count. /var/log/kern.log - FAILED (Facility is not configured correctly)"
					((count++))
				fi
			else
				echo "$count. /var/log/kern.log - FAILED (kern.log logging is not set)"
				((count++))
			fi
		else
			echo "$count. /var/log/kern.log - FAILED (Permissions of file is configured incorrectly)"
			((count++))
		fi
	else
		echo "$count. /var/log/kern.log - FAILED (Owner and group owner of file is configured incorrectly)"
		((count++))
	fi
else
	echo "$count. /var/log/kern.log - FAILED (/var/log/kern.log file does not exist)"
	((count++))
fi

checkvarlogdaemonexist=`ls -l /var/log/ | grep daemon.log`

if [ -n "$checkvarlogdaemonexist" ]
then
	checkvarlogdaemonown=`ls -l /var/log/daemon.log | cut -d ' ' -f3,4`

	if [ "$checkvarlogdaemonown" == "root root" ]
	then
		checkvarlogdaemonpermit=`ls -l /var/log/daemon.log | cut -d ' ' -f1`

		if [ "$checkvarlogdaemonpermit" == "-rw-------." ]
		then
			checkvarlogdaemon=`grep /var/log/daemon.log /etc/rsyslog.conf`

			if [ -n "$checkvarlogdaemon" ]
			then
				checkuserdaemon=`grep /var/log/daemon.log /etc/rsyslog.conf | grep "^daemon.*"`

				if [ -n "$checkuserdaemon" ]
				then
					echo "$count. /var/log/daemon.log - PASSED (Owner, group owner, permissions, facility are configured correctly; daemon.log logging is set)"
					((count++))
				else
					echo "$count. /var/log/daemon.log - FAILED (Facility is not configured correctly)"
					((count++))
				fi

			else
				echo "$count. /var/log/daemon.log - FAILED (daemon.log logging is not set)"
				((count++))
			fi
		else
			echo "$count. /var/log/daemon.log - FAILED (Permissions of file is configured incorrectly)"
			((count++))
		fi
	else
		echo "$count. /var/log/daemon.log - FAILED (Owner and group owner of file is configured incorrectly)"
		((count++))
	fi
else
	echo "$count. /var/log/daemon.log - FAILED (/var/log/daemon.log file does not exist)"
	((count++))
fi

checkvarlogsyslogexist=`ls -l /var/log/ | grep syslog.log`

if [ -n "$checkvarlogsyslogexist" ]
then
	checkvarlogsyslogown=`ls -l /var/log/syslog.log | cut -d ' ' -f3,4`

	if [ "$checkvarlogsyslogown" == "root root" ]
	then
		checkvarlogsyslogpermit=`ls -l /var/log/syslog.log | cut -d ' ' -f1`

		if [ "$checkvarlogsyslogpermit" == "-rw-------." ]
		then
			checkvarlogsyslog=`grep /var/log/syslog.log /etc/rsyslog.conf`

			if [ -n "$checkvarlogsyslog" ]
			then
				checkusersyslog=`grep /var/log/syslog.log /etc/rsyslog.conf | grep "^syslog.*"`

				if [ -n "$checkusersyslog" ]
				then
					echo "$count. /var/log/syslog.log - PASSED (Owner, group owner, permissions, facility are configured correctly; syslog.log logging is set)"
					((count++))
				else
					echo "$count. /var/log/syslog.log - FAILED (Facility is not configured correctly)"
					((count++))
				fi
			else
				echo "$count. /var/log/syslog.log - FAILED (syslog.log logging is not set)"
				((count++))
			fi
		else
			echo "$count. /var/log/syslog.log - FAILED (Permissions of file is configured incorrectly)"
			((count++))
		fi
	else
		echo "$count. /var/log/syslog.log - FAILED (Owner and group owner of file is configured incorrectly)"
		((count++))
	fi
else
	echo "$count. /var/log/syslog.log - FAILED (/var/log/syslog.log file does not exist)"
	((count++))
fi

checkvarlogunusedexist=`ls -l /var/log/ | grep unused.log`

if [ -n "$checkvarlogunusedexist" ]
then
	checkvarlogunusedown=`ls -l /var/log/unused.log | cut -d ' ' -f3,4`

	if [ "$checkvarlogunusedown" == "root root" ]
	then
		checkvarlogunusedpermit=`ls -l /var/log/unused.log | cut -d ' ' -f1`

		if [ "$checkvarlogunusedpermit" == "-rw-------." ]
		then
			checkvarlogunused=`grep /var/log/unused.log /etc/rsyslog.conf`

			if [ -n "$checkvarlogunused" ]
			then
				checkuserunused=`grep /var/log/unused.log /etc/rsyslog.conf | grep "^lpr,news,uucp,local0,local1,local2,local3,local4,local5,local6.*"`

				if [ -n "$checkuserunused" ]
				then
					echo "$count. /var/log/unused.log - PASSED (Owner, group owner, permissions, facility are configured correctly; unused.log logging is set)"
					((count++))
				else
					echo "$count. /var/log/unused.log - FAILED (Facility is not configured correctly)"
					((count++))
				fi
			else
				echo "$count. /var/log/unused.log - FAILED (unused.log logging is not set)"
				((count++))
			fi
		else
			echo "$count. /var/log/unused.log - FAILED (Permissions of file is configured incorrectly)"
			((count++))
		fi
	else
		echo "$count. /var/log/unused.log - FAILED (Owner and group owner of file is configured incorrectly)"
		((count++))
	fi
else
	echo "$count. /var/log/unused.log - FAILED (/var/log/unused.log file does not exist)"
	((count++))
fi

# 6.1.6 Accept Remote rsyslog Messages Only on Designated Log Hosts
checkrsysloglis=`grep '^$ModLoad imtcp.so' /etc/rsyslog.conf`
checkrsysloglis1=`grep '^$InputTCPServerRun' /etc/rsyslog.conf`

if [ -z "$checkrsysloglis" -o -z "$checkrsysloglis1" ]
then
	echo "$count. Remote rsyslog - FAILED (Rsyslog is not listening for remote messages)"
	((count++))
else
	echo "$count. Remote rsyslog - PASSED (Rsyslog is listening for remote messages)"
	((count++))
fi

# 6.2.1.1 Configure Audit Log Storage Size
checklogstoragesize=`grep max_log_file[[:space:]] /etc/audit/auditd.conf | awk '{print $3}'`

if [ "$checklogstoragesize" == 5 ]
then
	echo "$count. Audit Log Storage Size - PASSED (Maximum size of audit log files is configured correctly)"
	((count++))
else
	echo "$count. Audit Log Storage Size - FAILED (Maximum size of audit log files is not configured correctly)"
	((count++))
fi

# 6.2.1.2 Keep All Auditing Information
checklogfileaction=`grep max_log_file_action /etc/audit/auditd.conf | awk '{print $3}'`
 
if [ "$checklogfileaction" == keep_logs ]
then
	echo "$count. Audit Log File Action - PASSED (Action of the audit log file is configured correctly)"
	((count++))
else
	echo "$count. Audit Log File Action - FAILED (Action of the audit log file is not configured correcly)"
	((count++))
fi

# 6.2.1.3 Disable System on Audit Log Full
checkspaceleftaction=`grep space_left_action /etc/audit/auditd.conf | awk '{print $3}'`

if [ "$checkspaceleftaction" == email ]
then
	checkactionmailacc=`grep action_mail_acct /etc/audit/auditd.conf | awk '{print $3}'`

	if [ "$checkactionmailacc" == root ]
	then
		checkadminspaceleftaction=`grep admin_space_left_action /etc/audit/auditd.conf | awk '{print $3}'`
		
		if [ "$checkadminspaceleftaction" == halt ]
		then
			echo "$count. Disable System - PASSED (Auditd is correctly configured to notify the administrator and halt the system when audit logs are full)"
			((count++))
		else
			echo "$count. Disable System - FAILED (Auditd is not configured to halt the system when audit logs are full)"
			((count++))
		fi
	else
		echo "$count. Disable System - FAILED (Auditd is not configured to notify the administrator when audit logs are full)"
		((count++))
	fi
else
	echo "$count. Disable System - FAILED (Auditd is not configured to notify the administrator by email when audit logs are full)"
	((count++))
fi

# 6.2.1.4 Enable auditd Service
checkauditdservice=`systemctl is-enabled auditd`

if [ "$checkauditdservice" == enabled ]
then
	echo "$count. Auditd Service - PASSED (Auditd is enabled)"
	((count++))
else
	echo "$count. Auditd Service - FAILED (Auditd is not enabled)"
	((count++))
fi

# 6.2.1.5 Enable Auditing for Processes That Start Prior to auditd
checkgrub=`grep "linux" /boot/grub2/grub.cfg | grep "audit=1"`

if [ -z "$checkgrub" ]
then
	echo "$count. Prior Start Up - FAILED (Prior start up is not enabled)"
	((count++))
else
	echo "$count. Prior Start Up - PASSED (Prior start up is enabled)"
	((count++))
fi

# 6.2.1.6 - 6.2.1.8
checksystem=`uname -m | grep "64"`
checkmodifydatetimeadjtimex=`egrep 'adjtimex' /etc/audit/audit.rules`

if [ -z "$checksystem" ]
then
	echo "It is a 32-bit system."

	if [ -z "$checkmodifydatetimeadjtimex" ]
	then
        	echo "$count. Date & Time Modified Events - FAILED (Adjtimex is not configured)"
		((count++))
	else
		echo "$count. Date & Time Modified Events - PASSED (Adjtimex is configured)"
		((count++))	
	fi
else
	echo "It is a 64-bit system."

	if [ -z "$checkmodifydatetimeadjtimex" ]
	then
        	echo "$count. Date & Time Modified Events - FAILED (Adjtimex is not configured)"
		((count++))
	else
		echo "$count. Date & Time Modified Events - PASSED (Adjtimex is configured)"
		((count++))
	fi
fi

checkmodifydatetimesettime=`egrep 'settimeofday' /etc/audit/audit.rules`

if [ -z "$checksystem" ]
then
	if [ -z "$checkmodifydatetimesettime" ]
	then
        	echo "$count. Date & Time Modified Events - FAILED (Settimeofday is not configured)"
		((count++))
	else
        	echo "$count. Date & Time Modified Events - PASSED (Settimeofday is configured)"
		((count++))
	fi
else
	if [ -z "$checkmodifydatetimesettime" ]
	then
        	echo "$count. Date & Time Modified Events - FAILED (Settimeofday is not configured)"
		((count++))
	else
        	echo "$count. Date & Time Modified Events - PASSED (Settimeofday is configured)"
		((count++))
	fi
fi

checkmodifydatetimeclock=`egrep 'clock_settime' /etc/audit/audit.rules`

if [ -z "$checkmodifydatetimeclock" ]
then
       	echo "$count. Date & Time Modified Events - FAILED (Clock Settime is not configured)"
	((count++))
else
       	echo "$count. Date & Time Modified Events - PASSED (Clock Settime is configured)"
	((count++))
fi

checkmodifyusergroupinfo=`egrep '\/etc\/group' /etc/audit/audit.rules`

if [ -z "$checkmodifyusergroupinfo" ]
then
        echo "$count. Group Configuration - FAILED (Group is not configured)"
	((count++))
else
        echo "$count. Group Configuration - PASSED (Group is already configured)"
	((count++))
fi

checkmodifyuserpasswdinfo=`egrep '\/etc\/passwd' /etc/audit/audit.rules`

if [ -z "$checkmodifyuserpasswdinfo" ]
then
        echo "$count. Password Configuration - FAILED (Password is not configured)"
	((count++))
else
        echo "$count. Password Configuration - PASSED (Password is configured)"
	((count++))
fi

checkmodifyusergshadowinfo=`egrep '\/etc\/gshadow' /etc/audit/audit.rules`

if [ -z "$checkmodifyusergshadowinfo" ]
then
        echo "$count. GShadow Configuration - FAILED (GShadow is not configured)"
	((count++))
else
        echo "$count. GShadow Configuration - PASSED (GShadow is configured)"
	((count++))
fi

checkmodifyusershadowinfo=`egrep '\/etc\/shadow' /etc/audit/audit.rules`

if [ -z "$checkmodifyusershadowinfo" ]
then
        echo "$count. Shadow Configuration - FAILED (Shadow is not configured)"
	((count++))
else
        echo "$count. SHadow Configuration - PASSED (Shadow is configured)"
	((count++))
fi

checkmodifyuseropasswdinfo=`egrep '\/etc\/security\/opasswd' /etc/audit/audit.rules`

if [ -z "$checkmodifyuseropasswdinfo" ]
then
        echo "$count. OPasswd Configuration- FAILED (OPassword not configured)"
	((count++))
else
        echo "$count. OPasswd Configuration - PASSED (OPassword is configured)"
	((count++))
fi

checksystem=`uname -m | grep "64"`
checkmodifynetworkenvironmentname=`egrep 'sethostname|setdomainname' /etc/audit/audit.rules`

if [ -z "$checksystem" ]
then
	echo "It is a 32-bit system."

	if [ -z "$checkmodifynetworkenvironmentname" ]
	then
        	echo "$count. Modify the System's Network Environment Events - FAILED (Sethostname and setdomainname is not configured)"
		((count++))
	else
		echo "$count. Modify the System's Network Environment Events - PASSED (Sethostname and setdomainname is configured)"
		((count++))
	fi
else
	echo "It is a 64-bit system."

	if [ -z "$checkmodifynetworkenvironmentname" ]
	then
        	echo "$count. Modify the System's Network Environment Events - FAILED (Sethostname and setdomainname is not configured)"
		((count++))
	else
		echo "$count. Modify the System's Network Environment Events - PASSED (Sethostname and setdomainname is configured)"
		((count++))
	fi
fi

checkmodifynetworkenvironmentissue=`egrep '\/etc\/issue' /etc/audit/audit.rules`

if [ -z "$checkmodifynetworkenvironmentissue" ]
then
       	echo "$count. Modify the System's Network Environment Events - FAILED (/etc/issue is not configured)"
	((count++))
else
       	echo "$count. Modify the System's Network Environment Events - PASSED (/etc/issue is configured)"
	((count++))
fi

checkmodifynetworkenvironmenthosts=`egrep '\/etc\/hosts' /etc/audit/audit.rules`

if [ -z "$checkmodifynetworkenvironmenthosts" ]
then
       	echo "$count. Modify the System's Network Environment Events - FAILED (/etc/hosts is not configured)"
	((count++))
else
       	echo "$count. Modify the System's Network Environment Events - PASSED (/etc/hosts is configured)"
	((count++))
fi

checkmodifynetworkenvironmentnetwork=`egrep '\/etc\/sysconfig\/network' /etc/audit/audit.rules`

if [ -z "$checkmodifynetworkenvironmentnetwork" ]
then
       	echo "$count. Modify the System's Network Environment Events - FAILED (/etc/sysconfig/network is not configured)"
	((count++))
else
       	echo "$count. Modify the System's Network Environment Events - PASSED (/etc/sysconfig/network is configured)"
	((count++))
fi

# 6.2.1.9 Record Events That Modify the System's Mandatory Access Controls
checkmodifymandatoryaccesscontrol=`grep \/etc\/selinux /etc/audit/audit.rules`

if [ -z "$checkmodifymandatoryaccesscontrol" ]
then
	echo "$count. Modify the System's Mandatory Access Controls Events - FAILED (Recording of modified system's mandatory access controls events is not configured)"
	((count++))
else
	echo "$count. Modify the System's Mandatory Access Controls Events - PASSED (Recording of modified system's mandatory access controls events is configured)"
	((count++))
fi
