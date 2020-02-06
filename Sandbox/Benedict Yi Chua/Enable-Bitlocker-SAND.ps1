# Script Name: Enable-Bitlocker
# Description: Organizational Unit-agnostic Bitlocker Activation for DSS-supported Laptops and Desktops 
# Author: Benedict Yi Chua
# Collaborators: None
# Last Updated 02-06-2020

Write-Output "`n[ Bitlocker Activation Powershell Script ]`n"

#Active Directory Check Function

#Return 0 if computer is joined to AD.UCI.EDU doomain
#Return 1 if computer is joined to WORKGROUP
#Return 2 if computer is joined to NEITHER (Unsupported or unique domain)

function Test-Domain {

    $DomainExit = 0

    $JoinedDomain = $(Get-ADDomain -Current LocalComputer | Select Forest).Forest.ToLower()

    if ($JoinedDomain -eq "ad.uci.edu") {
        Write-Output "`n[i] Computer is joined to AD.`n"
    }

    elseif ($JoinedDomain -eq "workgroup") {
        $DomainExit = 1
        Write-Output "`n[!] Computer is joined to Local Workgroup.`n"
    }

    else {
        $DomainExit = 2
        Write-Output "`n[!] Computer is joined to an unsupported domain.`n"
    }

    return $DomainExit
}

#Bitlocker / Trusted Platform Module Compatibility Check Function

#Function must be executed with Administrator Privileges

#Return 0 if computer is Bitlocker-ready
#Return 1 if computer does not support Bitlocker
function Test-Compatibility {

    $CompatExit = 0

    if (((get-tpm | select TpmPresent).TpmPresent -eq $True) -and ((get-tpm | select TpmReady).TpmReady -eq $True)) {
        Write-Output "`n[i] TPM is ready for Bitlocker Activation.`n"
    }

    else {
        $CompatExit = 1
        Write-Output "`n[!] TPM not present or TPM not in Bitlocker-ready state.`n"
    }

    return $CompatExit

}

#Organizational Unit PIN Check Function
#Check performed against PIN requirement Group Policy Object #XXXXXXXXXXX-XXXXX-XXXXXXXX
#Return 0 if Active Directory OU does NOT require a PIN 
#Return 1 if Active Directory OU REQUIRES a PIN 

function Test-PINRequired {
    
    $PINReqExit = 0

    if (((gpresult /r /scope:computer | Out-String) -Contains "OIT - Bitlocker - Require Pin") -eq $False) {
        Write-Output "`n[i] Organizational Unit does not require a PIN.`n"

    }

    elseif (((gpresult /r /scope:computer | Out-String) -Contains "OIT - Bitlocker - Require Pin") -eq $True) {
        $PINReqExit = 1
        Write-Output "`n[i] Organizational Unit requires a PIN.`n`t A DSS-standard PIN will be created.`n"
        
    }

    else {
        Write-Output "`n[!] Unable to determine PIN requirement. Check connectivity to AD.`n"
    }

    return $PINReqExit
}

#Computer Name Check Function 
#Return 0 if name adheres to DEPT-DEVTYPE-XXX naming standard
#Return 1 if name differs from convention

function Test-Computername {


}



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

$ShortName = (whoami.exe | Out-String).replace("-wa","").replace("ad\","")

$FullTechName = userinfo -trait Name -person $ShortName

Write-Output "`n[i] Technician Identified in AD`n[i] Registering as $FullTechName`n"

#################################################################################

#Gets Baseline System Information

Write-Output "`n<<<`tSystem Baseline Information >>>`n"

$SystemSerial = $(Get-WmiObject -Class win32_bios | select SerialNumber).serialNumber

Write-Output "`n[System Serial Number: $SystemSerial]"

$HwBuild = Get-WmiObject -Class:Win32_ComputerSystem | Select Name,Manufacturer,Model

Write-Output "[System Name: $($HwBuild.Name)]`n[System Model: $($HwBuild.Manufacturer) $($HwBuild.Model)]`n"


#################################################################################


Read-Host -Prompt "Script Completed. Please transfer folder to DSS Bitlocker Network Directory. Press Enter to exit."