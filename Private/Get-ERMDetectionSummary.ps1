function Get-ERMDetectionSummary {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        $Components
    )
    $Failed = $Components |
        Where-Object {
            $_.Status -eq "Failed"
        }
    $Warnings = $Components |
        Where-Object {
            $_.Status -eq "Warning"
        }
    [PSCustomObject]@{
        TotalDetectors = $Components.Count
        Healthy = ($Components | Where-Object Status -eq "Healthy").Count
        Warnings = $Warnings.Count
        Failed = $Failed.Count
        FailedComponents = $Failed.Component
        WarningComponents = $Warnings.Component
    }
}