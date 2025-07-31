#!/bin/bash
#
###############################################################################################################################################
#
# ABOUT THIS PROGRAM
#
#	SortOfNewbie.sh
#	https://github.com/Headbolt/SortOfNewbie
#
#   This Script is designed for use in JAMF
#
#   - This script will ...
#			Check and create an account, with a Secure Token
#
###############################################################################################################################################
#
# HISTORY
#
#	Version: 1.0 - 31/07/2025
#
#	- 31/07/2025 - V1.0 - Created by Headbolt
#
###############################################################################################################################################
#
# DEFINE VARIABLES & READ IN PARAMETERS
#
###############################################################################################################################################
#
adminUser="${3}" # Grab the current logged in username pre-defined JAMF variable #3
User="${4}" # Grab the username for the user we want to create from JAMF variable #4 eg. username
Pass="${5}" # Grab the password for the user we want to create from JAMF variable #5 eg. password
FV2="${6}" # Grab the option of whether to enable this user for FileVault from JAMF variable #6 eg. YES / NO
Options="${7}" # Grab the options to set for this user from JAMF variable #7 eg. -UID 81 -admin -shell /usr/bin/false -home /private/var/VAULT
#
ScriptVer=v1.0
ScriptName="MacOS | Check and Create Local Account" # Set the name of the script for later logging
#
####################################################################################################
#
#   Checking and Setting Variables Complete
#
###############################################################################################################################################
# 
# SCRIPT CONTENTS - DO NOT MODIFY BELOW THIS LINE
#
###############################################################################################################################################
#
# Defining Functions
#
###############################################################################################################################################
#
# Local User Eval Function
#
Eval(){
#
/bin/echo 'Checking for existence of user account "'$User'"'
/bin/echo # Outputting a Blank Line for Reporting Purposes
Process="" # Ensure Variable is initially blank
#
UserList=$(dscl . list /Users | grep $User) # Look for required username on device
#
if [[ "$UserList" != "" ]]
	then
    	/bin/echo '"'$User'" Exists'
        Process="YES"
	else
		/bin/echo '"'$User'" Does NOT Exist'
		Process="NO"
fi
#
}
#
###############################################################################################################################################
#
# Local User Password Collection Function
#
CollectPass(){
#
/bin/echo 'Asking User to re-input password'
#
read -r -d '' applescriptCode <<'EOF'
   set dialogText to text returned of (display dialog "Please Re-Enter your Password" default answer "" with hidden answer)
   return dialogText
EOF
#
adminPass=$(osascript -e "$applescriptCode") # Grab User Input
AdminCreds="-adminUser $adminUser -adminPassword $adminPass" # Construct the Admin creds into 1 simple to use variable
SectionEnd
#
}
#
###############################################################################################################################################
#
# Admin Account Perms Check Function
#
PermsCheck(){
#
Elevated="" # Ensure Variable is initially blank
#
/bin/echo 'Checking if user "'$adminUser'" is an admin'
/bin/echo # Outputting a Blank Line for Reporting Purposes
#
CurrentLocalADAdmins=$(dscacheutil -q group -a name admin | grep "users" | grep -i $adminUser)
#
if [[ "$CurrentLocalADAdmins" != "" ]]
	then
		/bin/echo 'User "'$adminUser'" is an admin'
		Elevated="YES"
	else
		/bin/echo 'User "'$adminUser'" is NOT an admin'
		Elevate
		Elevated="YES"
fi
#
}
#
###############################################################################################################################################
#
# Temporary Admin Account Elevation Function
#
Elevate(){
#
SectionEnd
/bin/echo 'Temporarily making user "'$adminUser'" an admin'
#
ElevateCommand1="sudo dscl . -append /Groups/admin GroupMembership $adminUser" # Construct command to be run
ElevateCommand2="sudo dscl . -merge /Groups/admin GroupMembership $adminUser" # Construct command to be run
#
##### For Degugging un-comment these 5 lines
#SectionEnd
#/bin/echo 'Debug Mode'
#/bin/echo # Outputting a Blank Line for Reporting Purposes
#/bin/echo 'Command being run is "'$ElevateCommand1'"'
#/bin/echo 'Command being run is "'$ElevateCommand2'"'
#####
#
$ElevateCommand1 # Run Command
$ElevateCommand2 # Run Command
#
}
#
###############################################################################################################################################
#
# Temporary Admin Account Demote Function
#
Demote(){
#
SectionEnd
/bin/echo 'User "'$adminUser'" was temporarily made an admin, demoting'
#
DemoteCommand1="dseditgroup -o edit -d $adminUser admin" # Construct command to be run
DemoteCommand2="dseditgroup -o edit -d $adminUser _appserveradm" # Construct command to be run
DemoteCommand3="dseditgroup -o edit -d $adminUser _appserverusr" # Construct command to be run
#
##### For Degugging un-comment these 5 lines
#SectionEnd
#/bin/echo 'Debug Mode'
#/bin/echo # Outputting a Blank Line for Reporting Purposes
#/bin/echo 'Command being run is "'$DemoteCommand1'"'
#/bin/echo 'Command being run is "'$DemoteCommand2'"'
#/bin/echo 'Command being run is "'$DemoteCommand3'"'
#####
#
$DemoteCommand1 # Run Command
$DemoteCommand2 # Run Command
$DemoteCommand3 # Run Command
#
/bin/echo # Outputting a Blank Line for Reporting Purposes
/bin/echo 'Local admins are ...'
dscacheutil -q group -a name admin | grep "users" | cut -c 8-
#
}
#
###############################################################################################################################################
#
# Account Creation Function
#
Creation(){
#
CollectPass
#
/bin/echo 'Creating User "'$User'"'
/bin/echo "with the options $Options"
/bin/echo # Outputting a Blank Line for Reporting Purposes
#
SysAdminCommand="sysadminctl "$AdminCreds" -addUser "$User" -fullName "$User" "${Options}" -password "$Pass"" # Construct Final command to be run
$SysAdminCommand # Run Command
#
#Debug # Debug Function used to check what command gets run in the logs incase of issues.
#
SectionEnd
TokenCheck
#
}
#
###############################################################################################################################################
#
# Token Check Function
#
TokenCheck(){
#
/bin/echo "Checking Secure Token Status for $User Account"
NewUserStatus=$(sysadminctl -secureTokenStatus $User 2>&1)
NewUserToken=$(echo $NewUserStatus | awk '{print $7}')
/bin/echo '"'$User'" secureTokenStatus = '$NewUserToken''
#
}
#
###############################################################################################################################################
#
# Token Add Function
#
TokenAdd(){
#
SectionEnd
CollectPass
#
/bin/echo "Attempting Token Add"
#
SysAdminCommand="sysadminctl "$AdminCreds" -secureTokenOn "$User" -password "$Pass""
/bin/echo # Outputs a blank line for reporting purposes
$SysAdminCommand # Run Command
#
#Debug # Debug Function used to check what command gets run in the logs incase of issues.
#
/bin/echo "Re-Checking Secure Token Status"
/bin/echo # Outputs a blank line for reporting purposes
TokenCheck
#
}
#
###############################################################################################################################################
#
# Debug Function
#
Debug(){
#
SectionEnd
/bin/echo 'Debug Mode'
/bin/echo # Outputting a Blank Line for Reporting Purposes
/bin/echo 'Command being run is "'$SysAdminCommand'"'
#
SectionEnd
#
}
#
###############################################################################################################################################
#
# Script Start Function
#
ScriptStart(){
#
/bin/echo # Outputting a Blank Line for Reporting Purposes
SectionEnd
/bin/echo Starting Script '"'$ScriptName'"'
/bin/echo Script Version '"'$ScriptVer'"'
/bin/echo # Outputting a Blank Line for Reporting Purposes
/bin/echo  ----------------------------------------------- # Outputting a Dotted Line for Reporting Purposes
/bin/echo # Outputting a Blank Line for Reporting Purposes
#
}
#
###############################################################################################################################################
#
# Section End Function
#
SectionEnd(){
#
/bin/echo # Outputting a Blank Line for Reporting Purposes
/bin/echo  ----------------------------------------------- # Outputting a Dotted Line for Reporting Purposes
/bin/echo # Outputting a Blank Line for Reporting Purposes
#
}
#
###############################################################################################################################################
#
# Script End Function
#
ScriptEnd(){
/bin/echo Ending Script '"'$ScriptName'"'
/bin/echo # Outputting a Blank Line for Reporting Purposes
/bin/echo  ----------------------------------------------- # Outputting a Dotted Line for Reporting Purposes
/bin/echo # Outputting a Blank Line for Reporting Purposes
#
}
#
###############################################################################################################################################
#
# End Of Function Definition
#
###############################################################################################################################################
# 
# Begin Processing
#
####################################################################################################
#
ScriptStart
#
Eval
SectionEnd
#
if [[ "$Process" = "NO" ]]
	then
		PermsCheck
		SectionEnd
    	Creation
	else
		/bin/echo '"'$User'" Exists already'
		/bin/echo # Outputting a Blank Line for Reporting Purposes
		TokenCheck
		#
		if [[ "$NewUserToken" != "ENABLED" ]]
			then
				SectionEnd
				PermsCheck
				TokenAdd
		fi
		#
        SectionEnd
		UserElevated="" # Ensure Variable is initially blank
		#
		/bin/echo 'Checking if user "'$User'" is an admin'
		/bin/echo # Outputting a Blank Line for Reporting Purposes
		#
		CurrentLocalAdmins=$(dscacheutil -q group -a name admin | grep "users" | grep -i $User)
		#
		if [[ "$CurrentLocalAdmins" != "" ]]
			then
				/bin/echo 'User "'$User'" is an admin'
			else
				/bin/echo 'User "'$User'" is NOT an admin'
				SectionEnd
				/bin/echo 'Making user "'$User'" an admin'
				#
				ElevateCommandA="sudo dscl . -append /Groups/admin GroupMembership $User" # Construct command to be run
				ElevateCommandB="sudo dscl . -merge /Groups/admin GroupMembership $User" # Construct command to be run
				#
				##### For Degugging un-comment these 5 lines
				#SectionEnd
				#/bin/echo 'Debug Mode'
				#/bin/echo # Outputting a Blank Line for Reporting Purposes
				#/bin/echo 'Command being run is "'$ElevateCommandA'"'
				#/bin/echo 'Command being run is "'$ElevateCommandB'"'
				#####
				#
				$ElevateCommandA # Run Command
				$ElevateCommandB # Run Command
				/bin/echo # Outputting a Blank Line for Reporting Purposes
				/bin/echo 'New admins list is ....'
				dscacheutil -q group -a name admin | grep "users" | cut -c 8-            
		fi
fi
#
if [[ "$Elevated" != "" ]]
	then
		Demote
fi
#
SectionEnd
ScriptEnd
