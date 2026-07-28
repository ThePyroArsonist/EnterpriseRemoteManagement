function Get-ERMSystemInformation {
    [CmdletBinding()]

    param()

    try{
        $OS =
            Get-CimInstance `
            -ClassName Win32_OperatingSystem `
            -ErrorAction Stop
        $Computer =
            Get-CimInstance `
            -ClassName Win32_ComputerSystem `
            -ErrorAction Stop

        $Data =
        [PSCustomObject]@{
            ComputerName =
                $env:COMPUTERNAME
            Manufacturer =
                $Computer.Manufacturer
            Model =
                $Computer.Model
            OperatingSystem =
                $OS.Caption
            Version =
                $OS.Version
            Build =
                $OS.BuildNumber
            Architecture =
                $OS.OSArchitecture
            LastBoot =
                $OS.LastBootUpTime
        }

        return New-ERMDetectionResult `
            -Component "System" `
            -Data $Data

    }
    catch {
        return New-ERMDetectionResult `
            -Component "System" `
            -Status "Failed" `
            -Data $null `
            -Errors @(
                $_.Exception.Message
            )
    }
}