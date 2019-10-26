# Script Name: Register-MAC-Test-2
# Description: Device-agnostic MAC registration for DSS-supported Laptops and Desktops 
# Author: Daniel Dubisz 
# Collaborators: Benedict Yi Chua 
# Last Updated 10-24-2019

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

$ShortName = (whoami.exe | Out-String).replace("-wa", "").replace("ad\", "")

$FullTechName = userinfo -trait Name -person $ShortName

Write-Output "`n[i] Technician Identified in AD`n[i] Registering as $FullTechName`n"

#################################################################################

#Gets Baseline System Information

Write-Output "`n<<<`tSystem Baseline Information >>>`n"

$SystemSerial = $(Get-WmiObject -Class win32_bios | select SerialNumber).serialNumber

Write-Output "`n[System Serial Number: $SystemSerial]"

$HwBuild = Get-WmiObject -Class:Win32_ComputerSystem | Select Name, Manufacturer, Model

Write-Output "[System Name: $($HwBuild.Name)]`n[System Model: $($HwBuild.Manufacturer) $($HwBuild.Model)]`n"


#################################################################################


#Get Network Hardware Information

Write-Output "`n<<<`tNetwork Hardware Information Gathering >>>`n"

#Create array with Network Adapter information

$NetworkHw = Get-NetAdapter | select MacAddress, Name, InterfaceDescription, Status

#Sort array so current active adapter is on top

$NetworkHw = $NetworkHw | Sort-Object -Property Status -Descending

#Create blank array to fill with final information



#Set constant values for registration

$AdminUCINetID = "ADCOMDSS"
$IPAddress = '' #Blank for this stage

#Desktop and Laptop Registration Process is the same, filter by interface name

#D: created function for the creation of each powershell object
function regline {

    param (
        $Type
    )
    $RegistrationObject = New-Object PSObject

    $RegistrationObject | Add-Member -MemberType NoteProperty -Name MACAddress -Value $($line.MacAddress)
    $RegistrationObject | Add-Member -MemberType NoteProperty -Name IPAddress -Value $IPAddress
    $RegistrationObject | Add-Member -MemberType NoteProperty -Name UCINetID -Value $AdminUCINetID
    #D: created new property to catagorize the objects for later registration 
    $RegistrationObject | Add-Member -MemberType NoteProperty -Name Type -Value $Type 
    $RegistrationObject | Add-Member -MemberType NoteProperty -Name Comment -Value "Computername: $($HwBuild.Name). Model: $($HwBuild.Model). SN# $SystemSerial. $Type. Entered by $FullTechName"

    $script:RegistrationArray += $RegistrationObject
    Write-Output "`n[i] Entry Added."


}

$RegistrationArray = @() 

#D: as you can see, function calls where there used to be more lines, plus we could perhaps modify the function for later use in other scripts

foreach ($line in $NetworkHw) {

    #Checks for Docking Station entry and adds to object.

    if ($line.InterfaceDescription -like "*USB GbE*") {

        Write-Output "`n[i] Adding entry for Wired Dock..."

        regline -Type "Wired Dock"

    }

    #Checks for Ethernet entry and adds to array. 

    ElseIf ($line.InterfaceDescription -like "*Ethernet Connection*") {

        Write-Output "`n[i] Adding entry for Wired Ethernet..."

        regline -Type "Wired"

    }
    #Checks for Wireless entry and adds to object.

    ElseIf ($line.Name -like "*Wi-Fi*") {
        
        Write-Output "`n[i] Adding entry for Wireless Adapter..."

        regline -Type "Wireless"

    }
}
Write-Host ($RegistrationArray | Format-Table | Out-String)
Write-Output "All registrations complete."

#################################################################################

#Assign IP Addresses

Write-Output "`n<<<`tIP Address Assignment`t>>>`n"

#Assigns IP Addresses to onboard and external NICs
#If multiple IP addresses to assign, option exists to assign IPs to individual NICs


#D: Here's where I did the most change, 

# To protect against edge case for accidently asking for ip reg for wifi, and to condense the two ip loops, I created a loop for each of the entries.

# We use the new property of the object "Value" to see if they are going to need ip registration or not

# for each that do, we can just use the same variables to slot the ip into the right object in registration-array

# after the loop goes through the object, we remove the extra property that I made, as we don't need it anymore and so that your nicely made output to csv file remains correct,

# I did enjoy discovering how that worked, very neat.  


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

#D: Here I noticed that if we use temporary file for the temp file, we can run the command from wherever and don't have to 
# put it on the desktop, I think that'd be more convienient. 

$tempf = New-TemporaryFile
$UserPath = "$($env:USERPROFILE)\Desktop\$($HwBuild.Name)-MacIpRegistration.txt"

$RegistrationArray | convertto-csv -NoTypeInformation -Delimiter "," | % { $_ -replace '"', '' } | Out-File $tempf

Get-Content $tempf | select -Skip 1 | Out-File $UserPath

Remove-Item $tempf

Read-Host -Prompt "Script Completed. Press Enter to exit."