<#  #>param(
    [parameter(Mandatory=$True)]
    [string]$UserID,
    [string]$ServNowNumber
    )
#Declaring variables
#Sets the $TechName var to the logged in users display name.
[string]$TechName = ([adsi]"WinNT://$env:userdomain/$env:username,user").fullname
$TechName = $TechName.Trim("- RA")
$Today = (Get-Date -UFormat "%Y-%m-%d")
$Note = "Restrictions set on $Today by $TechName, Service-Now: $ServNowNumber"

#Add the Restrictions note to the users AD
Set-ADUser -Identity $UserID -Description $Note

#Get the list of group memberships for the user
$GroupList = (Get-ADPrincipalGroupMembership -Identity $UserID -Server (Get-ADDomain).PDCEmulator).Name
<<<<<<< HEAD


#Remove "Domain Users" from the $Grouplist array
=======
#Remove "Domain Users" from the GroupList
>>>>>>> 3af838aab65fd25338efd77decac9ae6840e50d7
$GroupList = @($GroupList | Where-Object { $_ -ne "Domain Users"})

#Add List of groups to Telephone notes

Set-ADUser -Identity $UserID -Replace @{info="$GroupList"}

<<<<<<< HEAD
#Remove the user from groups
=======
#Remove the user from AD groups
>>>>>>> 3af838aab65fd25338efd77decac9ae6840e50d7
foreach ($Group in $GroupList) {
    Remove-ADGroupMember -Identity $Group -Members $UserID -Confirm
}
#Non Retirees set 90 day expiration date
Set-ADUser  -AccountExpirationDate (Get-Date).AddDays(90)

<<<<<<< HEAD




Describe  'User-Closeout' {

    Context 'Verifying user closeout process' {
=======
#Copy home folder data to Graveyard
>>>>>>> 3af838aab65fd25338efd77decac9ae6840e50d7

function Move-Homefolder {
    [CmdletBinding()]
    param(
        [Parameter(ValueFromPipeline=$True)]
        [string]$UserID
        )
    Process {

#Get user profile path
[string]$UserProfilePath = Get-ADUser -Identity $UserID -Properties ProfilePath | select -ExpandProperty ProfilePath
if (!$UserProfilePath) {
    Write-Host "The user does not have a user profile path in AD"
    }
    else {
    #Remove the "\Profile from the end of the path to create $UserHomePath
    $UserHomePath = $UserProfilePath.Trim("\Profile")
    #Get number of files in the users Home folder
    $UserFileCount = Get-ChildItem \\$UserHomePath -Recurse | Measure-Object -Property length -Sum | select -ExpandProperty Count
    #Get Size of user home profile
    $UserHomeSize = Get-ChildItem \\$UserHomePath -Recurse | Measure-Object -Property length -Sum | select -ExpandProperty Sum
    #Copy user Home folder to Graveyard
    Copy-Item -Path \\$UserHomePath -Destination \\ad.uci.edu\UCI\OIT\Graveyard -Recurse
    }
  }
}




$UserHomePath = $UserProfilePath.Trim("\Profile")

#Get number of files in the users Home folder
$UserFileCount = Get-ChildItem \\$UserHomePath -Recurse | Measure-Object -Property length -Sum | select -ExpandProperty Count
#Get Size of user home profile
$UserHomeSize = Get-ChildItem \\$UserHomePath -Recurse | Measure-Object -Property length -Sum | select -ExpandProperty Sum

Copy-Item -Path \\$UserHomePath -Destination \\ad.uci.edu\UCI\OIT\Graveyard -Recurse


