function New-ERMSystemStateObject {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [array]
        $Detectors,
        [Parameter()]
        [datetime]
        $StartTime = (Get-Date)
    )

    # Normalize detector collection
    $Detectors = @($Detectors |
            Where-Object {
                $null -ne $_
            })

    # Capture completion time
    $EndTime = Get-Date

    # Determine detector health states
    $Failed = @($Detectors |
            Where-Object {
                $_.Status -eq "Failed"
            })

    $Warnings = @($Detectors |
            Where-Object {
                $_.Status -eq "Warning"
            })

    $Healthy = @($Detectors |
            Where-Object {
                $_.Status -eq "Healthy"
            })

    # Determine overall system health
    switch ($true){
        ($Failed.Count -gt 0){
            $OverallStatus = "Failed"
            break
        }
        ($Warnings.Count -gt 0){
            $OverallStatus = "Warning"
            break
        } default {
            $OverallStatus = "Healthy"
        }
    }

    # Build component summary
    $Summary = [PSCustomObject]@{
        TotalDetectors = $Detectors.Count
        Healthy = $Healthy.Count
        Warnings = $Warnings.Count
        Failed = $Failed.Count
        FailedComponents =
            if($Failed.Count -gt 0){
                [string[]]$Failed.Component
            }else {
                @()
            }
        WarningComponents =
            if($Warnings.Count -gt 0){
                [string[]]$Warnings.Component
            }else{
                @()
            }
    }

    # Component status table
    $ComponentStatus = $Detectors |
        Select-Object `
            Component,
            Status

    # Aggregate detector errors with source component
    $Errors =
    foreach($Detector in $Detectors){
        foreach($Error in $Detector.Errors){
            if($Error){
                [PSCustomObject]@{
                    Component = $Detector.Component
                    Message = $Error
                }
            }
        }
    }

    # Aggregate detector warnings with source component
    $WarningsList =
    foreach($Detector in $Detectors){
        foreach($Warning in $Detector.Warnings){
            if($Warning){
                [PSCustomObject]@{
                    Component = $Detector.Component
                    Message = $Warning
                }
            }
        }
    }

    # Normalize empty collections
    if($null -eq $Errors){
        $Errors = $null
    }
    if($null -eq $WarningsList){
        $WarningsList = $null
    }

    # Module metadata
    $ModuleInformation = [PSCustomObject]@{
        Name = "EnterpriseRemoteManagement"
        Version = "0.1.0"
        PowerShellVersion = $PSVersionTable.PSVersion.ToString()
    }

    # Detection execution metadata
    $RunInformation = [PSCustomObject]@{
        StartTime = $StartTime
        EndTime = $EndTime
        DurationMilliseconds = [math]::Round(($EndTime - $StartTime).TotalMilliseconds,2)
        DetectorCount = $Detectors.Count
    }

    # Return normalized ERM system state
    [PSCustomObject]@{
        SchemaVersion = "1.0"
        DetectionVersion = "0.1.0"
        ModuleInformation = $ModuleInformation
        ComputerName = $env:COMPUTERNAME
        DetectionTime = $EndTime
        OverallStatus = $OverallStatus
        RunInformation = $RunInformation
        Summary = $Summary
        ComponentStatus = $ComponentStatus
        Errors =
            if($Errors.Count -gt 0){
                $Errors
            }else{
                $null
            }
        Warnings =
            if($WarningsList.Count -gt 0){
                $WarningsList
            }else{
                $null
            }
        Components = $Detectors
    }
}