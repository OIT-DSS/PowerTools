# Gets system serial number

$serialnumber = wmic bios get serialnumber
Write-OutPut $serialnumber

# Gets system information

$computerinfo = wmic computersystem get model,name,manufacturer,systemtype

# Gets MAC Address (tested desktop only)



# More complex
Get-NetAdapter | select Name,MacAddress