# OIT DSS PowerShell Temporary Suspension
# Run before pushing Dell Command Update 3x Restart 

$RebootSuspend = 3

Suspend-Bitlocker -MountPoint "C:" -RebootCount $RebootSuspend

Write-Output "Bitlocker has been suspended for $RebootSuspend reboots."