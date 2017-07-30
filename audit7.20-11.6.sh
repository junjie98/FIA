#!/bin/bash
# Audit Script for RHEL 7 based on CIS BenchMarks
# Script misc. section

GREEN="\033[0;32m"
RED="\033[0;31m"
NC="\033[0m"
bold=$(tput bold)
normal=$(tput sgr0)

trap '' 2 20
trap '' SIGTSTP

# Check if script is executed by root
if [ "$EUID" -ne 0 ]
	then echo "Please run this script as root"
	exit
fi

datetime=`date +"%m%d%y-%H%M"`

echo "8.1 Set Warning Banner for Standard Login Services"

current=$(cat /etc/motd)

standard="WARNING: UNAUTHORIZED USERS WILL BE PROSECUTED!"

if [ "$current" == "$standard" ]; then
        echo "Audit status: PASSED!"
else
        echo "Audit status: FAILED!"
fi
#########################################################################
echo "8.2 Remove OS Information from Login Warning Banners"

current1=$(egrep '(\\v|\\r|\\m|\\s)' /etc/issue)
current2=$(egrep '(\\v|\\r|\\m|\\s)' /etc/motd)
current3=$(egrep '(\\v|\\r|\\m|\\s)' /etc/issue.net)

string1="\\v"
string2="\\r"
string3="\\m"
string4="\\s"

if [[ $current1 =~ $string1 || $current1 =~ $string2 || $current1 = ~$string3 || $current1 =~ $string4 ]]; then
        echo "Audit status: FAILED! [OS Information found in /etc/issue]"
else
        echo "/etc/issue has no issues. Continuing with verification"
fi

if [[ $current2 =~ $string1 || $current2 =~ $string2 || $current2 = ~$string3 || $current2 =~ $string4 ]]; then
        echo "Audit status: FAILED! [OS Information found in /etc/motd]"
else
        echo "/etc/motd has no issues. Continuing with verification"
fi

if [[ $current3 =~ $string1 || $current3 =~ $string2 || $current3 = ~$string3 || $current4 =~ $string4 ]]; then
        echo "Audit status: FAILED! [OS Information found in /etc/issue.net]"
else
        echo "/etc/issue.net has no issues. Continuing with verification"
fi

#Check whether Anacron Daemon is enabled or not
if rpm -q cronie-anacron
then
	echo "Anacron Daemon has been installed."
else
	echo "Please ensure that you have Anacron Daemon has been installed."
fi

#Check if Crond Daemon is enabled
checkCronDaemon=$(systemctl is-enabled crond)
if [[ $checkCronDaemon = "enabled" ]]
then
	echo "Crond Daemon has been enabled."
else
	echo "Please ensure that you have enabled crond Daemon."
fi

#Check if the correct permissions is configured for /etc/anacrontab
anacrontabFile="/etc/anacrontab"
if [ -e "$anacrontabFile" ]
then
	echo "The Anacrontab file ($anacrontabFile) exists."
	
	anacrontabPerm=$(stat -c "%a" "$anacrontabFile")
	anacrontabRegex="^[0-7]00$"
	if [[ $anacrontabPerm =~ $anacrontabRegex ]]
	then
		echo "Permissions has been set correctly for $anacrontabFile."
	else
		echo "Ensure that the permissions has been set correctly for $anacrontabFile."
	fi

	anacrontabOwn=$(stat -c "%U" "$anacrontabFile")
	if [ $anacrontabOwn = "root" ]
	then
		echo "Owner of the file ($anacrontabFile): $anacrontabOwn"
	else
		echo "Owner of the file ($anacrontabFile): $anacrontabOwn"
	fi

	anacrontabGrp=$(stat -c "%G" "$anacrontabFile")
	if [ $anacrontabGrp = "root" ]
	then
		echo "Group owner of the file ($anacrontabFile): $anacrontabGrp"
	else
		echo "Group owner of the file ($anacrontabFile): $anacrontabGrp. Please ensure that the group owner is root instead."
	fi
else
	echo "The Anacrontab file does not exist. Please ensure that you have Anacron Daemon installed."
fi

#Check if the correct permissions has been configured for /etc/crontab
crontabFile="/etc/crontab"
if [ -e "$crontabFile" ]
then
	crontabPerm=$(stat -c "%a" "$crontabFile")
	crontabRegex="^[0-7]00$"
	if [[ $crontabPerm =~ $crontabRegex ]]
	then
		echo "Permissions has been set correctly for $crontabFile."
	else
		echo "Ensure that the permissions has been set correctly for $crontabFile."
	fi

	crontabOwn=$(stat -c "%U" "$crontabFile")
	if [ $crontabOwn = "root" ]
	then
		echo "Owner of the file ($crontabFile): $crontabOwn"
	else
		echo "Owner of the file ($crontabFile): $crontabOwn. Please ensure that the owner of the file is root instead."
	fi

	crontabGrp=$(stat -c "%G" "$crontabFile")
	if [ $crontabGrp = "root" ]
	then
		echo "Group owner of the file ($crontabFile): $crontabGrp"
	else
		echo "Group owner of the file ($crontabFIle): $crontabGrp. Please ensure that the group owner of the file is root instead."
	fi

else
	echo "The crontab file ($crontabFile) does not exist."
fi

#Check if the correct permissions has been set for /etc/cron.XXXX
checkCronHDWMPerm(){
	local cronHDWMType=$1
	local cronHDWMFile="/etc/cron.$cronHDWMType"

	if [ -e "$cronHDWMFile" ]
	then
		local cronHDWMPerm=$(stat -c "%a" "$cronHDWMFile")
		local cronHDWMRegex="^[0-7]00$"
		if [[ $cronHDWMPerm =~ $cronHDWMRegex ]]
		then
			echo "Permissions has been set correctly for $cronHDWMFile."
		else
			echo "Ensure that the permissions has been set correctly for $cronHDWMFile."
		fi

		local cronHDWMOwn="$(stat -c "%U" "$cronHDWMFile")"
		if [ $cronHDWMOwn = "root" ]
		then
			echo "Owner of the file ($cronHDWMFile): $cronHDWMOwn"
		else
			echo "Owner of the file ($cronHDWMFile): $cronHDWMOwn. Please ensure that the owner of the file is root instead."
		fi

		local cronHDWMGrp="$(stat -c "%G" "$cronHDWMFile")"
		if [ $cronHDWMGrp = "root" ]
		then
			echo "Group Owner of the file ($cronHDWMFile): $cronHDWMGrp"
		else
			echo "Group Owner of the file ($cronHDWMFile): $cronHDWMGrp. Please ensure that the group owner of the file is root instead."
		fi
	else
		echo "File ($cronHDWMFile) does not exist."
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
	cronDPerm=$(stat -c "%a" "$cronDFile")
	cronDRegex="^[0-7]00$"
	if [[ $cronDPerm =~ $cronDRegex ]]
	then
		echo "Permissions has been set correctly for $cronDFile."
	else
		echo "Ensure that the permissions has been set correctly for $cronDFile."
	fi

	cronDOwn=$(stat -c "%U" "$cronDFile")
	if [ $cronDOwn = "root" ]
	then
		echo "Owner of the file ($cronDFile): $cronDOwn"
	else
		echo "Owner of the file ($cronDFile): $cronDOwn. Please ensure that the owner of the file is root instead."
	fi

	cronDGrp=$(stat -c "%G" "$cronDFile")
	if [ $cronDGrp = "root" ]
	then
		echo "Group owner of the file ($cronDFile): $cronDGrp"
	else
		echo "Group owner of the file ($cronDFile): $cronDGrp. Please ensure that the group owner of the file is root instead."
	fi
else
	echo "The cron.d file ($cronDFile) does not exist."
fi

#Check if /etc/at.deny is deleted and that a /etc/at.allow exists and check the permissions of the /etc/at.allow file
atDenyFile="/etc/at.deny"
if [ -e "$atDenyFile" ]
then
	echo "Please ensure that the file $atDenyFile is deleted."
else
	echo "$atDenyFile is deleted as recommended."
fi

atAllowFile="/etc/at.allow"
if [ -e "$atAllowFile" ]
then
        atAllowPerm=$(stat -c "%a" "$atAllowFile")
        atAllowRegex="^[0-7]00$"
        if [[ $atAllowPerm =~ $atAllowRegex ]]
        then
            	echo "Permissions has been set correctly for $atAllowFile."
        else
            	echo "Ensure that the permissions has been set correctly for $atAllowFile."
        fi

	atAllowOwn=$(stat -c "%U" "$atAllowFile")
        if [ $atAllowOwn = "root" ]
        then
            	echo "Owner of the file ($atAllowFile): $atAllowOwn"
        else
            	echo "Owner of the file ($atAllowFile): $atAllowOwn. Please ensure that the owner of the file is root instead."
        fi

	atAllowGrp=$(stat -c "%G" "$atAllowFile")
	if [ $atAllowGrp = "root" ]
	then
		echo "Group owner of the file ($atAllowFile): $atAllowGrp"
	else
		echo "Group owner of the file ($atAllowFile): $atAllowGrp. Please ensure that the group owner of the file is root instead."
	fi
else
	echo "Please ensure that a $atAllowFile is created for security purposes."
fi

#Check if /etc/cron.deny is deleted and that a /etc/cron.allow exists and check the permissions of the /etc/cron.allow file
cronDenyFile="/etc/cron.deny"
if [ -e "$cronDenyFile" ]
then
        echo "Please ensure that the file $cronDenyFile is deleted."
else
	echo "$cronDenyFile is deleted as recommended."
fi

cronAllowFile="/etc/cron.allow"
if [ -e "$cronAllowFile" ]
then
    	cronAllowPerm=$(stat -c "%a" "$cronAllowFile")
       	cronAllowRegex="^[0-7]00$"
        if [[ $cronAllowPerm =~ $cronAllowRegex ]]
        then
               	echo "Permissions has been set correctly for $cronAllowFile."
        else
               	echo "Ensure that the permissions has been set correctly for $cronAllowFile."
       	fi

       	cronAllowOwn=$(stat -c "%U" "$cronAllowFile")
        if [ $cronAllowOwn = "root" ]
        then
                echo "Owner of the file ($cronAllowFile): $cronAllowOwn"
        else
               	echo "Owner of the file ($atAllowFile): $cronAllowOwn. Please ensure that the owner of the file is root instead."
    	fi

    	cronAllowGrp=$(stat -c "%G" "$cronAllowFile")
       	if [ $cronAllowGrp = "root" ]
        then
            	echo "Group owner of the file ($cronAllowFile): $cronAllowGrp"
        else
            	echo "Group owner of the file ($cronAllowFile): $cronAllowGrp. Please ensure that the group owner of the file is root instead."
        fi
else
    	echo "Please ensure that a $cronAllowFile is created for security purposes."
fi

#10.1 verification 
chksshprotocol=`grep "^Protocol 2" /etc/ssh/sshd_config`

if [ "$chksshprotocol" == "Protocol 2" ]
then
	echo "SSH (Protocol) - Pass"
else
	echo "SSH (Protocol) - Fail"
fi

#10.2 verification
chksshloglevel=`grep "^LogLevel INFO" /etc/ssh/sshd_config`

if [ "$chksshloglevel" == "LogLevel INFO" ]
then
	echo "SSH (LogLevel) - Pass"
else
	echo "SSH (LogLevel) - Fail"
fi

#10.3 verification 
deterusergroupownership=`/bin/ls -l /etc/ssh/sshd_config | grep "root root" | grep "\-rw-------"`

if [ -n "deterusergroupownership" ] #-n means not null, -z means null
then
	echo "Ownership (User & Group)- Pass"
else
	echo "Ownership (User & Group)- Fail"
fi

#10.4 verification 
chkx11forwarding=`grep "^X11Forwarding no" /etc/ssh/sshd_config`

if [ "$chkx11forwarding" == "X11Forwarding no" ]
then
	echo "SSH (X11Forwarding no) - Pass"
else
	echo "SSH (X11Forwarding no) - Fail"
fi

#10.5 verification
maxauthtries=`grep "^MaxAuthTries 4" /etc/ssh/sshd_config`

if [ "$maxauthtries" == "MaxAuthTries 4" ]
then
	echo "SSH (MaxAuthTries 4) - Pass"
else
	echo "SSH (MaxAuthTries 4) - Fail"
fi

#10.6 verification
ignorerhosts=`grep "^IgnoreRhosts yes" /etc/ssh/sshd_config`

if [ "$ignorerhosts" == "IgnoreRhosts yes" ]
then
	echo "SSH (IgnoreRhosts yes) - Pass"
else
	echo "SSH (IgnoreRhosts yes) - Fail"
fi

#10.7 verification
hostbasedauthentication=`grep "^HostbasedAuthentication no" /etc/ssh/sshd_config`

if [ "$hostbasedauthentication" == "HostbasedAuthentication no" ]
then
	echo "SSH (HostbasedAuthentication no) - Pass"
else
	echo "SSH (HostbasedAuthentication no) - Fail"
fi


#10.8 verification
chksshrootlogin=`grep "^PermitRootLogin" /etc/ssh/sshd_config`

if [ "$chksshrootlogin" == "PermitRootLogin no" ]
then
	echo "SSH (Permit Root Login) - Pass"
else
	echo "SSH (Permit Root Login) - Fail"
fi

#10.9 verification
chksshemptypswd=`grep "^PermitEmptyPasswords" /etc/ssh/sshd_config`

if [ "$chksshemptypswd" == "PermitEmptyPasswords no" ]
then
	echo "SSH (Permit Empty Passwords) - Pass"
else
	echo "SSH (Permit Empty Passwords) - Fail"
fi

#10.10 verification
chksshcipher=`grep "Ciphers" /etc/ssh/sshd_config`

if [ "$chksshcipher" == "Ciphers aes128-ctr,aes192-ctr,aes256-ctr" ]
then
	echo "SSH (Cipher) - Pass"
else
	echo "SSH (Cipher) - Fail"
fi

#10.11 verification
chksshcai=`grep "^ClientAliveInterval" /etc/ssh/sshd_config`
chksshcacm=`grep "^ClientAliveCountMax" /etc/ssh/sshd_config`

if [ "$chksshcai" == "ClientAliveInterval 300" ]
then
	echo "SSH (ClientAliveInterval) - Pass"
else
	echo "SSH (ClientAliveInterval) - Fail"
fi

if [ "$chksshcacm" == "ClientAliveCountMax 0" ]
then
	echo "SSH (ClientAliveCountMax) - Pass"
else
	echo "SSH (ClientAliveCountMax) - Fail"
fi

#10.12 verification		*NOTE: Manually created users and groups as question was not very specific*
chksshalwusrs=`grep "^AllowUsers" /etc/ssh/sshd_config`
chksshalwgrps=`grep "^AllowGroups" /etc/ssh/sshd_config`
chksshdnyusrs=`grep "^DenyUsers" /etc/ssh/sshd_config`
chksshdnygrps=`grep "^DenyGroups" /etc/ssh/sshd_config`

if [ -z "$chksshalwusrs" -o "$chksshalwusrs" == "AllowUsers[[:space:]]" ]
then
	echo "SSH (AllowUsers) - Fail"
else
	echo "SSH (AllowUsers) - Pass"
fi

if [ -z "$chksshalwgrps" -o "$chksshalwgrps" == "AllowGroups[[:space:]]" ]
then
	echo "SSH (AllowGroups) - Fail"
else
	echo "SSH (AllowGroups) - Pass"
fi

if [ -z "$chksshdnyusrs" -o "$chksshdnyusrs" == "DenyUsers[[:space:]]" ]
then
	echo "SSH (DenyUsers) - Fail"
else
	echo "SSH (DenyUsers) - Pass"
fi

if [ -z "$chksshdnygrps" -o "$chksshdnygrps" == "DenyGroups[[:space:]]" ]
then
	echo "SSH (DenyGroups) - Fail"
else	
	echo "SSH (DenyGroups) - Pass"
fi

#10.13 verification
chksshbanner=`grep "Banner" /etc/ssh/sshd_config | awk '{ print $2 }'`

if [ "$chksshbanner" == "/etc/issue.net" -o "$chksshbanner" == "/etc/issue" ]
then
	echo "SSH (Banner) - Pass"
else
	echo "SSH (Banner) - Fail"
fi

#11.1
checkPassAlgo=$(authconfig --test | grep hashing | grep sha512)
checkPassRegex=".*sha512"
if [[ $checkPassAlgo =~ $checkPassRegex ]]
then
	echo "The password hashing algorithm is set to SHA-512 as recommended."
else
	echo "Please ensure that the password hashing algorithm is set to SHA-512 as recommended."
fi 

#11.2
pampwconf=$(grep pam_pwquality.so /etc/pam.d/system-auth)
correctpampwconf="password    requisite     pam_pwquality.so try_first_pass local_users_only retry=3 authtok_type="
if [[ $pampwconf == $correctpampwconf ]]
then
echo "Recommended settings is already configured."
else
echo "Please configure the settings again."
fi

minlen=$(grep "minlen" /etc/security/pwquality.conf)
dcredit=$(grep "dcredit" /etc/security/pwquality.conf)
ucredit=$(grep "ucredit" /etc/security/pwquality.conf)
ocredit=$(grep "ocredit" /etc/security/pwquality.conf)
lcredit=$(grep "lcredit" /etc/security/pwquality.conf)
correctminlen="# minlen = 14"
correctdcredit="# dcredit = -1"
correctucredit="# ucredit = -1"
correctocredit="# ocredit = -1"
correctlcredit="# lcredit = -1"

if [[ $minlen == $correctminlen && $dcredit == $correctdcredit && $ucredit == $correctucredit && $ocredit == $correctocredit && $lcredit == $correctlcredit ]]
then
echo "Recommended settings is already configured."
else
echo "Please configure the settings again."
fi

#11.3
faillockpassword=$(grep "pam_faillock" /etc/pam.d/password-auth)
faillocksystem=$(grep "pam_faillock" /etc/pam.d/system-auth)

read -d '' correctpamauth << "BLOCK" 
auth        required      pam_faillock.so preauth silent audit deny=5 unlock_time=900
auth        [default=die] pam_faillock.so authfail audit deny=5
auth        sufficient    pam_faillock.so authsucc audit deny=5
account     required      pam_faillock.so
BLOCK

if [[ $faillocksystem == "$correctpamauth" && $faillockpassword == "$correctpamauth" ]]
then
echo "Recommended settings is already configured."
else
echo "1Please configure the settings again."
fi

#11.4
pamlimitpw=$(grep "remember" /etc/pam.d/system-auth)
if [[ $pamlimitpw == *"remember=5"* ]]
then 
echo "Recommended settings is already configured."
else
echo "Please configure the settings again."
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
	echo "Please configure the settings again."
else
	echo "Recommended settings is already configured."
fi

#11.6
pamsu=$(grep pam_wheel.so /etc/pam.d/su | grep required)
if [[ $pamsu =~ ^#auth.*required ]]
then
echo "Please configure the settings again."
else
echo "Recommended settings is already configured."
fi

pamwheel=$(grep wheel /etc/group)
if [[ $pamwheel =~ ^wheel.*root ]]
then
echo "Recommended settings is already configured."
else
echo "Please configure the settings again."
fi

