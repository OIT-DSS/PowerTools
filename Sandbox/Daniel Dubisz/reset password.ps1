$ADuser =  Get-ADUser $userID 
    If($ADuser) 
    { 
        Set-adaccountpassword $userID -reset -newpassword (ConvertTo-SecureString -AsPlainText "Irvine8" -Force) 
        Set-aduser $userID -changepasswordatlogon $true 
    }