# Script Name: Register-Address-Field
# Description: Device-agnostic MAC Field registration for DSS-supported Laptops and Desktops 
# Author: Benedict Yi Chua
# Collaborators: None
# Last Updated 02-24-2020

#################################################################################

Write-Output "`n[ Mobile Access RegistrationScript - Field Mode ]`n"

$InformationPreference = 'Continue'
$WarningPreference = "Inquire"
$ErrorPreference = 'Stop'

#################################################################################

#String Compare Function

function Compare-String($ServiceName) { 

    $StringOne = Read-Host -Prompt "Enter $ServiceName"
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

#Checks IP Address for Validity. Will ask for re-entry.
function Set-IP() {

    $ValidIPString = "^([1-9]|[1-9][0-9]|1[0-9][0-9]|2[0-4][0-9]|25[0-5])(\.([0-9]|[1-9][0-9]|1[0-9][0-9]|2[0-4][0-9]|25[0-5])){3}$"
    
    $IPAddress = Compare-String("IP Address")

    if ($IPAddress -notmatch $ValidIPString) {

        Write-Warning -Message "`n[!] Invalid IP Address. Check entry and try again.`n"
        Set-IP($IPAddress)

    }

    else {
        return $IPAddress
    }
}

#################################################################################

#Gets Technician Full Name

Write-Output "`n<<<`tTechnician Assignment Identification >>>`n"

$TechnicianName = Compare-String("your name")

Write-Output "`n[i] Registering as $TechnicianName`n"

#################################################################################

#Gets Baseline System Information

Write-Output "`n<<<`tSystem Baseline Information >>>`n"

$SystemSerial = $(Get-WmiObject -Class win32_bios | select SerialNumber).serialNumber

Write-Output "`n[System Serial Number: $SystemSerial]"

$HwBuild = Get-WmiObject -Class:Win32_ComputerSystem | Select Name,Manufacturer,Model

Write-Output "[System Name: $($HwBuild.Name)]`n[System Model: $($HwBuild.Manufacturer) $($HwBuild.Model)]`n"


#################################################################################


#Get Network Hardware Information

Write-Output "`n<<<`tNetwork Hardware Information Gathering >>>`n"

#Create array with Network Adapter information

$NetworkHw = Get-NetAdapter | select MacAddress,Name,InterfaceDescription,Status

#Sort array so current active adapter is on top

$NetworkHw =  $NetworkHw | Sort-Object -Property Status -Descending

#Create blank array to fill with final information

$RegistrationArray = @() 

#Set constant values for registration

$AdminUCINetID = "ADCOMDSS"
$IPAddress = '' #Blank for this stage

#Desktop and Laptop Registration Process is the same, filter by interface name

foreach ($line in $NetworkHw) {

    #Checks for Docking Station entry and adds to object.

    if ($line.InterfaceDescription -like "*USB GbE*") {

    Write-Output "`n[i] Adding entry for Wired Dock..."

    $RegistrationObject = New-Object PSObject

    $RegistrationObject | Add-Member -MemberType NoteProperty -Name MACAddress -Value $($line.MacAddress)
    $RegistrationObject | Add-Member -MemberType NoteProperty -Name IPAddress -Value $IPAddress
    $RegistrationObject | Add-Member -MemberType NoteProperty -Name UCINetID -Value $AdminUCINetID
    $RegistrationObject | Add-Member -MemberType NoteProperty -Name Comment -Value "Computername: $($HwBuild.Name). Model: $($HwBuild.Model). SN# $SystemSerial. Wired Dock. Entered by $TechnicianName"

    $RegistrationArray += $RegistrationObject
    Write-Output "`n[i] Entry Added."

    }

    #Checks for Ethernet entry and adds to array. 

    ElseIf ($line.InterfaceDescription -like "*Ethernet Connection*") {

    Write-Output "`n[i] Adding entry for Wired Ethernet..."

    $RegistrationObject = New-Object PSObject

    $RegistrationObject | Add-Member -MemberType NoteProperty -Name MACAddress -Value $($line.MacAddress)
    $RegistrationObject | Add-Member -MemberType NoteProperty -Name IPAddress -Value $IPAddress
    $RegistrationObject | Add-Member -MemberType NoteProperty -Name UCINetID -Value $AdminUCINetID
    $RegistrationObject | Add-Member -MemberType NoteProperty -Name Comment -Value "Computername: $($HwBuild.Name). Model: $($HwBuild.Model). SN# $SystemSerial. Wired. Entered by $TechnicianName"

    $RegistrationArray += $RegistrationObject
    Write-Output "`n[i] Entry Added."

    }

    #Checks for Wireless entry and adds to object.

    ElseIf ($line.Name -like "*Wi-Fi*") {
        
    Write-Output "`n[i] Adding entry for Wireless Adapter..."

    $RegistrationObject = New-Object PSObject

    $RegistrationObject | Add-Member -MemberType NoteProperty -Name MACAddress -Value $($line.MacAddress)
    $RegistrationObject | Add-Member -MemberType NoteProperty -Name IPAddress -Value $IPAddress
    $RegistrationObject | Add-Member -MemberType NoteProperty -Name UCINetID -Value $AdminUCINetID
    $RegistrationObject | Add-Member -MemberType NoteProperty -Name Comment -Value "Computername: $($HwBuild.Name). Model: $($HwBuild.Model). SN# $SystemSerial. Wireless. Entered by $TechnicianName"

    $RegistrationArray += $RegistrationObject
    Write-Output "`n[i] Entry Added."

    }

}

Write-Host ($RegistrationArray | Format-Table | Out-String)
Write-Output "All registrations complete."

#################################################################################

#Assign IP Addresses

Write-Output "`n<<<`tIP Address Assignment`t>>>`n"

#Assigns IP Addresses to onboard and external NICs
#If multiple IP addresses to assign, option exists to assign IPs to individual NICs

Write-Output "`nEnter Primary IP Address to Register Below. Leave blank if no IP to assign.`n"

$IpPrimary = Set-IP(Compare-String("IP Address"))

if (($null -ne $IpPrimary) -and ($IpPrimary -ne '')) { 

    $RegistrationArray[0].IPAddress = $IpPrimary

}

while ($true) {

    $IpSecondary = Read-Host -Prompt "Enter Secondary IP Address to Register. Leave blank if no IP to assign."
    if (($null -eq $IpSecondary) -or ($IpSecondary -eq '')) {
        break
    }

    else {
        #Checks if the IP address is valid or not
        $IpAddressCheck = "((25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.){3}(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)"
        if ($IpSecondary -notmatch $IpAddressCheck) {
            Write-Host "`n[!] Invalid IP Address. Check entry and try again.`n"
        }
        else {
            $RegistrationArray[1].IPAddress = $IpSecondary
            break
        }
    }

}

Write-Host ($RegistrationArray | Format-Table | Out-String)
Write-Output "Registrations Updated"

#################################################################################

#CSV Output

Write-Host ($RegistrationArray | Format-List | Out-String)

$TempPath = "$($env:USERPROFILE)\Desktop\TEMP.txt"
$UserPath = "$($env:USERPROFILE)\Desktop\$($HwBuild.Name)-MacIpRegistration.txt"

$RegistrationArray | convertto-csv -NoTypeInformation -Delimiter "," | % {$_ -replace '"',''} | Out-File $TempPath

Get-Content $TempPath | select -Skip 1 | Out-File $UserPath

Remove-Item $TempPath

Read-Host -Prompt "Script Completed. Press Enter to exit."