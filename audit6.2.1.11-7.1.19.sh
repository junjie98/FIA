#!/bin/bash
GREEN="\033[0;32m"
RED="\033[0;31m"
NC="\033[0m"
bold=$(tput bold)
normal=$(tput sgr0)
# Audit Script for RHEL 7 based on CIS BenchMarks
# Script misc. section

trap '' 2 20
trap '' SIGTSTP

# Check if script is executed by root
if [ "$EUID" -ne 0 ]
	then echo "Please run this script as root"
	exit
fi

#6.2.1.10
chklogins=`grep logins /etc/audit/audit.rules`
loginfail=`grep "\-w /var/log/faillog -p wa -k logins" /etc/audit/audit.rules`
loginlast=`grep "\-w /var/log/lastlog -p wa -k logins" /etc/audit/audit.rules`
logintally=`grep "\-w /var/log/tallylog -p wa -k logins" /etc/audit/audit.rules`

if [ -z "$loginfail" -o -z "$loginlast" -o -z "$logintally" ]
then
        echo "FAILED - Login and logout events not recorded."
else
        echo "PASSED - Login and logout events recorded."
fi

#6.2.1.11
chksession=`egrep 'wtmp|btmp|utmp' /etc/audit/audit.rules`
sessionwtmp=`egrep "\-w /var/log/wtmp -p wa -k session" /etc/audit/audit.rules`
sessionbtmp=`egrep "\-w /var/log/btmp -p wa -k session" /etc/audit/audit.rules`
sessionutmp=`egrep "\-w /var/run/utmp -p wa -k session" /etc/audit/audit.rules`

if [ -z "$sessionwtmp" -o -z "$sessionbtmp" -o -z "sessionutmp" ]
then
        echo "FAILED - Session initiation information not collected."
else
        echo "PASSED - Session initiation information is collected."
fi

#6.2.1.12
chkpermission64=`grep perm_mod /etc/audit/audit.rules`
permission1=`grep "\-a always,exit -F arch=b64 -S chmod -S fchmod -S fchmodat -F auid>=1000 -F auid!=4294967295 -k perm_mod" /etc/audit/audit.rules`
permission2=`grep "\-a always,exit -F arch=b32 -S chmod -S fchmod -S fchmodat -F auid>=1000 -F
auid!=4294967295 -k perm_mod" /etc/audit/audit.rules`
permission3=`grep "\-a always,exit -F arch=b64 -S chown -S fchown -S fchownat -S|chown -F auid>=1000 -F auid!=4294967295 -k perm_mod" /etc/audit/audit.rules`
permission4=`grep "\-a always,exit -F arch=b32 -S chown -S fchown -S fchownat -S|chown -F auid>=1000 -F auid!=4294967295 -k perm_mod" /etc/audit/audit.rules`
permission5=`grep "\-a always,exit -F arch=b64 -S setxattr -S lsetxattr -S fsetxattr -S removexattr -S lremovexattr -S fremovexattr -F auid>=1000 -Fauid!=4294967295 -k perm_mod" /etc/audit/audit.rules`
permission6=`grep "\-a always,exit -F arch=b32 -S setxattr -S lsetxattr -S
 fsetxattr -S removexattr -S lremovexattr -S fremovexattr -F auid>=1000 -F
auid!=4294967295 -k perm_mod" /etc/audit/audit.rules`

if [ -z "$permission1" -o -z "$permission2" -o -z permission3 -o -z permission4 -o -z permission5 -o -z permission6 ]
then
        echo "FAILED - Permission modifications not recorded."

else
        echo "PASSED - Permission modification are recorded."
fi

#6.2.1.13
chkaccess=`grep access /etc/audit/audit.rules`
access1=`grep "\-a always,exit -F arch=b64 -S creat -S open -S openat -S truncate -S ftruncate -F exit=-EACCES -F auid>=1000 -F auid!=4294967295 - k access" /etc/audit/audit.rules`
access2=`grep "\-a always,exit -F arch=b32 -S creat -S open -S openat -S truncate -S ftruncate -F exit=-EACCES -F auid>=1000 -F auid!=4294967295 - k access" /etc/audit/audit.rules`
access3=`grep "\-a always,exit -F arch=b64 -S creat -S open -S openat -S truncate -S ftruncate -F exit=-EPERM -F auid>=1000 -F auid!=4294967295 - k access" /etc/audit/audit.rules`
access4=`grep "\-a always,exit -F arch=b32 -S creat -S open -S openat -S truncate -S ftruncate -F exit=-EPERM -F auid>=1000 -F auid!=4294967295 - k access" /etc/audit/audit.rules`
access5=`grep "\-a always,exit -F arch=b32 -S creat -S open -S openat -S truncate -S ftruncate -F exit=-EACCES -F auid>=1000 -F auid!=4294967295 - k access" /etc/audit/audit.rules`
access6=`grep "\-a always,exit -F arch=b32 -S creat -S open -S openat -S truncate -S ftruncate -F exit=-EPERM -F auid>=1000 -F auid!=4294967295 - k access" /etc/audit/audit.rules`

if [ -z "$access1" -o -z "$access2" -o -z "$access3" -o -z "$access4" -o -z "$access5" -o -z "$access6" ]
then
        echo "FAILED - Unsuccesful attempts to access files."

else
        echo "PASSED - Successful attempts to access files."
fi

#6.2.1.14 Collect Use of Privileged Commands
find / -xdev \( -perm -4000 -o -perm -2000 \) -type f | awk '{print "-a always,exit-F path=" $1 " -F perm=x -F auid>=1000 -F auid!=4294967295 -k privileged" }' > /tmp/1.log

checkpriviledge=`cat /tmp/1.log`
cat /etc/audit/audit.rules | grep -- "$checkpriviledge" > /tmp/2.log

checkpriviledgenotinfile=`grep -F -x -v -f /tmp/2.log /tmp/1.log`

if [ -n "$checkpriviledgenotinfile" ]
then
	echo "FAIL - Privileged Commands not in audit"
else
	echo "PASS - Privileged Commands in audit"
fi

rm /tmp/1.log
rm /tmp/2.log

#6.2.1.15 Collect Successful File System Mounts
bit64mountb64=`grep "\-a always,exit -F arch=b64 -S mount -F auid>=1000 -F auid!=4294967295 -k mounts" /etc/audit/audit.rules`
bit64mountb32=`grep "\-a always,exit -F arch=b32 -S mount -F auid>=1000 -F auid!=4294967295 -k mounts" /etc/audit/audit.rules`
bit32mountb32=`grep "\-a always,exit -F arch=b32 -S mount -F auid>=1000 -F auid!=4294967295 -k mounts" /etc/audit/audit.rules`

if [ -z "$bit64mountb64" -o -z "$bit64mountb32" -o -z "$bit32mountb32" ]
then
	echo "FAIL - To determine filesystem mounts" 
else
	echo "PASS - To determine filesystem mounts"
fi

#6.2.1.16 Collect File Delection Events by User
bit64delb64=`grep "\-a always,exit -F arch=b64 -S unlink -S unlinkat -S rename -S renameat -F auid>=1000 -F auid!=4294967295 -k delete" /etc/audit/audit.rules`
bit64delb32=`grep "\-a always,exit -F arch=b32 -S unlink -S unlinkat -S rename -S renameat -F auid>=1000 -F auid!=4294967295 -k delete" /etc/audit/audit.rules`
bit32delb32=`grep "\-a always,exit -F arch=b32 -S unlink -S unlinkat -S rename -S renameat -F auid>=1000 -F auid!=4294967295 -k delete" /etc/audit/audit.rules`

if [ -z "$bit64delb64" -o -z "$bit64delb32" -o -z "$bit32delb32" ]
then
	echo "FAIL - To determine the file delection event by user"
else
	echo "PASS - To determine the file delection event by user"
fi

#6.2.1.17 Collect Changes to System Administration Scope
chkscope=`grep scope /etc/audit/audit.rules`
sudoers='-w /etc/sudoers -p wa -k scope'

if [ -z "$chkscope" -o "$chkscope" != "$sudoers" ]
then
	echo "FAIL - To unauthorize change to scope of system administrator activity"
else
	echo "PASS - To unauthorize change to scope of system administrator activity"
fi

#6.2.1.18 
chkadminrules=`grep actions /etc/audit/audit.rules`
adminrules='-w /var/log/sudo.log -p wa -k actions'

if [ -z "$chkadminrules" -o "$chkadminrules" != "$adminrules" ]
then 
	echo "FAILED - Administrator activity not recorded"
else
	echo "PASSED - Administrator activity recorded"
fi

#6.2.1.19
chkmod1=`grep "\-w /sbin/insmod -p x -k modules" /etc/audit/audit.rules`
chkmod2=`grep "\-w /sbin/rmmod -p x -k modules" /etc/audit/audit.rules`
chkmod3=`grep "\-w /sbin/modprobe -p x -k modules" /etc/audit/audit.rules`
chkmod4=`grep "\-a always,exit -F arch=b64 -S init_module -S delete_module -k modules" /etc/audit/audit.rules`

if [ -z "$chkmod1" -o -z "$chkmod2" -o -z "$chkmod3" -o -z "$chkmod4" ]
then
	echo "FAILED - Kernel module not recorded"
else
	echo "PASSED - Kernel module recorded"
fi

#6.2.1.20
chkimmute=`grep "^-e 2" /etc/audit/audit.rules`
immute='-e 2'

if [ -z "$chkimmute" -o "$chkimmute" != "$immute" ]
then
	echo "FAILED - Audit configuration is not immutable"
else
	echo "PASSED - Audit configuration immutable"
fi

#6.2.1.21
chkrotate1=`grep "/var/log/messages" /etc/logrotate.d/syslog`
chkrotate2=`grep "/var/log/secure" /etc/logrotate.d/syslog`
chkrotate3=`grep "/var/log/maillog" /etc/logrotate.d/syslog`
chkrotate4=`grep "/var/log/spooler" /etc/logrotate.d/syslog`
chkrotate5=`grep "/var/log/boot.log" /etc/logrotate.d/syslog`
chkrotate6=`grep "/var/log/cron" /etc/logrotate.d/syslog`

if [ -z "chkrotate1" -o -z "$chkrotate2" -o -z "$chkrotate3" -o -z "$chkrotate4" -o -z "$chkrotate5" -o -z "$chkrotate6" ]
then
	echo "FAILED - System logs not rotated"
else
	echo "PASSED - System logs recorded"
fi

printf "\n"

echo "7.1 Set Password Expiration Days"

value=$(cat /etc/login.defs | grep "^PASS_MAX_DAYS" | awk '{ print $2 }')

standard=90 

if [ ! $value = $standard ]; then
  echo "Audit status: FAILED!"
elif [ $value = $standard ]; then
  echo "Audit status: PASSED!"
else
  echo "ERROR: FATAL ERROR, CONTACT SYSTEM ADMINISTRATOR!"
fi
#########################################################################
echo "7.2 Set Password Change Minimum Number of Days"
value=$(cat /etc/login.defs | grep "^PASS_MIN_DAYS" | awk '{ print $2 }')

standard=7 

if [ ! $value = $standard ]; then
	echo "Audit status: FAILED!"
elif [ $value = $standard ]; then
	echo "Audit status: PASSED!"
else
	echo ERROR: "FATAL ERROR, CONTACT SYSTEM ADMINISTRATOR!"
fi
#########################################################################
echo "7.3 Set Password Expiring Warning Days"
value=$(cat /etc/login.defs | grep "^PASS_WARN_AGE" | awk '{ print $2 }')

standard=7 

if [ ! $value = $standard ]; then
	echo "Audit status: FAILED!"
elif [ $value = $standard ]; then
	echo "Audit status: PASSED!"
else
	echo ERROR: "FATAL ERROR, CONTACT SYSTEM ADMINISTRATOR!"
fi
#########################################################################
#7.4 Disable System Accounts

echo "7.4 Disable System Accounts"

current=$(egrep -v "^\+" /etc/passwd | awk -F: '($1!="root" && $1!="sync" && $1!="shutdown" && $1!="halt" && $3<1000 && $7!="/sbin/nologin" && $7!="/bin/false") { print $1 }')

if [ -z "$current" ]; then
	echo "Audit status: PASSED!"
elif [ ! -z "$current" ]; then
	echo "Audit status: FAILED!"
else
	echo "FATAL ERROR. PLEASE CONTACT YOUR SYSTEM ADMINISTRATOR!"
fi
#########################################################################
echo "7.5 Set Default Group for root Account"

current=$(grep "^root:" /etc/passwd | cut -f4 -d:)

if [ "$current" == 0 ]; then
        echo "Audit status: PASSED!"
else
        echo "Audit status: FAILED!"
fi
#########################################################################
echo "7.6 Set Default umask for Users"

current=$(egrep -h "\s+umask ([0-7]{3})" /etc/bashrc /etc/profile | awk '{print $2}')

counter=0

for line in ${current}
do
	if [ "${line}" != "077" ] 
	then
       		((counter++))	
	fi
done

if [ ${counter} == 0 ]
then 
	echo "Audit status: PASSED!"
else     
	echo "Audit status: FAILED!"
fi
#########################################################################
echo "7.7 Lock Inactive User Accounts"

current=$(useradd -D | grep INACTIVE | awk -F= '{print $2}')

if [ "${current}" -le 30 ] && [ "${current}" -gt 0 ]
then
        echo "Audit status: PASSED!"
else
        echo "Audit status: FAILED!"
fi
#########################################################################
echo "7.8 Ensure Password Fields Are Not Empty"
current=$(cat /etc/shadow | awk -F: '($2 == "") { print $1 }')

if [ "$current" = "" ];then
	echo "Audit status: PASSED!"
else
	echo "Audit status: FAILED!" 
fi
#########################################################################
echo "7.9 Verify No Legacy "+" Entries Exist in /etc/passwd, /etc/shadow and /etc/group files"

passwd=$(grep '^+:' /etc/passwd) 
shadow=$(grep '^+:' /etc/shadow)
group=$(grep '^+:' /etc/group)

if [ "$passwd" == "" ]  && [ "$shadow" == "" ] && [ "$group" == "" ];then
	echo "Audit Status: PASSED!"
else
	echo "Audit Status: FAILED!"
fi
#########################################################################
echo "7.10 Verify No UID 0 Accounts Exist Other Than Root"

current=$(/bin/cat /etc/passwd | /bin/awk -F: '($3 ==0) { print $1 }')

if [ "$current" = "root" ];then
	echo "Audit status: PASSED!"
else
	echo "Audit status: FAILED!"
fi
#########################################################################
echo "7.11 Ensure root PATH Integrity"

check=0

#Check for Empty Directory in PATH (::)
if [ "`echo $PATH | grep ::`" != "" ]
then
	#echo "Empty Directory in PATH (::)"
	((check++))
fi

#Check for Trailing : in PATH
if [ "`echo $PATH | grep :$`" != "" ]
then
	#echo "Trailing : in PATH"
	((check++))
fi

p=`echo $PATH | sed -e 's/::/:/' -e 's/:$//' -e 's/:/ /g'`
set -- $p
while [ "$1" != "" ]
do
	#Check if PATH contains .
        if [ "$1" = "." ]
        then
		#echo "PATH contains ."
		((check++))
		shift
		continue
        fi
	
	#Check if PATH entry is a directory
        if [ -d $1 ]
        then
                dirperm=`ls -ldH $1 | cut -f1 -d" "`
                #Check if Group Write permission is set on directory
		if [ `echo $dirperm | cut -c6` != "-" ]
                then
			#echo "Group Write permission set on directory $1"
			((check++))
                fi
		#Check if Other Write permission is set on directory
                if [ `echo $dirperm | cut -c9` != "-" ]
		then
			#echo "Other Write permission set on directory $1"
			((check++))
                fi
		
		#Check if PATH entry is owned by root
                dirown=`ls -ldH $1 | awk '{print $3}'`
                if [ "$dirown" != "root" ]
                then
                       #echo $1 is not owned by root
			((check++))
                fi
        else
		#echo $1 is not a directory
		((check++))
        fi
	shift
done

#echo ${check}
if [ ${check} == 0 ]
then
	echo "Audit status: PASSED!"
elif [ ${check} != 0 ]
then
	echo "Audit status: FAILED!"
else
	echo "FATAL ERROR. PLEASE CONTACT YOUR SYSTEM ADMINISTRATOR!"
fi

printf "\n"

####################################### 7.12 #######################################

echo "------------------------------------------------------------------------------------------"
echo ' '
echo "${bold}7.12 Check Permissions on User Home Directories${normal}"
echo ' '
intUserAcc="$(/bin/cat /etc/passwd | /bin/egrep -v '(root|halt|sync|shutdown)' | /bin/awk -F: '($7 != "/sbin/nologin"){ print $6 }')"

if [ -z "$intUserAcc" ]
then
        echo "There is no interactive user account."
        echo ' '
else
        /bin/cat /etc/passwd | /bin/egrep -v '(root|halt|sync|shutdown)' | /bin/awk -F: '($7 != "/sbin/nologin"){ print $6 }' | while read -r line; do

                echo "Checking user home directory $line"
                permission="$(ls -ld $line)"
                echo " Permission is ${permission:0:10}"
                ## check 6th field ##
                if [ ${permission:5:1} == *"w"* ]
                then
                        echo -e "${RED} 6th field of permission is w ${NC}"
                else
                        echo -e "${GREEN} 6th field of permission is '-' ${NC}"
                fi

                ## check 8th field ##
                if [ ${permission:7:1} == "-" ]
                then
                        echo -e "${GREEN} 8th field of permission is '-' ${NC}"
                else
                        echo -e "${RED} 8th field of permission is not '-' ${NC}"
 fi

                ## check 9th field ##
                if [ ${permission:8:1} == "-" ]
                then
                        echo -e "${GREEN} 9th field of permission is '-' ${NC}"
                else
                        echo -e "${RED} 9th field of permission is not '-' ${NC}"
                fi

                ## check 10th field ##
                if [ ${permission:9:1} == "-" ]
                then
                        echo -e "${GREEN} 10th field of permission is '-' ${NC}"
                else
                        echo -e "${RED} 10th field of permission is not '-' ${NC}"
                fi
                echo " "
        done
fi

####################################### 7.13 #######################################

echo "------------------------------------------------------------------------------------------"
echo ' '
echo "${bold}7.13 Check User Dot File Permissions${normal}"
echo ' '

intUserAcc="$(/bin/cat /etc/passwd | /bin/egrep -v '(root|halt|sync|shutdown)' | /bin/awk -F: '($7 != "/sbin/nologin"){ print $6 }')"

if [ -z "$intUserAcc" ]
then
        echo "There is no interactive user account."
        echo ' '
else
        /bin/cat /etc/passwd | /bin/egrep -v '(root|halt|sync|shutdown)' | /bin/awk -F: '($7 != "/sbin/nologin"){ print $6 }' | while read -r line; do

                echo "Checking hidden files in user home directory $line"
                cd $line
                hiddenfiles="$(echo .*)"

                if [ -z "$hiddenfiles" ]
                then
echo " There is no hidden files"
                else
                        for file in ${hiddenfiles[*]}
                        do
                                permission="$(stat -c %A $file)"
                                echo " Checking hidden file $file"
                                echo "  Permission is $permission"

                                ## check 6th field ##
                                if [ ${permission:5:1} == *"w"* ]
                                then
                                        echo -e " ${RED} 6th field of permission is 'w' ${NC}"
                                else
                                        echo -e " ${GREEN} 6th field of permission is not 'w' ${NC}"
                                fi

                                ## check 9th field ##
                                if [ ${permission:8:1} == *"w"* ]
                                then
                                        echo -e " ${RED} 9th field of permission is 'w' ${NC}"
                                else
                                        echo -e " ${GREEN} 9th field of permission is not 'w' ${NC}"
                                fi
 echo ' '
                        done
                fi
        done
fi

####################################### 7.14 #######################################

echo "------------------------------------------------------------------------------------------"
echo ' '
echo "${bold}7.14 Check Existence of and Permissions on User .netrc Files${normal}"
echo ' '
intUserAcc="$(/bin/cat /etc/passwd | /bin/egrep -v '(root|halt|sync|shutdown)' | /bin/awk -F: '($7 != "/sbin/nologin"){ print $6 }')"

if [ -z "$intUserAcc" ]
then
        echo " There is no interactive user account."
        echo ' '
else
        /bin/cat /etc/passwd | /bin/egrep -v '(root|halt|sync|shutdown)' | /bin/awk -F: '($7 != "/sbin/nologin"){ print $6 }' | while read -r line; do
 echo "Checking user home directory $line"
                permission="$(ls -al $line | grep .netrc)"
                if  [ -z "$permission" ]
                then
                        echo " There is no .netrc file"
                        echo ' '
                else
                        ls -al $line | grep .netrc | while read -r netrc; do
                                echo " $netrc"

                                ## check 5th field ##
                                if [ ${netrc:4:6} == "------" ]
                                then
                                        echo -e " ${GREEN} 5th-10th field of permission is '------' ${NC}"
                                else
                                        echo -e " ${RED} 5th-10th field of permission is not '------' ${NC}"
                                fi

                                echo ' '
                        done
                fi
        done
fi

#################################### 7.15 ####################################

echo "------------------------------------------------------------------------------------------"
echo ' '
echo "${bold}7.15 Check for Presence of User .rhosts Files${normal}"
echo ' '

intUserAcc="$(/bin/cat /etc/passwd | /bin/egrep -v '(root|halt|sync|shutdown)' | /bin/awk -F: '($7 != "/sbin/nologin"){ print $6 }')"

if [ -z "$intUserAcc" ]
then
        echo "There is no interactive user account."
        echo ' '
else
        /bin/cat /etc/passwd | /bin/egrep -v '(root|halt|sync|shutdown)' | /bin/awk -F: '($7 != "/sbin/nologin"){ print $6 }' | while read -r line; do
                echo "Checking user home directory $line"
                rhostsfile="$(ls -al $line | grep .rhosts)"

 if  [ -z "$rhostsfile" ]
                then
                        echo " There is no .rhosts file"
                        echo ' '
                else
                        ls -al $line | grep .rhosts | while read -r rhosts; do
                                for file in $rhosts
                                do
                                        if [[ $file = *".rhosts"* ]]
                                        then
                                                echo " Checking .rhosts file $file"
                                                #check if file created user matches directory user
                                                filecreateduser=$(stat -c %U $line/$file)
                                                if [[ $filecreateduser = *"$line"* ]]
                                                then
                                                       echo -e "${GREEN} $file created user is the same user in the directory${NC}"

 echo ' '
                                                else
                                                        echo -e "${RED} $file created user is not the same in the directory. This file should be deleted! ${NC}"

 echo ' '
                                                fi
                                        fi
                                done                    
                        done
                fi
        done
fi

echo "------------------------------------------------------------------------------------------"
echo ' '
echo "${bold}End of verification.${normal}"
echo ' '

####################################### 7.16 ######################################

echo "------------------------------------------------------------------------------------------"
echo ' '
echo "${bold}7.16 Check Groups in /etc/passwd${normal}"
echo ' '

for i in $(cut -s -d: -f4 /etc/passwd | sort -u); do
	grep -q -P "^.*?:x:$i:" /etc/group
	if [ $? -ne 0 ]
	then
		echo -e "${RED}Group $i is referenced by /etc/passwd but does not exist in /etc/group${NC}"
	else
		echo -e "${GREEN}Group $i is referenced by /etc/passwd and exist in /etc/group${NC}"
	fi
done

####################################### 7.17 ######################################

echo "------------------------------------------------------------------------------------------"
echo ' '
echo "${bold}7.17 Check That Users Are Assigned Valid Home Directories && Home Directory Ownership is Correct${normal}"
echo ' '

cat /etc/passwd | awk -F: '{ print $1,$3,$6 }' | while read user uid dir; do

	#checking validity of  user assigned home directories
	if [ $uid -ge 500 -a ! -d"$dir" -a $user != "nfsnobody" ]
	then
		echo -e "${RED}The home directory $dir of user $user does not exist.${NC}"
		
	else
		echo -e "${GREEN}The home directory $dir of user $user exist.${NC}"
	fi

	#checking user home directory ownership
	if [ $uid -ge 500 -a -d"$dir" -a $user != "nfsnobody" ]
	then
		owner=$(stat -L -c "%U" "$dir")
		if [ "$owner" != "$user" ]
		then
			echo -e "${RED}The home directory ($dir) of user $user is owned by $owner.${NC}"
		else

			echo -e "${GREEN}Then home directory ($dir) of user $user is owned by $owner.${NC}"
		fi
	fi
		
	
done

####################################### 7.18 ######################################

echo "------------------------------------------------------------------------------------------"
echo ' '
echo "${bold}7.18 Check for Duplicate UIDs ${normal}"
echo ' ' 

/bin/cat /etc/passwd | /bin/cut -f3 -d":" | /bin/sort -n | /usr/bin/uniq -c | while read x; do
	[ -z "${x}" ] && break
	set - $x
	if [ $1 -gt 1 ]
	then
		users=`/bin/gawk -F: '($3 == n) { print $1 }' n=$2 /etc/passwd | /user/bin/xargs`
		echo -e "${RED}Duplicate UID $2: ${users}${NC}"
	else
		echo -e "${GREEN}There is no duplicate UID $2 ${NC}" 
	fi

done

####################################### 7.19 ######################################

echo "------------------------------------------------------------------------------------------"
echo ' '
echo "${bold}7.19 Check for Duplicate GIDs ${normal}"
echo ' '

/bin/cat /etc/group | /bin/cut -f3 -d"." | /bin/sort -n | /usr/bin/uniq -c | while read x; do
	[ -z "${x}" ] && break
	set - $x
	if [ $1 -gt 1 ]
	then
		grp=`/bin/gawk -F: '($3 == n) { print $1 }' n=$2 /etc/group | xargs`
		echo -e "${RED}Duplicate GID $2: $grp$.{NC}"
	else
		echo -e "${GREEN}There is no duplicated GID $2 ${NC}"
	fi
done