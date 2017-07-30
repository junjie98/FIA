#!/bin/bash
# Audit Script for RHEL 7 based on CIS BenchMarks
# Script misc. section

trap '' 2 20
trap '' SIGTSTP

# Check if script is executed by root
if [ "$EUID" -ne 0 ]
	then echo "Please run this script as root"
	exit
fi

datetime=`date +"%m%d%y-%H%M"`

#7.20 - Check that reserved UIDs are assigned to only system accounts
echo "7.20 Check that reserved UIDs are assigned to only system accounts."

systemaccount=(root bin daemon adm lp sync shutdown halt mail news uucp operator games gopher ftp nobody nscd vcsa rpc mailnull smmsp pcap ntp dbus avahi sshd rpcuser nfsnobody haldaemon avahi-autoipd distcache apache oprofile webalizer dovecot squid named xfs gdm sabayon usbmuxd rtkit abrt saslauth pulse postfix tcpdump systemd-network tss radvd [51]=qemu)

nameCounter=0
systemNameFile="/etc/passwd"
while IFS=: read -r f1 f2 f3 f4 f5 f6 f7
do
	if [[ $f3 -lt 500 ]]
	then
		for i in ${systemaccount[*]}
		do
			if [[ $f1 == $i ]]
			then
				nameCounter=$((nameCounter+1))
			else
				nameCounter=$((nameCounter+0))
			fi
		done

		if [[ $nameCounter < 1 ]]
		then
			echo "User '$f1' is not a system account but has a reserved UID of $f3."
		fi
		nameCounter=0
	fi
done <"$systemNameFile"

#7.21 - Duplicate User Names
echo ""

echo "7.21 Check for duplicate user names."

cat /etc/passwd | cut -f1 -d":" | /bin/sort -n | /usr/bin/uniq -c |
while read x ; do
[ -z "${x}" ] && break
set - $x
if [ $1 -gt 1 ]; then
uids=`/bin/gawk -F: '($1 == n) { print $3 }' n=$2 /etc/passwd | xargs`
echo "There are $1 duplicate user name titled '$2' found in the system and its respective UIDs are ${uids}."
fi
done


#7.22 - Duplicate Group Names
echo ""

echo "7.22 Check for duplicate group names."

cat /etc/group | cut -f1 -d":" | /bin/sort -n | /usr/bin/uniq -c | 
while read x ; do
[ -z "${x}" ] && break
set - $x
if [ $1 -gt 1 ]; then
gids=`/bin/gawk -F: '($1 == n) { print $3 }' n=$2 /etc/group | xargs`
echo "There are $1 duplicate group name titled '$2' found in the system and its respective UIDs are ${gids}."
fi
done


#7.23 - Check for presence of user .forward files
echo ""

echo "7.23 Check for presence of user ./forward files."

for dir in `/bin/cat /etc/passwd | /bin/awk -F: '{ print $6 }'`; do
if [ ! -h "$dir/.forward" -a -f "$dir/.forward" ]; then 
echo ".forward file titled '$dir/.forward' found in the system."
fi
done

# 8.1 Set Warning Banner for Standard Login Services
current=`cat /etc/motd`

standard="WARNING: UNAUTHORIZED USERS WILL BE PROSECUTED!"

if [ "$current" == "$standard" ]; then
        echo "$count. Set Warning Banner for Standard Login Services - PASSED"
	((count++))
else
        echo "$count. Set Warning Banner for Standard Login Services - FAILED"
	((count++))
fi

# 8.2 Remove OS Information from Login Warning Banners
current1=`egrep '(\\v|\\r|\\m|\\s)' /etc/issue`
current2=`egrep '(\\v|\\r|\\m|\\s)' /etc/motd`
current3=`egrep '(\\v|\\r|\\m|\\s)' /etc/issue.net`

string1="\\v"
string2="\\r"
string3="\\m"
string4="\\s"

if [[ $current1 =~ $string1 || $current1 =~ $string2 || $current1 = ~$string3 || $current1 =~ $string4 ]]; then
        echo "$count. /etc/issue - FAILED"
	((count++))
else
        echo "$count. /etc/issue - PASSED"
	((count++))
fi

if [[ $current2 =~ $string1 || $current2 =~ $string2 || $current2 = ~$string3 || $current2 =~ $string4 ]]; then
        echo "$count. /etc/motd - FAILED"
	((count++))
else
        echo "$count. /etc/motd - PASSED"
	((count++))
fi

if [[ $current3 =~ $string1 || $current3 =~ $string2 || $current3 = ~$string3 || $current4 =~ $string4 ]]; then
        echo "$count. /etc/issue.net - FAILED"
	((count++))
else
        echo "$count. /etc/issue.net - PASSED"
	((count++))
fi

printf "\n"
count=1
echo "Configure cron and anacron"
#Check whether Anacron Daemon is enabled or not
if rpm -q cronie-anacron
then
	echo "$count. Anacron Daemon has been installed - PASSED"
	((count++))
else
	echo "$count. Please ensure that you have Anacron Daemon has been installed - FAILED"
	((count++))
fi

#Check if Crond Daemon is enabled
checkCronDaemon=`systemctl is-enabled crond`
if [[ $checkCronDaemon == "enabled" ]]
then
	echo "$count. Crond Daemon has been enabled - PASSED"
	((count++))
else
	echo "$count. Please ensure that you have enabled crond Daemon - FAILED"
	((count++))
fi

#Check if the correct permissions is configured for /etc/anacrontab
anacrontabFile="/etc/anacrontab"
if [ -e "$anacrontabFile" ]
then
	echo "The Anacrontab file ($anacrontabFile) exists."
	
	anacrontabPerm=`stat -c "%a" "$anacrontabFile"`
	anacrontabRegex="^[0-7]00$"
	if [[ $anacrontabPerm =~ $anacrontabRegex ]]
	then
		echo "$count. Permissions has been set correctly for $anacrontabFile - PASSED"
		((count++))
	else
		echo "$count. Ensure that the permissions has been set correctly for $anacrontabFile. - FAILED"
		((count++))
	fi

	anacrontabOwn=`stat -c "%U" "$anacrontabFile"`
	if [ $anacrontabOwn == "root" ]
	then
		echo "$count. Owner of the file ($anacrontabFile): $anacrontabOwn"
		((count++))
	else
		echo "$count. Owner of the file ($anacrontabFile): $anacrontabOwn"
		((count++))
	fi

	anacrontabGrp=`stat -c "%G" "$anacrontabFile"`
	if [ $anacrontabGrp == "root" ]
	then
		echo "$count. Group owner of the file ($anacrontabFile): $anacrontabGrp"
		((count++))
	else
		echo "$count. Group owner of the file ($anacrontabFile): $anacrontabGrp. Please ensure that the group owner is root instead"
		((count++))
	fi
else
	echo "$count. The Anacrontab file does not exist. Please ensure that you have Anacron Daemon installed"
	((count++))
fi

#Check if the correct permissions has been configured for /etc/crontab
crontabFile="/etc/crontab"
if [ -e "$crontabFile" ]
then
	crontabPerm=`stat -c "%a" "$crontabFile"`
	crontabRegex="^[0-7]00$"
	if [[ $crontabPerm =~ $crontabRegex ]]
	then
		echo "$count. Permissions has been set correctly for $crontabFile - PASSED"
		((count++))
	else
		echo "$count. Ensure that the permissions has been set correctly for $crontabFile - FAILED"
		((count++))
	fi

	crontabOwn=`stat -c "%U" "$crontabFile"`
	if [ $crontabOwn == "root" ]
	then
		echo "$count. Owner of the file ($crontabFile): $crontabOwn - PASSED"
		((count++))
	else
		echo "$count. Owner of the file ($crontabFile): $crontabOwn. Please ensure that the owner of the file is root instead - FAILED"
		((count++))
	fi

	crontabGrp=`stat -c "%G" "$crontabFile"`
	if [ $crontabGrp == "root" ]
	then
		echo "$count. Group owner of the file ($crontabFile): $crontabGrp"
		((count++))
	else
		echo "$count. Group owner of the file ($crontabFIle): $crontabGrp. Please ensure that the group owner of the file is root instead"
		((count++))
	fi

else
	echo "$count. The crontab file ($crontabFile) does not exist"
	((count++))
fi

#Check if the correct permissions has been set for /etc/cron.XXXX
checkCronHDWMPerm(){
	local cronHDWMType=$1
	local cronHDWMFile="/etc/cron.$cronHDWMType"

	if [ -e "$cronHDWMFile" ]
	then
		local cronHDWMPerm=`stat -c "%a" "$cronHDWMFile"`
		local cronHDWMRegex="^[0-7]00$"
		if [[ $cronHDWMPerm =~ $cronHDWMRegex ]]
		then
			echo "$count. Permissions has been set correctly for $cronHDWMFile - PASSED"
			((count++))
		else
			echo "$count. Ensure that the permissions has been set correctly for $cronHDWMFile - FAILED"
			((count++))
		fi

		local cronHDWMOwn=`stat -c "%U" "$cronHDWMFile"`
		if [ $cronHDWMOwn = "root" ]
		then
			echo "$count. Owner of the file ($cronHDWMFile): $cronHDWMOwn - PASSED"
			((count++))
		else
			echo "$count. Owner of the file ($cronHDWMFile): $cronHDWMOwn. Please ensure that the owner of the file is root instead - FAILED"
			((count++))
		fi

		local cronHDWMGrp=`stat -c "%G" "$cronHDWMFile"`
		if [ $cronHDWMGrp = "root" ]
		then
			echo "$count. Group Owner of the file ($cronHDWMFile): $cronHDWMGrp - PASSED"
			((count++))
		else
			echo "$count. Group Owner of the file ($cronHDWMFile): $cronHDWMGrp. Please ensure that the group owner of the file is root instead - FAILED"
			((count++))
		fi
	else
		echo "$count. File ($cronHDWMFile) does not exist"
		((count++))
	fi	
}

checkCronHDWMPerm "hourly"
checkCronHDWMPerm "daily"
checkCronHDWMPerm "weekly"
checkCronHDWMPerm "monthly"

#Check if the permissions has been set correctly for /etc/cron.d
cronDFile="/etc/cron.d"
if [ -e "$cronDFile" ]
then
	echo "The cron.d file ($cronDFile) exists."
	cronDPerm=`stat -c "%a" "$cronDFile"`
	cronDRegex="^[0-7]00$"
	if [[ $cronDPerm =~ $cronDRegex ]]
	then
		echo "$count. Permissions has been set correctly for $cronDFile - PASSED"
		((count++))
	else
		echo "$count. Ensure that the permissions has been set correctly for $cronDFile - FAILED"
		((count++))
	fi

	cronDOwn=`stat -c "%U" "$cronDFile"`
	if [ $cronDOwn = "root" ]
	then
		echo "$count. Owner of the file ($cronDFile): $cronDOwn - PASSED"
		((count++))
	else
		echo "$count. Owner of the file ($cronDFile): $cronDOwn. Please ensure that the owner of the file is root instead - FAILED"
		((count++))
	fi

	cronDGrp=`stat -c "%G" "$cronDFile"`
	if [ $cronDGrp = "root" ]
	then
		echo "$count. Group owner of the file ($cronDFile): $cronDGrp - PASSED"
		((count++))
	else
		echo "$count. Group owner of the file ($cronDFile): $cronDGrp. Please ensure that the group owner of the file is root instead"
		((count++))
	fi
else
	echo "$count. The cron.d file ($cronDFile) does not exist"
	((count++))
fi

#Check if /etc/at.deny is deleted and that a /etc/at.allow exists and check the permissions of the /etc/at.allow file
atDenyFile="/etc/at.deny"
if [ -e "$atDenyFile" ]
then
	echo "$count. Please ensure that the file $atDenyFile is deleted - FAILED"
	((count++))
else
	echo "$count. $atDenyFile is deleted as recommended - PASSED"
	((count++))
fi

atAllowFile="/etc/at.allow"
if [ -e "$atAllowFile" ]
then
        atAllowPerm=`stat -c "%a" "$atAllowFile"`
        atAllowRegex="^[0-7]00$"
        if [[ $atAllowPerm =~ $atAllowRegex ]]
        then
            	echo "$count. Permissions has been set correctly for $atAllowFile - PASSED"
		((count++))
        else
            	echo "$count. Ensure that the permissions has been set correctly for $atAllowFile - FAILED"
		((count++))
        fi

	atAllowOwn=`stat -c "%U" "$atAllowFile"`
        if [ $atAllowOwn = "root" ]
        then
            	echo "$count. Owner of the file ($atAllowFile): $atAllowOwn - PASSED"
		((count++))
        else
            	echo "$count. Owner of the file ($atAllowFile): $atAllowOwn. Please ensure that the owner of the file is root instead - FAILED"
		((count++))
        fi

	atAllowGrp=`stat -c "%G" "$atAllowFile"`
	if [ $atAllowGrp = "root" ]
	then
		echo "$count. Group owner of the file ($atAllowFile): $atAllowGrp - PASSED"
		((count++))
	else
		echo "$count. Group owner of the file ($atAllowFile): $atAllowGrp. Please ensure that the group owner of the file is root instead - FAILED"
		((count++))
	fi
else
	echo "$count. Please ensure that a $atAllowFile is created for security purposes"
	((count++))
fi

#Check if /etc/cron.deny is deleted and that a /etc/cron.allow exists and check the permissions of the /etc/cron.allow file
cronDenyFile="/etc/cron.deny"
if [ -e "$cronDenyFile" ]
then
        echo "$count. Please ensure that the file $cronDenyFile is deleted - FAILED"
	((count++))
else
	echo "$count. $cronDenyFile is deleted as recommended - PASSED"
	((count++))
fi

cronAllowFile="/etc/cron.allow"
if [ -e "$cronAllowFile" ]
then
    	cronAllowPerm=`stat -c "%a" "$cronAllowFile"`
       	cronAllowRegex="^[0-7]00$"
        if [[ $cronAllowPerm =~ $cronAllowRegex ]]
        then
               	echo "$count. Permissions has been set correctly for $cronAllowFile - PASSED"
		((count++))
        else
               	echo "$count. Ensure that the permissions has been set correctly for $cronAllowFile - FAILED"
		((count++))
       	fi

       	cronAllowOwn=`stat -c "%U" "$cronAllowFile"`
        if [ $cronAllowOwn = "root" ]
        then
                echo "$count. Owner of the file ($cronAllowFile): $cronAllowOwn - PASSED"
		((count++))
        else
               	echo "$count. Owner of the file ($atAllowFile): $cronAllowOwn. Please ensure that the owner of the file is root instead - FAILED"
		((count++))
    	fi

    	cronAllowGrp=`stat -c "%G" "$cronAllowFile"`
       	if [ $cronAllowGrp = "root" ]
        then
            	echo "$count. Group owner of the file ($cronAllowFile): $cronAllowGrp"
		((count++))
        else
            	echo "$count. Group owner of the file ($cronAllowFile): $cronAllowGrp. Please ensure that the group owner of the file is root instead - FAILED"
		((count++))
        fi
else
    	echo "$count. Please ensure that a $cronAllowFile is created for security purposes"
	((count++))
fi

printf "\n"
count=1
echo "Configure SSH"
#10.1 verification 
chksshprotocol=`grep "^Protocol 2" /etc/ssh/sshd_config`

if [ "$chksshprotocol" == "Protocol 2" ]
then
	echo "$count. SSH (Protocol) - PASSED"
	((count++))
else
	echo "$count. SSH (Protocol) - FAILED"
	((count++))
fi

#10.2 verification
chksshloglevel=`grep "^LogLevel INFO" /etc/ssh/sshd_config`

if [ "$chksshloglevel" == "LogLevel INFO" ]
then
	echo "$count. SSH (LogLevel) - PASSED"
	((count++))
else
	echo "$count. SSH (LogLevel) - FAILED"
	((count++))
fi

#10.3 verification 
deterusergroupownership=`/bin/ls -l /etc/ssh/sshd_config | grep "root root" | grep "\-rw-------"`

if [ -n "deterusergroupownership" ] #-n means not null, -z means null
then
	echo "$count. Ownership (User & Group) - PASSED"
	((count++))
else
	echo "$count. Ownership (User & Group) - FAILED"
	((count++))
fi

#10.4 verification 
chkx11forwarding=`grep "^X11Forwarding no" /etc/ssh/sshd_config`

if [ "$chkx11forwarding" == "X11Forwarding no" ]
then
	echo "$count. SSH (X11Forwarding no) - PASSED"
	((count++))
else
	echo "$count. SSH (X11Forwarding no) - FAILED"
	((count++))
fi

#10.5 verification
maxauthtries=`grep "^MaxAuthTries 4" /etc/ssh/sshd_config`

if [ "$maxauthtries" == "MaxAuthTries 4" ]
then
	echo "$count. SSH (MaxAuthTries 4) - PASSED"
	((count++))
else
	echo "$count. SSH (MaxAuthTries 4) - FAILED"
	((count++))
fi

#10.6 verification
ignorerhosts=`grep "^IgnoreRhosts yes" /etc/ssh/sshd_config`

if [ "$ignorerhosts" == "IgnoreRhosts yes" ]
then
	echo "$count. SSH (IgnoreRhosts yes) - PASSED"
	((count++))
else
	echo "$count. SSH (IgnoreRhosts yes) - FAILED"
	((count++))
fi

#10.7 verification
hostbasedauthentication=`grep "^HostbasedAuthentication no" /etc/ssh/sshd_config`

if [ "$hostbasedauthentication" == "HostbasedAuthentication no" ]
then
	echo "$count. SSH (HostbasedAuthentication no) - PASSED"
	((count++))
else
	echo "$count. SSH (HostbasedAuthentication no) - FAILED"
	((count++))
fi


#10.8 verification
chksshrootlogin=`grep "^PermitRootLogin" /etc/ssh/sshd_config`

if [ "$chksshrootlogin" == "PermitRootLogin no" ]
then
	echo "$count. SSH (Permit Root Login) - PASSED"
	((count++))
else
	echo "$count. SSH (Permit Root Login) - FAILED"
	((count++))
fi

#10.9 verification
chksshemptypswd=`grep "^PermitEmptyPasswords" /etc/ssh/sshd_config`

if [ "$chksshemptypswd" == "PermitEmptyPasswords no" ]
then
	echo "$count. SSH (Permit Empty Passwords) - PASSED"
	((count++))
else
	echo "$count. SSH (Permit Empty Passwords) - FAILED"
	((count++))
fi

#10.10 verification
chksshcipher=`grep "Ciphers" /etc/ssh/sshd_config`

if [ "$chksshcipher" == "Ciphers aes128-ctr,aes192-ctr,aes256-ctr" ]
then
	echo "$count. SSH (Cipher) - PASSED"
	((count++))
else
	echo "$count. SSH (Cipher) - FAILED"
	((count++))
fi

#10.11 verification
chksshcai=`grep "^ClientAliveInterval" /etc/ssh/sshd_config`
chksshcacm=`grep "^ClientAliveCountMax" /etc/ssh/sshd_config`

if [ "$chksshcai" == "ClientAliveInterval 300" ]
then
	echo "$count. SSH (ClientAliveInterval) - PASSED"
	((count++))
else
	echo "$count. SSH (ClientAliveInterval) - FAILED"
	((count++))
fi

if [ "$chksshcacm" == "ClientAliveCountMax 0" ]
then
	echo "$count. SSH (ClientAliveCountMax) - PASSED"
	((count++))
else
	echo "$count. SSH (ClientAliveCountMax) - FAILED"
	((count++))
fi

#10.12 verification		*NOTE: Manually created users and groups as question was not very specific*
chksshalwusrs=`grep "^AllowUsers" /etc/ssh/sshd_config`
chksshalwgrps=`grep "^AllowGroups" /etc/ssh/sshd_config`
chksshdnyusrs=`grep "^DenyUsers" /etc/ssh/sshd_config`
chksshdnygrps=`grep "^DenyGroups" /etc/ssh/sshd_config`

if [ -z "$chksshalwusrs" -o "$chksshalwusrs" == "AllowUsers[[:space:]]" ]
then
	echo "$count. SSH (AllowUsers) - FAILED"
	((count++))
else
	echo "$count. SSH (AllowUsers) - PASSED"
	((count++))
fi

if [ -z "$chksshalwgrps" -o "$chksshalwgrps" == "AllowGroups[[:space:]]" ]
then
	echo "$count. SSH (AllowGroups) - FAILED"
	((count++))
else
	echo "$count. SSH (AllowGroups) - PASSED"
	((count++))
fi

if [ -z "$chksshdnyusrs" -o "$chksshdnyusrs" == "DenyUsers[[:space:]]" ]
then
	echo "$count. SSH (DenyUsers) - FAILED"
	((count++))
else
	echo "$count. SSH (DenyUsers) - PASSED"
	((count++))
fi

if [ -z "$chksshdnygrps" -o "$chksshdnygrps" == "DenyGroups[[:space:]]" ]
then
	echo "$count. SSH (DenyGroups) - FAILED"
	((count++))
else	
	echo "$count. SSH (DenyGroups) - PASSED"
	((count++))
fi

#10.13 verification
chksshbanner=`grep "Banner" /etc/ssh/sshd_config | awk '{ print $2 }'`

if [ "$chksshbanner" == "/etc/issue.net" -o "$chksshbanner" == "/etc/issue" ]
then
	echo "$count. SSH (Banner) - PASSED"
	((count++))
else
	echo "$count. SSH (Banner) - FAILED"
	((count++))
fi

printf "\n"
count=1
echo "Configure PAM"

#11.1
checkPassAlgo=`authconfig --test | grep hashing | grep sha512`
checkPassRegex=".*sha512"
if [[ $checkPassAlgo =~ $checkPassRegex ]]
then
	echo "$count. The password hashing algorithm is set to SHA-512 as recommended - PASSED"
	((count++))
else
	echo "$count. Please ensure that the password hashing algorithm is set to SHA-512 as recommended - FAILED"
	((count++))
fi 

#11.2
pampwconf=`grep pam_pwquality.so /etc/pam.d/system-auth`
correctpampwconf="password    requisite     pam_pwquality.so try_first_pass local_users_only retry=3 authtok_type="
if [[ $pampwconf == $correctpampwconf ]]
then
	echo "$count. Recommended settings is already configured - PASSED"
	((count++))
else
	echo "$count. Please configure the settings again - FAILED"
	((count++))
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
	echo "$count. Recommended settings is already configured - PASSED"
	((count++))
else
	echo "$count. Please configure the settings again - FAILED"
	((count++))
fi

#11.3
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
	echo "$count. Recommended settings is already configured - PASSED"
	((count++))
else
	echo "$count. Please configure the settings again - FAILED"
	((count++))
fi

#11.4
pamlimitpw=`grep "remember" /etc/pam.d/system-auth`
if [[ $pamlimitpw == *"remember=5"* ]]
then 
	echo "$count. Recommended settings is already configured - PASSED"
	((count++))
else
	echo "$count. Please configure the settings again - FAILED"
	((count++))
fi

#11.5
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

if [ $systemConsoleCounter != 2 ]
then
	echo "$count. Please configure the settings again - FAILED"
	((count++))
else
	echo "$count. Recommended settings is already configured - PASSED"
	((count++))
fi

#11.6
pamsu=`grep pam_wheel.so /etc/pam.d/su | grep required`
if [[ $pamsu =~ ^#auth.*required ]]
then
	echo "$count. Please configure the settings again - FAILED"
	((count++))
else
	echo "$count. Recommended settings is already configured - PASSED"
	((count++))
fi

pamwheel=`grep wheel /etc/group`
if [[ $pamwheel =~ ^wheel.*root ]]
then
	echo "$count. Recommended settings is already configured - PASSED"
	((count++))
else
	echo "$count. Please configure the settings again - FAILED"
	((count++))
fi