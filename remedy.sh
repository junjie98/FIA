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

echo "Create seperate partition for /tmp"
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
	
	echo "Create seperate partition for /var"
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

	echo "Bind mount /var/tmp directory to /tmp"
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

	echo "Create separate partition for /var/log"
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

	echo "Create seperate partition for /var/log/audit"
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
	
	echo "Create seperate partition for /home"
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

echo "Add nodev option to removable media partitions"
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

echo "Set sticky bit on all world-writable directories"
checksticky=`df --local -P | awk {'if (NR!=1) print $6'} | xargs -l '{}' find '{}' -xdev -type d \( -perm -0002 -a ! -perm -1000 \) 2> /dev/null`

if [ -n "$checksticky" ]
then
	df --local -P | awk {'if (NR!=1) print $6'} | xargs -l '{}' find '{}' -xdev -type d \( -perm -0002 -a ! -perm -1000 \) 2> /dev/null | xargs chmod o+t
fi

echo "Disable mounting of legacy filesystems"
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

echo "Checking of telnet-server"
checktelnetserver=`yum list telnet-server | grep "Available Packages"`
if [ -n "$checktelnetserver" ]
then
	echo "Telnet-server is not installed, hence no action will be taken"
else
	echo "Telnet-server is installed, it will now be removed"
	yum erase -y telnet-server
fi 

echo "Checking of telnet"
checktelnet=`yum list telnet | grep "Available Packages"`
if [ -n "$checktelnet" ]
then
	echo "Telnet is not installed, hence no action will be taken"
else
	echo "Telnet is installed, it will now be removed"
	yum erase -y telnet
fi 

echo "Checking of rsh-server"
checkrshserver=`yum list rsh-server | grep "Available Packages"`
if [ -n "$checkrshserver" ]
then
	echo "Rsh-server is not installed, hence no action will be taken"
else
	echo "Rsh-server is installed, it will now be removed"
	yum erase -y rsh-server
fi 

echo "Checking of rsh"
checkrsh=`yum list rsh | grep "Available Packages"`
if [ -n "$checkrsh" ]
then
	echo "Rsh is not installed, hence no action will be taken"
else
	echo "Rsh is installed, it will now be removed"
	yum erase -y rsh
fi 

echo "Checking of ypserv"
checkypserv=`yum list ypserv | grep "Available Packages"`
if [ -n "$checkypserv" ]
then
	echo "Ypserv is not installed, hence no action will be taken"
else
	echo "Ypserv is installed, it will now be removed"
	yum erase -y ypserv
fi 

echo "Checking of ypbind"
checkypbind=`yum list ypbind | grep "Available Packages"`
if [ -n "$checkypbind" ]
then
	echo "Ypbind is not installed, hence no action will be taken"
else
	echo "Ypbind is installed, it will now be removed"
	yum erase -y ypbind
fi 

echo "Checking of tftp"
checktftp=`yum list tftp | grep "Available Packages"`
if [ -n "$checktftp" ]
then
	echo "Tftp is not installed, hence no action will be taken"
else
	echo "Tftp is installed, it will now be removed"
	yum erase -y tftp
fi

echo "Checking of tftp-server"
checktftp=`yum list tftp-server| grep "Available Packages"`
if [ -n "$checktftp-server" ]
then
	echo "Tftp-server is not installed, hence no action will be taken"
else
	echo "Tftp-server is installed, it will now be removed"
	yum erase -y tftp-server
fi 

echo "Checking of xinetd"
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

echo "Set daemon umask"
umaskcheck=`grep ^umask /etc/sysconfig/init`
if [ -z "$umaskcheck" ]
then
	echo "umask 027" >> /etc/sysconfig/init
fi

echo "Remove the x window system"
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

echo "Disable avahi server"
checkavahi=`systemctl status avahi-daemon | grep inactive`
checkavahi1=`systemctl status avahi-daemon | grep disabled`

if [ -z "$checkavahi" -o -z "$checkavahi1" ]
then
	systemctl disable avahi-daemon.service avahi-daemon.socket
	systemctl stop avahi-daemon.service avahi-daemon.socket
	yum remove -y avahi-autoipd avahi-libs avahi
fi

echo "Disable print server - cups"
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

echo "Remove DHCP server"
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

echo "Configure NTP"
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

echo "Remove LDAP"
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

echo "Disable NFS & RPC"
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

echo "Remove DNS, FTP, HTTP, HTTP-Proxy, SNMP"
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

echo "MTA"
checkmta=`netstat -an | grep LIST | grep "127.0.0.1:25[[:space:]]"`

if [ -z "$checkmta" ]
then
	sed -ie '116iinet_interfaces = localhost' /etc/postfix/main.cf
	systemctl restart postfix
fi

echo "Set User/Group Owner on /boot/grub2/grub.cfg"
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
	echo "Done, Change SUCCESSFUL"
fi

echo "Set Permissions on /boot/grub2/grub.cfg"
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

echo "Set Boot Loader Password"
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

echo "Restrict Core Dumps"
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

echo "Enable Randomized Virtual Memory Region Placement"
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

echo "Install the rsyslog package"
echo "Activate the rsyslog Service"
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

echo "Configure /etc/rsyslog.conf"
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

echo "Create and Set Permissions on rsyslog Log Files"
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

echo "Configure rsyslog to Send Logs to a Remote Log Host"
checkloghost=`grep "^*.*[^|][^|]*@" /etc/rsyslog.conf`
if [ -z "$checkloghost" ]  # If there is no log host
then
	echo "*.* @@logfile.example.com"
	echo "Remote Log Host has been configured"
else
	echo "$checkloghost is the Remote Log Host"
fi

echo "Accept Remote rsyslog Messages Only on Designated Log Hosts"
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

echo "Configure Audit Log Storage Size"
checkvalue=`grep -w "max_log_file" /etc/audit/auditd.conf | awk -F ' ' '{print $3}'`
if [ "$checkvalue" != "5" ]
then
	sed -i /$checkvalue/d /etc/audit/auditd.conf
	printf "max_log_file = 5" >> /etc/audit/auditd.conf
	echo "Change SUCCESS"
else
	echo "The value is already 5"
fi

echo "Keep All Auditing Information"
checkvalue2=`grep -w "max_log_file_action" /etc/audit/auditd.conf | awk -F ' ' '{print $3}'`
if [ "$checkvalue2" != "keep_logs" ]
then
	sed -i '18d' /etc/audit/auditd.conf
        sed -ie '18imax_log_file_action = keep_logs' /etc/audit/auditd.conf
        echo "Change SUCCESS"
else
        echo "The value is already keep_logs"
fi

echo "Disable System on Audit Log Full"
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

echo "Enable auditd Service"
checkauditdservice=`systemctl is-enabled auditd`

if [ "$checkauditdservice" == enabled ]
then
	echo "Auditd is already enabled"
else
	echo "Auditd is not enabled"
	systemctl enable auditd
	echo "Auditd Service is now enabled"
fi

echo "Enable Auditing for Processes That Start Prior to auditd"
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

echo "Record Events That Modify Date and Time Information"
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

echo "Record Events That Modify User/Group Information"
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

echo "Record Events That Modify the System's Network Environment"
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

echo "Record Events That Modify the System's Mandatory Access Controls"
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

echo "Collect Login and Logout Events"
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

echo "Collect Session Initiation Information "
sessionwtmp=`egrep '\-w /var/log/wtmp -p wa -k session' /etc/audit/audit.rules`
sessionbtmp=`egrep '\-w /var/log/btmp -p wa -k session' /etc/audit/audit.rules`
sessionutmp=`egrep '\-w /var/run/utmp -p wa -k session' /etc/audit/audit.rules`

if [ -z "$sessionwtmp" -o -z "$sessionbtmp" -o -z "$sessionutmp" ]
then 
	if [ -z "$sessionwtmp"]
	then 
		echo "-w /var/log/wtmp -p wa -k session" >> /etc/audit/rules.d/audit.rules
		echo "-w /var/log/wtmp -p wa -k session" >> /etc/audit/audit.rules
	fi
	if [ -z "$sessionbtmp"]
	then 
		echo "-w /var/log/btmp -p wa -k session" >> /etc/audit/rules.d/audit.rules
		echo "-w /var/log/btmp -p wa -k session" >> /etc/audit/audit.rules
	fi
	if [ -z "$sessionutmp"]
	then
		echo "-w /var/run/utmp -p wa -k session" >> /etc/audit/rules.d/audit.rules
		echo "-w /var/run/utmp -p wa -k session" >> /etc/audit/audit.rules
	fi
fi

service auditd restart

echo "Collect Discretionary Access Control Permission Modification Events"
permission1=`grep "\-a always,exit -F arch=b64 -S chmod -S fchmod -S fchmodat -F auid>=1000 -F auid!=4294967295 -k perm_mod" /etc/audit/audit.rules`

permission2=`grep "\-a always,exit -F arch=b32 -S chmod -S fchmod -S fchmodat -F auid>=1000 -F auid!=4294967295 -k perm_mod" /etc/audit/audit.rules`

permission3=`grep "\-a always,exit -F arch=b64 -S chown -S fchown -S fchownat -S|chown -F auid>=1000 -F auid!=4294967295 -k perm_mod" /etc/audit/audit.rules`

permission4=`grep "\-a always,exit -F arch=b32 -S chown -S fchown -S fchownat -S|chown -F auid>=1000 -F auid!=4294967295 -k perm_mod" /etc/audit/audit.rules`

permission5=`grep "\-a always,exit -F arch=b64 -S setxattr -S lsetxattr -S fsetxattr -S removexattr -S lremovexattr -S fremovexattr -F auid>=1000 -Fauid!=4294967295 -k perm_mod" /etc/audit/audit.rules`

permission6=`grep "\-a always,exit -F arch=b32 -S setxattr -S lsetxattr -S fsetxattr -S removexattr -S lremovexattr -S fremovexattr -F auid>=1000 -F auid!=4294967295 -k perm_mod" /etc/audit/audit.rules`

if [ -z "$permission1" -o -z "$permission2" -o -z permission3 -o -z permission4 -o -z permission5 -o -z permission6  ]
then 
	if [ -z "$permission1" ]
	then
		echo "-a always,exit -F arch=b64 -S chmod -S fchmod -S fchmodat -F auid>=1000 -F auid!=4294967295 -k perm_mod" >> /etc/audit/audit.rules
		echo "-a always,exit -F arch=b64 -S chmod -S fchmod -S fchmodat -F auid>=1000 -F auid!=4294967295 -k perm_mod" >> /etc/audit/rules.d/audit.rules
	fi

	if [ -z "$permission2" ]
	then 
		echo "-a always,exit -F arch=b32 -S chmod -S fchmod -S fchmodat -F auid>=1000 -F auid!=4294967295 -k perm_mod" >> /etc/audit/audit.rules
		echo "-a always,exit -F arch=b32 -S chmod -S fchmod -S fchmodat -F auid>=1000 -F auid!=4294967295 -k perm_mod" >> /etc/audit/rules.d/audit.rules
	fi
	if [ -z "$permission3" ]
	then 
		echo "-a always,exit -F arch=b64 -S chown -S fchown -S fchownat -S lchown -F auid>=1000 -F auid!=4294967295 -k perm_mod" >> /etc/audit/audit.rules
		echo "-a always,exit -F arch=b64 -S chown -S fchown -S fchownat -S lchown -F auid>=1000 -F auid!=4294967295 -k perm_mod" >> /etc/audit/rules.d/audit.rules
	fi
	if [ -z "$permission4" ]
	then
		echo "-a always,exit -F arch=b32 -S chown -S fchown -S fchownat -S lchown -F auid>=1000 -F auid!=4294967295 -k perm_mod" >> /etc/audit/audit.rules
		echo "-a always,exit -F arch=b32 -S chown -S fchown -S fchownat -S lchown -F auid>=1000 -F auid!=4294967295 -k perm_mod" >> /etc/audit/rules.d/audit.rules
	fi
	if [ -z "$permission5" ]
	then 
		echo "-a always,exit -F arch=b64 -S setxattr -S lsetxattr -S fsetxattr -S removexattr -S lremovexattr -S fremovexattr -F auid>=1000 -F auid!=4294967295 -k perm_mod" >> /etc/audit/audit.rules
	fi
	if [ -z "$permission6" ]
	then 
		echo "-a always,exit -F arch=b32 -S setxattr -S lsetxattr -S fsetxattr -S removexattr -S lremovexattr -S fremovexattr -F auid>=1000 -F auid!=4294967295 -k perm_mod" >> /etc/audit/audit.rules
		echo "-a always,exit -F arch=b32 -S setxattr -S lsetxattr -S fsetxattr -S removexattr -S lremovexattr -S fremovexattr -F auid>=1000 -F auid!=4294967295 -k perm_mod" >> /etc/audit/rules.d/audit.rules

	fi
fi
service auditd restart

echo "Collect Unsuccessful Unauthorized Access Attempts to Files"
access1=`grep "\-a always,exit -F arch=b64 -S creat -S open -S openat -S truncate -S ftruncate -F exit=-EACCES -F auid>=1000 -F auid!=4294967295 - k access" /etc/audit/audit.rules`

access2=`grep "\-a always,exit -F arch=b32 -S creat -S open -S openat -S truncate -S ftruncate -F exit=-EACCES -F auid>=1000 -F auid!=4294967295 - k access" /etc/audit/audit.rules`

access3=`grep "\-a always,exit -F arch=b64 -S creat -S open -S ope
nat -S truncate -S ftruncate -F exit=-EPERM -F auid>=1000 -F auid!=4294967295 - k access" /etc/audit/audit.rules`

access4=`grep "\-a always,exit -F arch=b32 -S creat -S open -S ope
nat -S truncate -S ftruncate -F exit=-EPERM -F auid>=1000 -F auid!=4294967295 - k access" /etc/audit/audit.rules`

access5=`grep "\-a always,exit -F arch=b32 -S creat -S open -S ope
nat -S truncate -S ftruncate -F exit=-EACCES -F auid>=1000 -F auid!=4294967295 - k access" /etc/audit/audit.rules`

access6=`grep "\-a always,exit -F arch=b32 -S creat -S open -S ope
nat -S truncate -S ftruncate -F exit=-EPERM -F auid>=1000 -F auid!=4294967295 - k access" /etc/audit/audit.rules`

if [ -z "$access1" -o -z "$access2" ]
then
	if [ -z "$access1" ]
	then     
   		echo "-a always,exit -F arch=b64 -S creat -S open -S openat -S truncate -S ftruncate -F exit=-EACCES -F auid>=1000 -F auid!=4294967295 - k access" >> /etc/audit/audit.rules
		echo "-a always,exit -F arch=b64 -S creat -S open -S openat -S truncate -S ftruncate -F exit=-EACCES -F auid>=1000 -F auid!=4294967295 - k access" >> /etc/audit/rules.d/audit.rules
	fi
	if [ -z "$access2" ]
	then 
		echo "-a always,exit -F arch=b32 -S creat -S open -S openat -S truncate -S ftruncate -F exit=-EACCES -F auid>=1000 -F auid!=4294967295 - k access" >> /etc/audit/audit.rules
		echo "-a always,exit -F arch=b32 -S creat -S open -S openat -S truncate -S ftruncate -F exit=-EACCES -F auid>=1000 -F auid!=4294967295 - k access" >> /etc/audit/rules.d/audit.rules
	fi
	if [ -z "$access3" ]
	then
		echo "-a always,exit -F arch=b64 -S creat -S open -S openat -S truncate -S ftruncate -F exit=-EPERM -F auid>=1000 -F auid!=4294967295 - k access" >>  /etc/audit/audit.rules
		echo "-a always,exit -F arch=b64 -S creat -S open -S openat -S truncate -S ftruncate -F exit=-EPERM -F auid>=1000 -F auid!=4294967295 - k access" >>  /etc/audit/rules.d/audit.rules
	fi
	if [ -z "$access4" ]
	then 
		echo "-a always,exit -F arch=b32 -S creat -S open -S openat -S truncate -S ftruncate -F exit=-EPERM -F auid>=1000 -F auid!=4294967295 - k access" >>  /etc/audit/audit.rules
		echo "-a always,exit -F arch=b32 -S creat -S open -S openat -S truncate -S ftruncate -F exit=-EPERM -F auid>=1000 -F auid!=4294967295 - k access" >>  /etc/audit/rules.d/audit.rules
	fi
	if [ -z "$access5" ]
	then
		echo "-a always,exit -F arch=b32 -S creat -S open -S openat -S truncate -S ftruncate -F exit=-EACCES -F auid>=1000 -F auid!=4294967295 - k access" >>  /etc/audit/audit.rules
		echo "-a always,exit -F arch=b32 -S creat -S open -S openat -S truncate -S ftruncate -F exit=-EACCES -F auid>=1000 -F auid!=4294967295 - k access" >>  /etc/audit/rules.d/audit.rules
	fi
	if [ -z "$access6" ]
	then 
		echo "-a always,exit -F arch=b32 -S creat -S open -S openat -S truncate -S ftruncate -F exit=-EPERM -F auid>=1000 -F auid!=4294967295 - k access" >>  /etc/audit/audit.rules
		echo "-a always,exit -F arch=b32 -S creat -S open -S openat -S truncate -S ftruncate -F exit=-EPERM -F auid>=1000 -F auid!=4294967295 - k access" >>  /etc/audit/rules.d/audit.rules
	fi
fi

service auditd restart

echo "Collect Use of Privileged Commands"
find / -xdev \( -perm -4000 -o -perm -2000 \) -type f | awk '{print "-a always,exit-F path=" $1 " -F perm=x -F auid>=1000 -F auid!=4294967295 -k privileged" }' > /tmp/1.log
checkpriviledge=`cat /tmp/1.log`
cat /etc/audit/audit.rules | grep -- "$checkpriviledge" > /tmp/2.log
checkpriviledgenotinfile=`grep -F -x -v -f /tmp/2.log /tmp/1.log`

if [ -n "$checkpriviledgenotinfile" ]
then
	echo "$checkpriviledgenotinfile" >> /etc/audit/audit.rules
	echo "$checkpriviledgenotinfile" >> /etc/audit/rules.d/audit.rules
fi

rm /tmp/1.log
rm /tmp/2.log

echo "Collect Successful File System Mounts"
bit64mountb64=`grep "\-a always,exit -F arch=b64 -S mount -F auid>=1000 -F auid!=4294967295 -k mounts" /etc/audit/audit.rules`
bit64mountb32=`grep "\-a always,exit -F arch=b32 -S mount -F auid>=1000 -F auid!=4294967295 -k mounts" /etc/audit/audit.rules`
bit32mountb32=`grep "\-a always,exit -F arch=b32 -S mount -F auid>=1000 -F auid!=4294967295 -k mounts" /etc/audit/audit.rules`

if [ -z "$bit64mountb64" ]
then
	echo "-a always,exit -F arch=b64 -S mount -F auid>=1000 -F auid!=4294967295 -k mounts" >> /etc/audit/audit.rules
	echo "-a always,exit -F arch=b64 -S mount -F auid>=1000 -F auid!=4294967295 -k mounts" >> /etc/audit/rules.d/audit.rules
fi

if [ -z "$bit64mountb32" ]
then
	echo "-a always,exit -F arch=b32 -S mount -F auid>=1000 -F auid!=4294967295 -k mounts" >> /etc/audit/audit.rules
	echo "-a always,exit -F arch=b32 -S mount -F auid>=1000 -F auid!=4294967295 -k mounts" >> /etc/audit/rules.d/audit.rules
fi

service auditd restart

if [ -z "$bit32mountb32" ]
then
	echo "-a always,exit -F arch=b32 -S mount -F auid>=1000 -F auid!=4294967295 -k mounts" >> /etc/audit/audit.rules
	echo "-a always,exit -F arch=b32 -S mount -F auid>=1000 -F auid!=4294967295 -k mounts" >> /etc/audit/rules.d/audit.rules
fi

service auditd restart

echo "Collect File Delection Events by User"
bit64delb64=`grep "\-a always,exit -F arch=b64 -S unlink -S unlinkat -S rename -S renameat -F auid>=1000 -F auid!=4294967295 -k delete" /etc/audit/audit.rules`
bit64delb32=`grep "\-a always,exit -F arch=b32 -S unlink -S unlinkat -S rename -S renameat -F auid>=1000 -F auid!=4294967295 -k delete" /etc/audit/audit.rules`
bit32delb32=`grep "\-a always,exit -F arch=b32 -S unlink -S unlinkat -S rename -S renameat -F auid>=1000 -F auid!=4294967295 -k delete" /etc/audit/audit.rules`

if [ -z "$bit64delb64" ]
then
	echo "-a always,exit -F arch=b64 -S unlink -S unlinkat -S rename -S renameat -F auid>=1000 -F auid!=4294967295 -k delete" >> /etc/audit/audit.rules
	echo "-a always,exit -F arch=b64 -S unlink -S unlinkat -S rename -S renameat -F auid>=1000 -F auid!=4294967295 -k delete" >> /etc/audit/rules.d/audit.rules
fi

if [ -z "$bit64delb32" ]
then
	echo "-a always,exit -F arch=b32 -S unlink -S unlinkat -S rename -S renameat -F auid>=1000 -F auid!=4294967295 -k delete" >> /etc/audit/audit.rules
	echo "-a always,exit -F arch=b32 -S unlink -S unlinkat -S rename -S renameat -F auid>=1000 -F auid!=4294967295 -k delete" >> /etc/audit/rules.d/audit.rules
fi

service auditd restart

if [ -z "$bit32delb32" ]
then
	echo "-a always,exit -F arch=b32 -S unlink -S unlinkat -S rename -S renameat -F auid>=1000 -F auid!=4294967295 -k delete" >> /etc/audit/audit.rules
	echo "-a always,exit -F arch=b32 -S unlink -S unlinkat -S rename -S renameat -F auid>=1000 -F auid!=4294967295 -k delete" >> /etc/audit/rules.d/audit.rules
fi

service auditd restart

echo "Collect Changes to System Administrator Scope"
sudoers=`grep "\-w /etc/sudoers -p wa -k scope" /etc/audit/audit.rules`

if [ -z "$sudoers" ]
then
	echo "-w /etc/sudoers -p wa -k scope" >> /etc/audit/audit.rules
	echo "-w /etc/sudoers -p wa -k scope" >> /etc/audit/rules.d/audit.rules
fi
service auditd restart

echo "Collect System Administrator Actions (sudolog)"
remauditrules=`grep actions /etc/audit/audit.rules`
auditrules='-w /var/log/sudo.log -p wa -k actions'

if [ -z "$remauditrules" -o "$remauditrules" != "$auditrules" ] 
then
	echo "$auditrules" >> /etc/audit/audit.rules
	echo "$auditrules" >> /etc/audit/rules.d/audit.rules
fi

service auditd restart

echo "Collect Kernel Module Loading and Unloading"
remmod1=`grep "\-w /sbin/insmod -p x -k modules" /etc/audit/audit.rules`
remmod2=`grep "\-w /sbin/rmmod -p x -k modules" /etc/audit/audit.rules`
remmod3=`grep "\-w /sbin/modprobe -p x -k modules" /etc/audit/audit.rules`
remmod4=`grep "\-a always,exit -F arch=b64 -S init_module -S delete_module -k modules" /etc/audit/audit.rules`

if [ -z "$remmod1" -o -z "$remmod2" -o -z "$remmod3" -o -z "$remmod4" -o -z "$remmod5" ]
then
	if [ -z "$remmod1" ]
	then
		echo "-w /sbin/insmod -p x -k modules" >> /etc/audit/audit.rules
		echo "-w /sbin/insmod -p x -k modules" >> /etc/audit/rules.d/audit.rules
	fi

	if [ -z "$remmod2" ]
	then	
		echo "-w /sbin/rmmod -p x -k modules" >> /etc/audit/audit.rules
		echo "-w /sbin/rmmod -p x -k modules" >> /etc/audit/rules.d/audit.rules
	fi

	if [ -z "$remmod3" ]
	then
		echo "-w /sbin/modprobe -p x -k modules" >> /etc/audit/audit.rules
		echo "-w /sbin/modprobe -p x -k modules" >> /etc/audit/rules.d/audit.rules
	fi

	if [ -z "$remmod4" ]
	then
		echo "-a always,exit -F arch=b64 -S init_module -S delete_module -k modules" >> /etc/audit/audit.rules
		echo "-a always,exit -F arch=b64 -S init_module -S delete_module -k modules" >> /etc/audit/rules.d/audit.rules
	fi
fi

service auditd restart
echo "Make the Audit Configuration Immutable"
remimmute=`grep "^-e 2" /etc/audit/audit.rules`
immute='-e 2'

if [ -z "$remimmute" -o "$remimmute" != "$immute" ]
then
	echo "$immute" >> /etc/audit/audit.rules
	echo "$immute" >> /etc/audit/rules.d/audit.rules
fi

service auditd restart
echo "Configure logrotate"
remlogrotate=`grep "/var/log" /etc/logrotate.d/syslog`
logrotate='/var/log/messages /var/log/secure /var/log/maillog /var/log/spooler /var/log/boot.log /var/log/cron {'

if [ -z "$remlogrotate" -o "$remlogrotate" != "$logrotate" ]
then
	rotate1=`grep "/var/log/messages" /etc/logrotate.d/syslog`
	rotate2=`grep "/var/log/secure" /etc/logrotate.d/syslog`
	rotate3=`grep "/var/log/maillog" /etc/logrotate.d/syslog`
	rotate4=`grep "/var/log/spooler" /etc/logrotate.d/syslog`
	rotate5=`grep "/var/log/boot.log" /etc/logrotate.d/syslog`
	rotate6=`grep "/var/log/cron" /etc/logrotate.d/syslog`
	
	if [ -z "$rotate1" ]
	then
		echo "/var/log/messages" >> /etc/logrotate.d/syslog
	fi

	if [ -z "$rotate2" ]
	then
		echo "/var/log/secure" >> /etc/logrotate.d/syslog
	fi

	if [ -z "$rotate3" ]
	then 
		echo "/var/log/maillog" >> /etc/logrotate.d/syslog
	fi

	if [ -z "$rotate4" ]
	then
		echo "/var/log/spooler" >> /etc/logrotate.d/syslog
	fi

	if [ -z "$rotate5" ]
	then
		echo "/var/log/boot.log" >> /etc/logrotate.d/syslog
	fi

	if [ -z "$rotate6" ]
	then
		echo "/var/log/cron" >> /etc/logrotate.d/syslog
	fi
fi

service auditd restart

echo "Set Password Expiration Days"

current=`cat /etc/login.defs | grep "^PASS_MAX_DAYS" | awk '{ print $2 }'`
standard=90 #change this value according to the enterprise's required standard
if [ ! $current = $standard ]; then
  sed -i "s/^PASS_MAX_DAYS.*99999/PASS_MAX_DAYS $standard/" /etc/login.defs | grep "^PASS_MAX_DAYS.*$standard"
fi

echo "Set Password Change Minimum Number of Days"

current=`cat /etc/login.defs | grep "^PASS_MIN_DAYS" | awk '{ print $2 }'`
standard=7 #change this value according to the enterprise's required standard
if [ ! $current = $standard ]; then
	sed -i "s/^PASS_MIN_DAYS.*0/PASS_MIN_DAYS $standard/" /etc/login.defs | grep "^PASS_MIN_DAYS.*$standard"
fi

echo "Set Password Expiring Warning Days"

current=`cat /etc/login.defs | grep "^PASS_WARN_AGE" | awk '{ print $2 }'`
standard=7 #change this value according to the enterprise's required standard
if [ ! $current = $standard ]; then
	sed -i "s/^PASS_WARN_AGE.*0/PASS_WARN_AGE $standard/" /etc/login.defs | grep "^PASS_WARN_AGE.*$standard"
fi

echo "Disable System Accounts"

for user in `awk -F: '($3 < 1000) { print $1 }' /etc/passwd` ; do 
	if [ $user != "root" ]; then 
		usermod -L $user &> /dev/null 
		if [ $user != "sync" ] && [ $user != "shutdown" ] && [ $user != "halt" ]; then
			usermod -s /sbin/nologin $user &> /dev/null
			fi 
		fi 
	done

echo "Set Default Group for root Account"
 
current=`grep "^root:" /etc/passwd | cut -f4 -d:`
  
if [ "$current" == 0 ]; then
	echo "Default Group for root Account is already set correctly"
else
	usermod -g 0 root
	echo "Default Group for root Account is modified successfully"
fi

echo "Set Default umask for Users"

remedy=`egrep -h "\s+umask ([0-7]{3})" /etc/bashrc /etc/profile | awk '{ print $2 }'`

if [ "$remedy" != 077 ];then 
	sed -i 's/022/077/g' /etc/profile /etc/bashrc
	sed -i 's/002/077/g' /etc/profile /etc/bashrc
fi

echo "Lock Inactive User Accounts"

useradd -D -f 30

echo "Ensure Password Fields are Not Empty"

current=`cat /etc/shadow | awk -F: '($2 == ""){print $1}'`

for line in ${current}
do
	/usr/bin/passwd -l ${line}	
done

echo "7.9 Verify No Legacy "+" Entries Exist in /etc/passwd,/etc/shadow,/etc/group"

passwd=`grep '^+:' /etc/passwd`
shadow=`grep '^+:' /etc/shadow`
group=`grep '^+:' /etc/group`

for accounts in $passwd
do
  	if [ "$accounts" != "" ];then
                userdel --force $accounts
                groupdel --force $accounts
fi
done

echo "Verify No UID 0 Accounts Exist Other Than Root"

remedy=`/bin/cat /etc/passwd | /bin/awk -F: '($3 == 0) { print $1 }'`

for accounts in $remedy
do
	if [ "$accounts" != "root" ];then
		userdel --force $accounts
		groupdel --force $accounts
fi
done

echo "Check Permissions on User Home Directories"
x=0
while [ $x = 0 ]
do
        clear
        echo "Do you want to set all user home directory permission as default? (y/n) - Press 'q' to quit."
        read answer
        case "$answer" in
                y)
                echo "You said - yes"
                intUserAcc=`/bin/cat /etc/passwd | /bin/egrep -v '(root|halt|sync|shutdown)' | /bin/awk -F: '($7 != "/sbin/nologin"){ print $6 }'`
                if [ -z "$intUserAcc" ]
                then
                        echo "There is no interactive user account"
                else
                        /bin/cat /etc/passwd | /bin/egrep -v '(root|halt|sync|shutdown)' | /bin/awk -F: '($7 != "/sbin/nologin"){ print $6 }' | while read -r line; do
                                chmod g-x $line
                                chmod o-rwx $line
                                echo "Directory $line permission is set default."
                        done
                fi
		 x=1
                ;;
                n)
                echo "You said -No"
                x=1
                ;;
                q)
                x=1
                echo "Exiting..."
                sleep 2
                ;;
                *)
                clear
                echo "This is not an option"
                sleep 3
                ;;
        esac
done

echo "Check User Dot File Permissions"

x=0
while [ $x = 0 ]
do
        clear
        echo "Do you want to set all user hidden file permission as default? (y/n) - Press 'q' to quit."
        read answer
        case "$answer" in
                y)
                echo "You said - yes"
                intUserAcc=`/bin/cat /etc/passwd | /bin/egrep -v '(root|halt|sync|shutdown)' | /bin/awk -F: '($7 != "/sbin/nologin"){ print $6 }')`
                if [ -z "$intUserAcc" ]
                then
                        echo "There is no interactive user account"
                else
                        /bin/cat /etc/passwd | /bin/egrep -v '(root|halt|sync|shutdown)' | /bin/awk -F: '($7 != "/sbin/nologin"){ print $6 }' | while read -r line; do
                                hiddenfiles="$(echo .*)"

                                if [ -z "$hiddenfiles" ]
                                then
                                        echo "There is no hidden files."
                                else
					for file in ${hiddenfiles[*]}
                                        do
                                                chmod g-w $file
                                                chmod o-w $file
                                                echo "User directory $line hidden file $file permission is set as default"
                                        done
                                fi
                        done
                fi
                x=1
                ;;
                n)
                echo "You said -No"
                x=1
                ;;
                q)
                x=1
                echo "Exiting..."
                sleep 2
                ;;
  *)
                clear
                echo "This is not an option"
                sleep 3
                ;;
        esac
done
echo "Check Existence of and Permissions on User .netrc Files"

x=0
while [ $x = 0 ]
do
        clear
        echo "Do you want to set all user .netrc file  permission as default? (y/n) - Press 'q' to quit."
        read answer
        case "$answer" in
                y)
                echo "You said - yes"
                intUserAcc=`/bin/cat /etc/passwd | /bin/egrep -v '(root|halt|sync|shutdown)' | /bin/awk -F: '($7 != "/sbin/nologin"){ print $6 }'`
                if [ -z "$intUserAcc" ]
                then
                        echo "There is no interactive user account"
                else
                        /bin/cat /etc/passwd | /bin/egrep -v '(root|halt|sync|shutdown)' | /bin/awk -F: '($7 != "/sbin/nologin"){ print $6 }' | while read -r line; do
				  permission=`ls -al $line | grep .netrc`
                                if [ -z "$permission" ]
                                then
                                        echo "There is no .netrc file in user directory $line"
                                        echo ' '
                                else
                                        ls -al $line | grep .netrc | while read -r netrc; do
                                                for file in $netrc
                                                do

 cd $line

 if [[ $file = *".netrc"* ]]

 then

         chmod go-rwx $file

         echo "User directory $line .netrc file $file permission is set as default"

 fi
                                                done
                                        done
                                fi
                        done
                fi
                x=1
                ;;
		 n)
                echo "You said -No"
                x=1
                ;;
                q)
                x=1
                echo "Exiting..."
                sleep 2
                ;;
                *)
                clear
                echo "This is not an option"
                sleep 3
                ;;
        esac
done

echo "Check for Presence of User .rhosts Files"
intUserAcc=`/bin/cat /etc/passwd | /bin/egrep -v '(root|halt|sync|shutdown)' | /bin/awk -F: '($7 != "/sbin/nologin"){ print $6 }'`
if [ -z "$intUserAcc" ]
then
        #echo "There is no interactive user account"
        echo ''
else
        /cat /etc/passwd | /egrep -v '(root|halt|sync|shutdown)' | awk -F: '($7 != "/sbin/nologin"){ print $6 }' | while read -r line; do
                #echo "Checking user home directory $line"
		rhostsfile=`ls -al $line | grep .rhosts`
                if  [ -z "$rhostsfile" ]
                then
                        #echo " There is no .rhosts file"
                        echo ''
                else
                        ls -al $line | grep .rhosts | while read -r rhosts; do
                                for file in $rhosts
                                do
                                        if [[ $file = *".rhosts"* ]]
                                        then
                                                #echo " Checking .rhosts file $file"
                                                #check if file created user matches directory user
                                                filecreateduser=$(stat -c %U $line/$file)
                                                if [[ $filecreateduser = *"$line"* ]]
                                                then
 							echo ''
                                                else
							echo ''
                                                        cd $line
							rm $file
                                                fi
                                        fi
                                done
                        done
                fi
        done
fi

echo "Check Groups in /etc/passwd"
x=0
while [ $x = 0 ]
do
        clear
	echo "Groups defined in /etc/passwd file but not in /etc/group file will pose a threat to system security since the group permission are not properly managed."
        echo ' '
	echo " For all groups that are already defined in /etc/passwd, do you want to defined them in /etc/group? (y/n) - Press 'q' to quit."
        read answer
        case "$answer" in
                y)
                echo "You said - yes"
                
		for i in $(cut -s -d: -f4 /etc/passwd | sort -u); do
        		grep -q -P "^.*?:x:$i:" /etc/group
        		if [ $? -ne 0 ]
        		then
				groupadd -g $i group$i
			fi
		done


                x=1
                ;;
                n)
                echo "You said -No"
                x=1
                ;;
                q)
                x=1
                echo "Exiting..."
                sleep 2
                ;;
                *)
                clear
                echo "This is not an option"
                sleep 3
                ;;
        esac
done

echo "Check That Users Are Assigned Valid Home Directories and Home Directory Ownership is Correct"
x=0
while [ $x = 0 ]
do
        clear
	echo "Users without assigned home directories should be removed or assigned a home directory."
	echo ' '
	echo " For all users without assigned home directories, press 'a' to assign a home directory, 'b' to remove user or 'q' to quit."
        read answer
        case "$answer" in
                a)
                echo "You choose to assign a home directory for all users without an assigned home directory."
                cat /etc/passwd | awk -F: '{ print $1,$3,$6 }' | while read user uid dir; do
                        if [ $uid - ge 500 -a ! -d"$dir" -a $user != "nfsnobody" ]
                        then
				mkhomedir_helper $user
                        fi
                done
                x=1
                ;;
                b)
                echo "You choose to remove all users without an assigned home directory."
		cat /etc/passwd | awk -F: '{ print $1,$3,$6 }' | while read user uid dir; do
			if [ $uid - ge 500 -a ! -d"$dir" -a $user != "nfsnobody" ]
			then
				userdel -r -f $user
			fi
		done
		x=1
                ;;
                q)
                x=1
                echo "Exiting..."
                sleep 2
                ;;
                *)
                clear
                echo "This is not an option"
                sleep 3
                ;;
        esac
done

echo "Check for Duplicate UIDs"
echo "No Output = Pass"
cat /etc/passwd | cut -f3 -d":" | sort -n | uniq -c |\
	while read x ; do
	[ -z "${x}" ] && break
	set - $x
	if [ $1 -gt 1 ]; then
		users=`gawk -F: '($3 == n) { print $1 }' n=$2 \/etc/passwd | xargs`
        	echo "Duplicate UID ($2): ${users}"
    	fi
done

echo "Check for Duplicate GIDs"
echo "No Output = Pass"
cat /etc/group | cut -f3 -d":" | sort -n | uniq -c |\
	while read x ; do
	[ -z "${x}" ] && break
	set - $x
	if [ $1 -gt 1 ]; then
		grps=`gawk -F: '($3 == n) { print $1 }' n=$2 \/etc/group | xargs`
		echo "Duplicate GID ($2): ${grps}"
	fi 
done

echo "Check for Duplicate User Names"
echo "No Output = Pass"
cat /etc/passwd | cut -f1 -d":" | sort -n | uniq -c |\
	while read x ; do
	[ -z "${x}" ] && break
	set - $x
	if [ $1 -gt 1 ]; then
		uids=`gawk -F: '($1 == n) { print $3 }' n=$2 \/etc/passwd | xargs`
		echo "Duplicate User Name ($2): ${uids}"
	fi
done

echo "Check for Presence of User .forward Files"
for dir in `/bin/cat /etc/passwd | /bin/awk -F: '{ print $6 }'`; do
	if [ ! -h "$dir/.forward" -a -f "$dir/.forward" ]; then
		chmod u=rw- $dir/.forward
		chmod g=--- $dir/.forward
		chmod o=--- $dir/.forward
		echo "Remediation performed for presence of $dir/.forward file."
		echo "$dir/.forward can only be read and written by the owner only now."
	fi
done

echo "Set Warning Banner for Standard Login Services"
echo "WARNING: UNAUTHORIZED USERS WILL BE PROSECUTED!" > '/etc/motd'

echo "Remove OS Information from Login Warning Banners"
current1=`egrep '(\\v|\\r|\\m|\\s)' /etc/issue`
current2=`egrep '(\\v|\\r|\\m|\\s)' /etc/motd`
current3=`egrep  '(\\v|\\r|\\m|\\s)' /etc/issue.net`

string1="\\v"
string2="\\r"
string3="\\m"
string4="\\s"

if [[ $current1 =~ $string1 || $current1 =~ $string2 || $current1 =~ $string3 || $current1 =~ $string4 ]]; then
        sed -i.bak '/\\v\|\\r\|\\m\|\\s/d' /etc/issue
fi

if [[ $current2 =~ $string1 || $current2 =~ $string2 || $current2 =~ $string3 || $current2 =~ $string4 ]]; then
        sed -i.bak '/\\v\|\\r\|\\m\|\\s/d' /etc/motd
fi


if [[ $current3 =~ $string1 || $current3 =~ $string2 || $current3 =~ $string3 || $current4 =~ $string4 ]]; then
        sed -i.bak '/\\v\|\\r\|\\m\|\\s/d' /etc/issue.net
fi

echo "Enable anacron Daemon"

if rpm -q cronie-anacron
then
    	echo "Remediation passed: Anacron Daemon is installed."
else
    	sudo yum install cronie-anacron -y
fi

if rpm -q cronie-anacron #double checking 
then
	:
else
	echo "It seems as if an error has occured and the Anacron Daemon service cannot be installed. Pleas ensure that you have created a yum repository."
fi

echo "Enable crond Daemon"
checkCrondDaemon=`systemctl is-enabled crond`
if [ "$checkCrondDaemon" = "enabled" ]
then
    	echo "Remedation passed: Crond Daemon is enabled."
else
    	systemctl enable crond
	doubleCheckCrondDaemon=`systemctl is-enabled crond`
	if [ "$doubleCheckCrondDaemon" = "enabled" ]
	then
		:
	else
		echo "It seems as if an error has occurred and crond cannot be enabled. Please ensure that you have a yum repository available and cron service installed (yum install cron -y)."
	fi
fi

echo "Set User/Group Owner and Permission on /etc/anacrontab"
anacrontabFile="/etc/anacrontab"
anacrontabPerm=`stat -c "%a" "$anacrontabFile"`
anacrontabRegex="^[0-7]00$"
if [[ $anacrontabPerm =~ $anacrontabRegex ]]
then
	echo "Remedation passed: The correct permissions has been configured for $anacrontabFile."
else
	sudo chmod og-rwx $anacrontabFile
	anacrontabPermCheck=`stat -c "%a" "$anacrontabFile"`
        anacrontabRegexCheck="^[0-7]00$"
	if [[ $anacrontabPermCheck =~ $anacrontabRegexCheck ]]
	then
		:
	else
		echo "It seems as if an error has occured and the permissions for $anacrontabFile cannot be configured as required."
	fi
fi

anacrontabOwn=`stat -c "%U" "$anacrontabFile"`
if [ $anacrontabOwn = "root" ]
then
	echo "The owner of the file $anacrontabFile is root."
else
	sudo chown root:root $anacrontabFile
	anacrontabOwnCheck=`stat -c "%U" "$anacrontabFile"`
       	if [ $anacrontabOwnCheck = "root" ]
       	then
                :
	else
		echo "It seems as if an error has occured and the owner of the file ($anacrontabFile) cannot be set as root."
        fi
fi

anacrontabGrp=`stat -c "%G" "$anacrontabFile"`
if [ $anacrontabGrp = "root" ]
then
	echo "The group owner of the file $anacrontabFile is root."
else
	sudo chown root:root $anacrontabFile
	anacrontabGrpCheck=`stat -c "%G" "$anacrontabFile"`
        if [ $anacrontabGrpCheck = "root" ]
	then
		: 
	else
		echo "It seems as if an error has occured and the group owner of the $anacrontabFile file cannot be set as root instead."
        fi
fi


echo "Set User/Group Owner and Permission on /etc/crontab"
crontabFile="/etc/crontab"
crontabPerm=`stat -c "%a" "$crontabFile"`
crontabRegex="^[0-7]00$"
if [[ $crontabPerm =~ $crontabRegex ]]
then
	echo "The correct permissions has been set for $crontabFile."
else
	sudo chmod og-rwx $crontabFile
	checkCrontabPerm=`stat -c "%a" "$crontabFile"`
	checkCrontabRegex="^[0-7]00$"
	if [[ $checkCrontabPerm =~ $checkCrontabRegex ]]
	then
		:
	else
		echo "It seems as if an error has occured and the permisions of the file $crontabFile cannot be set as recommended."
	fi
fi

crontabOwn=`stat -c "%U" "$crontabFile"`
if [ $crontabOwn = "root" ]
then
	echo "The owner of the file $crontabFile is root."
else
	sudo chown root:root $crontabFile
	checkCrontabOwn=`stat -c "%U" "$crontabFile"`
	if [ $checkCrontabOwn = "root" ]
	then
        	:
	else
		echo "It seems as if an error has occured and that the owner of the $crontabFile file cannot be set as root instead."
	fi

fi

crontabGrp=`stat -c "%G" "$crontabFile"`
if [ $crontabGrp = "root" ]
then
	echo "The group owner of the file $crontabFile is root."
else
	sudo chown root:root $crontabFile
	checkCrontabGrp=`stat -c "%G" "$crontabFile"`
	if [ $checkCrontabGrp = "root" ]
	then
        	:
	else
		echo "It seems as if an error has occured and that the group owner of the $crontabFile file cannot be set as root instead."
	fi
fi

echo "Set User/Group Owner and Permission on /etc/cron.[hourly,daily,weekly,monthly]"
patchCronHDWMPerm(){
        local cronHDWMType=$1
        local cronHDWMFile="/etc/cron.$cronHDWMType"

	local cronHDWMPerm=`stat -c "%a" "$cronHDWMFile"`
	local cronHDWMRegex="^[0-7]00$"
	if [[ $cronHDWMPerm =~ $cronHDWMRegex ]]
	then
		echo "The correct permissions has been set for $cronHDWMFile."
	else
		sudo chmod og-rwx $cronHDWMFile
		local checkCronHDWMPerm=`stat -c "%a" "$cronHDWMFile"`
	        local checkCronHDWMRegex="^[0-7]00$"
		if [[ $checkCronHDWMPerm =~ $checkCronHDWMRegex ]]
       		then
                	:
       		else
			echo "It seems as if an error has occured and that the permissions for the $cronHDWMFile file cannot be set as recommended."
		fi
	fi

	local cronHDWMOwn=`stat -c "%U" "$cronHDWMFile"`
	if [ $cronHDWMOwn = "root" ]
        then
		echo "The owner of the $cronHDWMFile file is root."
	else
		sudo chown root:root $cronHDWMFile
		local checkCronHDWMOwn=`stat -c "%U" "$cronHDWMFile"`
	        if [ $checkCronHDWMOwn = "root" ]
	        then
        	        :
	        else
			echo "It seems as if an error has occured and that the owner of the $cronHDWMFile cannot be set as root instead."
		fi

	fi

	local cronHDWMGrp=`stat -c "%G" "$cronHDWMFile"`
        if [ $cronHDWMGrp = "root" ]
        then
		echo "The group owner of the $cronHDWMFile file is root."
	else
		sudo chown root:root $cronHDWMFile
		local checkCronHDWMGrp=`stat -c "%G" "$cronHDWMFile"`
	        if [ $checkCronHDWMGrp = "root" ]
	        then
        	        :
       		else
			echo "It seems as if an error has occured and that the group owner of the $cronHDWMFile cannot be set to root instead."
		fi
	fi
}

patchCronHDWMPerm "hourly"
patchCronHDWMPerm "daily"
patchCronHDWMPerm "weekly"
patchCronHDWMPerm "monthly"

echo "Set User/Group Owner and Permission on /etc/cron.d"
cronDFile="/etc/cron.d"
cronDPerm=`stat -c "%a" "$cronDFile"`
cronDRegex="^[0-7]00$"
if [[ $cronDPerm =~ $cronDRegex ]]
then
	echo "The correct permissions has been set for $cronDFile."
else
	sudo chmod og-rwx $cronDFile
	checkCronDPerm=`stat -c "%a" "$cronDFile"`
	checkCronDRegex="^[0-7]00$"
	if [[ $checkCronDPerm =~ $checkCronDRegex ]]
	then
		:
	else
		echo "It seems as if an error has occured and that the recommended permissions for the $cronDFile file cannot be configured."
	fi

fi

cronDOwn=`stat -c "%U" "$cronDFile"`
if [ $cronDOwn = "root" ]
then
	echo "The owner of the $cronDFile file is root."
else
        sudo chown root:root $cronDFile
	checkCronDOwn=`stat -c "%U" "$cronDFile"`
	if [ $checkCronDOwn = "root" ]
	then
        	:
	else
		echo "It seems as if an error has occured and that the owner of the $cronDFile cannot be set as root instead."
	fi
fi

cronDGrp=`stat -c "%G" "$cronDFile"`
if [ $cronDGrp = "root" ]
then
	echo "The group owner of the $cronDFile file is root."
else
	sudo chown root:root $cronDFile
	checkCronDGrp=`stat -c "%G" "$cronDFile"`
	if [ $checkCronDGrp = "root" ]
	then
        	:
	else
		echo "It seems as if an error has occured and that the group owner of the $cronDFile cannot be set as root instead."
	fi
fi

echo "Restrict at Daemon"
atDenyFile="/etc/at.deny"
if [ -e "$atDenyFile" ]
then
    	sudo rm $atDenyFile
else
    	echo "$atDenyFile is deleted or does not exist"
fi

atAllowFile="/etc/at.allow"
if [ -e "$atAllowFile" ]
then
    	atAllowPerm=`stat -c "%a" "$atAllowFile"`
        atAllowRegex="^[0-7]00$"
        if [[ $atAllowPerm =~ $atAllowRegex ]]
        then
            	echo "The correct permissions has been set for $atAllowFile."
        else
            	sudo chmod og-rwx $atAllowFile
		checkAtAllowPerm=`stat -c "%a" "$atAllowFile"`
	        checkAtAllowRegex="^[0-7]00$"
	        if [[ $checkAtAllowPerm =~ $checkAtAllowRegex ]]	
	        then
        	        :
        	else
			echo "It seems as if an error has occured and the recommended permissions cannot be set for the $atAllowFile file."
		fi
        fi

	atAllowOwn=`stat -c "%U" "$atAllowFile"`
        if [ $atAllowOwn = "root" ]
        then
            	echo "The owner of the $atAllowFile is root."
        else
            	sudo chown root:root $atAllowFile
		checkAtAllowOwn=`stat -c "%U" "$atAllowFile"`
	       	if [ $checkAtAllowOwn = "root" ]
	       	then
			:
		else
			echo "It seems as if an error has occured and that the owne of the $overallCounter file cannot be set as root instead."
		fi
        fi

	atAllowGrp=`stat -c "%G" "$atAllowFile"`
        if [ $atAllowGrp = "root" ]
        then
            	echo "The group owner of the $atAllowFile is root."
        else
            	sudo chown root:root $atAllowFile
		checkAtAllowGrp=`stat -c "%G" "$atAllowFile"`
	        if [ $checkAtAllowGrp = "root" ]
	        then
	                :
        	else
			echo "It seems as if an error has occured and that the group owner of the $atAllowFile file cannot as set to root instead."
		fi
        fi
else
    	touch $atAllowFile
	sudo chmod og-rwx $atAllowFile
        checkAtAllowPerm2=`stat -c "%a" "$atAllowFile"`
        checkAtAllowRegex2="^[0-7]00$"
        if [[ $checkAtAllowPerm2 =~ $checkAtAllowRegex2 ]]
        then
		:
	else
		echo "It seems as if an error has occured and the recommended permissions cannot be configured for the $atAllowFile file."
	fi
	
	sudo chown root:root $atAllowFile
        checkAtAllowOwn2=`stat -c "%U" "$atAllowFile"`
        if [ $checkAtAllowOwn2 = "root" ]
        then
               	:
       	else
                echo "It seems as if an error has occured and that the owner of the $atAllowFile file cannot be set as root instead"
       	fi	

	sudo chown root:root $atAllowFile
        checkAtAllowGrp2=`stat -c "%G" "$atAllowFile"`
        if [ $checkAtAllowGrp2 = "root" ]
        then
		:
	else
		echo "It seems as if an error has occured and that the group owner of the $atAllowFile file cannot be set as root instead."
	fi
fi

echo "Restrict at/cron to Authorized Users"
cronDenyFile="/etc/cron.deny"
if [ -e "$cronDenyFile" ]
then
    	sudo rm $cronDenyFile
else
    	echo "$cronDenyFile is deleted or does not exist."
fi

cronAllowFile="/etc/cron.allow"
if [ -e "$cronAllowFile" ]
then
        cronAllowPerm=`stat -c "%a" "$cronAllowFile"`
        cronAllowRegex="^[0-7]00$"
       	if [[ $cronAllowPerm =~ $cronAllowRegex ]]
    	then
                echo "The correct permissions for $cronAllowFile has been configured."
        else
            	sudo chmod og-rwx $cronAllowFile
               	checkCronAllowPerm=$(stat -c "%a" "$atAllowFile")
            	checkCronAllowRegex="^[0-7]00$"
               	if [[ $checkCronAllowPerm =~ $checkCronAllowRegex ]]
               	then
                       	:
               	else
                        echo "It seems as if an error has occured and the recommended permissions cannot be configured for the $cronAllowFile file."
                fi
       	fi

	cronAllowOwn=`stat -c "%U" "$cronAllowFile"`
        if [ $cronAllowOwn = "root" ]
        then
            	echo "The owner of the $cronAllowFile is root."
        else
            	sudo chown root:root $cronAllowFile
                checkCronAllowOwn=`stat -c "%U" "$cronAllowFile"`
                if [ $checkCronAllowOwn = "root" ]
                then
                    	:
                else
                        echo "It seems as if an error has occured and that the owner of the $cronAllowFile file cannot be set as root instead."
                fi
        fi

	cronAllowGrp=`stat -c "%G" "$cronAllowFile"`
        if [ $cronAllowGrp = "root" ]
        then
            	echo "The group owner of the $cronAllowFile is set to root."
        else
            	sudo chown root:root $cronAllowFile
                checkCronAllowGrp=`stat -c "%G" "$cronAllowFile"`
                if [ $checkCronAllowGrp = "root" ]
                then
                    	:
                else
                        echo "It seems as if an error has occured and that the group owner of the $cronAllowFile cannot be set as root instead."
                fi
        fi
else
	touch $cronAllowFile
        sudo chmod og-rwx $cronAllowFile
        checkCronAllowPerm2=`stat -c "%a" "$cronAllowFile"`
        checkCronAllowRegex2="^[0-7]00$"
        if [[ $checkCronAllowPerm2 =~ $checkCronAllowRegex2 ]]
        then
            	:
        else
                echo "It seems as if an error has occured and the recommended permissions cannot be configured for the $cronAllowFIle file."
        fi

        sudo chown root:root $cronAllowFile
        checkCronAllowOwn2=`stat -c "%U" "$cronAllowFile"`
        if [ $checkCronAllowOwn2 = "root" ]
        then
            	:
        else
                echo "It seems as if an error has occured and that the owner of the $cronAllowFile cannot be set as root instead"
        fi

	sudo chown root:root $cronAllowFile
	checkCronAllowGrp2=`stat -c "%G" "$cronAllowFile"`
        if [ $checkCronAllowGrp2 = "root" ]
        then
            	:
        else
		echo "It seems as if an error has occured and that the group owner of the $cronAllowFile cannot be set as root instead."
	fi
fi

echo "Set SSH Protocol to 2"
remsshprotocol=`grep "^Protocol 2" /etc/ssh/sshd_config`
if [ "$remsshprotocol" != "Protocol 2" ]
then
	sed -ie "23s/#//" /etc/ssh/sshd_config
fi

echo "Set LogLevel to INFO"
remsshloglevel=`grep "^LogLevel" /etc/ssh/sshd_config`
if [ "$remsshloglevel" != "LogLevel INFO" ]
then
	sed -ie "43s/#//" /etc/ssh/sshd_config
fi

echo "Set Permissions on /etc/ssh/sshd_config"
remdeterusergroupownership=`grep "^LogLevel" /etc/ssh/sshd_config`
if [ -z "$remdeterusergroupownership" ]
then
	chown root:root /etc/ssh/sshd_config
	chmod 600 /etc/ssh/sshd_config
fi

echo "Disable SSH X11 Forwarding"
remsshx11forwarding=`grep "^X11Forwarding" /etc/ssh/sshd_config`
if [ "$remsshx11forwarding" != "X11Forwarding no" ]
then
	sed -ie "116s/#//" /etc/ssh/sshd_config
	sed -ie "117s/^/#/" /etc/ssh/sshd_config
fi

echo "Set SSH MaxAuthTries to 4 or Less"
maxauthtries=`grep "^MaxAuthTries 4" /etc/ssh/sshd_config`
if [ "$maxauthtries" != "MaxAuthTries 4" ]
then
	sed -ie "50d" /etc/ssh/sshd_config
	sed -ie "50iMaxAuthTries 4" /etc/ssh/sshd_config
fi

echo "Set SSH IgnoreRhosts to Yes"
ignorerhosts=`grep "^IgnoreRhosts" /etc/ssh/sshd_config`
if [ "$ignorerhosts" != "IgnoreRhosts yes" ]
then
	sed -ie "73d" /etc/ssh/sshd_config
	sed -ie "73iIgnoreRhosts yes" /etc/ssh/sshd_config
fi

echo "Set SSH HostbasedAuthentication to No"
hostbasedauthentication=`grep "^HostbasedAuthentication" /etc/ssh/sshd_config`
if [ "$hostbasedauthentication" != "HostbasedAuthentication no" ]
then
	sed -ie "68d" /etc/ssh/sshd_config
	sed -ie "68iHostbasedAuthentication no" /etc/ssh/sshd_config
fi

echo "Disable SSH Root Login"
remsshrootlogin=`grep "^PermitRootLogin" /etc/ssh/sshd_config`
if [ "$remsshrootlogin" != "PermitRootLogin no" ]
then
	sed -ie "48d" /etc/ssh/sshd_config
	sed -ie "48iPermitRootLogin no" /etc/ssh/sshd_config
fi

echo "Set SSH PermitEmptyPasswords to No"
remsshemptypswd=`grep "^PermitEmptyPasswords" /etc/ssh/sshd_config`
if [ "$remsshemptypswd" != "PermitEmptyPasswords no" ]
then
	sed -ie "77d" /etc/ssh/sshd_config
	sed -ie "77iPermitEmptyPasswords no" /etc/ssh/sshd_config
fi

echo "Use Only Approved Cipher in Counter Mode"
remsshcipher=`grep "Ciphers" /etc/ssh/sshd_config`
if [ "$remsshcipher" != "Ciphers aes128-ctr,aes192-ctr,aes256-ctr" ]
then
	sed -ie "36d" /etc/ssh/sshd_config
	sed -ie "36iCiphers aes128-ctr,aes192-ctr,aes256-ctr" /etc/ssh/sshd_config
fi

echo "Set Idle Timeout Interval for User Login"
remsshcai=`grep "^ClientAliveInterval" /etc/ssh/sshd_config`
remsshcacm=`grep "^ClientAliveCountMax" /etc/ssh/sshd_config`

if [ "$remsshcai" != "ClientAliveInterval 300" ]
then
	sed -ie "127d" /etc/ssh/sshd_config
	sed -ie "127iClientAliveInterval 300" /etc/ssh/sshd_config
fi

if [ "$remsshcacm" != "ClientAliveCountMax 0" ]
then
	sed -ie "128d" /etc/ssh/sshd_config
	sed -ie "128iClientAliveCountMax 0" /etc/ssh/sshd_config
fi

echo "Limit Access via SSH"
remsshalwusrs=`grep "^AllowUsers" /etc/ssh/sshd_config`
remsshalwgrps=`grep "^AllowGroups" /etc/ssh/sshd_config`
remsshdnyusrs=`grep "^DenyUsers" /etc/ssh/sshd_config`
remsshdnygrps=`grep "^DenyGroups" /etc/ssh/sshd_config`

if [ -z "$remsshalwusrs" -o "$remsshalwusrs" == "AllowUsers[[:space:]]" ]
then
	echo "AllowUsers user1" >> /etc/ssh/sshd_config
fi

if [ -z "$remsshalwgrps" -o "$remsshalwgrps" == "AllowUsers[[:space:]]" ]
then
	echo "AllowGroups group1" >> /etc/ssh/sshd_config
fi

if [ -z "$remsshdnyusrs" -o "$remsshdnyusrs" == "AllowUsers[[:space:]]" ]
then
	echo "DenyUsers user2 user3" >> /etc/ssh/sshd_config
fi

if [ -z "$remsshdnygrps" -o "$remsshdnygrps" == "AllowUsers[[:space:]]" ]
then
	echo "DenyGroups group2" >> /etc/ssh/sshd_config
fi

echo "Set SSH Banner"
remsshbanner=`grep "Banner" /etc/ssh/sshd_config | awk '{ print $2 }'`

if [ "$remsshbanner" == "/etc/issue.net" -o "$remsshbanner" == "/etc/issue" ]
then
	sed -ie "138d" /etc/ssh/sshd_config
	sed -ie "138iBanner /etc/issue.net" /etc/ssh/sshd_config
fi

echo "Upgrade Password Hashing Algorithm to SHA-512"
checkPassAlgo=`authconfig --test | grep hashing | grep sha512`
checkPassRegex=".*sha512"
if [[ $checkPassAlgo =~ $checkPassRegex ]]
then
    	echo "The password hashing algorithm is set to SHA-512 as recommended."
else
    	authconfig --passalgo=sha512 --update
	doubleCheckPassAlgo2=`authconfig --test | grep hashing | grep sha512`
	doubleCheckPassRegex2=".*sha512"
	if [[ $doubleCheckPassAlgo2 =~ $doubleCheckPassRegex2 ]]
	then
    		echo "The password hashing algorithm is set to SHA-512 as recommended."
		cat /etc/passwd | awk -F: '($3 >= 1000 && $1 != "test") { print $1 }' | xargs -n 1 chage -d 0
		if [ $? -eq 0 ]
		then
			echo "Users will be required to change their password upon the next log in session."
		else
			echo "It seems as if error has occured and that the userID cannot be immediately expired. After a password hashing algorithm update, it is essential to ensure that all the users have changed their passwords."
		fi
	else
		echo "It seems as if an error has occured and the password hashing algorithm cannot be set as SHA-512."
	fi
fi

echo " Set Password Creation Requirement Parameters Using pam_pwquality"
pampwquality=`grep pam_pwquality.so /etc/pam.d/system-auth`
pampwqualityrequisite=`grep "password    requisite" /etc/pam.d/system-auth`
correctpampwquality="password    requisite     pam_pwquality.so try_first_pass local_users_only retry=3 authtok_type="
if [[ $pampwquality == $correctpampwquality ]]
then
	echo "No remediation needed."
else
	if [[ -n $pampwqualityrequisite ]]
	then
		sed -i 's/.*requisite.*/password    requisite     pam_pwquality.so try_first_pass local_users_only retry=3 authtok_type=/' /etc/pam.d/system-auth
		echo "Remediation completed."
	else
		echo $correctpampwquality >> /etc/pam.d/system-auth
		echo "Remediation completed."
	fi
fi

minlen=`grep "minlen" /etc/security/pwquality.conf`
dcredit=`grep "dcredit" /etc/security/pwquality.conf`
ucredit=`grep "ucredit" /etc/security/pwquality.conf`
ocredit=`grep "ocredit" /etc/security/pwquality.conf`
lcredit=`grep "lcredit" /etc/security/pwquality.conf`
correctminlen="# minlen = 14"
correctdcredit="# dcredit = -1"
correctucredit="# ucredit = -1"
correctocredit="# ocredit = -1"
correctlcredit="# lcredit = -1"


if [[ $minlen == $correctminlen && $dcredit == $correctdcredit && $ucredit == $correctucredit && $ocredit == $correctocredit && $lcredit == $correctlcredit ]]
then
	echo "No Remediation needed."
else
	sed -i -e 's/.*minlen.*/# minlen = 14/' -e 's/.*dcredit.*/# dcredit = -1/' -e  's/.*ucredit.*/# ucredit = -1/' -e 's/.*ocredit.*/# ocredit = -1/' -e 's/.*lcredit.*/# lcredit = -1/' /etc/security/pwquality.conf
	echo "Remediation completed."
fi

echo "Set Lockout for Failed Password Attempts"
faillockpassword=`grep "pam_faillock" /etc/pam.d/password-auth`
faillocksystem=`grep "pam_faillock" /etc/pam.d/system-auth`

read -d '' correctpamauth << "BLOCK"
auth        required      pam_faillock.so preauth silent audit deny=5 unlock_time=900
auth        [default=die] pam_faillock.so authfail audit deny=5
auth        sufficient    pam_faillock.so authsucc audit deny=5
account     required      pam_faillock.so
BLOCK


if [[ $faillocksystem == "$correctpamauth" && $faillockpassword == "$correctpamauth" ]]
then
	echo "No remediation needed."
elif [[ $faillocksystem == "$correctpamauth" && $faillockpassword != "$correctpamauth" ]]
then
	if [[ -n $faillockpassword ]]
	then
		sed -i '/pam_faillock.so/d' /etc/pam.d/password-auth
		sed -i -e '5i auth        required      pam_faillock.so preauth silent audit deny=5 unlock_time=900' -e '7i auth        [default=die] pam_faillock.so authfail audit deny=5' -e '8i auth        sufficient    pam_faillock.so authsucc audit deny=5' -e '10i account     required      pam_faillock.so' /etc/pam.d/password-auth
		echo "Remediation completed."
	else
		sed -i -e '5i auth        required      pam_faillock.so preauth silent audit deny=5 unlock_time=900' -e '7i auth        [default=die] pam_faillock.so authfail audit deny=5' -e '8i auth        sufficient    pam_faillock.so authsucc audit deny=5' -e '10i account     required      pam_faillock.so' /etc/pam.d/password-auth
		echo "Remediation completed."
	fi
elif [[ $faillocksystem != "$correctpamauth" && $faillockpassword == "$correctpamauth" ]]
then
	if [[ -n $faillocksystem ]]
	then
		sed -i '/pam_faillock.so/d' /etc/pam.d/system-auth
		sed -i -e '5i auth        required      pam_faillock.so preauth silent audit deny=5 unlock_time=900' -e '7i auth        [default=die] pam_faillock.so authfail audit deny=5' -e '8i auth        sufficient    pam_faillock.so authsucc audit deny=5' -e '10i account     required      pam_faillock.so' /etc/pam.d/system-auth
		echo "Remediation completed."
	else
		sed -i -e '5i auth        required      pam_faillock.so preauth silent audit deny=5 unlock_time=900' -e '7i auth        [default=die] pam_faillock.so authfail audit deny=5' -e '8i auth        sufficient    pam_faillock.so authsucc audit deny=5' -e '10i account     required      pam_faillock.so' /etc/pam.d/system-auth
		echo "Remediation completed."
	fi
else
	if [[ -n $faillocksystem && -z $faillockpassword ]]
	then
		sed -i '/pam_faillock.so/d' /etc/pam.d/system-auth
		sed -i -e '5i auth        required      pam_faillock.so preauth silent audit deny=5 unlock_time=900' -e '7i auth        [default=die] pam_faillock.so authfail audit deny=5' -e '8i auth        sufficient    pam_faillock.so authsucc audit deny=5' -e '10i account     required      pam_faillock.so' /etc/pam.d/system-auth
		sed -i -e '5i auth        required      pam_faillock.so preauth silent audit deny=5 unlock_time=900' -e '7i auth        [default=die] pam_faillock.so authfail audit deny=5' -e '8i auth        sufficient    pam_faillock.so authsucc audit deny=5' -e '10i account     required      pam_faillock.so' /etc/pam.d/password-auth
		echo "Remediation completed."
	elif [[ -z $faillocksystem && -n $faillockpassword ]]
	then
		sed -i '/pam_faillock.so/d' /etc/pam.d/password-auth
		sed -i -e '5i auth        required      pam_faillock.so preauth silent audit deny=5 unlock_time=900' -e '7i auth        [default=die] pam_faillock.so authfail audit deny=5' -e '8i auth        sufficient    pam_faillock.so authsucc audit deny=5' -e '10i account     required      pam_faillock.so' /etc/pam.d/password-auth
		sed -i -e '5i auth        required      pam_faillock.so preauth silent audit deny=5 unlock_time=900' -e '7i auth        [default=die] pam_faillock.so authfail audit deny=5' -e '8i auth        sufficient    pam_faillock.so authsucc audit deny=5' -e '10i account     required      pam_faillock.so' /etc/pam.d/system-auth
		echo "Remediation completed."
	elif [[ -n $faillocksystem && -n $faillockpassword ]]
	then
		sed -i '/pam_faillock.so/d' /etc/pam.d/system-auth
		sed -i -e '5i auth        required      pam_faillock.so preauth silent audit deny=5 unlock_time=900' -e '7i auth        [default=die] pam_faillock.so authfail audit deny=5' -e '8i auth        sufficient    pam_faillock.so authsucc audit deny=5' -e '10i account     required      pam_faillock.so' /etc/pam.d/system-auth
		sed -i '/pam_faillock.so/d' /etc/pam.d/password-auth
		sed -i -e '5i auth        required      pam_faillock.so preauth silent audit deny=5 unlock_time=900' -e '7i auth        [default=die] pam_faillock.so authfail audit deny=5' -e '8i auth        sufficient    pam_faillock.so authsucc audit deny=5' -e '10i account     required      pam_faillock.so' /etc/pam.d/password-auth
		echo "Remediation completed."
	else
		sed -i -e '5i auth        required      pam_faillock.so preauth silent audit deny=5 unlock_time=900' -e '7i auth        [default=die] pam_faillock.so authfail audit deny=5' -e '8i auth        sufficient    pam_faillock.so authsucc audit deny=5' -e '10i account     required      pam_faillock.so' /etc/pam.d/system-auth
		sed -i -e '5i auth        required      pam_faillock.so preauth silent audit deny=5 unlock_time=900' -e '7i auth        [default=die] pam_faillock.so authfail audit deny=5' -e '8i auth        sufficient    pam_faillock.so authsucc audit deny=5' -e '10i account     required      pam_faillock.so' /etc/pam.d/password-auth
		echo "Remediation completed."
	fi
fi

echo "Limit Password Reuse"
pamlimitpw=`grep "remember" /etc/pam.d/system-auth`
existingpamlimitpw=`grep "password.*sufficient" /etc/pam.d/system-auth`
if [[ $pamlimitpw == *"remember=5"* ]]
then
	echo "No remediation needed."
else
	if [[ -n $existingpamlimitpw ]]
	then
		sed -i 's/password.*sufficient.*/password    sufficient    pam_unix.so sha512 shadow nullok remember=5 try_first_pass use_authtok/' /etc/pam.d/system-auth
		echo "Remediation completed."
else
	sed -i '/password/a password sufficient pam_unix.so remember=5' /etc/pam.d/system-auth
	echo "Remediation completed." 
	fi
fi 

echo "Restrict root Login to System Console"
systemConsole="/etc/securetty"
systemConsoleCounter=0
while read -r line; do
	if [ -n "$line" ]
	then
		[[ "$line" =~ ^#.*$ ]] && continue
		if [ "$line" == "vc/1" ] || [ "$line" == "tty1" ]
		then
			systemConsoleCounter=$((systemConsoleCounter+1))
		else	
			systemConsoleCounter=$((systemConsoleCounter+1))
		fi
	fi
done < "$systemConsole"

read -d '' correctsyscon << "BLOCKED"
vc/1
tty1
BLOCKED


if [ $systemConsoleCounter != 2 ]
then
	echo "$correctsyscon" > /etc/securetty
	echo "Remediation completed."
else
	echo "No remediation needed."
fi

echo "Restrict Access to the su Command"
pamsu=`grep pam_wheel.so /etc/pam.d/su | grep required`
if [[ $pamsu =~ ^#auth.*required ]]
then
	sed -i 's/#.*pam_wheel.so use_uid/auth            required        pam_wheel.so use_uid/' /etc/pam.d/su
	echo "Remediation completed."
else
	echo "No remediation needed."
fi

pamwheel=`grep wheel /etc/group`
if [[ $pamwheel =~ ^wheel.*root ]]
then
	echo "No remediation is needed."
else
	usermod -aG wheel root
	echo "Remediation completed."
fi

echo "This remediation is performed at $datetime"
read -n 1 -s -r -p "Press any key to exit!"
kill -9 $PPID
