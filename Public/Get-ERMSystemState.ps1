function Get-ERMSystemState {

    [CmdletBinding()]

    param()
    $StartTime = Get-Date

    Write-ERMLog -Message "Starting system detection"

    try{
        $Detectors =
        @(
            Get-ERMSystemInformation
            Get-ERMPowerShellInformation
            Get-ERMIdentityInformation
            Get-ERMDomainInformation
            Get-ERMCapabilityInformation
            Get-ERMNetworkInformation
            Get-ERMActiveDirectoryInformation
            Get-ERMCertificateInformation
        )

        $State =
            New-ERMSystemStateObject `
                -Detectors $Detectors `
                -StartTime $StartTime

        Write-ERMLog -Message "System detection completed"
        return $State
    }
    catch{
        Write-ERMLog -Level Error -Message $_.Exception.Message
        throw
    }
}