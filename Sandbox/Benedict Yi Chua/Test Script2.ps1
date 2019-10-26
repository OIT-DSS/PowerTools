# Gets system serial number

$serialNumber = wmic bios get serialnumber

# Gets system information

$sysinfo = wmic computersystem get model,name,manufacturer,systemtype

# Gets MAC Address (tested desktop only)

$macinfo = Get-NetAdapter | select MacAddress

# More complex
# Get-NetAdapter | select Name,MacAddress


$text = "$serialNumber" + "$sysinfo" + "$macinfo"

$text > 'file.txt'