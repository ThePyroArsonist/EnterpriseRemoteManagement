function Get-ERMPowerShellInformation {
    [CmdletBinding()]
    param()

    try{
        $Data = [PSCustomObject]@{
            ComputerName = $env:COMPUTERNAME
            Version = $PSVersionTable.PSVersion.ToString()
            MajorVersion = $PSVersionTable.PSVersion.Major
            MinorVersion = $PSVersionTable.PSVersion.Minor
            Edition = $PSVersionTable.PSEdition
            CLRVersion =
                if($PSVersionTable.CLRVersion){
                    $PSVersionTable.CLRVersion.ToString()
                } else {
                    "Not Applicable"
                }
            ExecutionPolicy = Get-ExecutionPolicy
        }
        New-ERMDetectionResult `
            -Component "PowerShell" `
            -Data $Data
    }catch{
        New-ERMDetectionResult `
            -Component "PowerShell" `
            -Status "Failed" `
            -Data $null `
            -Errors @($_.Exception.Message)
    }
}