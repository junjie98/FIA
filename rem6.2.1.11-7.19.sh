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

#6.2.1.11
sessionwtmp=`egrep '\-w /var/log/wtmp -p wa -k session' /etc/audit/audit.rules`
sessionbtmp=`egrep '\-w /var/log/btmp -p wa -k session' /etc/audit/audit.rules`
sessionutmp=`egrep '\-w /var/run/utmp -p wa -k session' /etc/audit/audit.rules`

if [ -z "$sessionwtmp" -o -z "$sessionbtmp" -o -z "$sessionutmp" ]
then 
	if [ -z "$sessionwtmp"]
	then 
		echo "-w /var/log/wtmp -p wa -k session" >> /etc/audit/audit.rules
	fi
	if [ -z "$sessionbtmp"]
	then 
		echo "-w /var/log/btmp -p wa -k session" >> /etc/audit/audit.rules
	fi
	if [ -z "$sessionutmp"]
	then
		echo "-w /var/run/utmp -p wa -k session" >> /etc/audit/audit.rules
	fi
fi

pkill -HUP -P 1 auditd

#6.2.1.12
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
	fi

	if [ -z "$permission2" ]
	then 
		echo "-a always,exit -F arch=b32 -S chmod -S fchmod -S fchmodat -F auid>=1000 -F auid!=4294967295 -k perm_mod" >> /etc/audit/audit.rules
	fi
	if [ -z "$permission3" ]
	then 
		echo "-a always,exit -F arch=b64 -S chown -S fchown -S fchownat -S lchown -F auid>=1000 -F auid!=4294967295 -k perm_mod" >> /etc/audit/audit.rules
	fi
	if [ -z "$permission4" ]
	then
		echo "-a always,exit -F arch=b32 -S chown -S fchown -S fchownat -S lchown -F auid>=1000 -F auid!=4294967295 -k perm_mod" >> /etc/audit/audit.rules
	fi
	if [ -z "$permission5" ]
	then 
		echo "-a always,exit -F arch=b64 -S setxattr -S lsetxattr -S fsetxattr -S removexattr -S lremovexattr -S fremovexattr -F auid>=1000 -F auid!=4294967295 -k perm_mod" >> /etc/audit/audit.rules
	fi
	if [ -z "$permission6" ]
	then 
		echo "-a always,exit -F arch=b32 -S setxattr -S lsetxattr -S fsetxattr -S removexattr -S lremovexattr -S fremovexattr -F auid>=1000 -F auid!=4294967295 -k perm_mod" >> /etc/audit/audit.rules

	fi
fi
pkill -P 1 -HUP auditd

#6.2.1.13
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
	fi
	if [ -z "$access2" ]
	then 
		echo "-a always,exit -F arch=b32 -S creat -S open -S openat -S truncate -S ftruncate -F exit=-EACCES -F auid>=1000 -F auid!=4294967295 - k access" >> /etc/audit/audit.rules
	fi
	if [ -z "$access3" ]
	then
		echo "-a always,exit -F arch=b64 -S creat -S open -S openat -S truncate -S ftruncate -F exit=-EPERM -F auid>=1000 -F auid!=4294967295 - k access" >>  /etc/audit/audit.rules
	fi
	if [ -z "$access4" ]
	then 
		echo "-a always,exit -F arch=b32 -S creat -S open -S openat -S truncate -S ftruncate -F exit=-EPERM -F auid>=1000 -F auid!=4294967295 - k access" >>  /etc/audit/audit.rules
	fi
	if [ -z "$access5" ]
	then
		echo "-a always,exit -F arch=b32 -S creat -S open -S openat -S truncate -S ftruncate -F exit=-EACCES -F auid>=1000 -F auid!=4294967295 - k access" >>  /etc/audit/audit.rules
	fi
	if [ -z "$access6" ]
	then 
		echo "-a always,exit -F arch=b32 -S creat -S open -S openat -S truncate -S ftruncate -F exit=-EPERM -F auid>=1000 -F auid!=4294967295 - k access" >>  /etc/audit/audit.rules
	fi
fi

pkill -P 1 -HUP auditd

#6.2.1.14 Collect Use of Privileged Commands
find / -xdev \( -perm -4000 -o -perm -2000 \) -type f | awk '{print "-a always,exit-F path=" $1 " -F perm=x -F auid>=1000 -F auid!=4294967295 -k privileged" }' > /tmp/1.log
checkpriviledge=`cat /tmp/1.log`
cat /etc/audit/audit.rules | grep -- "$checkpriviledge" > /tmp/2.log
checkpriviledgenotinfile=`grep -F -x -v -f /tmp/2.log /tmp/1.log`

if [ -n "$checkpriviledgenotinfile" ]
then
	echo "$checkpriviledgenotinfile" >> /etc/audit/audit.rules
fi

rm /tmp/1.log
rm /tmp/2.log

#6.2.1.15 Collect Successful File System Mounts
bit64mountb64=`grep "\-a always,exit -F arch=b64 -S mount -F auid>=1000 -F auid!=4294967295 -k mounts" /etc/audit/audit.rules`
bit64mountb32=`grep "\-a always,exit -F arch=b32 -S mount -F auid>=1000 -F auid!=4294967295 -k mounts" /etc/audit/audit.rules`
bit32mountb32=`grep "\-a always,exit -F arch=b32 -S mount -F auid>=1000 -F auid!=4294967295 -k mounts" /etc/audit/audit.rules`

if [ -z "$bit64mountb64" ]
then
	echo "-a always,exit -F arch=b64 -S mount -F auid>=1000 -F auid!=4294967295 -k mounts" >> /etc/audit/audit.rules
fi

if [ -z "$bit64mountb32" ]
then
	echo "-a always,exit -F arch=b32 -S mount -F auid>=1000 -F auid!=4294967295 -k mounts" >> /etc/audit/audit.rules
fi

pkill -HUP -P 1 auditd

if [ -z "$bit32mountb32" ]
then
	echo "-a always,exit -F arch=b32 -S mount -F auid>=1000 -F auid!=4294967295 -k mounts" >> /etc/audit/audit.rules
fi

pkill -HUP -P 1 auditd

#2.6.1.16 Collect File Delection Events by User
bit64delb64=`grep "\-a always,exit -F arch=b64 -S unlink -S unlinkat -S rename -S renameat -F auid>=1000 -F auid!=4294967295 -k delete" /etc/audit/audit.rules`
bit64delb32=`grep "\-a always,exit -F arch=b32 -S unlink -S unlinkat -S rename -S renameat -F auid>=1000 -F auid!=4294967295 -k delete" /etc/audit/audit.rules`
bit32delb32=`grep "\-a always,exit -F arch=b32 -S unlink -S unlinkat -S rename -S renameat -F auid>=1000 -F auid!=4294967295 -k delete" /etc/audit/audit.rules`

if [ -z "$bit64delb64" ]
then
	echo "-a always,exit -F arch=b64 -S unlink -S unlinkat -S rename -S renameat -F auid>=1000 -F auid!=4294967295 -k delete" >> /etc/audit/audit.rules
fi

if [ -z "$bit64delb32" ]
then
	echo "-a always,exit -F arch=b32 -S unlink -S unlinkat -S rename -S renameat -F auid>=1000 -F auid!=4294967295 -k delete" >> /etc/audit/audit.rules
fi

pkill -HUP -P 1 auditd

if [ -z "$bit32delb32" ]
then
	echo "-a always,exit -F arch=b32 -S unlink -S unlinkat -S rename -S renameat -F auid>=1000 -F auid!=4294967295 -k delete" >> /etc/audit/audit.rules
fi

pkill -P 1 -HUP auditd

#6.2.1.17 Collect Changes to System Administrator Scope
sudoers=`grep "\-w /etc/sudoers -p wa -k scope" /etc/audit/audit.rules`

if [ -z "$sudoers" ]
then
	echo "-w /etc/sudoers -p wa -k scope" >> /etc/audit/audit.rules
fi
pkill -HUP -P 1 auditd

#6.2.1.18
remauditrules=`grep actions /etc/audit/audit.rules`
auditrules='-w /var/log/sudo.log -p wa -k actions'

if [ -z "$remauditrules" -o "$remauditrules" != "$auditrules" ] 
then
	echo "$auditrules" >> /etc/audit/audit.rules
fi

pkill -HUP -P 1 auditd

#6.2.1.19
remmod1=`grep "\-w /sbin/insmod -p x -k modules" /etc/audit/audit.rules`
remmod2=`grep "\-w /sbin/rmmod -p x -k modules" /etc/audit/audit.rules`
remmod3=`grep "\-w /sbin/modprobe -p x -k modules" /etc/audit/audit.rules`
remmod4=`grep "\-a always,exit -F arch=b64 -S init_module -S delete_module -k modules" /etc/audit/audit.rules`

if [ -z "$remmod1" -o -z "$remmod2" -o -z "$remmod3" -o -z "$remmod4" -o -z "$remmod5" ]
then
	if [ -z "$remmod1" ]
	then
		echo "-w /sbin/insmod -p x -k modules" >> /etc/audit/audit.rules
	fi

	if [ -z "$remmod2" ]
	then	
		echo "-w /sbin/rmmod -p x -k modules" >> /etc/audit/audit.rules
	fi

	if [ -z "$remmod3" ]
	then
		echo "-w /sbin/modprobe -p x -k modules" >> /etc/audit/audit.rules
	fi

	if [ -z "$remmod4" ]
	then
		echo "-a always,exit -F arch=b64 -S init_module -S delete_module -k modules" >> /etc/audit/audit.rules
	fi
fi

#6.2.1.20
remimmute=`grep "^-e 2" /etc/audit/audit.rules`
immute='-e 2'

if [ -z "$remimmute" -o "$remimmute" != "$immute" ]
then
	echo "$immute" >> /etc/audit/audit.rules
fi

#6.2.1.21
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
		echo "/var/log/cron" //etc/logrotate.d/syslog
	fi
fi

pkill -P 1 -HUP auditd

---------------------------------------------------------------------------------------------------------------
echo "Current Remediation Process: 7.1 Set Password Expiration Days"

current=$(cat /etc/login.defs | grep "^PASS_MAX_DAYS" | awk '{ print $2 }')
standard=90 #change this value according to the enterprise's required standard
if [ ! $current = $standard ]; then
  sed -i "s/^PASS_MAX_DAYS.*99999/PASS_MAX_DAYS $standard/" /etc/login.defs | grep "^PASS_MAX_DAYS.*$standard"
fi

---------------------------------------------------------------------------------------------------------------

echo "Current Remediation Process: 7.2 Set Password Change Minimum Number of Days"

current=$(cat /etc/login.defs | grep "^PASS_MIN_DAYS" | awk '{ print $2 }')
standard=7 #change this value according to the enterprise's required standard
if [ ! $current = $standard ]; then
	sed -i "s/^PASS_MIN_DAYS.*0/PASS_MIN_DAYS $standard/" /etc/login.defs | grep "^PASS_MIN_DAYS.*$standard"
fi

---------------------------------------------------------------------------------------------------------------

echo "Current Remediation Process: 7.3 Set Password Expiring Warning Days"

current=$(cat /etc/login.defs | grep "^PASS_WARN_AGE" | awk '{ print $2 }')
standard=7 #change this value according to the enterprise's required standard
if [ ! $current = $standard ]; then
	sed -i "s/^PASS_WARN_AGE.*0/PASS_WARN_AGE $standard/" /etc/login.defs | grep "^PASS_WARN_AGE.*$standard"
fi

---------------------------------------------------------------------------------------------------------------

echo "Current Remediation Process: 7.4 Disable System Accounts"

for user in `awk -F: '($3 < 1000) { print $1 }' /etc/passwd` ; do 
	if [ $user != "root" ]; then 
		usermod -L $user &> /dev/null 
		if [ $user != "sync" ] && [ $user != "shutdown" ] && [ $user != "halt" ]; then
			usermod -s /sbin/nologin $user &> /dev/null
			fi 
		fi 
	done

---------------------------------------------------------------------------------------------------------------

echo "Current Remediation Process: 7.5 Set Default Group for root Account"
 
current=$(grep "^root:" /etc/passwd | cut -f4 -d:)
  
if [ "$current" == 0 ]; then
    echo "Default Group for rooot Account is already set correctly"
    exit 0
else
    usermod -g 0 root
    echo "Default Group for root Account is modified successfully"
fi

---------------------------------------------------------------------------------------------------------------

echo "Current Remediation Process: 7.6 Set Default umask for Users"

remedy=$(egrep -h "\s+umask ([0-7]{3})" /etc/bashrc /etc/profile | awk '{ print $2 }')

if [ "$remedy" != 077 ];then 
	sed -i 's/022/077/g' /etc/profile /etc/bashrc
	sed -i 's/002/077/g' /etc/profile /etc/bashrc
fi

---------------------------------------------------------------------------------------------------------------

echo "Current Remediation Process: 7.7 Lock Inactive User Accounts"

useradd -D -f 30

---------------------------------------------------------------------------------------------------------------

echo "Current Remediation Process: 7.8 Ensure Password Fields are Not Empty"

current=$(cat /etc/shadow | awk -F: '($2 == ""){print $1}')

for line in ${current}
do
	/usr/bin/passwd -l ${line}	
done

---------------------------------------------------------------------------------------------------------------

echo "Current Remediation Process: 7.9 Verify No Legacy "+" Entries Exist in /etc/passwd,/etc/shadow,/etc/group"

passwd=$(grep '^+:' /etc/passwd)
shadow=$(grep '^+:' /etc/shadow)
group=$(grep '^+:' /etc/group)

for accounts in $passwd
do
  	if [ "$accounts" != "" ];then
                userdel --force $accounts
                groupdel --force $accounts
fi
done

---------------------------------------------------------------------------------------------------------------

echo "Current Remediation Process: 7.10 Verify No UID 0 Accounts Exist Other Than Root"

remedy=$(/bin/cat /etc/passwd | /bin/awk -F: '($3 == 0) { print $1 }')

for accounts in $remedy
do
	if [ "$accounts" != "root" ];then
		userdel --force $accounts
		groupdel --force $accounts
fi
done

####################################### 7.12 ######################################

x=0
while [ $x = 0 ]
do
        clear
        echo "Do you want to set all user home directory permission as default? (y/n) - Press 'q' to quit."
        read answer
        case "$answer" in
                y)
                echo "You said - yes"
                intUserAcc="$(/bin/cat /etc/passwd | /bin/egrep -v '(root|halt|sync|shutdown)' | /bin/awk -F: '($7 != "/sbin/nologin"){ print $6 }')"
                if [ -z "$intUserAcc" ]
                then
                        echo "There is no interactive user account."
                        echo ' '
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

####################################### 7.13 #######################################

x=0
while [ $x = 0 ]
do
        clear
        echo "Do you want to set all user hidden file permission as default? (y/n) - Press 'q' to quit."
        read answer
        case "$answer" in
                y)
                echo "You said - yes"
                intUserAcc="$(/bin/cat /etc/passwd | /bin/egrep -v '(root|halt|sync|shutdown)' | /bin/awk -F: '($7 != "/sbin/nologin"){ print $6 }')"
                if [ -z "$intUserAcc" ]
                then
                        echo "There is no interactive user account."
                        echo ' '
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

####################################### 7.14 #######################################

x=0
while [ $x = 0 ]
do
        clear
        echo "Do you want to set all user .netrc file  permission as default? (y/n) - Press 'q' to quit."
        read answer
        case "$answer" in
                y)
                echo "You said - yes"
                intUserAcc="$(/bin/cat /etc/passwd | /bin/egrep -v '(root|halt|sync|shutdown)' | /bin/awk -F: '($7 != "/sbin/nologin"){ print $6 }')"
                if [ -z "$intUserAcc" ]
                then
                        echo "There is no interactive user account."
                        echo ' '
                else
                        /bin/cat /etc/passwd | /bin/egrep -v '(root|halt|sync|shutdown)' | /bin/awk -F: '($7 != "/sbin/nologin"){ print $6 }' | while read -r line; do
				  permission="$(ls -al $line | grep .netrc)"
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


####################################### 7.15 #######################################

intUserAcc="$(/bin/cat /etc/passwd | /bin/egrep -v '(root|halt|sync|shutdown)' | /bin/awk -F: '($7 != "/sbin/nologin"){ print $6 }')"
if [ -z "$intUserAcc" ]
then
        #echo "There is no interactive user account."
        echo ''
else
        /bin/cat /etc/passwd | /bin/egrep -v '(root|halt|sync|shutdown)' | /bin/awk -F: '($7 != "/sbin/nologin"){ print $6 }' | while read -r line; do
                #echo "Checking user home directory $line"
		rhostsfile="$(ls -al $line | grep .rhosts)"
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
#echo -e "${GREEN} $file created user is the same user in the directory${NC}"

 echo ''
                                                else

 #echo -e "${RED} $file created user is not the same in the directory. This file should be deleted! ${NC}"

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

####################################### 7.16 ######################################

echo "Remediation for 7.16 groups in /etc/passwd"
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
                		#echo -e "${RED}Group $i is referenced by /etc/passwd but does not exist in /etc/group${NC}"
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

####################################### 7.17 ######################################

echo "Remediation for 7.17 users without valid home directories"
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

echo "Remediation for 7.17 For users without ownership for its home directory"
x=0
while [ $x = 0 ]
do
        clear
        echo "For new users, the home directory on the server is automatically created with BUILTIN\Administrators set as owner. Hence, these users might not have ownership over its home directory."
        echo ' '
        echo " Do you want to set ownership for users without ownership over its home directory? (y/n) -- Press 'q' to quit."
        read answer
        case "$answer" in
                y)
                echo "You have said - yes."
		cat /etc/passwd | awk -F: '{ print $1,$3,$6 }' | while read user uid dir; do
                        if [ $uid -ge 500 -a -d"$dir" -a $user != "nfsnobody" ]
                        then
				sudo chown $user: $dir
                        fi
                done
                x=1
                ;;
                n)
                echo "You have said - no."
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