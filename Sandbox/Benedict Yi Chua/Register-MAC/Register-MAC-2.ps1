# Script Name:  Register-MAC-2
# Description:  Device-agnostic MAC and IP registration for DSS-supported Laptops and Desktops
#               Dynamic adjustment for field and office use.
# Author:       Benedict Yi Chua
# Collaborators: None
# Last Updated  02-16-2020

#################################################################################

Write-Information -MessageData "`n[ Mobile Access Registration Script - Advanced ]`n"

# DEBUG | $null = Start-Transcript "$($env:USERPROFILE)\Desktop\Register-MAC-Debug.log"

$InformationPreference = 'Continue'
$WarningPreference = "Continue"
$ErrorActionPreference = 'Stop'

#################################################################################


# Person Lookup Function
function Get-DirectoryEntry {
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

# Current Technician Name Retrieval Function
# Uses UCI Directory if online, uses manual entry if offline 

function Get-Techname() {

    if ($env:UserName.ToLower() -eq "installer" -OR $env:UserName.ToLower() -eq "rfelange" -OR $env:UserName.ToLower() -eq "servi") {

        Write-Information -MessageData "- Registering Offline"
        $TechName = Compare-String("your name")
        return $TechName

    }

    elseif ($env:UserName.ToLower() -contains "-wa") {

        Write-Information -MessageData "- Registering Online"
        $TechName = ($env:UserName).replace("-wa", "").replace("ad\", "")
        $TechName = Get-DirectoryEntry -trait Name -person $TechName
        return $TechName

    } 
    
    else {
        Write-Error -Message ("[!] Could not register technician. Contact PowerTools Developers.")
    }

}

#################################################################################

# String Compare Function
function Compare-String($ServiceName) { 

    $StringOne = Read-Host -Prompt "Enter $ServiceName"

    if ($null -eq $StringOne) {

        return $StringOne

    } 
    $StringTwo = Read-Host -Prompt "Re-enter $ServiceName"

    if ($StringOne -eq $StringTwo) {

        return $StringOne

    }

    else {

        Write-Warning -Message "`n[!] Entries do not match.`n"
        Compare-String($ServiceName)

    }

}

#################################################################################

# IP Address Check Function
function Set-IP() {

    $ValidIPString = "^([1-9]|[1-9][0-9]|1[0-9][0-9]|2[0-4][0-9]|25[0-5])(\.([0-9]|[1-9][0-9]|1[0-9][0-9]|2[0-4][0-9]|25[0-5])){3}$"
    
    $IPAddress = Compare-String("IP Address")

    if ($IPAddress -match $ValidIPString) {

        Write-Information -MessageData "- Valid IP"
        return $IPAddress

    }

    elseif ($IPAddress -eq "" -or $null -eq $IPAddress){

        Write-Information -MessageData "- Blank IP"
        return $IPAddress

    }

    else {

        Write-Warning -Message "`n[!] Invalid IP Address. Check entry and try again.`n"
        Set-IP($IPAddress)

    }
}

#################################################################################

# Interface Documentation / Create Object Function
function New-RegistrationObject($ObjectLine, $ObjectType) { 

    $IPAddress = '' #Blank for this stage
    $AdminUCINetID = "ADCOMDSS"

    $RegistrationObject = New-Object PSObject

    $RegistrationObject | Add-Member -MemberType NoteProperty -Name MACAddress -Value $($ObjectLine.MacAddress)
    $RegistrationObject | Add-Member -MemberType NoteProperty -Name IPAddress -Value $IPAddress
    $RegistrationObject | Add-Member -MemberType NoteProperty -Name UCINetID -Value $AdminUCINetID
    $RegistrationObject | Add-Member -MemberType NoteProperty -Name Comment -Value "Computername: $($HwBuild.Name). Model: $($HwBuild.Model). SN# $($HwBuild.SerialNumber). $ObjectType. Entered by $TechName."

    $global:RegistrationArray += $RegistrationObject

}

#################################################################################

#Get Technician Full Name

Write-Information -MessageData "`n<<<`tTechnician Assignment Identification >>>`n"

$TechName = Get-Techname

Write-Information -MessageData "`n- Registering as $TechName`n"

#Get Baseline System Information

Write-Information -MessageData "`n<<<`tSystem Baseline Information >>>`n"

$HwBuild = Get-WmiObject -Class:Win32_ComputerSystem | Select-Object Name, Manufacturer, Model
$SystemSerial = $(Get-WmiObject -Class win32_bios | Select-Object SerialNumber).serialNumber
$HwBuild | Add-Member -Name 'SystemSerial' -Value $SystemSerial -MemberType NoteProperty

Write-Information -MessageData $HwBuild | Format-Table

#################################################################################

#Get Network Hardware Information

Write-Information -MessageData "`n<<<`tNetwork Hardware Information Gathering >>>`n"

#Create array with Network Adapter information

$NetworkHw = Get-NetAdapter | Select-Object MacAddress, Status, Name, InterfaceDescription | Sort-Object -Property Status -Descending

Write-Information -MessageData $NetworkHw | Format-Table

#Create blank array to fill with final information
$global:RegistrationArray = @() 

#Desktop and Laptop Registration Process is the same, filter by interface name

foreach ($line in $NetworkHw) {

    #Check for Docking Station entry and adds to object.

    if ($line.InterfaceDescription -like "*USB GbE*") {

        New-RegistrationObject($line, "Wired Dock")

    }

    #Check for Ethernet entry and adds to array. 
    ElseIf ($line.Name -like "*Ethernet*") {

        New-RegistrationObject($line, "Wired")

    }

    #Check for Wireless entry and adds to object.
    ElseIf ($line.Name -like "*Wi-Fi*") {

        New-RegistrationObject($line, "Wireless")

    }
}

Write-Information -MessageData ($RegistrationArray | Format-Table | Out-String)
Write-Information -MessageData "All Interfaces Indexed"

#################################################################################

#Assign IP Addresses

Write-Information -MessageData "`n<<<`tIP Address Assignment`t>>>`n"

#Assigns IP Addresses to onboard and external NICs
#If multiple IP addresses to assign, option exists to assign IPs to individual NICs

Write-Information -MessageData "`nEnter Primary IP Address to Register Below. Leave blank if no IP to assign.`n"

$IpPrimary = Set-IP
$RegistrationArray[0].IPAddress = $IpPrimary


Write-Information -MessageData "`nEnter Secondary IP Address to Register Below. Leave blank if no IP to assign.`n"

$IpSecondary = Set-IP
$RegistrationArray[1].IPAddress = $IpSecondary

Write-Information -MessageData "- Registrations Updated"

#################################################################################

#CSV-Like Output

Write-Information -MessageData "`n<<<`tFinal Registration Information`t>>>`n"

Write-Information -MessageData ($RegistrationArray | Format-List | Out-String)

$TempPath = "$($env:USERPROFILE)\Desktop\TEMP.txt"
$UserPath = "$($env:USERPROFILE)\Desktop\$($HwBuild.Name)-Mobile-Access-Reg.txt"

$RegistrationArray | convertto-csv -NoTypeInformation -Delimiter "," | ForEach-Object { $_ -replace '"', '' } | Out-File $TempPath

Get-Content $TempPath | Select-Object -Skip 1 | Out-File $UserPath

Remove-Item $TempPath

# DEBUG | $null = Stop-Transcript

Read-Host -Prompt "Script Completed. Batch Registration Text saved to Desktop.`n`nPress [Enter] to exit"