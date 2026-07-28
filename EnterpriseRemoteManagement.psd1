@{
    # Module identity
    RootModule = 'EnterpriseRemoteManagement.psm1'
    ModuleVersion = '0.1.0'
    GUID = '6d8d0d1e-9d76-4c88-9e7e-9c0f3d6f4a11'
    Author = 'Enterprise Remote Management Team'
    CompanyName = 'Internal'
    Copyright = '(c) Enterprise Remote Management'

    Description = '
    Enterprise PowerShell module for secure remote management,
    WinRM HTTPS configuration, inventory, and compliance.'
    PowerShellVersion = '5.1'

    # Public commands
    FunctionsToExport = @(
        "Get-ERMSystemState"
        "Get-ERMNetworkInformation"
        "Get-ERMActiveDirectoryInformation"
    )

    CmdletsToExport = @()
    VariablesToExport = @()
    AliasesToExport = @()
    PrivateData = @{
        PSData = @{
            Tags = @(
                'WinRM',
                'Security',
                'Automation',
                'Enterprise'
            )
        }
    }
}