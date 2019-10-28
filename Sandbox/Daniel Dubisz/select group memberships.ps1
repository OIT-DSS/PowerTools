#$usersname = "lmistry"
#$ticket = "TASK0038114"
#$thedate = [datetime]"04-05-2019"


Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

$form = New-Object “System.Windows.Forms.Form”;
 $form.Width = 500;
 $form.Height = 150;
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
 $textLabel3.Top = 85;

$textLabel3.Text = 'Sep Date';

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

#############Define default values for the input boxes
 $defaultValue = “”
$textBox1.Text = $defaultValue;
 $textBox2.Text = $defaultValue;
 $textBox3.Text = $defaultValue;

#############define button
 $button = New-Object “System.Windows.Forms.Button”;
 $button.Left = 360;
 $button.Top = 85;
 $button.Width = 100;
 $button.Text = “Enter”;

############# This is when you have to close the form after getting values
 $eventHandler = [System.EventHandler]{
 $textBox1.Text;
 $textBox2.Text;
 $textBox3.Text;
 $form.Close();};

$button.Add_Click($eventHandler) ;

#############Add controls to all the above objects defined
 $form.Controls.Add($button);
 $form.Controls.Add($textLabel1);
 $form.Controls.Add($textLabel2);
 $form.Controls.Add($textLabel3);
 $form.Controls.Add($textBox1);
 $form.Controls.Add($textBox2);
 $form.Controls.Add($textBox3);
 $ret = $form.ShowDialog();

#################return values
$ticket = $textBox1.Text 
$usersname = $textBox2.Text 
$thedate = $textBox3.Text

$thedate=[datetime]

$userFromTicket = Get-ADUser $usersname

#shows all the groups that the user is part of

$correctUserResponse = Read-Host "is $($userFromTicket.Name) the correct user as seen on the ticket? [Y\N]"

if ($correctUserResponse -eq 'Y')
{
break
}

if ($correctUserResponse -eq 'N')
{
Write-Host "Please put in the information again"
}

 

([ADSISEARCHER]"samaccountname=$($usersname)").Findone().Properties.memberof -replace '^CN=([^,]+).+$','$1' | Add-Content C:\temp\Dan_D\somefile.txt
Invoke-Item C:\temp\Dan_D\somefile.txt

#sets account to expire in 90 days from the date you take off the ticket

Set-ADAccountExpiration -Identity $usersname -DateTime $thedate.AddDays(90)

#grabs who you are

$me = $env:USERNAME -replace "-ra", ""

#updates description

Set-ADUser $usersname -Description "Restricted; $(Get-Date -Format 'd'); $me; $($ticket)"

#removes user from all groups except for the domain users one
 
Get-ADUser "$usersname" -Properties MemberOf | Select -Expand MemberOf | %{Remove-ADGroupMember $_ -member "$usersname"}

#creates new folder for the user in the AD grave yard

New-Item -Path \\ad.uci.edu\UCI\OIT\Graveyard\AD -name "$usersname" -ItemType 'directory'

#selects user profile path, changes it to the one in users view all, then robocopys it into the new folder in AD graveyard. comment no longer relevant -> also have had some trouble
#with setting permissions for robocopy for v2, so will auto make that under my account before robo copy. 

$profiled = (get-aduser $usersname -properties ProfilePath | Select-Object profilepath).profilepath 
$realprofile = $profiled -replace "users", "Users-ViewAll" -replace "Profile", "" 

#takes ownership of users files so robocopy goes smoothly
takeown /F $realprofile /R


Robocopy.exe $realprofile \\ad.uci.edu\UCI\OIT\Graveyard\AD\$usersname /e

#after robocopy's done, compares the 2 folders to see if they are the same

$newgraveyard = Get-childitem -Recurse -path \\ad.uci.edu\UCI\OIT\Graveyard\AD\$usersname
$comporig = Get-ChildItem -Recurse -Path $realprofile

Compare-Object -ReferenceObject $realprofile -DifferenceObject $newgraveyard

Invoke-Item $realprofile

$finish = "Copied files for (AD\$usersname) into the AD graveyard. Filepath: $graveyard. Deleted users profile. Closing ticket."

$finish | Add-Content  C:\temp\Dan_D\closingremarks.txt

Invoke-Item  C:\temp\Dan_D\closingremarks.txt
