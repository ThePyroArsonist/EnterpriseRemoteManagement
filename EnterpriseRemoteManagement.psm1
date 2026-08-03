# Load private functions
$PrivateFunctions = Get-ChildItem -Path "$PSScriptRoot\Private\*.ps1"

foreach ($Function in $PrivateFunctions) {
    Write-Host "Loading PRIVATE: $($Function.Name)" -ForegroundColor Cyan
    try {
        . $Function.FullName
    } catch {
        Write-Host "FAILED PRIVATE: $($Function.Name)" -ForegroundColor Red
        throw
    }
}

# Load public functions
$PublicFunctions = Get-ChildItem -Path "$PSScriptRoot\Public\*.ps1"
foreach ($Function in $PublicFunctions) {
    Write-Host "Loading PUBLIC: $($Function.Name)" -ForegroundColor Green
    try {
        . $Function.FullName
    } catch {
        Write-Host "FAILED PUBLIC: $($Function.Name)" -ForegroundColor Red
        throw
    }
}


Write-Host "`n=== Module Functions ===" -ForegroundColor Yellow

Get-ChildItem Function: |
    Where-Object Name -like "*ERM*" |
    Sort-Object Name |
    Select-Object Name

Write-Host "=========================`n" -ForegroundColor Yellow

Write-Host "Exporting functions..." -ForegroundColor Yellow

Export-ModuleMember -Function @(
    'Get-ERMSystemState',
    'Get-ERMNetworkInformation',
    'Get-ERMActiveDirectoryInformation',
    'Get-ERMCertificateInformation'
)

#Script Version
$script:ERMVersion = "0.1.0"