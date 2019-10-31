Describe  'User-Closeout' {

    Context 'Verifying user closeout process' {

        It 'Restrictions Note has been set' {
            Get-AdUser -Identity $user -Properties Description | Select-Object -ExpandProperty Description | Should beLike "Restrictions*"
        }
        It 'List of group memberships set' {
            Get-AdUser -Identity $user -Properties info | Select-Object -ExpandProperty Description | Should beLike
        }
    }
}