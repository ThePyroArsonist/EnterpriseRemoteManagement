function Write-ERMLog {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]
        $Message,

        [ValidateSet(
            "Information",
            "Warning",
            "Error"
        )]
        [string]
        $Level = "Information"
    )

    $Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $LogDirectory = Join-Path $PSScriptRoot "..\Logs"

    # Ensure logging directory exists
    if (-not (Test-Path -Path $LogDirectory)){
        New-Item -Path $LogDirectory -ItemType Directory -Force | Out-Null
    }

    $LogPath = Join-Path $LogDirectory "ERM.log"
    $Entry = [PSCustomObject]@{
        Timestamp = $Timestamp
        Computer = $env:COMPUTERNAME
        Level = $Level
        Message = $Message
    }

    $Entry |
        ConvertTo-Json -Compress |
        Add-Content -Path $LogPath -Encoding UTF8

    switch ($Level){
        "Error" {
            Write-Error $Message
        } "Warning" {
            Write-Warning $Message
        } default {
            Write-Verbose $Message
        }

    }

}