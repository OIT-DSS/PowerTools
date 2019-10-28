# [WARNING - DO NOT USE THIS SCRIPT YET. IT IS UNDER CONSTRUCTION AND MAY MAKE UNDESIRED CHANGES TO TARGETED AD USER ACCOUNTS]

# Author(s): Benedict Yi Chua, Daniel Dubisz
# Collaborators: Ramon Garcia
# Organization: UC Irvine Office of Information Technology

# Script Name: Decommission-ADUser
# Description: Automated Decommission for Active Directory User Accounts managed by DSS
# Last Updated: 10-8-2019

Write-Output "`n[ DSS Active Directory User Decommission Powershell Script ]`n"

# Initialize Log File 
#   TO DO - Create Log File in Current Desktop

#################################################################################

# Gets Technician Full Name

Write-Output "`n<<<`tTechnician Assignment Identification >>>`n"

$ShortTechName = (whoami.exe | Out-String).replace("-wa", "").replace("ad\", "")

$FullTechName = Get-FullName -trait Name -person $ShortTechName

Write-Output "`n[i] Technician Identified in AD`n[i] Logging actions taken as $FullTechName`n"

#################################################################################

# Acquire ServiceNow Record of Account Decommission Ticket

Write-Output "`n<<<`tServiceNow Record Entry >>>`n"

$ServiceNowRecord = Read-Host -Prompt "Enter the ServiceNow record number for this request"

#################################################################################

# Acquire AD Username / UCINetID of Account Being Decommissioned

Write-Output "`n<<<`tTarget AD User Account to Decommission >>>`n"

$TargetADUser = Read-Host -Prompt "Enter the SAMAccountname or UCINetID of the account being decommissioned"

#################################################################################

# Define Function to Check LDAP if User Exists. 
#   If user exists, declare match exists.
#   If user does not exist, warn and note in log.

function Get-FullName {
    param (
        $trait,
        $person
    )
    $url = 'https://new-psearch.ics.uci.edu/people/' + $person
    $re_request = Invoke-WebRequest $url

    $myarray = $re_request.AllElements 

    $stuff = $myarray | Where-Object { $_.outerhtml -ceq "<SPAN class=label>$trait</SPAN>" -or $_.outerHTML -ceq "<SPAN class=table_label>$trait</SPAN>" }
 

    $name = ([array]::IndexOf($myarray, $stuff)) + 1

    $myarray[$name].innerText
}

#################################################################################

Write-Output "`n<<<`tAD User Account LDAP Checkpoint >>>`n"

# Gets Target ADUser Full Name. Runs check against Campus LDAP.

$LDAPFullName = Get-FullName -trait Name -person $TargetADUser

while ($True) {
    If (($LDAPFullName -eq ($Null)) -or ($LDAPFullName -eq '')) {
        Read-Host -Prompt "[!] LDAP Entry could not be verified. Please re-verify entry.
        Note that users separated from the University may have LDAP entries deleted before AD account decommission.
        Press [Enter] to dismiss this message and continue"
        # Note entry in log
        break
    }

    Else {

        Read-Host -Prompt "LDAP Verified for ADUser with full name $($LDAPFullName).
        Press [Enter] to dismiss this message and continue"
        # Note entry in log
        break
    }

}

#################################################################################

# Set account expiration to 90 days. Add restriction comment.

Write-Output "`n<<<`tAccount Expiration and Restriction Entry>>>`n"

Write-Output "`nSetting 90-day expiration...`n"
Get-ADUser -Filter {SamAccountName -eq $TargetADUser} | Set-ADUser -AccountExpirationDate (Get-Date).AddDays(90)

Write-Output "`nSetting account restriction comment...`n"
get-aduser -Identity $TargetADUser -Properties Description | ForEach-Object { Set-ADUser $_ -Description “RESTRICTED. $(Get-Date) $($FullTechName). Ticket $($ServiceNowRecord)." }


#################################################################################


Write-Output "`nSearching for AD User Accounts matching $(Get-ADUser $TargetADUser).name`n"

$ProfileSearchString = $TargetADUser + "*"

$LikeAccountsObject = Get-ADUser -Filter "SamAccountName -like '$ProfileSearchString'"

($LikeAccountsObject | Measure-Object).Count

"`r`n$(($LikeAccountsObject | Measure-Object).Count) account(s) detected for $TargetADUser `r"

#foreach will iterate through all the code at once for each object, then run all the code for the 2nd object, etc. 

#creates an array to store as many user profiles as are found by searching the net id, I think it should for the most part return only 1 profile.

$user_profiles = @()



#writes the SG's for the account in log

"`r`nSG's for $($unit.SamAccountName)`n`r" 

$userSG = ([ADSISEARCHER]"samaccountname=$($unit.SamAccountName)").Findone().Properties.memberof -replace '^CN=([^,]+).+$','$1' 
if ($userSG -eq "")
{
    "`r`nNo SG's for $($unit.SamAccountName) have been found.`n`r" 

}
else
{
$userSG 
}

#if profile is found, creates var for it to robocopy/delete later

if ((get-aduser $unit -properties ProfilePath | Select-Object profilepath).profilepath)
{
$profiled = (get-aduser $unit -properties ProfilePath | Select-Object profilepath).profilepath
$realprofile = $profiled -replace "users", "Users-ViewAll" -replace "Profile", "" 

$user_profiles += ,$realprofiled
}
 


#if no user profiles are found

if (!($user_profiles))
{
 "`r`nno profile for the user $($LikeAccountsObject[0].Name) has been found, no robocopy or profile deletion is needed."
 #inv
}

#if user profiles are found

if($user_profiles)
{

#creates graveyard directory
New-Item -Path \\ad.uci.edu\UCI\OIT\Graveyard\AD -name "$TargetADUser" -ItemType 'directory'

#takes ownership of users files so robocopy goes smoothly
ECHO 'Y' | takeown.exe /F $realprofile /R


Robocopy.exe $realprofile \\ad.uci.edu\UCI\OIT\Graveyard\AD\$TargetADUser /e

#after robocopy's done, compares the 2 folders to see if they are the same

$SourceDir = Get-ChildItem $realprofile -Recurse
$DestDir = Get-ChildItem -Recurse -Path \\ad.uci.edu\UCI\OIT\Graveyard\AD\$TargetADUser 


$result = Compare-Object -ReferenceObject $SourceDir -DifferenceObject $DestDir

if ($result)
{
    Write-Host "Error in copying, please manually check the files to make sure that everything is ok."
    invoke-item \\ad.uci.edu\UCI\OIT\Graveyard\AD\$TargetADUser
    Invoke-Item $realprofile
    Break
}

$finish = "Copied files for (AD\$TargetADUser) into the AD graveyard. Filepath: \\ad.uci.edu\UCI\OIT\Graveyard\AD\$TargetADUser. Deleted users profile. Closing ticket."

$finish 

remove-item -Path $realprofile -Force -Confirm

if (!(Test-Path $realprofile))
{
Write-Host "Account has succesfully been deleted."
}

}

Invoke-Item