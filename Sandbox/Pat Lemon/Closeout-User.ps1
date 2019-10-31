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
#Remove "Domain Users" from the $Grouplist array
$GroupList = @($GroupList | Where-Object { $_ -ne "Domain Users"})

#Add List of groups to Telephone notes
Set-ADUser -Identity $UserID -Replace @{info="$GroupList"}

#Remove the user from groups
foreach ($Group in $GroupList) {
    Remove-ADGroupMember -Identity $Group -Members $UserID
}





Describe  'User-Closeout' {

    Context 'Verifying user closeout process' {

        It 'Restrictions Note has been set' {
            Get-AdUser -Identity $UserID -Properties Description | Select-Object -ExpandProperty Description | Should be $Note
        }
        It 'List of group memberships set' {
            Get-AdUser -Identity $UserID -Properties info | Select-Object -ExpandProperty info | Should be $GroupList

        }
    }
}
