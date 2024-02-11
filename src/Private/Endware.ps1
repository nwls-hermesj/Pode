function Invoke-PodeEndware {
    param(
        [Parameter()]
        $Endware
    )

    # if there's no endware, do nothing
    if (($null -eq $Endware) -or ($Endware.Length -eq 0)) {
        return
    }

    # loop through each of the endware, invoking the next if it returns true
    foreach ($eware in @($Endware)) {
        if (($null -eq $eware) -or ($null -eq $eware.Logic)) {
            continue
        }

        try {
            $null = Invoke-PodeScriptBlock -ScriptBlock $eware.Logic -Arguments $eware.Arguments -UsingVariables $eware.UsingVariables -Scoped -Splat
        }
        catch {
            $_ | Write-PodeErrorLog
        }
    }
}