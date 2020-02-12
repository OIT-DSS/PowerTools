# Script Name: Enable-Bitlocker
# Description: Organizational Unit-agnostic Bitlocker Activation for DSS-supported Laptops and Desktops 
# Author: Benedict Yi Chua
# Collaborators: None
# Last Updated 02-06-2020

#################################################################################

Write-Output "`n[ Bitlocker Activation Powershell Script ]`n"

$InformationPreference = 'Continue'
$WarningPreference = "Inquire"
$ErrorPreference = 'Stop'

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

Write-Output "`n<<< Loading Precheck Modules >>>`n"

#Active Directory Check Function

#Return 0 if computer is joined to AD.UCI.EDU doomain
#Return 1 if computer is joined to WORKGROUP
#Return 2 if computer is joined to NEITHER (Unsupported or unique domain)

function Test-Domain {

    $JoinedDomain = $env:USERDNSDOMAIN

    if ($JoinedDomain -eq "ad.uci.edu") {
        Write-Information -MessageData "`n[i] Computer is joined to AD.`n"
    }

    elseif ($JoinedDomain -eq "workgroup") {
        Write-Error -MessageData "`n[!] Computer is joined to Local Workgroup.`n"
    }

    else {
        Write-Error -MessageData "`n[!] Computer is joined to an unsupported domain.`n"
    }

}

#Bitlocker / Trusted Platform Module Compatibility Check Function

#Function must be executed with Administrator Privileges

#Return 0 if computer is Bitlocker-ready
#Return 1 if computer does not support Bitlocker
function Test-Compatibility {

    if (((get-tpm | select TpmPresent).TpmPresent -eq $True) -and ((get-tpm | select TpmReady).TpmReady -eq $True)) {

        Write-Information -MessageData "`n[i] TPM is ready for Bitlocker Activation.`n"
    }

    else {

        Write-Warning -MessageData "`n[!] TPM not present or TPM not in Bitlocker-ready state. Press Enter to Proceed.`n"
    }

}

#Organizational Unit PIN Check Function
#Check performed against PIN requirement Group Policy Report
#Return 0 if Active Directory OU does NOT require a PIN 
#Return 1 if Active Directory OU REQUIRES a PIN 
#Return 2 if Unable to Determine

function Test-PINRequired {

    $PINReqExit = 0

    if (((gpresult /r /scope:computer | Out-String) -Contains "OIT - Bitlocker - Require Pin") -eq $False) {
        Write-Information -MessageData "`n[i] Organizational Unit does not require a PIN.`n"

    }

    elseif (((gpresult /r /scope:computer | Out-String) -Contains "OIT - Bitlocker - Require Pin") -eq $True) {
        $PINReqExit = 1
        Write-Information -MessageData "`n[i] Organizational Unit requires a PIN.`n`t A DSS-standard PIN will be created.`n"
        
    }

    else {
        $PINReqExit = 2
        Write-Warning -MessageData "`n[!] Unable to determine PIN requirement. Check connectivity to AD`n"
    }

    return $PINReqExit
}

#Computer Name Check Function 
#Return 0 if name matches DEPT-DEVTYPE-XXX naming standard
#Return 1 if name differs from convention

function Test-Computername {

    $CleanName = ($env:computername | Out-String).ToLower()

    if ($CleanName -contains "temp") {

        Write-Error -MessageData "`n[!] Computer assigned temporary name.`nRename to DEPT-DEVTYPE-XXX Standard before running activating Bitlocker`n"
    } 

    elseif ($CleanName -contains "minint") {

        Write-Error -MessageData "`n[!] Computer has not been assigned a name.`n"
    }



}

#################################################################################

Write-Output "`n<<< Running Bitlocker Activation Preflight Checks >>>`n"

# Verify device meets DSS Standards for Bitlocker Activation

Test-Domain
Test-Computername
Test-Compatibility

$PinFlag = Test-PINRequired

Read-Host -prompt "> All checks pass. Insert USB Key and press Enter to begin activation"

#################################################################################

# Scan for external USB Disk
$ExtDrivePath = ((get-volume | where drivetype -eq removable | foreach driveletter) + ":\")

Write-Output "`n> Creating Folder Structure on Removable Disk $ExtDrivePath `n"

# Create Bitlocker Folder
New-Item -Path $ExtDrivePath -Name $env:computername -ItemType "directory"

# Update external Path
$ExtDrivePath = ($ExtDrivePath + $env:computername)

# Set Bitlocker Folder as Current Directory
Set-Location -Path $ExtDrivePath


#################################################################################

Write-Output "`n<<< Activating Bitlocker >>>`n"

# Activation Sectio

# https://community.spiceworks.com/topic/1972369-powershell-script-to-enable-bitlocker

if ($PinFlag -eq 1){

    
    Write-Output "`n> Activating Bitlocker with PIN`n"
    
    $SecureString = Read-Host -Prompt "Enter Bitlocker PIN" -AsSecureString

    $BSTR = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($SecureString)            
    $PlainConvert = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($BSTR) 

    Write-Output "`n> Backing Up Device PIN to External USB`n"

    New-Item -Path . -Name ($env:computername + " PIN.txt") -ItemType "file" -Value $PlainConvert

    Enable-Bitlocker -MountPoint "c:" -EncryptionMethod XtsAes128 -UsedSpaceOnly -RecoveryPasswordProtector

}

elseif ($PinFlag -eq 0) {

    Write-Output "`n> Activating Bitlocker without PIN`n"

    Enable-Bitlocker -MountPoint "c:" -EncryptionMethod XtsAes128 -UsedSpaceOnly -RecoveryPasswordProtector
}

# Find and Save Bitlocker Recovery Keys to Drive

Write-Output "`n> Backing Up Bitlocker Recovery Key to External USB`n"

$RecoveryFileName = ($env:computername + "Bitlocker Recovery Key.txt")

manage-bde -protectors -get C: -type RecoveryPassword > $ExtDrivePath\$RecoveryFileName

#################################################################################


Read-Host "[!] Script Completed. Please transfer folder to DSS Bitlocker Network Directory. Press Enter to exit."