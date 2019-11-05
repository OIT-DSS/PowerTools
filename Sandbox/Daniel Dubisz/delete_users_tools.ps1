

# Author(s): Daniel Dubisz
# Organization: UC Irvine Office of Information Technology

# Script Name: Delete_AD_Account
# Description: Automates proccess of deleting user account.
# Last Updated: 10-8-2019

#gets accounts all accounts in AD that have the usersname var at the beginning, to see if they have any extra accounts like -wa.

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

$form = New-Object “System.Windows.Forms.Form”;
$form.Width = 500;
$form.Height = 220;
$form.Text = $title;
$form.StartPosition = [System.Windows.Forms.FormStartPosition]::CenterScreen;

##############Define text label1
$textLabel1 = New-Object “System.Windows.Forms.Label”;
$textLabel1.Left = 25;
$textLabel1.Top = 15;

$textLabel1.Text = 'Ticket #';

##############Define text label2

$textLabel2 = New-Object “System.Windows.Forms.Label”;
$textLabel2.Left = 25;
$textLabel2.Top = 50;

$textLabel2.Text = 'Username';

##############Define text label3

$textLabel3 = New-Object “System.Windows.Forms.Label”;
$textLabel3.Left = 25;
$textLabel3.Top = 90;

$textLabel3.Text = 'Sep Date';

##############Define text label4

$textLabel4 = New-Object “System.Windows.Forms.Label”;
$textLabel4.Left = 25;
$textLabel4.Top = 130;
$textLabel4.Text = 'Retiring';

############Define text box1 for input
$textBox1 = New-Object “System.Windows.Forms.TextBox”;
$textBox1.Left = 150;
$textBox1.Top = 10;
$textBox1.width = 200;

############Define text box2 for input

$textBox2 = New-Object “System.Windows.Forms.TextBox”;
$textBox2.Left = 150;
$textBox2.Top = 50;
$textBox2.width = 200;

############Define text box3 for input

$textBox3 = New-Object “System.Windows.Forms.TextBox”;
$textBox3.Left = 150;
$textBox3.Top = 90;
$textBox3.width = 200;

############Define checkbox 4 for input
$checkBox1 = New-Object “System.Windows.Forms.CheckBox”;
$checkBox1.Left = 150;
$checkBox1.Top = 130;
$checkBox1.width = 200;

#############Define default values for the input boxes
$defaultValue = “”
$textBox1.Text = $defaultValue;
$textBox2.Text = $defaultValue;
$textBox3.Text = $defaultValue;


#############define button
$button = New-Object “System.Windows.Forms.Button”;
$button.Left = 360;
$button.Top = 130;
$button.Width = 100;
$button.Text = “Enter”;

############# This is when you have to close the form after getting values
$eventHandler = [System.EventHandler] {
    $textBox1.Text;
    $textBox2.Text;
    $textBox3.Text;
    $checkBox1.CheckState;
    $form.Close(); };

$button.Add_Click($eventHandler) ;

#############Add controls to all the above objects defined
$form.Controls.Add($button);
$form.Controls.Add($textLabel1);
$form.Controls.Add($textLabel2);
$form.Controls.Add($textLabel3);
$form.Controls.Add($textLabel4);
$form.Controls.Add($textBox1);
$form.Controls.Add($textBox2);
$form.Controls.Add($textBox3);
$form.Controls.Add($checkBox1);
$ret = $form.ShowDialog();

#################return values
$ticket = $textBox1.Text 
$usersname = $textBox2.Text 
$thedate = $textBox3.Text
$retired = $checkBox1.CheckState

# creates temporary log file

$log_file = New-TemporaryFile

notepad.exe $log_file

########################        Tests authenticity of the user      ########################       

Write-Output "`n<<<`tUser verification >>>`n"

do {

    $userFromTicket = Get-ADUser $usersname

    $correctUserResponse = Read-Host "is $($userFromTicket.Name) the correct user as seen on the ticket? [Y\N]"

    if ($correctUserResponse -eq 'Y') {
        break
    }

    if ($correctUserResponse -eq 'N') {
        Write-Host "Please put in the information again"
    }
}
while ($correctUserResponse -ne 'Y')

########################       Function for obtaining info of the user      ########################       
function Get-FullName {
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

##################      User Assingment Step        ################

Write-Output "`n<<<`tUser Status >>>`n"

if (!(Get-FullName -trait Title -person $usersname)) {

    "`r`n$usersname is a student, will proceed with immediate account account expiration`r" | Tee-Object $log_file
    $is_student
} 

#finds all accounts, wa, ra, sa, a and the like.

$profileSearch = $usersname + "*"

$accounts = Get-ADUser -Filter "SamAccountName -like '$profileSearch'"

#informs user of how many accounts were found.

Write-Output "`n<<<`tAccounts Found >>>`n"

($accounts | Measure-Object).Count

"`r`n$(($accounts | Measure-Object).Count) account(s) detected for $usersname `r" | Tee-Object $log_file

#################       User Profile Iteration      ###################

foreach ($unit in $accounts) {

    #writes the accounts name in log

    $user = $unit.SamAccountName

    "`r`n$($unit.Name)`n" | Tee-Object  $log_file

    #writes the SG's for the account in log

    "`r`nSG's for $user`n`r" | Tee-Object $log_file 
    $userSG = ([ADSISEARCHER]"samaccountname=$user").Findone().Properties.memberof -replace '^CN=([^,]+).+$', '$1' 
    if ($userSG -eq "") {
        "`r`nNo SG's for $user have been found.`n`r" | Tee-Object $log_file
    }
    else {
        $userSG | Tee-Object $log_file
    }
    
    # sets account to be restricted

    Set-ADUser $user -Description "Restricted; $thedate; $me; $($ticket)"

    if ($unit -eq $accounts[0]) {

        $profiled = (get-aduser $unit -properties ProfilePath | Select-Object profilepath).profilepath
        $realprofile = $profiled -replace "users", "Users-ViewAll" -replace "Profile", "" 

        if ($is_student) {
            get-ADAccountExpiration -Identity $user -DateTime $thedate
        }
        elseif ($retired) {
            Move-ADObject $unit -target ''
            Set-ADUser $user -Description "Moved to Retirement OU; $thedate; $me; $($ticket)"
        }
        else {
            get-ADAccountExpiration -Identity $user -DateTime $thedate.AddDays(90)
        }
    }

    else {
        get-ADAccountExpiration -Identity $user -DateTime $thedate
    }

    # removes user from Security groups

    Get-ADUser "$user" -Properties MemberOf | Select -Expand MemberOf | % { Remove-ADGroupMember $_ -member "$user" }
}

#if no user profiles are found

if (!($profiled)) {
    "`r`nno profile for the user $($accounts[0].Name) has been found, no robocopy or profile deletion is needed." | Tee-Object $log_file
}

#if user profiles are found
else {
    #creates graveyard directory
    New-Item -Path \\ad.uci.edu\UCI\OIT\Graveyard\AD -name "$usersname" -ItemType 'directory'

    #takes ownership of users files so robocopy goes smoothly
    ECHO 'Y' | takeown.exe /F $realprofile /R
    Robocopy.exe $realprofile \\ad.uci.edu\UCI\OIT\Graveyard\AD\$usersname /e

    #after robocopy's done, compares the 2 folders to see if they are the same

    $SourceDir = Get-ChildItem $realprofile -Recurse
    $DestDir = Get-ChildItem -Recurse -Path \\ad.uci.edu\UCI\OIT\Graveyard\AD\$usersname 
    $result = Compare-Object -ReferenceObject $SourceDir -DifferenceObject $DestDir

    if ($result) {
        Write-Host "Error in copying, please manually check the files to make sure that everything is ok."
        invoke-item \\ad.uci.edu\UCI\OIT\Graveyard\AD\$usersname
        Invoke-Item $realprofile
        Invoke-Item $log_file
        Break
    }

    $finish = "Copied files for (AD\$usersname) into the AD graveyard. Filepath: \\ad.uci.edu\UCI\OIT\Graveyard\AD\$usersname. Deleted users profile. Closing ticket."

    $finish | Tee-Object  $log_file

    remove-item -Path $realprofile -Force -Confirm

    if (!(Test-Path $realprofile)) {
        Write-Host "Account has succesfully been deleted."
    }
}

notepad.exe $log_file