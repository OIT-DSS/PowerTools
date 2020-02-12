$Password = Read-Host -AsSecureString -Prompt
New-LocalUser "Presenter" -Password $Password -FullName "Presenter" -Description "Presenter"
Add-LocalGroupMember -Group "Users" -Member "Presenter"
Restart-Computer