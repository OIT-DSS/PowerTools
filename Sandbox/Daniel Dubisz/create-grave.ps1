#grabs who you are
do {
$usersname = "vadebona"


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



$me = $env:USERNAME -replace "-ra", ""

New-Item -Path \\ad.uci.edu\UCI\OIT\Graveyard\AD -name "$usersname" -ItemType 'directory'

#selects user profile path, changes it to the one in users view all, then robocopys it into the new folder in AD graveyard. comment no longer relevant -> also have had some trouble
#with setting permissions for robocopy for v2, so will auto make that under my account before robo copy. 

$profiled = (get-aduser $usersname -properties ProfilePath | Select-Object profilepath).profilepath 
$realprofile = $profiled -replace "users", "Users-ViewAll" -replace "Profile", "" 

#takes ownership of users files so robocopy goes smoothly
#takeown /F $realprofile /R


Robocopy.exe $realprofile \\ad.uci.edu\UCI\OIT\Graveyard\AD\$usersname /e

#after robocopy's done, compares the 2 folders to see if they are the same

$SourceDir = Get-ChildItem $realprofile -Recurse
$DestDir = Get-ChildItem -Recurse -Path \\ad.uci.edu\UCI\OIT\Graveyard\AD\$usersname 

Compare-Object -ReferenceObject $SourceDir -DifferenceObject $DestDir
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

Invoke-Item  C:\temp\Dan_D\closingremarks.txt

Invoke-Item $realprofile

remove-item -Path $realprofile -Force -Confirm

if (!(Test-Path $realprofile))
{
Write-Host "Account has succesfully been deleted."
}
