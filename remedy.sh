#!/bin/bash
# Remedy Script for RHEL 7 based on CIS BenchMarks
# Script misc. section
 
trap '' 2 20
trap '' SIGTSTP

# Check if script is executed by root
if [ "$EUID" -ne 0 ]
	then echo "Please run this script as root"
	exit
fi

datetime=`date +"%m%d%y-%H%M"`

# 1.1 Create seperate partition for /tmp
checkforsdb1lvm=`fdisk -l | grep /dev/sdb1 | grep "Linux LVM"`
if [ -z "$checkforsdb1lvm" ]
then
	echo "Please create a /dev/sdb1 partition with at least 8GB and LVM system ID first"
else
	printf "/tmp\n"
	tmpcheck=`grep "[[:space:]]/tmp[[:space:]]" /etc/fstab`
	if [ -z "$tmpcheck" ]
	then
		vgcheck=`vgdisplay | grep "VG Name" | grep "MyVG"`
		if [ -z "$vgcheck" ]
		then
			vgcreate MyVG /dev/sdb1 &> /dev/null
		fi
		
		lvcheck=`lvdisplay | grep "LV Name" | grep "TMPLV"`
		if [ -z "$lvcheck" ]
		then 
			lvcreate -L 500M -n TMPLV MyVG &> /dev/null
			mkfs.ext4 /dev/MyVG/TMPLV &> /dev/null
		fi
		echo "/dev/MyVG/TMPLV	/tmp	ext4	defaults 0 0" >> /etc/fstab
		mount -a
		echo "1. /tmp partition - FIXED"
	fi

	nodevcheck1=`grep "[[:space:]]/tmp[[:space:]]" /etc/fstab | grep nodev` # 1.2 Set nodev option for partition
	nosuidcheck1=`grep "[[:space:]]/tmp[[:space:]]" /etc/fstab | grep nosuid` # 1.3 Set nosuid option for partition
	noexeccheck1=`grep "[[:space:]]/tmp[[:space:]]" /etc/fstab | grep noexec` # 1.4 Set noexec option for partition


	if [ -z "$nodevcheck1" ]
	then
		sed -ie 's:\(.*\)\(\s/tmp\s\s*\)\(\w*\s*\)\(\w*\s*\)\(.*\):\1\2\3nodev,\4\5:' /etc/fstab
		echo "2. nodev for /tmp - FIXED (Persistent)"
	fi


	if [ -z "$nosuidcheck1" ]
	then
		sed -ie 's:\(.*\)\(\s/tmp\s\s*\)\(\w*\s*\)\(\w*\s*\)\(.*\):\1\2\3nosuid,\4\5:' /etc/fstab
		echo "3. nosuid for /tmp - FIXED (Persistent)"
	fi


	if [ -z "$noexeccheck1" ]
	then
		sed -ie 's:\(.*\)\(\s/tmp\s\s*\)\(\w*\s*\)\(\w*\s*\)\(.*\):\1\2\3noexec,\4\5:' /etc/fstab
		echo "4. noexec for /tmp - FIXED (Persistent)"
	fi	


	nodevcheck2=`mount | grep "[[:space:]]/tmp[[:space:]]" | grep nodev`
	if [ -z "$nodevcheck2" ]
	then
		mount -o remount,nodev /tmp
		echo "5. nodev for /tmp - FIXED (Non-persistent)"
	fi

	nosuidcheck2=`mount | grep "[[:space:]]/tmp[[:space:]]" | grep nosuid`
	if [ -z "$nosuidcheck2" ]
	then
		mount -o remount,nosuid /tmp
		echo "6. nosuid for /tmp - FIXED (Non-persistent)"
	fi

	noexeccheck2=`mount | grep "[[:space:]]/tmp[[:space:]]" | grep noexec`
	if [ -z "$noexeccheck2" ]
	then
		mount -o remount,noexec /tmp
		echo "7. noexec for /tmp - FIXED (Non-persistent)"
	fi

	printf "\n"
	printf "/var\n"
	
	# 1.5 Create seperate partition for /var
	varcheck=`grep "[[:space:]]/var[[:space:]]" /etc/fstab`
	if [ -z "$varcheck" ]
	then
		vgcheck=`vgdisplay | grep "VG Name" | grep "MyVG"`
		if [ -z "$vgcheck" ]
		then
			vgcreate MyVG /dev/sdb1 &> /dev/null
		fi
		
		lvcheck=`lvdisplay | grep "LV Name" | grep "VARLV"`
		if [ -z "$lvcheck" ]
		then 
			lvcreate -L 5G -n VARLV MyVG &> /dev/null
			mkfs.ext4 /dev/MyVG/VARLV &> /dev/null
		fi
		echo "# /dev/MyVG/VARLV	/var	ext4	defaults 0 0" >> /etc/fstab
		mount -a
		echo "1. /var partition - FIXED"
	fi

	vartmpdircheck=`ls -l /var | grep "tmp"`
	if [ -z "$vartmpdircheck" ]
	then
		mkdir -p /var/tmp
	fi

	# 1.6 Bind mount /var/tmp directory to /tmp
	vartmpcheck1=`grep -e "/tmp[[:space:]]" /etc/fstab | grep "/var/tmp"`

	if [ -z "$vartmpcheck1" ]
	then
		echo "# /tmp	/var/tmp	none	bind	0 0" >> /etc/fstab 
		echo "2. /var/tmp bind mount - FIXED (Persistent)"
	fi

	vartmpcheck2=`mount | grep "/var/tmp"`

	if [ -z "$vartmpcheck2" ]
	then
		mount --bind /tmp /var/tmp
		echo "3. /var/tmp bind mount - FIXED (Non-persistent)"
	fi

	varlogdircheck=`ls -l /var | grep "log"`
	if [ -z "$varlogdircheck" ]
	then
		mkdir -p /var/log
	fi

	# 1.7 Create separate partition for /var/log
	varlogcheck=`grep "[[:space:]]/var/log[[:space:]]" /etc/fstab`
	if [ -z "$varlogcheck" ]
	then
		vgcheck=`vgdisplay | grep "VG Name" | grep "MyVG"`
		if [ -z "$vgcheck" ]
		then
			vgcreate MyVG /dev/sdb1 &> /dev/null
		fi
		
		lvcheck=`lvdisplay | grep "LV Name" | grep "VARLOGLV"`
		if [ -z "$lvcheck" ]
		then 
			lvcreate -L 200M -n VARLOGLV MyVG &> /dev/null
			mkfs.ext4 /dev/MyVG/VARLOGLV &> /dev/null
		fi
		echo "/dev/MyVG/VARLOGLV	/var/log	ext4	defaults 0 0" >> /etc/fstab
		mount -a
		echo "4. /var/log partition - FIXED"
	fi

	auditdircheck=`ls -l /var/log | grep "audit"`
	if [ -z "$auditdircheck" ]
	then
		mkdir -p /var/log/audit	
	fi

	# 1.8 Create seperate partition for /var/log/audit
	varlogauditcheck=`grep "[[:space:]]/var/log/audit[[:space:]]" /etc/fstab`
	if [ -z "$varlogauditcheck" ]
	then
		vgcheck=`vgdisplay | grep "VG Name" | grep "MyVG"`
		if [ -z "$vgcheck" ]
		then
			vgcreate MyVG /dev/sdb1 &> /dev/null
		fi
		
		lvcheck=`lvdisplay | grep "LV Name" | grep "VARLOGAUDITLV"`
		if [ -z "$lvcheck" ]
		then 
			lvcreate -L 200M -n VARLOGAUDITLV MyVG &> /dev/null
			mkfs.ext4 /dev/MyVG/VARLOGAUDITLV &> /dev/null
		fi
		echo "/dev/MyVG/VARLOGAUDITLV	/var/log/audit	ext4	defaults 0 0" >> /etc/fstab
		mount -a
		echo "5. /var/log/audit partition - FIXED"
	fi

	printf "\n"
	printf "/home\n"
	
	# 1.9 Create seperate partition for /home
	homecheck=`grep "[[:space:]]/home[[:space:]]" /etc/fstab`
	if [ -z "$homecheck" ]
	then
		vgcheck=`vgdisplay | grep "VG Name" | grep "MyVG"`
		if [ -z "$vgcheck" ]
		then
			vgcreate MyVG /dev/sdb1 &> /dev/null
		fi
		
		lvcheck=`lvdisplay | grep "LV Name" | grep "HOMELV"`
		if [ -z "$lvcheck" ]
		then 
			lvcreate -L 500M -n HOMELV MyVG &> /dev/null
			mkfs.ext4 /dev/MyVG/HOMELV &> /dev/null
		fi
		echo "/dev/MyVG/HOMELV	/home	ext4	defaults 0 0" >> /etc/fstab
		mount -a
		echo "1. /home partition - FIXED"
	fi


	homenodevcheck1=`grep "[[:space:]]/home[[:space:]]" /etc/fstab | grep nodev`

	if [ -z "$homenodevcheck1" ]
	then
		sed -ie 's:\(.*\)\(\s/home\s\s*\)\(\w*\s*\)\(\w*\s*\)\(.*\):\1\2\3nodev,\4\5:' /etc/fstab
		echo "2. nodev for /home - FIXED (Persistent)"
	fi

	homenodevcheck2=`mount | grep "[[:space:]]/home[[:space:]]" | grep nodev`
	if [ -z "$homenodevcheck2" ]
	then
		mount -o remount,nodev /home
		echo "3. nodev for /home - FIXED (Non-persistent)"
	fi
fi

# 1.11 Add nodev option to removable media partitions
cdcheck=`grep cd /etc/fstab`
if [ -n "$cdcheck" ]
then
	cdnodevcheck=`grep cdrom /etc/fstab | grep nodev`
	if [ -z "$cdnodevcheck" ]
	then
		sed -ie 's:\(.*\)\(\s/cdrom\s\s*\)\(\w*\s*\)\(\w*\s*\)\(.*\):\1\2\3nodev,\4\5:' /etc/fstab
		echo "nodev for /cdrom fixed"
	fi

	cdnosuidcheck=`grep cdrom /etc/fstab | grep suid`
	if [ -z "$cdnosuidcheck" ]
	then
		sed -ie 's:\(.*\)\(\s/cdrom\s\s*\)\(\w*\s*\)\(\w*\s*\)\(.*\):\1\2\3nosuid,\4\5:' /etc/fstab
		echo "nosuid for /cdrom fixed"
	fi


	cdnoexeccheck=`grep cdrom /etc/fstab | grep exec`
	if [ -z "$cdnoexeccheck" ]
	then
		sed -ie 's:\(.*\)\(\s/cdrom\s\s*\)\(\w*\s*\)\(\w*\s*\)\(.*\):\1\2\3noexec,\4\5:' /etc/fstab
		echo "noexec for /cdrom fixed"
	fi

fi

# 1.14 Set sticky bit on all world-writable directories
checksticky=`df --local -P | awk {'if (NR!=1) print $6'} | xargs -l '{}' find '{}' -xdev -type d \( -perm -0002 -a ! -perm -1000 \) 2> /dev/null`

if [ -n "$checksticky" ]
then
	df --local -P | awk {'if (NR!=1) print $6'} | xargs -l '{}' find '{}' -xdev -type d \( -perm -0002 -a ! -perm -1000 \) 2> /dev/null | xargs chmod o+t
fi

# 1.15 Disable mounting of legacy filesystems
checkcramfs=`/sbin/lsmod | grep cramfs`
checkfreevxfs=`/sbin/lsmod | grep freevxfs`
checkjffs2=`/sbin/lsmod | grep jffs2`
checkhfs=`/sbin/lsmod | grep hfs`
checkhfsplus=`/sbin/lsmod | grep hfsplus`
checksquashfs=`/sbin/lsmod | grep squashfs`
checkudf=`/sbin/lsmod | grep udf`

if [ -n "$checkcramfs" -o -n "$checkfreevxfs" -o -n "$checkjffs2" -o -n "$checkhfs" -o -n "$checkhfsplus" -o -n "$checksquashfs" -o -n "$checkudf" ]
then
	echo "install cramfs /bin/true" >> /etc/modprobe.d/CIS.conf
	echo "install freevxfs /bin/true" >> /etc/modprobe.d/CIS.conf
	echo "install jffs2 /bin/true" >> /etc/modprobe.d/CIS.conf
	echo "install hfs /bin/true" >> /etc/modprobe.d/CIS.conf
	echo "install hfsplus /bin/true" >> /etc/modprobe.d/CIS.conf
	echo "install squashfs /bin/true" >> /etc/modprobe.d/CIS.conf
	echo "install udf /bin/true" >> /etc/modprobe.d/CIS.conf
fi

# 2.1 Checking of telnet-server
checktelnetserver=`yum list telnet-server | grep "Available Packages"`
if [ -n "$checktelnetserver" ]
then
	echo "Telnet-server is not installed, hence no action will be taken"
else
	echo "Telnet-server is installed, it will now be removed"
	yum erase -y telnet-server
fi 

# 2.1 Checking of telnet
checktelnet=`yum list telnet | grep "Available Packages"`
if [ -n "$checktelnet" ]
then
	echo "Telnet is not installed, hence no action will be taken"
else
	echo "Telnet is installed, it will now be removed"
	yum erase -y telnet
fi 

# 2.1 Checking of rsh-server
checkrshserver=`yum list rsh-server | grep "Available Packages"`
if [ -n "$checkrshserver" ]
then
	echo "Rsh-server is not installed, hence no action will be taken"
else
	echo "Rsh-server is installed, it will now be removed"
	yum erase -y rsh-server
fi 

# 2.1-2.2 Checking of rsh
checkrsh=`yum list rsh | grep "Available Packages"`
if [ -n "$checkrsh" ]
then
	echo "Rsh is not installed, hence no action will be taken"
else
	echo "Rsh is installed, it will now be removed"
	yum erase -y rsh
fi 

# 2.3 Checking of ypserv
checkypserv=`yum list ypserv | grep "Available Packages"`
if [ -n "$checkypserv" ]
then
	echo "Ypserv is not installed, hence no action will be taken"
else
	echo "Ypserv is installed, it will now be removed"
	yum erase -y ypserv
fi 

# 2.3 Checking of ypbind
checkypbind=`yum list ypbind | grep "Available Packages"`
if [ -n "$checkypbind" ]
then
	echo "Ypbind is not installed, hence no action will be taken"
else
	echo "Ypbind is installed, it will now be removed"
	yum erase -y ypbind
fi 

# 2.4 Checking of tftp
checktftp=`yum list tftp | grep "Available Packages"`
if [ -n "$checktftp" ]
then
	echo "Tftp is not installed, hence no action will be taken"
else
	echo "Tftp is installed, it will now be removed"
	yum erase -y tftp
fi

# 2.4 Checking of tftp-server
checktftp=`yum list tftp-server| grep "Available Packages"`
if [ -n "$checktftp-server" ]
then
	echo "Tftp-server is not installed, hence no action will be taken"
else
	echo "Tftp-server is installed, it will now be removed"
	yum erase -y tftp-server
fi 

# 2.5 Checking of xinetd
checkxinetd=`yum list xinetd | grep "Available Packages"`
if [ -n "$checkxinetd" ]
then
	echo "Xinetd is not installed, hence no action will be taken"
else
	echo "Xinetd is installed, it will now be removed"
	yum erase -y xinetd
fi 

checkxinetd=`yum list xinetd | grep "Available Packages"`
if [ -n "$checkxinetd" ]
then
	echo "Xinetd is not installed, hence chargen-dgram is not installed"
else	
	checkchargendgram=`chkconfig --list chargen-dgram | grep "off"` # 2.6 Checking of chargen-dgram
	if [ -n "$checkchargendgram" ]
	then
		echo "chargen-dgram is not active, hence no action will be taken"
	else
		echo "chargen-dgram is active, it will now be disabled"
		chkconfig chargen-dgram off
	fi 
fi 

if [ -n "$checkxinetd" ]
then
	echo "Xinetd is not installed, hence chargen-stream is not installed"
else	
	checkchargenstream=`chkconfig --list chargen-stream | grep "off"` # 2.7 Checking of chargen-stream
	if [ -n "$checkchargenstream" ]
	then
		echo "chargen-stream is not active, hence no action will be taken"
	else
		echo "chargen-stream is active, it will now be disabled"
		chkconfig chargen-stream off
	fi 
fi 

if [ -n "$checkxinetd" ]
then
	echo "Xinetd is not installed, hence daytime-dgram is not installed"
else	
	checkdaytimedgram=`chkconfig --list daytime-dgram | grep "off"` # 2.8 Checking of daytime-dgram
	if [ -n "$checkdaytimedgram" ]
	then
	echo "daytime-dgram is not active, hence no action will be taken"
	else
	echo "daytime-dgram is active, it will now be disabled"
	chkconfig daytime-dgram off
	fi 
fi

if [ -n "$checkxinetd" ]
then
	echo "Xinetd is not installed, hence daytime-stream is not installed"
else	
	checkdaytimestream=`chkconfig --list daytime-stream | grep "off"` # 2.8 Checking of daytime-stream
	if [ -n "$checkdaytimestream" ]
	then
		echo "daytime-stream is not active, hence no action will be taken"
	else
		echo "daytime-stream is active, it will now be disabled"
		chkconfig daytime-stream off
	fi 
fi 

if [ -n "$checkxinetd" ]
then
	echo "Xinetd is not installed, hence echo-dgram is not installed"
else	
	checkechodgram=`chkconfig --list echo-dgram | grep "off"` # 2.9 Checking of echo-dgram
	if [ -n "$checkechodgram" ]
	then
		echo "echo-dgram is not active, hence no action will be taken"
	else
		echo "echo-dgram is active, it will now be disabled"
		chkconfig echo-dgram off
	fi
fi

if [ -n "$checkxinetd" ]
then
	echo "Xinetd is not installed, hence echo-stream is not installed"
else	
	checkechostream=`chkconfig --list echo-stream | grep "off"` # 2.9 Checking of echo-stream
	if [ -n "$checkechostream" ]
	then
		echo "echo-stream is not active, hence no action will be taken"
	else
		echo "echo-stream is active, it will now be disabled"
		chkconfig echo-stream off
	fi 
fi

if [ -n "$checkxinetd" ]
then
	echo "Xinetd is not installed, hence tcpmux-server is not installed"
else	
	checktcpmuxserver=`chkconfig --list tcpmux-server | grep "off"` # 2.10 Checking of tcpmux-server
	if [ -n "$checktcpmuxserver" ]
	then
		echo "tcpmux-server is not active, hence no action will be taken"
	else
		echo "tcpmux-server is active, it will now be disabled"
		chkconfig tcpmux-server off
	fi 
fi 

# 3.1 Set daemon umask
umaskcheck=`grep ^umask /etc/sysconfig/init`
if [ -z "$umaskcheck" ]
then
	echo "umask 027" >> /etc/sysconfig/init
fi

# 3.2 Remove the x window system
checkxsystem=`ls -l /etc/systemd/system/default.target | grep graphical.target`
checkxsysteminstalled=`rpm  -q xorg-x11-server-common | grep "not installed"`

if [ -n "$checkxsystem" ]
then
	if [ -z "$checkxsysteminstalled" ]
	then
		rm '/etc/systemd/system/default.target'
		ln -s '/usr/lib/systemd/system/multi-user.target' '/etc/systemd/system/default.target'
		yum remove -y xorg-x11-server-common
	fi
fi

# 3.3 Disable avahi server
checkavahi=`systemctl status avahi-daemon | grep inactive`
checkavahi1=`systemctl status avahi-daemon | grep disabled`

if [ -z "$checkavahi" -o -z "$checkavahi1" ]
then
	systemctl disable avahi-daemon.service avahi-daemon.socket
	systemctl stop avahi-daemon.service avahi-daemon.socket
	yum remove -y avahi-autoipd avahi-libs avahi
fi

# 3.4 Disable print server - cups
checkcupsinstalled=`yum list cups | grep "Available Packages" `
checkcups=`systemctl status cups | grep inactive`
checkcups1=`systemctl status cups | grep disabled`
if [ -z "$checkcupsinstalled" ]
then
	if [ -z "$checkcups" -o -z "$checkcups1" ]
	then
		systemctl stop cups
		systemctl disable cups
	fi
fi

# 3.5 Remove DHCP server
checkyumdhcp=`yum list dhcp | grep "Available Packages" `
checkyumdhcpactive=`systemctl status dhcp | grep inactive `
checkyumdhcpenable=`systemctl status dhcp | grep disabled `
if [ -z "$checkyumdhcp" ]
then
	if [ -z "$checkyumdhcpactive" -o -z "$checkyumdhcpenable" ]
	then
		systemctl disable dhcp
		systemctl stop dhcp
		yum -y erase dhcp
	fi
fi

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

# 6.1.5 Configure rsyslog to Send Logs to a Remote Log Host
checkloghost=`grep "^*.*[^|][^|]*@" /etc/rsyslog.conf`
if [ -z "$checkloghost" ]  # If there is no log host
then
	echo "*.* @@logfile.example.com"
	echo "Remote Log Host has been configured"
else
	echo "$checkloghost is the Remote Log Host"
fi

# 6.1.6 Accept Remote rsyslog Messages Only on Designated Log Hosts
checkmodload=`cat /etc/rsyslog.conf | grep "^ModLoad imtcp"`
checkinput=`cat /etc/rsyslog.conf | grep "^InputTCPServerRun"`
if [ "$checkmodload" == "" ]
then
	#If the string has not been commented out
	echo "ModLoad imtcp is up? : PASSED"
else
	# If the thing has been commented out
	echo "ModLoad imtcp is up? : FAILED"
	echo "Setting configuration..."
	printf "\n\$ModLoad imtcp.so" >> /etc/rsyslog.conf
	echo "Change SUCCESS"
fi
if [ "$checkinput" == "" ]
then
	#If the string has not been commented out
        echo "InputTCPServerRun is up? : PASSED"
else
	# If the string has been commented out
        echo "InputTCPServerRun is up? : FAILED"
        echo "Setting configuration..."
	printf "\n\$InputTCPServerRun 514" >> /etc/rsyslog.conf
        echo "Change SUCCESS"
fi

# 6.2.1.1 Configure Audit Log Storage Size
checkvalue=`grep -w "max_log_file" /etc/audit/auditd.conf | awk -F ' ' '{print $3}'`
if [ "$checkvalue" != "5" ]
then
	sed -i /$checkvalue/d /etc/audit/auditd.conf
	printf "max_log_file = 5" >> /etc/audit/auditd.conf
	echo "Change SUCCESS"
else
	echo "The value is already 5"
fi

# 6.2.1.2 Keep All Auditing Information
checkvalue2=`grep -w "max_log_file_action" /etc/audit/auditd.conf | awk -F ' ' '{print $3}'`
if [ "$checkvalue2" != "keep_logs" ]
then
	sed -i '18d' /etc/audit/auditd.conf
        sed -ie '18imax_log_file_action = keep_logs' /etc/audit/auditd.conf
        echo "Change SUCCESS"
else
        echo "The value is already keep_logs"
fi

# 6.2.1.3 Disable System on Audit Log Full
checkvalue3=`grep -w "space_left_action" /etc/audit/auditd.conf | awk -F ' ' '{print $3}'`
if [ "$checkvalue3" != "email" ]
then
        sed -i '20d' /etc/audit/auditd.conf
        sed -ie '20ispace_left_action = email' /etc/audit/auditd.conf
        echo "Change SUCCESS"
else
        echo "The value is already email"
fi

printf "\n"

checkvalue4=`grep -w "action_mail_acct" /etc/audit/auditd.conf | awk -F ' ' '{print $3}'`
if [ "$checkvalue4" != "root" ]
then
        sed -i '21d' /etc/audit/auditd.conf
        sed -ie '21iaction_mail_acct = root' /etc/audit/auditd.conf
        echo "Change SUCCESS"
else
        echo "The value is already root"
fi

printf "\n"

checkvalue5=`grep -w "admin_space_left_action" /etc/audit/auditd.conf | awk -F ' ' '{print $3}'`
if [ "$checkvalue5" != "halt" ]
then
        sed -i '23d' /etc/audit/auditd.conf
        sed -ie '23iadmin_space_left_action = halt' /etc/audit/auditd.conf
        echo "Change is SUCCESSFUL"
else
        echo "The value is already halt"
fi

# 6.2.1.4 Enable auditd Service
checkauditdservice=`systemctl is-enabled auditd`

if [ "$checkauditdservice" == enabled ]
then
	echo "Auditd is already enabled"
else
	echo "Auditd is not enabled"
	systemctl enable auditd
	echo "Auditd Service is now enabled"
fi

# 6.2.1.5 Enable Auditing for Processes That Start Prior to auditd
checkgrub=`grep "linux" /boot/grub2/grub.cfg | grep "audit=1"`
if [ -z "$checkgrub"  ]
then
	var="GRUB_CMDLINE_LINUX"
	sed -i /$var/d /etc/default/grub
	printf "\nGRUB_CMDLINE_LINUX=\"audit=1\"" >> /etc/default/grub
else
	echo "audit 1 is present"
fi

grub2-mkconfig -o /boot/grub2/grub.cfg

# 6.2.1.6 Record Events That Modify Date and Time Information
checksystem=`uname -m | grep "64"`
checkmodifydatetimeadjtimex=`egrep 'adjtimex' /etc/audit/audit.rules`

if [ -z "$checksystem" ]
then
	echo "It is a 32-bit system."

	if [ -z "$checkmodifydatetimeadjtimex" ]
	then
        	echo "Date & Time Modified Events - FAILED (Adjtimex is not configured)"
        	echo "-a always,exit -F arch=b32 -S adjtimex -S settimeofday -S stime -k time-change" >> /etc/audit/rules.d/audit.rules
		echo "-a always,exit -F arch=b32 -S adjtimex -S settimeofday -S stime -k time-change" >> /etc/audit/audit.rules
        	echo "Adjtimex is now configured"
	else
		echo "Date & Time Modified Events - PASSED (Adjtimex is configured)"
	fi
else
	echo "It is a 64-bit system."

	if [ -z "$checkmodifydatetimeadjtimex" ]
	then
        	echo "Date & Time Modified Events - FAILED (Adjtimex is not configured)"
		echo "-a always,exit -F arch=b64 -S adjtimex -S settimeofday -k time-change" >> /etc/audit/rules.d/audit.rules
		echo "-a always,exit -F arch=b64 -S adjtimex -S settimeofday -k time-change" >> /etc/audit/audit.rules
       		echo "-a always,exit -F arch=b32 -S adjtimex -S settimeofday -S stime -k time-change" >> /etc/audit/rules.d/audit.rules
		echo "-a always,exit -F arch=b32 -S adjtimex -S settimeofday -S stime -k time-change" >> /etc/audit/audit.rules
        	echo "Adjtimex is now configured"
	else
		echo "Date & Time Modified Events - PASSED (Adjtimex is configured)"
	fi
fi

checkmodifydatetimesettime=`egrep 'clock_settime' /etc/audit/audit.rules`

if [ -z "$checksystem" ]
then
	if [ -z "$checkmodifydatetimesettime" ]
	then
        	echo "Date & Time Modified Events - FAILED (Settimeofday is not configured)"
        	echo "-a always,exit -F arch=b32 -S clock_settime -k time-change" >> /etc/audit/rules.d/audit.rules
		echo "-a always,exit -F arch=b32 -S clock_settime -k time-change" >> /etc/audit/audit.rules
        	echo "Clock set time is now configured"
	else
        	echo "Date & Time Modified Events - PASSED (Clock set time is configured)"
	fi
else
	if [ -z "$checkmodifydatetimesettime" ]
	then
        	echo "Date & Time Modified Events - FAILED (Clock set time is not configured)"
		echo "-a always,exit -F arch=b64 -S clock_settime -k time-change" >> /etc/audit/rules.d/audit.rules
		echo "-a always,exit -F arch=b64 -S clock_settime -k time-change" >> /etc/audit/audit.rules
        	echo "-a always,exit -F arch=b32 -S clock_settime -k time-change" >> /etc/audit/rules.d/audit.rules
		echo "-a always,exit -F arch=b32 -S clock_settime -k time-change" >> /etc/audit/audit.rules
        	echo "Clock set time is now configured"
	else
        	echo "Date & Time Modified Events - PASSED (Clock set time is configured)"
	fi
fi

checkmodifydatetimeclock=`egrep '/etc/localtime' /etc/audit/audit.rules`

if [ -z "$checkmodifydatetimeclock" ]
then
       	echo "Date & Time Modified Events - FAILED (/etc/localtime is not configured)"
       	echo "-w /etc/localtime -p wa -k time-change" >> /etc/audit/rules.d/audit.rules
	echo "-w /etc/localtime -p wa -k time-change" >> /etc/audit/audit.rules
       	echo "/etc/localtime is now configured"
else
       	echo "Date & Time Modified Events - PASSED (/etc/localtime is configured)"
fi

service auditd restart

# 6.2.1.7 Record Events That Modify User/Group Information
checkmodifyusergroupinfo=`egrep '\/etc\/group' /etc/audit/audit.rules`

if [ -z "$checkmodifyusergroupinfo" ]
then
        echo "Group Configuration - FAILED (Group is not configured)"
        echo "-w /etc/group -p wa -k identity" >> /etc/audit/audit.rules
	echo "-w /etc/group -p wa -k identity" >> /etc/audit/rules.d/audit.rules
        echo "Group is now configured"
else
        echo "Group Configuration - PASSED (Group is already configured)"
fi

checkmodifyuserpasswdinfo=`egrep '\/etc\/passwd' /etc/audit/audit.rules`

if [ -z "$checkmodifyuserpasswdinfo" ]
then
        echo "Password Configuration - FAILED (Password is not configured)"
        echo "-w /etc/passwd -p wa -k identity" >> /etc/audit/audit.rules
	echo "-w /etc/passwd -p wa -k identity" >> /etc/audit/rules.d/audit.rules
        echo "Password is now configured"
else
        echo "Password Configuration - PASSED (Password is configured)"
fi

checkmodifyusergshadowinfo=`egrep '\/etc\/gshadow' /etc/audit/audit.rules`

if [ -z "$checkmodifyusergshadowinfo" ]
then
        echo "GShadow Configuration - FAILED (GShadow is not configured)"
        echo "-w /etc/gshadow -p wa -k identity" >> /etc/audit/audit.rules
	echo "-w /etc/gshadow -p wa -k identity" >> /etc/audit/rules.d/audit.rules
        echo "GShadow is now configured"
else
        echo "GShadow Configuration - PASSED (GShadow is configured)"
fi

checkmodifyusershadowinfo=`egrep '\/etc\/shadow' /etc/audit/audit.rules`

if [ -z "$checkmodifyusershadowinfo" ]
then
        echo "Shadow Configuration - FAILED (Shadow is not configured)"
        echo "-w /etc/shadow -p -k identity" >> /etc/audit/audit.rules
	echo "-w /etc/shadow -p -k identity" >> /etc/audit/rules.d/audit.rules
        echo "Shadow is now configured"
else
        echo "Shadow Configuration - PASSED (Shadow is configured)"
fi

checkmodifyuseropasswdinfo=`egrep '\/etc\/security\/opasswd' /etc/audit/audit.rules`

if [ -z "$checkmodifyuseropasswdinfo" ]
then
        echo "OPasswd Configuration- FAILED (OPassword not configured)"
        echo "-w /etc/security/opasswd -p wa -k identity" >> /etc/audit/audit.rules
	echo "-w /etc/security/opasswd -p wa -k identity" >> /etc/audit/rules.d/audit.rules
        echo "OPassword is now configured"
else
        echo "OPasswd Configuration - PASSED (OPassword is configured)"
fi

service auditd restart

# 6.2.1.8 Record Events That Modify the System's Network Environment
checkmodifynetworkenvironmentname=`egrep 'sethostname|setdomainname' /etc/audit/audit.rules`

if [ -z "$checksystem" ]
then
	echo "It is a 32-bit system."

	if [ -z "$checkmodifynetworkenvironmentname" ]
	then
        	echo "Modify the System's Network Environment Events - FAILED (Sethostname and setdomainname is not configured)"
        	echo "-a always,exit -F arch=b32 -S sethostname -S setdomainname -k system-locale" >> /etc/audit/rules.d/audit.rules
		echo "-a always,exit -F arch=b32 -S sethostname -S setdomainname -k system-locale" >> /etc/audit/audit.rules
        	echo "Sethostname and setdomainname is now configured"
	else
		echo "Modify the System's Network Environment Events - PASSED (Sethostname and setdomainname is configured)"
	fi
else
	echo "It is a 64-bit system."

	if [ -z "$checkmodifynetworkenvironmentname" ]
	then
        	echo "Modify the System's Network Environment Events - FAILED (Sethostname and setdomainname is not configured)"
        	echo "-a always,exit -F arch=b64 -S sethostname -S setdomainname -k system-locale" >> /etc/audit/rules.d/audit.rules
		echo "-a always,exit -F arch=b64 -S sethostname -S setdomainname -k system-locale" >> /etc/audit/audit.rules
		echo "-a always,exit -F arch=b32 -S sethostname -S setdomainname -k system-locale" >> /etc/audit/rules.d/audit.rules
		echo "-a always,exit -F arch=b32 -S sethostname -S setdomainname -k system-locale" >> /etc/audit/audit.rules
        	echo "Sethostname is now configured"
	else
		echo "Modify the System's Network Environment Events - PASSED (Sethostname and setdomainname is configured)"
	fi
fi

checkmodifynetworkenvironmentissue=`egrep '\/etc\/issue' /etc/audit/audit.rules`

if [ -z "$checkmodifynetworkenvironmentissue" ]
then
       	echo "Modify the System's Network Environment Events - FAILED (/etc/issue is not configured)"
       	echo "-w /etc/issue -p wa -k system-locale" >> /etc/audit/rules.d/audit.rules
	echo "-w /etc/issue -p wa -k system-locale" >> /etc/audit/audit.rules
       	echo "-w /etc/issue.net -p wa -k system-locale" >> /etc/audit/rules.d/audit.rules
	echo "-w /etc/issue.net -p wa -k system-locale" >> /etc/audit/audit.rules
       	echo "/etc/issue is now configured"
else
       	echo "Modify the System's Network Environment Events - PASSED (/etc/issue is configured)"
fi

checkmodifynetworkenvironmenthosts=`egrep '\/etc\/hosts' /etc/audit/audit.rules`

if [ -z "$checkmodifynetworkenvironmenthosts" ]
then
       	echo "Modify the System's Network Environment Events - FAILED (/etc/hosts is not configured)"
       	echo "-w /etc/hosts -p wa -k system-locale" >> /etc/audit/rules.d/audit.rules
	echo "-w /etc/hosts -p wa -k system-locale" >> /etc/audit/audit.rules
       	echo "/etc/hosts is now configured"
else
       	echo "Modify the System's Network Environment Events - PASSED (/etc/hosts is configured)"
fi

checkmodifynetworkenvironmentnetwork=`egrep '\/etc\/sysconfig\/network' /etc/audit/audit.rules`

if [ -z "$checkmodifynetworkenvironmentnetwork" ]
then
       	echo "Modify the System's Network Environment Events - FAILED (/etc/sysconfig/network is not configured)"
       	echo "-w /etc/sysconfig/network -p wa -k system-locale" >> /etc/audit/rules.d/audit.rules
	echo "-w /etc/sysconfig/network -p wa -k system-locale" >> /etc/audit/audit.rules
       	echo "/etc/sysconfig/network is now configured"
else
       	echo "Modify the System's Network Environment Events - PASSED (/etc/sysconfig/network is configured)"
fi

service auditd restart

# 6.2.1.9 Record Events That Modify the System's Mandatory Access Controls
var=`grep \/etc\/selinux /etc/audit/audit.rules`
if [ -z "$var" ]
then
	echo "Record Events That Modify the System's Mandatory Access Controls - FAILED"
	echo "-w /etc/selinux/ -p wa -k MAC-policy" >> /etc/audit/rules.d/audit.rules
	echo "-w /etc/selinux/ -p wa -k MAC-policy" >> /etc/audit/audit.rules
else
	echo "It is being recorded"
fi

service auditd restart

# 6.2.1.10 Collect Login and Logout Events
loginfail=`grep "\-w /var/log/faillog -p wa -k logins" /etc/audit/audit.rules`
loginlast=`grep "\-w /var/log/lastlog -p wa -k logins" /etc/audit/audit.rules`
logintally=`grep "\-w /var/log/tallylog -p wa -k logins" /etc/audit/audit.rules`

if [ -z "$loginfail" -o -z "$loginlast" -o -z "$logintally" ]
then
	if [ -z "$loginfail" ]
	then
		echo "-w /var/log/faillog -p wa -k logins" >> /etc/audit/rules.d/audit.rules
		echo "-w /var/log/faillog -p wa -k logins" >> /etc/audit/audit.rules
	fi
	if [ -z "$loginlast" ]
	then
		echo "-w /var/log/lastlog -p wa -k logins" >> /etc/audit/rules.d/audit.rules		
		echo "-w /var/log/lastlog -p wa -k logins" >> /etc/audit/audit.rules
	fi
	if [ -z "$logintally" ]
	then
		echo "-w /var/log/tallylog -p wa -k logins" >> /etc/audit/rules.d/audit.rules
		echo "-w /var/log/tallylog -p wa -k logins" >> /etc/audit/audit.rules
	fi
fi
	
service auditd restart
