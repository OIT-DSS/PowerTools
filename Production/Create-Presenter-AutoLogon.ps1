#Creates New Local User "Presenter" with the following parameters: 

#Prerequsites: 
#[1] Computer must be unjoined from AD first 
#[2] Script must be run as administrator
#Note: Use Powershell.exe -ExecutionPolicy Bypass %FilePath% if error occurs

Clear-Host
$ErrorActionPreference = 'Stop'
$VerbosePreference = 'Continue'

#Presenter Account Variables
$Username = "Presenter"
$Password = "presenter"
$Account_Description = "OIT-Provisioned Presenter Account"
$AutoLogon = "Disabled"

#Declare LocalUser Object
$ObjLocalUser = $null

Try {
    Write-Verbose "Searching for $($Username) in LocalUser DataBase"
    $ObjLocalUser = Get-LocalUser $Username
    Write-Verbose "User $($Username) was found"
}

Catch [Microsoft.PowerShell.Commands.UserNotFoundException] {
    "User $($Username) was not found" | Write-Warning
}

Catch {
    "An unspecifed error occured" | Write-Error
    Exit # Stop Powershell! 
}

#Create the user if it was not found (Example)
If (!$ObjLocalUser) {
    Write-Verbose "Creating User $($Username)" 

    #Converts Pasword to a Secure String Object
    $Presenter_Password = ConvertTo-SecureString $Password -AsPlainText -Force #Value can be changed

    #Creates Presenter Account
    New-LocalUser -Name $Username -FullName $Username -Password $Presenter_Password  -Description $Account_Description -AccountNeverExpires -PasswordNeverExpires

    #Add Presenter Account to Users Group
    Add-LocalGroupMember -Group "Users" -Member "Presenter"

    Write-Verbose "Created User $($Username)." 
}

#EnableAutoLogon if toggled

If ($AutoLogon = "Enabled") { 
    Write-Verbose "Enabling Autologon for User $($Username)." 
    $RegPath = "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon"

    Set-ItemProperty $RegPath "AutoAdminLogon" -Value "1" -type String 
    Set-ItemProperty $RegPath "DefaultUsername" -Value "$Username" -type String 
    Set-ItemProperty $RegPath "DefaultPassword" -Value "$Password" -type String
    Write-Verbose "Autologon Enabled for User $($Username)." 
}

Write-Verbose "Script completed, exiting..." 