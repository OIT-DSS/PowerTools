<#  #>param(
    [parameter(Mandatory=$True)]
    [string]$UserID,
    [string]$ServNowNumber
    )
#Sets the $TechName var to the logged in users display name. Need to work on removing "- RA"
$TechName = ([adsi]"WinNT://$env:userdomain/$env:username,user").fullname
#Get todays date in [yyyy-mm-dd] format
$Today = (Get-Date -UFormat "%Y-%m-%d")

function Set-RestrictNote {
    [CmdletBinding()]
    param(
        [parameter(Mandatory=$True,ValueFromPipeline=$True,ValueFromPipelineByPropertyName=$true)]
        [string]$UserID,
        [string]$ServNowNumber
        )
#End of Parameters
    Process {
    $Note = "Restrictions set on $Today by $TechName, Service-Now: $ServNowNumber"
    #Write the notes to the Description field on the General tab
    Write-Host -ForegroundColor Green "Note added to description field: `n$Note"
    Set-ADUser -Identity $UserID -Description $Note
    }
#End of Process
}<#  #>
function Get-Grouplist {
    [CmdletBinding()]
    param(
        [parameter(Mandatory=$True,ValueFromPipeline=$True,ValueFromPipelineByPropertyName=$true)]
        [string]$UserID
        )
#End of Parameters
    Process {
    #Collect list of AD Group Memberships
    #Need to remove "Domain Users from $GroupList
    Write-Host -ForegroundColor Green "Collecting list of group memberships for $UserID"
    $GroupList = (Get-ADPrincipalGroupMembership -Identity $UserID -Server (Get-ADDomain).PDCEmulator).Name
    Write-Host -ForegroundColor Green "List of groups collected for $UserID"
    Write-Output $GroupList
    }
#End of Process
}

function Set-GrouplistNote {
    [CmdletBinding()]
    param(
        [parameter(Mandatory=$True,ValueFromPipeline=$True,ValueFromPipelineByPropertyName=$true)]
        [string[]]$GroupList,
        [parameter(Mandatory=$True,ValueFromPipeline=$True,ValueFromPipelineByPropertyName=$true)]
        [string]$UserID
        )
#End of Parameters
    Process {
        foreach ($Group in $GroupList) {
            Set-ADUser -Identity $UserID -Replace @{info="$GroupList"}
        }
    }
 }

function Remove-Memberships {
    [CmdletBinding()]
    param(
        [parameter(Mandatory=$True,ValueFromPipeline=$True,ValueFromPipelineByPropertyName=$true)]
        [string[]]$GroupList,
        [parameter(Mandatory=$True,ValueFromPipeline=$True,ValueFromPipelineByPropertyName=$true)]
        [string]$UserID
        #End of Parameters
    Process {

