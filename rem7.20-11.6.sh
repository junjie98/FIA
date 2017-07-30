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

echo "Current Remediation Process: 8.1 Set Warning Banner for Standard Login Services"

echo "WARNING: UNAUTHORIZED USERS WILL BE PROSECUTED!" > '/etc/motd'

---------------------------------------------------------------------------------------------------------------

echo "Current Remediation Process: 8.2 Remove OS Information from Login Warning Banners"

current1=$(egrep '(\\v|\\r|\\m|\\s)' /etc/issue)
current2=$(egrep '(\\v|\\r|\\m|\\s)' /etc/motd)
current3=$(egrep  '(\\v|\\r|\\m|\\s)' /etc/issue.net)

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

#Check whether Anacron Daemon is installed or not and install if it is found to be uninstalled

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

#Check if Crond Daemon is enabled and enable it if it is not enabled
checkCrondDaemon=$(systemctl is-enabled crond)
if [ "$checkCrondDaemon" = "enabled" ]
then
    	echo "Remedation passed: Crond Daemon is enabled."
else
    	systemctl enable crond
	doubleCheckCrondDaemon=$(systemctl is-enabled crond)
	if [ "$doubleCheckCrondDaemon" = "enabled" ]
	then
		:
	else
		echo "It seems as if an error has occurred and crond cannot be enabled. Please ensure that you have a yum repository available and cron service installed (yum install cron -y)."
	fi
fi

#Check if the correct permissions is configured for /etc/anacrontab and configure them if they are not
anacrontabFile="/etc/anacrontab"
anacrontabPerm=$(stat -c "%a" "$anacrontabFile")
anacrontabRegex="^[0-7]00$"
if [[ $anacrontabPerm =~ $anacrontabRegex ]]
then
	echo "Remedation passed: The correct permissions has been configured for $anacrontabFile."
else
	sudo chmod og-rwx $anacrontabFile
	anacrontabPermCheck=$(stat -c "%a" "$anacrontabFile")
        anacrontabRegexCheck="^[0-7]00$"
	if [[ $anacrontabPermCheck =~ $anacrontabRegexCheck ]]
	then
		:
	else
		echo "It seems as if an error has occured and the permissions for $anacrontabFile cannot be configured as required."
	fi
fi

anacrontabOwn=$(stat -c "%U" "$anacrontabFile")
if [ $anacrontabOwn = "root" ]
then
	echo "Remediation passed: The owner of the file $anacrontabFile is root."
else
	sudo chown root:root $anacrontabFile
	anacrontabOwnCheck=$(stat -c "%U" "$anacrontabFile")
       	if [ $anacrontabOwnCheck = "root" ]
       	then
                :
	else
		echo "It seems as if an error has occured and the owner of the file ($anacrontabFile) cannot be set as root."
        fi
fi

anacrontabGrp=$(stat -c "%G" "$anacrontabFile")
if [ $anacrontabGrp = "root" ]
then
	echo "Remediation passed: The group owner of the file $anacrontabFile is root."
else
	sudo chown root:root $anacrontabFile
	anacrontabGrpCheck=$(stat -c "%G" "$anacrontabFile")
        if [ $anacrontabGrpCheck = "root" ]
	then
		: 
	else
		echo "It seems as if an error has occured and the group owner of the $anacrontabFile file cannot be set as root instead."
        fi
fi


#Check if the correct permissions has been configured for /etc/crontab and configure them if they are not
crontabFile="/etc/crontab"
crontabPerm=$(stat -c "%a" "$crontabFile")
crontabRegex="^[0-7]00$"
if [[ $crontabPerm =~ $crontabRegex ]]
then
	echo "Remediation passed: The correct permissions has been set for $crontabFile."
else
	sudo chmod og-rwx $crontabFile
	checkCrontabPerm=$(stat -c "%a" "$crontabFile")
	checkCrontabRegex="^[0-7]00$"
	if [[ $checkCrontabPerm =~ $checkCrontabRegex ]]
	then
		:
	else
		echo "It seems as if an error has occured and the permisions of the file $crontabFile cannot be set as recommended."
	fi
fi

crontabOwn=$(stat -c "%U" "$crontabFile")
if [ $crontabOwn = "root" ]
then
	echo "Remediation passed: The owner of the file $crontabFile is root."
else
	sudo chown root:root $crontabFile
	checkCrontabOwn=$(stat -c "%U" "$crontabFile")
	if [ $checkCrontabOwn = "root" ]
	then
        	:
	else
		echo "It seems as if an error has occured and that the owner of the $crontabFile file cannot be set as root instead."
	fi

fi

crontabGrp=$(stat -c "%G" "$crontabFile")
if [ $crontabGrp = "root" ]
then
	echo "Remediation passed: The group owner of the file $crontabFile is root."
else
	sudo chown root:root $crontabFile
	checkCrontabGrp=$(stat -c "%G" "$crontabFile")
	if [ $checkCrontabGrp = "root" ]
	then
        	:
	else
		echo "It seems as if an error has occured and that the group owner of the $crontabFile file cannot be set as root instead."
	fi
fi

#Check if the correct permissions has been set for /etc/cron.XXXX and change them if they are not
patchCronHDWMPerm(){
        local cronHDWMType=$1
        local cronHDWMFile="/etc/cron.$cronHDWMType"

	local cronHDWMPerm=$(stat -c "%a" "$cronHDWMFile")
	local cronHDWMRegex="^[0-7]00$"
	if [[ $cronHDWMPerm =~ $cronHDWMRegex ]]
	then
		echo "Remediation passed: The correct permissions has been set for $cronHDWMFile."
	else
		sudo chmod og-rwx $cronHDWMFile
		local checkCronHDWMPerm=$(stat -c "%a" "$cronHDWMFile")
	        local checkCronHDWMRegex="^[0-7]00$"
		if [[ $checkCronHDWMPerm =~ $checkCronHDWMRegex ]]
       		then
                	:
       		else
			echo "It seems as if an error has occured and that the permissions for the $cronHDWMFile file cannot be set as recommended."
		fi
	fi

	local cronHDWMOwn="$(stat -c "%U" "$cronHDWMFile")"
	if [ $cronHDWMOwn = "root" ]
        then
		echo "Remediation passed: The owner of the $cronHDWMFile file is root."
	else
		sudo chown root:root $cronHDWMFile
		local checkCronHDWMOwn="$(stat -c "%U" "$cronHDWMFile")"
	        if [ $checkCronHDWMOwn = "root" ]
	        then
        	        :
	        else
			echo "It seems as if an error has occured and that the owner of the $cronHDWMFile cannot be set as root instead."
		fi

	fi

	local cronHDWMGrp="$(stat -c "%G" "$cronHDWMFile")"
        if [ $cronHDWMGrp = "root" ]
        then
		echo "Remediation passed: The group owner of the $cronHDWMFile file is root."
	else
		sudo chown root:root $cronHDWMFile
		local checkCronHDWMGrp="$(stat -c "%G" "$cronHDWMFile")"
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

#Check if the permissions has been set correctly for /etc/cron.d and set them right if they are not
cronDFile="/etc/cron.d"
cronDPerm=$(stat -c "%a" "$cronDFile")
cronDRegex="^[0-7]00$"
if [[ $cronDPerm =~ $cronDRegex ]]
then
	echo "Remediation passed: The correct permissions has been set for $cronDFile."
else
	sudo chmod og-rwx $cronDFile
	checkCronDPerm=$(stat -c "%a" "$cronDFile")
	checkCronDRegex="^[0-7]00$"
	if [[ $checkCronDPerm =~ $checkCronDRegex ]]
	then
		:
	else
		echo "It seems as if an error has occured and that the recommended permissions for the $cronDFile file cannot be configured."
	fi

fi

cronDOwn=$(stat -c "%U" "$cronDFile")
if [ $cronDOwn = "root" ]
then
	echo "Remediation passed: The owner of the $cronDFile file is root."
else
        sudo chown root:root $cronDFile
	checkCronDOwn=$(stat -c "%U" "$cronDFile")
	if [ $checkCronDOwn = "root" ]
	then
        	:
	else
		echo "It seems as if an error has occured and that the owner of the $cronDFile cannot be set as root instead."
	fi
fi

cronDGrp=$(stat -c "%G" "$cronDFile")
if [ $cronDGrp = "root" ]
then
	echo "Remediation passed: The group owner of the $cronDFile file is root."
else
	sudo chown root:root $cronDFile
	checkCronDGrp=$(stat -c "%G" "$cronDFile")
	if [ $checkCronDGrp = "root" ]
	then
        	:
	else
		echo "It seems as if an error has occured and that the group owner of the $cronDFile cannot be set as root instead."
	fi
fi

#Check if /etc/at.deny is deleted and that a /etc/at.allow exists and check the permissions of the /e$
atDenyFile="/etc/at.deny"
if [ -e "$atDenyFile" ]
then
    	sudo rm $atDenyFile
else
    	echo "Remediation passed: $atDenyFile is deleted or does not exist."
fi

atAllowFile="/etc/at.allow"
if [ -e "$atAllowFile" ]
then
    	atAllowPerm=$(stat -c "%a" "$atAllowFile")
        atAllowRegex="^[0-7]00$"
        if [[ $atAllowPerm =~ $atAllowRegex ]]
        then
            	echo "Remediation passed: The correct permissions has been set for $atAllowFile."
        else
            	sudo chmod og-rwx $atAllowFile
		checkAtAllowPerm=$(stat -c "%a" "$atAllowFile")
	        checkAtAllowRegex="^[0-7]00$"
	        if [[ $checkAtAllowPerm =~ $checkAtAllowRegex ]]	
	        then
        	        :
        	else
			echo "It seems as if an error has occured and the recommended permissions cannot be set for the $atAllowFile  file."
		fi
        fi

	atAllowOwn=$(stat -c "%U" "$atAllowFile")
        if [ $atAllowOwn = "root" ]
        then
            	echo "Remediation passed: The owner of the $atAllowFile is root."
        else
            	sudo chown root:root $atAllowFile
		checkAtAllowOwn=$(stat -c "%U" "$atAllowFile")
	       	if [ $checkAtAllowOwn = "root" ]
	       	then
			:
		else
			echo "It seems as if an error has occured and that the owne of the $overallCounter file cannot be set as root instead."
		fi
        fi

	atAllowGrp=$(stat -c "%G" "$atAllowFile")
        if [ $atAllowGrp = "root" ]
        then
            	echo "Remediation passed: The group owner of the $atAllowFile is root."
        else
            	sudo chown root:root $atAllowFile
		checkAtAllowGrp=$(stat -c "%G" "$atAllowFile")
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
        checkAtAllowPerm2=$(stat -c "%a" "$atAllowFile")
        checkAtAllowRegex2="^[0-7]00$"
        if [[ $checkAtAllowPerm2 =~ $checkAtAllowRegex2 ]]
        then
		:
	else
		echo "It seems as if an error has occured and the recommended permissions cannot be configured for the $atAllowFile file."
	fi
	
	sudo chown root:root $atAllowFile
        checkAtAllowOwn2=$(stat -c "%U" "$atAllowFile")
        if [ $checkAtAllowOwn2 = "root" ]
        then
               	:
       	else
                echo "It seems as if an error has occured and that the owner of the $atAllowFile file cannot be set as root instead"
       	fi	

	sudo chown root:root $atAllowFile
        checkAtAllowGrp2=$(stat -c "%G" "$atAllowFile")
        if [ $checkAtAllowGrp2 = "root" ]
        then
		:
	else
		echo "It seems as if an error has occured and that the group owner of the $atAllowFile file cannot be set as root instead."
	fi
fi

#Check if /etc/cron.deny is deleted and that a /etc/cron.allow exists and check the permissions, configure as recommended if found to have not been configured correctly
cronDenyFile="/etc/cron.deny"
if [ -e "$cronDenyFile" ]
then
    	sudo rm $cronDenyFile
else
    	echo "Remediation passed: $cronDenyFile is deleted or does not exist."
fi

cronAllowFile="/etc/cron.allow"
if [ -e "$cronAllowFile" ]
then
        cronAllowPerm=$(stat -c "%a" "$cronAllowFile")
        cronAllowRegex="^[0-7]00$"
       	if [[ $cronAllowPerm =~ $cronAllowRegex ]]
    	then
                echo "Remediation passed: The correct permissions for $cronAllowFile has been configured."
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

	cronAllowOwn=$(stat -c "%U" "$cronAllowFile")
        if [ $cronAllowOwn = "root" ]
        then
            	echo "Remedation passed: The owner of the $cronAllowFile is root."
        else
            	sudo chown root:root $cronAllowFile
                checkCronAllowOwn=$(stat -c "%U" "$cronAllowFile")
                if [ $checkCronAllowOwn = "root" ]
                then
                    	:
                else
                        echo "It seems as if an error has occured and that the owner of the $cronAllowFile file cannot be set as root instead."
                fi
        fi

	cronAllowGrp=$(stat -c "%G" "$cronAllowFile")
        if [ $cronAllowGrp = "root" ]
        then
            	echo "Remediation passed: The group owner of the $cronAllowFile is set to root."
        else
            	sudo chown root:root $cronAllowFile
                checkCronAllowGrp=$(stat -c "%G" "$cronAllowFile")
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
        checkCronAllowPerm2=$(stat -c "%a" "$cronAllowFile")
        checkCronAllowRegex2="^[0-7]00$"
        if [[ $checkCronAllowPerm2 =~ $checkCronAllowRegex2 ]]
        then
            	:
        else
                echo "It seems as if an error has occured and the recommended permissions cannot be configured for the $cronAllowFIle file."
        fi

        sudo chown root:root $cronAllowFile
        checkCronAllowOwn2=$(stat -c "%U" "$cronAllowFile")
        if [ $checkCronAllowOwn2 = "root" ]
        then
            	:
        else
                echo "It seems as if an error has occured and that the owner of the $cronAllowFile cannot be set as root instead"
        fi

	sudo chown root:root $cronAllowFile
	checkCronAllowGrp2=$(stat -c "%G" "$cronAllowFile")
        if [ $checkCronAllowGrp2 = "root" ]
        then
            	:
        else
		echo "It seems as if an error has occured and that the group owner of the $cronAllowFile cannot be set as root instead."
	fi
fi

#10.1 remedy
remsshprotocol=`grep "^Protocol 2" /etc/ssh/sshd_config`
if [ "$remsshprotocol" != "Protocol 2" ]
then
	sed -ie "23s/#//" /etc/ssh/sshd_config
fi

#10.2 remedy
remsshloglevel=`grep "^LogLevel" /etc/ssh/sshd_config`
if [ "$remsshloglevel" != "LogLevel INFO" ]
then
	sed -ie "43s/#//" /etc/ssh/sshd_config
fi

#10.3 remedy
remdeterusergroupownership=`grep "^LogLevel" /etc/ssh/sshd_config`
if [ -z "$remdeterusergroupownership" ]
then
	chown root:root /etc/ssh/sshd_config
	chmod 600 /etc/ssh/sshd_config
fi

#10.4 remedy
remsshx11forwarding=`grep "^X11Forwarding" /etc/ssh/sshd_config`
if [ "$remsshx11forwarding" != "X11Forwarding no" ]
then
	sed -ie "116s/#//" /etc/ssh/sshd_config
	sed -ie "117s/^/#/" /etc/ssh/sshd_config
fi

#10.5 remedy
maxauthtries=`grep "^MaxAuthTries 4" /etc/ssh/sshd_config`
if [ "$maxauthtries" != "MaxAuthTries 4" ]
then
	sed -ie "50d" /etc/ssh/sshd_config
	sed -ie "50iMaxAuthTries 4" /etc/ssh/sshd_config
fi

#10.6 remedy
ignorerhosts=`grep "^IgnoreRhosts" /etc/ssh/sshd_config`
if [ "$ignorerhosts" != "IgnoreRhosts yes" ]
then
	sed -ie "73d" /etc/ssh/sshd_config
	sed -ie "73iIgnoreRhosts yes" /etc/ssh/sshd_config
fi

#10.7 remedy
hostbasedauthentication=`grep "^HostbasedAuthentication" /etc/ssh/sshd_config`
if [ "$hostbasedauthentication" != "HostbasedAuthentication no" ]
then
	sed -ie "68d" /etc/ssh/sshd_config
	sed -ie "68iHostbasedAuthentication no" /etc/ssh/sshd_config
fi

#10.8 remedy
remsshrootlogin=`grep "^PermitRootLogin" /etc/ssh/sshd_config`
if [ "$remsshrootlogin" != "PermitRootLogin no" ]
then
	sed -ie "48d" /etc/ssh/sshd_config
	sed -ie "48iPermitRootLogin no" /etc/ssh/sshd_config
fi

#10.9 remedy
remsshemptypswd=`grep "^PermitEmptyPasswords" /etc/ssh/sshd_config`
if [ "$remsshemptypswd" != "PermitEmptyPasswords no" ]
then
	sed -ie "77d" /etc/ssh/sshd_config
	sed -ie "77iPermitEmptyPasswords no" /etc/ssh/sshd_config
fi

#10.10 remedy
remsshcipher=`grep "Ciphers" /etc/ssh/sshd_config`
if [ "$remsshcipher" != "Ciphers aes128-ctr,aes192-ctr,aes256-ctr" ]
then
	sed -ie "36d" /etc/ssh/sshd_config
	sed -ie "36iCiphers aes128-ctr,aes192-ctr,aes256-ctr" /etc/ssh/sshd_config
fi

#10.11 remedy
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

#10.12 remedy
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

#10.13 remedy
remsshbanner=`grep "Banner" /etc/ssh/sshd_config | awk '{ print $2 }'`

if [ "$remsshbanner" == "/etc/issue.net" -o "$remsshbanner" == "/etc/issue" ]
then
	sed -ie "138d" /etc/ssh/sshd_config
	sed -ie "138iBanner /etc/issue.net" /etc/ssh/sshd_config
fi

#11.1
checkPassAlgo=$(authconfig --test | grep hashing | grep sha512)
checkPassRegex=".*sha512"
if [[ $checkPassAlgo =~ $checkPassRegex ]]
then
    	echo "The password hashing algorithm is set to SHA-512 as recommended."
else
    	authconfig --passalgo=sha512 --update
	doubleCheckPassAlgo2=$(authconfig --test | grep hashing | grep sha512)
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

#11.2
pampwquality=$(grep pam_pwquality.so /etc/pam.d/system-auth)
pampwqualityrequisite=$(grep "password    requisite" /etc/pam.d/system-auth)
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
echo "No Remediation needed."
else
sed -i -e 's/.*minlen.*/# minlen = 14/' -e 's/.*dcredit.*/# dcredit = -1/' -e  's/.*ucredit.*/# ucredit = -1/' -e 's/.*ocredit.*/# ocredit = -1/' -e 's/.*lcredit.*/# lcredit = -1/' /etc/security/pwquality.conf
echo "Remediation completed."
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

#11.4
pamlimitpw=$(grep "remember" /etc/pam.d/system-auth)
existingpamlimitpw=$(grep "password.*sufficient" /etc/pam.d/system-auth)
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

#11.6
pamsu=$(grep pam_wheel.so /etc/pam.d/su | grep required)
if [[ $pamsu =~ ^#auth.*required ]]
then
	sed -i 's/#.*pam_wheel.so use_uid/auth            required        pam_wheel.so use_uid/' /etc/pam.d/su
	echo "Remediation completed."
else
	echo "No remediation needed."
fi

pamwheel=$(grep wheel /etc/group)
if [[ $pamwheel =~ ^wheel.*root ]]
then
	echo "No remediation is needed."
else
	usermod -aG wheel root
	echo "Remediation completed."
fi