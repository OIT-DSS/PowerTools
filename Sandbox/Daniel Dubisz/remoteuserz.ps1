$usersname = "moraleo1"

Get-ADUser $username

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

#grabs the info from the netid
$me = userinfo -trait Name -person $usersname
if (!(userinfo -trait Level -person $usersname))
{
    Write-Host "this guy not student".
}
userinfo -trait Major -person "bychua"

$me