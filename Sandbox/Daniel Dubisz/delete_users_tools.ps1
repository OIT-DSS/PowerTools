

#gets accounts all accounts in AD that have the usersname var at the beginning, to see if they have any extra accounts like -wa.

#note: you can have the box that asks the users for everything, but then if there's a problem with the username then just have them write it in again.
do {
$usersname = "mjsahaky"


$userFromTicket = Get-ADUser $usersname

#shows all the groups that the user is part of

$correctUserResponse = Read-Host "is $($userFromTicket.Name) the correct user as seen on the ticket? [Y\N]"

if ($correctUserResponse -eq 'Y')
{
break
}

if ($correctUserResponse -eq 'N')
{
Write-Host "Please put in the information again"
}
}
while($correctUserResponse -ne 'Y')

$profileSearch = $usersname + "*"

$accounts = Get-ADUser -Filter "SamAccountName -like '$profileSearch'"

#informs user of how many accounts were found. 

#whichever line is first, use set content to reset the file

invoke-item "C:\temp\Dan_D\closingremarks.txt"


($accounts | Measure-Object).Count

"`r`n$(($accounts | Measure-Object).Count) account(s) detected for $usersname `r" | Set-Content C:\temp\Dan_D\closingremarks.txt


#foreach will iterate through all the code at once for each object, then run all the code for the 2nd object, etc. 

#creates an array to store as many user profiles as are found by searching the net id, I think it should for the most part return only 1 profile.

$user_profiles = @()

foreach ($unit in $accounts) {

#writes the accounts name in log

"`r`n$($unit.Name)`n" | Add-Content  C:\temp\Dan_D\closingremarks.txt


#writes the SG's for the account in log

"`r`nSG's for $($unit.SamAccountName)`n`r" | Add-Content C:\temp\Dan_D\closingremarks.txt

$userSG = ([ADSISEARCHER]"samaccountname=$($unit.SamAccountName)").Findone().Properties.memberof -replace '^CN=([^,]+).+$','$1' 
if ($userSG -eq "")
{
    "`r`nNo SG's for $($unit.SamAccountName) have been found.`n`r" | Add-Content C:\temp\Dan_D\closingremarks.txt

}
else
{
$userSG | Add-Content C:\temp\Dan_D\closingremarks.txt
}

#if profile is found, creates var for it to robocopy/delete later

if ((get-aduser $unit -properties ProfilePath | Select-Object profilepath).profilepath)
{
$profiled = (get-aduser $unit -properties ProfilePath | Select-Object profilepath).profilepath
$realprofile = $profiled -replace "users", "Users-ViewAll" -replace "Profile", "" 

$user_profiles += ,$realprofiled
}
 
}

#if no user profiles are found

if (!($user_profiles))
{
 "`r`nno profile for the user $($accounts[0].Name) has been found, no robocopy or profile deletion is needed."
 inv
}

#if user profiles are found

if($user_profiles)
{

#creates graveyard directory
New-Item -Path \\ad.uci.edu\UCI\OIT\Graveyard\AD -name "$usersname" -ItemType 'directory'

#takes ownership of users files so robocopy goes smoothly
ECHO 'Y' | takeown.exe /F $realprofile /R


Robocopy.exe $realprofile \\ad.uci.edu\UCI\OIT\Graveyard\AD\$usersname /e

#after robocopy's done, compares the 2 folders to see if they are the same

$SourceDir = Get-ChildItem $realprofile -Recurse
$DestDir = Get-ChildItem -Recurse -Path \\ad.uci.edu\UCI\OIT\Graveyard\AD\$usersname 


$result = Compare-Object -ReferenceObject $SourceDir -DifferenceObject $DestDir

if ($result)
{
    Write-Host "Error in copying, please manually check the files to make sure that everything is ok."
    invoke-item \\ad.uci.edu\UCI\OIT\Graveyard\AD\$usersname
    Invoke-Item $realprofile
    Break
}

$finish = "Copied files for (AD\$usersname) into the AD graveyard. Filepath: \\ad.uci.edu\UCI\OIT\Graveyard\AD\$usersname. Deleted users profile. Closing ticket."

$finish | Add-Content  C:\temp\Dan_D\closingremarks.txt

remove-item -Path $realprofile -Force -Confirm

if (!(Test-Path $realprofile))
{
Write-Host "Account has succesfully been deleted."
}

}

Invoke-Item