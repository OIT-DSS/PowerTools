# Script Name:  Configure-BIOS
# Description:  Device-agnostic BIOS Configuration
# Author:       Benedict Yi Chua
# Collaborators: None
# Last Updated  05-04-2020

# Comments: Requires PXE Boot to be Enabled, may already be enabled on new computers.

#################################################################################
Write-Information -MessageData "`n[ BIOS Configuration Script ]`n"

# DEBUG | $null = Start-Transcript "$($env:USERPROFILE)\Desktop\Register-MAC-Debug.log"

$InformationPreference = 'Continue'
$WarningPreference = "Continue"
$ErrorActionPreference = 'Stop'

# TO- DO Insert logic for TB3 preboot on laptops
# Preboot support https://www.dell.com/support/manuals/us/en/04/dell-command-powershell-provider-v1.2/dcpp_ug_1.2/setting-up-dell-command-powershell-provider-in-a-windows-preinstallation-environment?guid=guid-b9329f0c-0772-48d1-9d91-72588c07cdca&lang=en-us

#################################################################################

# Self-elevate the script if required
# Credit

if (-Not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] 'Administrator')) {
    if ([int](Get-CimInstance -Class Win32_OperatingSystem | Select-Object -ExpandProperty BuildNumber) -ge 6000) {
        $CommandLine = "-File `"" + $MyInvocation.MyCommand.Path + "`" " + $MyInvocation.UnboundArguments
        Start-Process -FilePath PowerShell.exe -Verb Runas -ArgumentList $CommandLine
        Exit
    }
}

#################################################################################

# Install Dell BIOS Provider Module and Import for Use

Install-Module DellBIOSProvider
Import-Module DellBIOSProvider

# All-Computers - Configure UEFI boot to be default

Set-Location -Path DellSmbios:\BootSequence\BootList
Set-Item BootList .\BootList "Uefi"
Set-Item BootSequence .\BootSequence "0,6,7" #Actual may vary

# All-Computers - Disable Legacy boot options

Set-Location -Path DellSmbios:\AdvancedBootOptions\
Set-Item .\AttemptLegacyBoot "Disabled"
Set-Item .\LegacyOrom "Disabled"

# All-Computers - Configure Default PXE and SMART settings

Set-Location -Path DellSmbios:\SystemConfiguration\
Set-Item .\UefiNwStack "Enabled"
Set-Item .\EmbNic1 "EnabledPxe"
Set-Item .\SmartErrors "Enabled"

# All-Computers - Enable Secure Boot

Set-Location -Path DellSmbios:\SecureBoot\
Set-Item .\SecureBoot "Enabled" # May Error Out

# All-Computers - Configure Wake on LAN and Power States

Set-Location -Path DellSmbios:\PowerManagement\
Set-Item .\WakeonLan "LanWithPxe"

# All-Computers - Enable BIOS Recovery Options

Set-Location -Path DellSmbios:\Maintenance
Set-Item .\BiosRcvrFrmHdd "Enabled"
Set-Item .\BiosAutoRcvr "Enabled"

# Desktop-Computers - Can be all - Disable S4 and S5

Set-Location -Path DellSmbios:\PowerManagement\ -PassThru
Set-Item DeepSleepCtrl "Disabled"

# Laptop-Computers - Configure WLAN and WWAN card control

Set-Item .\WlanAutoSense "Enabled"
Set-Item .\WwanAutoSense "Enabled"

# Laptop-Computers - Configure Default Boot Option

Set-Location -Path DellSmbios:\PostBehavior

Set-Item .\FastBoot "Thorough" #Full config initialize, important for TB3 docks, etc. 
Set-Item .\MacAddrPassThru "SystemUnique"

#End of Script
