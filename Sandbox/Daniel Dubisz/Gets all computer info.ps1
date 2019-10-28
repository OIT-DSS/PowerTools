$type
##get's mac address of ethernet adapter that's active and isn't a virtual connection.
$macReg = get-wmiobject win32_networkadapter -filter "netconnectionstatus = 2" | Where-Object -Property Name -NotMatch "VM" 
 if ($macReg.Name -notmatch "Ethernet") {$type = "wireless"}
 else{$type = "Wired"} 
 $Mac = $macReg.MACAddress
##Grab's computer info about name and model
 $name = (Get-ComputerInfo | Select-Object CSName).CSName 
 $model = (Get-ComputerInfo | Select-Object CSModel).CSModel 

 Write-Host "$Mac; $name; $type; $model"
 