
Write-Output "DSS Mobile Access Registration Powershell Script"

#Prompts user to enter device type for registration purposes.

Write-Output "`n<<<`tDevice Type Selection`t>>>`n"

while ($true) {

    $deviceType = Read-Host -Prompt "Is this a [l]aptop or a [d]esktop? [l/d] "

    if ($deviceType -ne "l" -and $deviceType -ne "d") {
        Write-Output "[!] Device type not recognized. Please enter a device type."
    }
        
    else {
        Write-Output "`nDevice Type Selected: $($deviceType)"
        break
    }
}

Write-Output "`n<<<`tUser Assignment Selection`t>>>`n"

# Takes input of UCINETID (optional). 
# If UCINETID is not valid, will cycle back and provide option to register without. 

while ($true) {

    $userRegistration = Read-Host -prompt "`nDo you have the UCINetID of the user? [y/n]"

    if ($userRegistration -eq "y") {
        do {
            $UCINetID = Read-Host -prompt "`nEnter the user's UCINetID"
            $url = 'https://new-psearch.ics.uci.edu/people/' + $UCINetID
            $request = Invoke-WebRequest $url
            if ($request.AllElements.Count -le 70) {
                Write-Host "Sorry, looks like that didn't return a valid person"
            }
            
        } 
        while ($request.AllElements.Count -le 70)
        break
    }

    elseif ($userRegistration -eq "n") {
        break
    }

    elseif ($userRegistration -ne "y" -and $userRegistration -ne "n") {
        Write-Output "[!] That is not a valid input. Select [y]es or [n]o."
    }
}

$trim = whoami.exe
$trim.ToString() | Out-Null
$tmpstring = $trim.Replace("-wa", "")  
$your_name = $tmpstring.Replace("ad\", "")
#function that goes through the page to find the right element for the data required

Write-Output "`n<<<`tIP Address Assignment`t>>>`n"

# Accepts Reserved DHCP IP address if available
# If multiple IP addresses to assign, option exists to assign IPs to individual NICs

while ($true) {
    $ip = Read-Host -Prompt "Do you have the ip to register? (if no, just leave blank and press enter)"
    if (($null -eq $ip) -or ($ip -eq '')) {
        $ipString = ''
        break
    }
    else {
        #Checks if the IP address is valid or not
        $IpCheck = "((25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.){3}(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)"
        if ($ip -notmatch $IpCheck) {
            Write-Host "Looks like that wasn't a valid IP Address, go ahead and try again"
        }
        else {
            $ipString = " IP: " + $ip + ','
            break
        }
    }
}


function userinfo {
    param (
        $trait,
        $person
    )
    $url = 'https://new-psearch.ics.uci.edu/people/' + $person
    $re_request = Invoke-WebRequest $url

    $netidWebPage = $re_request.AllElements 

    $netIDProperties = $netidWebPage | Where-Object { $_.outerhtml -ceq "<SPAN class=label>$trait</SPAN>" -or $_.outerHTML -ceq "<SPAN class=table_label>$trait</SPAN>" }
 

    $name = ([array]::IndexOf($netidWebPage, $netIDProperties)) + 1

    $netidWebPage[$name].innerText
}

#grabs the info from the netid
$me = userinfo -trait Name -person $your_name
$UCINetID = userinfo -trait UCInetID -person $UCINetID
$dep = userinfo -trait Department -person $UCINetID
$loc = userinfo -trait Address -person $UCINetID

if ($userRegistration -eq "y") {
    $info = "For $UCINetID in $dep; at $loc. Inputted by $me."
}
elseif($userRegistration -eq "n") { $info = "Inputted by $me." }

#get's mac address of ethernet adapter that's active and isn't a virtual connection.


$macwired = (get-wmiobject win32_networkadapter -filter "netconnectionstatus = 2" | Where-Object -Property Name -NotMatch "VM" | Where-Object -Property netconnectionid -Match "Ethernet")
$macDoc = $macwired.MACAddress
#checks if the mac is for a docking station or not.
#perhaps here we would want to tell the user to plug it into the dock. and then if they want to put in 2 diff ips for dock and eth, the one where net conn statues = 2
#will auto go to eth, and the one where net conn status doesn't = 2 but still says eth will go to the laptop wired nic.

Write-Output "`n<<<`tDock Registration Selection`t>>>`n"

#if it's a laptop, gets the wifi mac address as well.
if ($deviceType -eq "l") {

    $connections = Get-NetAdapter 

    $WirelessMac = $connections | Where-Object { ( $_.Name -match "Wireless" -or $_.Name -match "Wi-fi") }

    $WirelessMac = $WirelessMac.MacAddress

    $laptopMacAddresses = $connections | Where-Object Name -Match Ethernet | Where-Object InterfaceDescription -NotMatch "Cisco AnyConnect"

    $dockQuestion = Read-Host -prompt "`nDo you have A Doc to register? If so, please make sure it is connected [y/n]"

    if ($dockQuestion -eq 'y') {
        
        $dock? = " Docking station"

        if ($laptopMacAddresses.Count -ge 2 ) {


            $macDoc = ($laptopMacAddresses | Where-Object Status -Match Up).MacAddress
            $macEth = ($laptopMacAddresses | Where-Object Status -Match Disconnected).MacAddress

            while ($true) {
                $ip_laptop = Read-Host -Prompt "`nDo you want to register a different ip for the ethernet MAC address? (if no, just leave blank and press enter)`n"
                if (($null -eq $ip_laptop) -or ($ip_laptop -eq '')) {
                    $ip_wired_string = ''
                    break
                }
                else {
                    #Checks if the IP address is valid or not
                    $IpCheck = "((25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.){3}(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)"
                    if ($ip_laptop -notmatch $IpCheck) {
                        Write-Host "Looks like that wasn't a valid IP Address, go ahead and try again"
                    }
                    else {
                        $ip_wired_string =" IP: " + $ip_laptop + ','
                        break
                    }
                }
            }
        }
       
    }
}

#opens up a page for adding bulk ips, so the user can log in and input the information
#has redundency in case internet explorer doesn't work. 

#removes un-needed output by sending it to tmp file and deleting it
$tempf = New-TemporaryFile

Invoke-WebRequest 'http://apps.oit.uci.edu/mobileaccess/admin/mac/add_bulk.php' | Out-File $tempf

Remove-Item $tempf 

if (!(Get-Process -Name iexplore -ErrorAction SilentlyContinue)) {
    Start-Process 'C:\Program Files (x86)\Google\Chrome\Application\chrome.exe' -ArgumentList 'http://apps.oit.uci.edu/mobileaccess/admin/mac/add_bulk.php'
}

#Grab's computer info about name, model and serial number
$name = (Get-WmiObject win32_computersystem).Name
$model = (Get-WmiObject win32_computersystem).model
$ST = (Get-WmiObject win32_bios).SerialNumber
 
#outputs info for the user to input for registration
#auto attatches to clipboard for pasting

#if there was a dock
if ($dockQuestion -match "y") {
    Write-Host `n"********************Dock Mac Address*******************"`n
}
#if it's a desktop/ no dock 
else {
    Write-Host `n"********************Wired Mac Address*************************"`n
}
$Clip = "$macDoc,$ip,ADCOMDSS,Computername: $name, Model: $model, SN # $ST,$ipString Wired$dock?. $info"

Write-Host "$Clip"`n
 
Set-Clipboard -Value $Clip
 
#if laptop, clips mac for ethernet and wireless connection
if ($deviceType -eq "l") {
    Write-Host `n"*******************Wireless Mac Address********************"`n
    
    $Wireless = "$WirelessMac,,ADCOMDSS,Computername: $name, Model: $model, SN # $ST,$ipString Wireless. $info"

    Write-Host $Wireless`n

    #if there's a dock, and an ethernet port
    if (($laptopMacAddresses.Count -ge 2) -and $macEth) {
        Write-Host `n"********************Wired Mac Address*************************"`n

        $wired = "$macEth,$ip_laptop,ADCOMDSS,Computername: $name, Model: $model; SN # $ST,$ip_wired_string Wired. $info"
    
        Write-Host $wired`n

        Set-Clipboard -Value "$Clip`n `n$Wireless`n `n$wired"
        
        break
    }
    #this is if it's just a laptop with ethernet connection and wireless MAC
    else {

        Set-Clipboard -Value  "$Clip`n `n$Wireless"
        
    }
}