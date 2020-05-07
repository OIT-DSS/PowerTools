<#
.SYNOPSIS
    Creates a new AD account for OIT users
.DESCRIPTION
    The scripts pulls user data from the UCI LDAP database and the source user 
    provided by the requester. The collected data is used to create a new active
    directory account, set the roaming profile, create a roaming profile directory,
    create a random password for first login, and add new user to source user's 
    AD groups.
.PARAMETER SourceUser
    The UCINetID of the existing user to copy data from. 
.PARAMETER NewUser
    The UCINetID of the new user.
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory=$true,Position=0,ValueFromPipeline=$true)]
    [String]$SourceUser,
    [Parameter(Mandatory=$true,Position=1,ValueFromPipeline=$true)]
    [String]$NewUser
    )

#Generate random password for user's first login
$Password = New-DicewarePassword -PasswordMinWords 1 -PasswordMinLength 8

#Pull the new users data from UCILDAP.  If an LDAP account does not exist for $NewUser
#The script will notify the user and exit.        
try {
    $NewUserObj = Get-UciLdapUser -UCInetID $NewUser -ErrorAction Stop
}
catch {  
    
    Write-Warning -Message "User $NewUser not found at ldap.oit.uci.edu. Please check the UCINetID and try again."
    Read-Host -Prompt "Press any key to exit the script."
    exit
}
# $NewUserObjdisplayName = 'Test UserDSS'
# $NewUserObjgivenName = 'FirstName'
# $NewUserObjsn = 'LastName'

try {
    $SourceUserObj = Get-ADUser -Identity $SourceUser -Properties ProfilePath
}
catch {
    Write-Warning -Message "$SourceUser is not a valid Active Directory account"
    Read-Host -Prompt "Press the Enter key to continue."
    exit   
}
if (!$SourceUserObj.ProfilePath) {
    Write-Warning "$SourceUser does not have a roaming profile configured. 
    If $NewUser requires a roaming profile it will need to be manually added
    after the script has completed."
    Read-Host -Prompt "Press the Enter key to continue."
}
else {
    $NewProfilePath = $SourceUserObj.ProfilePath -replace $SourceUser, $NewUser
    Write-Host "A roaming profile directory will be created here: 
    $NewProfilePath"
    Read-Host -Prompt "Press the Enter key to continue."
    New-Item -Path $NewProfilePath -ItemType Directory
}
#Get the OU Path of the Source User
# try {
#     $OUPath = (Get-ADUser -Identity $SourceUser -ErrorAction Stop).DistinguishedName -split ',(?=OU)') | Select-Object -skip 1) -join ','
# }
# catch  {  
#     Write-Warning -Message "$SourceUser is not a valid Active Directory account"
#     Read-Host -Prompt "Press any key to exit the script."
#     exit 
# }
# #Check the Profile Path of the Source User, if the path exists it will by copied to the new user
# $ProfilePath = (Get-ADUser -Identity $SourceUser -Properties ProfilePath).ProfilePath 
#     if (!$ProfilePath) {
#        Write-Warning "$SourceUser does not have a roaming profile. $NewUser will not have a roaming profile created."
#        Read-Host -Prompt "Press any key to continue."
#     }
#     else {
#         $NewProfilePath = $ProfilePath -replace $SourceUser, $NewUser
#         Write-Host "A roaming profile directory will be created here: $NewProfilePath"
#         New-Item -Path $NewProfilePath -ItemType Directory
# }


#Parameters for new-aduser
$NewUserParams =  @{
    'SamAccountName'        = $NewUser
    'UserPrincipalName'     = "$NewUser@ad.uci.edu" 
    'Name'                  = $NewUserObj.displayName
    'GivenName'             = $NewUserObj.givenName
    'Surname'               = $NewUserObj.sn
    'DisplayName'           = $NewUserObj.displayName
    'AccountPassword'       = (ConvertTo-SecureString -AsPlainText $Password -Force)
    'ChangePasswordAtLogon' = $true 
    'Enabled'               = $true 
                               #Converts DistinguishedName to a format usable for the 'Path' Parameter
    'Path'                  = ($SourceUserObj.DistinguishedName -split ',(?=OU)') | Select-Object -skip 1) -join ','
    'ProfilePath'           = $NewProfilePath
    'Email'                 = $Email
}

#Create new AD user
New-ADUser @NewUserParams

#Collect and Display Group Memberships of Source User
$GroupList = (Get-ADPrincipalGroupMembership -Identity $SourceUser -Server (Get-ADDomain).PDCEmulator).Name | Where-Object { $_ -ne "Domain Users"}
Write-Host "$NewUser will be added to the following Active Directory Groups."
$GroupList 
Write-Host "Please make any changes to group memberships manually after the script has completed."
Read-Host -Prompt "Press the Enter key to continue."

#Add New user to the same groups as the Source User
foreach ($Group in $GroupList) {
    Add-ADGroupMember -Identity $Group -Members $NewUser
}

#Get-ADUser -Identity $SourceUser -Properties memberof | Select-Object -ExpandProperty memberof |  Add-ADGroupMember -Members $TargetUser
-
#Get and Set user permissions on the user profile directory
$Acl = Get-Acl -Path $NewProfilePath
$AccessRule = New-Object System.Security.AccessControl.FileSystemAccessRule("ad.uci.edu\$NewUser","Modify","ContainerInherit,ObjectInherit", "None", "Allow")
$Acl.SetAccessRule($AccessRule)
Set-Acl -Path $NewProfilePath -AclObject $Acl


#Need to display the changes made to the script user.  
#Make it easy to copy and paste temp password
#Output text file with all changes made
Write-Host "A new active directory account has been created for $NewUser.
Temporary Password:$Password
Group Memberships:
$GroupList
Roaming Profile: $NewProfilePath"








