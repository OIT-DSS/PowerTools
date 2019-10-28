if (!([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) { Start-Process powershell.exe "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs; exit }


#silences error of execution policy at beginning
$ErrorActionPreference = 'silentlycontinue'

#gets ip address from user, if they have the ip address already. Checks if the IP address is valid or not
  while ($true){
$ip = Read-Host -Prompt "Do you have the ip to register? (if no, just leave blank and press enter)"
if($ip -eq "")
{
    break
}
else {
$IpCheck =  "((25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.){3}(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)"
if ($ip -notmatch $IpCheck) 
{
    Write-Host "Looks like that wasn't a valid IP Address, go ahead and try again"
}
else 
{
    break
}
}
}

#checks if computer is laptop or desktop, to see if they need to register the wifi MAC
$type = Read-Host -Prompt "Is this a laptop or a desktop? (l/d)" 
#opens up a page for adding bulk ips, so the user can log in and input the information

Invoke-WebRequest -Uri "http://apps.oit.uci.edu/mobileaccess/admin/mac/add_bulk.php" | Out-String 

##get's mac address of ethernet adapter that's active and isn't a virtual connection.
$macDoc = (get-wmiobject win32_networkadapter -filter "netconnectionstatus = 2" | Where-Object -Property Name -NotMatch "VM" | Where-Object -Property netconnectionid -Match "Ethernet").MacAddress

## if it's a laptop, gets the wifi mac address as well.
 if ($type -eq "l")
 {
 $WirelessMac = (get-wmiobject win32_networkadapter | Where-Object -Property Name -NotMatch "VM" | Where-Object -Property Name -Match "Wireless").MacAddress
 }

##Grab's computer info about name, model and serial number
 $name = (Get-WmiObject win32_computersystem).Name
 $model = (Get-WmiObject win32_computersystem).model
 $ST = (Get-WmiObject win32_bios).SerialNumber
 

 #outputs info for the user to input for registration
 #auto attatches to clipboard for pasting
 
 Write-Host "$macDoc,$ip,ADCOMDSS,$name; Wired; $model; $ST; $ip"
 $Clip = "$macDoc,$ip,ADCOMDSS,$name; Wired; $model; $ST; $ip" | Clip
 if($type -eq "l")
 {
 Write-Host "$WirelessMac,,ADCOMDSS,$name; Wireless; $model; $ST; $ip"

 $clip = "$macDoc,$ip,ADCOMDSS,$name; Wired; $model; $ST; $ip" +
 "$WirelessMac,,ADCOMDSS,$name; Wireless; $model; $ST; $ip" | Clip
 }
 