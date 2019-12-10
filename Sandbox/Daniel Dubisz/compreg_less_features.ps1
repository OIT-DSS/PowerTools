# Author(s): Benedict Yi Chua, Daniel Dubisz
# Collaborators: Ramon Garcia
# Organization: UC Irvine Office of Information Technology

# Script Name: Register-MAC-Test-2
# Description: Device-agnostic MAC registration for DSS-supported Laptops and Desktops
# Last Updated: 10-24-2019

Write-Output "`n[ DSS Mobile Access Registration Powershell Script ]`n"

#################################################################################

# UCINetID Lookup, returns full name corresponding to given UCINetID

function Get-FullName {
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

# Gets Technician Full Name

Write-Output "`n<<<`tTechnician Assignment Identification >>>`n"

$ShortName = (whoami.exe | Out-String).replace("-wa", "").replace("ad\", "")

$FullTechName = Get-FullName -trait Name -person $ShortName

Write-Output "`n[i] Technician Identified in AD`n[i] Registering as $FullTechName`n"

#################################################################################

# Gets Baseline System Information

Write-Output "`n<<<`tSystem Baseline Information >>>`n"

$SystemSerial = $(Get-WmiObject -Class win32_bios | select SerialNumber).serialNumber

Write-Output "`n[System Serial Number: $SystemSerial]"

$HwBuild = Get-WmiObject -Class:Win32_ComputerSystem | Select Name, Manufacturer, Model

Write-Output "[System Name: $($HwBuild.Name)]`n[System Model: $($HwBuild.Manufacturer) $($HwBuild.Model)]`n"

#################################################################################

# Get Network Hardware Information

Write-Output "`n<<<`tNetwork Hardware Information Gathering >>>`n"

# Create array with Network Adapter information

$NetworkHw = Get-NetAdapter | select MacAddress, Name, InterfaceDescription, Status

# Sort array so current active adapter is on top

$NetworkHw = $NetworkHw | Sort-Object -Property Status -Descending

#Set constant values for registration

$AdminUCINetID = "ADCOMDSS"
$IPAddress = '' #Blank for this stage

#Desktop and Laptop Registration Process is the same, filter by interface name

# Generic function to create object containing individual registration entry

function Create-RegObject {

    param (
        $Type
    )
    $RegistrationObject = New-Object PSObject

    $RegistrationObject | Add-Member -MemberType NoteProperty -Name MACAddress -Value $($line.MacAddress)
    $RegistrationObject | Add-Member -MemberType NoteProperty -Name IPAddress -Value $IPAddress
    $RegistrationObject | Add-Member -MemberType NoteProperty -Name UCINetID -Value $AdminUCINetID
    $RegistrationObject | Add-Member -MemberType NoteProperty -Name Type -Value $Type 
    $RegistrationObject | Add-Member -MemberType NoteProperty -Name Comment -Value "Computername: $($HwBuild.Name). Model: $($HwBuild.Model). SN# $SystemSerial. $Type. Entered by $FullTechName"

    $script:RegistrationArray += $RegistrationObject
    Write-Output "`n[i] Entry Added."


}

$RegistrationArray = @() 

#D: as you can see, function calls where there used to be more lines, 
# plus we could perhaps modify the function for later use in other scripts

foreach ($line in $NetworkHw) {

    #Checks for Docking Station entry and adds to object.

    if ($line.InterfaceDescription -like "*USB GbE*") {

        Write-Output "`n[i] Adding entry for Wired Dock..."

        Create-RegObject -Type "Wired Dock"

    }

    #Checks for Ethernet entry and adds to array. 

    ElseIf ($line.InterfaceDescription -like "*Ethernet Connection*") {

        Write-Output "`n[i] Adding entry for Wired Ethernet..."

        Create-RegObject -Type "Wired"

    }
    #Checks for Wireless entry and adds to object.

    ElseIf ($line.Name -like "*Wi-Fi*") {
        
        Write-Output "`n[i] Adding entry for Wireless Adapter..."

        Create-RegObject -Type "Wireless"

    }
}
Write-Host ($RegistrationArray | Format-Table | Out-String)
Write-Output "All registrations complete."

#################################################################################

# Assign IP Addresses

Write-Output "`n<<<`tIP Address Assignment`t>>>`n"

# Assigns IP Addresses to onboard and external NICs
# If multiple IP addresses to assign, option exists to assign IPs to individual NICs

foreach ($entries in $RegistrationArray) {
    if (!($entries.Type -like "Wireless")) {
        while ($true) {
            
            $IpPrimary = Read-Host -Prompt "Enter IP Address for the $($entries.Type) connection to Register. Leave blank if no IP to assign."
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
                
                    $entries.IPAddress = $IpPrimary
                    break
                }
                
            }

        }
    }
    Write-Host "`n"
    $entries.PSObject.properties.remove('Type')
}

Write-Host ($RegistrationArray | Format-Table | Out-String)
Write-Output "Registrations Updated"

#################################################################################

#CSV Output

Write-Host ($RegistrationArray | Format-List | Out-String)

#opens up page for registration

$tempf = New-TemporaryFile

Invoke-WebRequest 'http://apps.oit.uci.edu/mobileaccess/admin/mac/add_bulk.php' | Out-File $tempf

Remove-Item $tempf 

$NoFormatTempFile = New-TemporaryFile

$RegistrationArray | convertto-csv -NoTypeInformation -Delimiter "," | % { $_ -replace '"', '' } | Out-File $NoFormatTempFile

Get-Content $NoFormatTempFile | select -Skip 1 | clip

Remove-Item $NoFormatTempFile

Read-Host -Prompt "Script Completed. Bulk Registrations written to Desktop. Press Enter to exit."