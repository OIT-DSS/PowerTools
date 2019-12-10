param(
    [Parameter(Mandatory = $true, 
                Position = 0)]
    [string]$UserID,

    [Parameter(Mandatory = $true, 
                Position = 1)]
    [string]$ServNowNumber,

    [switch]$Retire
)
#Variables start here
#Sets the $TechName var to the logged in users display name and removes "- RA"
$TechName = ([adsi]"WinNT://$env:userdomain/$env:username,user").fullname -replace " - RA", ""
$Today = (Get-Date -UFormat "%Y-%m-%d")

#Create note to be added to the users Description field on the General tab
$Note = "Restrictions set on $Today by $TechName, Service-Now: $ServNowNumber"

#Add the Restrictions note to the users AD
Set-ADUser -Identity $UserID -Description $Note

#Get the list of group memberships of the user and remove Domain Users from the list
$GroupList = (Get-ADPrincipalGroupMembership -Identity $UserID (Get-ADDomain).PDCEmulator).Name | Where-Object { $_ -ne "Domain Users"}

Set-ADUser -Identity $UserID -Replace @{info="$GroupList"}

#Remove the user from AD groups
foreach ($Group in $GroupList) {
    Remove-ADGroupMember -Identity $Group -Members $UserID -Confirm 
}
#Non Retirees set 90 day expiration date
Set-ADUser -Identity $UserID -AccountExpirationDate (Get-Date).AddDays(90)

#Get user profile path
[string]$UserProfilePath = Get-ADUser -Identity $UserID -Properties ProfilePath | select -ExpandProperty ProfilePath

#Check if the user has a profile path in AD
if (!$UserProfilePath) {
    
    Write-Host "The user does not have a user profile path listed in Active Directory"

} else {

    function Move-Homefolder {
        [CmdletBinding()]
        param(
            [Parameter(Mandatory = $true,
                        ValueFromPipeline=$True,
                        ValueFromPipelineByPropertyName = $true)]
            [string]$UserID
        )
        Process {
            #Set the path for the graveyard
            $GraveyardPath = '\\ad.uci.edu\UCI\OIT\Graveyard'

            #Remove the "\Profile from the end of the path to create $UserHomePath
            $UserHomePath = $UserProfilePath.Trim("\Profile")
        
            #Get number of files in the users Home folder
            $UserFileCount = Get-ChildItem \\$UserHomePath -Recurse | Measure-Object -Property length -Sum | select -ExpandProperty Count
        
            #Get Size of user home profile
            $UserHomeSize = (Get-ChildItem \\$UserHomePath -Recurse | Measure-Object -Property Length -Sum -ErrorAction Stop).Sum
            #convert to GB for display
            $UserHomeSizeGB = "{0:N2} GBs" -f ($UserHomeSize / 1GB)
        
            #Copy user Home folder to Graveyard
            Write-Progress "Copying $UserFileCount files totaling $UserHomeSizeGB of data"
            Copy-Item -Path \\$UserHomePath -Destination $GraveyardPath -Recurse -PassThru

            #Output file count and size for comparison before delete
            Write-Output $UserFileCount
            Write-Output $UserHomeSize
        }
    }
}





