# Author(s): Benedict Yi Chua
# Collaborators: None
# Organization: UC Irvine Office of Information Technology

# Script Name: Run before pushing Dell Command Update 3x Restart 
# Description: 
# Last Updated: 

$RebootSuspend = 3

Suspend-Bitlocker -MountPoint "C:" -RebootCount $RebootSuspend

Write-Output "Bitlocker has been suspended for $RebootSuspend reboots."