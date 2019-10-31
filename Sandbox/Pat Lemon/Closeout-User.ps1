<#  #>param(
    [parameter(Mandatory=$True)]
    [string]$UserID,
    [string]$ServNowNumber
    )
#Sets the $TechName var to the logged in users display name. 
#Need to work on removing "- RA"
$TechName = ([adsi]"WinNT://$env:userdomain/$env:username,user").fullname
$Today = (Get-Date -UFormat "%Y-%m-%d")
$Note = "Restrictions set on $Today by $TechName, Service-Now: $ServNowNumber"

#Add the Restrictions note to the users AD
Set-ADUser -Identity $UserID -Description $Note

#Get the list of group memberships for the user
$GroupList = (Get-ADPrincipalGroupMembership -Identity $UserID -Server (Get-ADDomain).PDCEmulator).Name
#Remove "Domain Users" from the GroupList
$GroupList = @($GroupList | Where-Object { $_ =ne "Domain Users"})

#Add List of groups to Telephone notes
Set-ADUser -Identity $UserID -Replace @{info="$GroupList"}

foreach ($Group in $GroupList) {
    Remove-ADGroupMember -Identity $Group -Members $UserID
}
