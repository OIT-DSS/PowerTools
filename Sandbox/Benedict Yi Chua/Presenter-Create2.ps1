Clear-Host
$ErrorActionPreference = 'Stop'
$VerbosePreference = 'Continue'

#User to search for
$USERNAME = "Presenter"

#Declare LocalUser Object
$ObjLocalUser = $null

Try {
    Write-Verbose "Searching for $($USERNAME) in LocalUser DataBase"
    $ObjLocalUser = Get-LocalUser $USERNAME
    Write-Verbose "User $($USERNAME) was found"
}

Catch [Microsoft.PowerShell.Commands.UserNotFoundException] {
    "User $($USERNAME) was not found" | Write-Warning
}

Catch {
    "An unspecifed error occured" | Write-Error
    Exit # Stop Powershell! 
}

#Create the user if it was not found (Example)
If (!$ObjLocalUser) {
    Write-Verbose "Creating User $($USERNAME)" #(Example)

    New-LocalUser "Presenter" -Password "presenter" -FullName "Presenter" -Description "Presenter" -PasswordNeverExpires
    Add-LocalGroupMember -Group "Users" -Member "Presenter"

    $RegPath = "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon"
    $DefaultUsername = ".\Presenter"
    $DefaultPassword = "presenter"

    Set-ItemProperty $RegPath "AutoAdminLogon" -Value "1" -type String 
    Set-ItemProperty $RegPath "DefaultUsername" -Value "$DefaultUsername" -type String 
    Set-ItemProperty $RegPath "DefaultPassword" -Value "$DefaultPassword" -type String
}