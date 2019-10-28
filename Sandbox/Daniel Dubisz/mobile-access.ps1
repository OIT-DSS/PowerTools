$c = $host.UI.PromptForCredential('Your Credentials', 'Enter Credentials', '','')

$R = Invoke-WebRequest -Uri "https://login.uci.edu/ucinetid/webauth?return_url=http://apps.oit.uci.edu/mobileaccess/admin/mac/add.php" -SessionVariable websession

$form = $R.Forms[0]

$form.Fields['ucinetid'] = $c.Username
$form.Fields['password'] = $c.GetNetworkCredential().Password

Invoke-WebRequest -Uri ("https://login.uci.edu/ucinetid/webauth?return_url=http://apps.oit.uci.edu/mobileaccess/admin/mac/add.php" + $form.Action) -SessionVariable websession

$form