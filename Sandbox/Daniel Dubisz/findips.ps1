#may need to make it recursive or something, but not sure if needed anyways
#$me = $env:USERNAME -replace "-ra", ""
#
#$acl = Get-Acl \\ad.uci.edu\UCI\OIT\Users\$env:USERNAME\Profile.V2
#$permission = "AD\$env:USERNAME","FullControl","Allow"
#$accessRule = New-Object System.Security.AccessControl.FileSystemAccessRule $permission
#$acl.SetAccessRule($accessRule)
#$acl | Set-Acl \\ad.uci.edu\UCI\OIT\Graveyard\AD\portersg

Get-ChildItem \\ad.uci.edu\UCI\OIT\Graveyard\AD\portersg 



#Get-Acl -Path \\ad.uci.edu\UCI\OIT\Users\$me\Profile.V2 | Set-Acl -Path \\ad.uci.edu\UCI\OIT\Graveyard\AD\portersg
