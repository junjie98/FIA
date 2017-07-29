#!/bin/bash

trap '' 2 20
trap '' SIGTSTP

# Check if script is executed by root
if [ "$EUID" -ne 0 ]
	then echo "Please run this script as root"
	exit
fi

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