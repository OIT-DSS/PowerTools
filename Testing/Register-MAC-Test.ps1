# Script Name: RegisterMAC
# Description: Device-agnostic MAC registration for DSS-supported Laptops and Desktops 
# Author: Daniel Dubisz
# Collaborators: Benedict Yi Chua 
# Last Updated 09-19-2019

Write-Output "`n[ DSS Mobile Access Registration Powershell Script ]`n"

#################################################################################

#Person Lookup Function

function userinfo {
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

#Gets Technician Full Name

Write-Output "`n<<<`tTechnician Assignment Identification >>>`n"

$ShortName = (whoami.exe | Out-String).replace("-wa","").replace("ad\","")

$FullTechName = userinfo -trait Name -person $ShortName

Write-Output "`n[i] Technician Identified in AD`n[i] Registering as $FullTechName`n"

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
    $RegistrationObject | Add-Member -MemberType NoteProperty -Name Comment -Value "Computername: $($HwBuild.Name). Model: $($HwBuild.Model). SN# $SystemSerial. Wired Dock. Entered by $FullTechName"

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
    $RegistrationObject | Add-Member -MemberType NoteProperty -Name Comment -Value "Computername: $($HwBuild.Name). Model: $($HwBuild.Model). SN# $SystemSerial. Wired. Entered by $FullTechName"

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
    $RegistrationObject | Add-Member -MemberType NoteProperty -Name Comment -Value "Computername: $($HwBuild.Name). Model: $($HwBuild.Model). SN# $SystemSerial. Wireless. Entered by $FullTechName"

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

while ($true) {

    $IpPrimary = Read-Host -Prompt "Enter Primary IP Address to Register. Leave blank if no IP to assign."
    if (($null -eq $IpPrimary) -or ($IpPrimary -eq '')) {  
        break
    }

    else {
        #Checks if the IP address is valid or not
        $IpAddressCheck = "((25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.){3}(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)"
        if ($IpPrimary -notmatch $IpAddressCheck) {
            Write-Host "`n[!] Invalid IP Address. Check entry and try again.`n"
        }
        else {
            $RegistrationArray[0].IPAddress = $IpPrimary
            break
        }
    }

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

Get-Content TEMP.txt | select -Skip 1 | Out-File $UserPath

Remove-Item TEMP.txt

Read-Host -Prompt "Script Completed. Press Enter to exit."

rm $PSCommandPath