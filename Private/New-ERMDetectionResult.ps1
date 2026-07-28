function New-ERMDetectionResult {
    [CmdletBinding()]

    param(
        [Parameter(Mandatory)]
        [string]
        $Component,
        [Parameter(Mandatory)]
        [object]
        $Data,
        [ValidateSet(
            "Healthy",
            "Warning",
            "Failed"
        )]
        [string]
        $Status = "Healthy",
        [array]
        $Errors = @(),
        [array]
        $Warnings = @()
    )

    [PSCustomObject]@{
        Component = $Component
        Status = $Status
        Data = $Data
        Errors = $Errors
        Warnings = $Warnings
        DetectionTime = Get-Date
        DetectorVersion = "0.1.0"
    }
}