function Get-ERMActiveDirectoryInformation {

    [CmdletBinding()]

    param()


    try {

        # Initialize
        $Errors = @()
        $Warnings = @()

        # Detect Active Directory module
        $ADModule = Get-Module -ListAvailable -Name ActiveDirectory
        $ADAvailable = $false

        if($ADModule){
            $ADAvailable = $true
        }else{
            $Warnings += "Active Directory PowerShell module is not installed."
        }

        # Basic computer/domain state
        $ComputerSystem = Get-CimInstance Win32_ComputerSystem
        $OSInformation = Get-CimInstance Win32_OperatingSystem
        $DomainJoined = $ComputerSystem.PartOfDomain
        $IsDomainController = $false

        # Detect DC role
        try{
            $DomainRole = $ComputerSystem.DomainRole

            # DomainRole values:
            #
            # 4 = Backup Domain Controller
            # 5 = Primary Domain Controller
            if($DomainRole -ge 4){
                $IsDomainController = $true
            }
        }catch{
            $Warnings += "Unable to determine domain controller role."
        }

        # Base AD data structure
        $ADData = [PSCustomObject]@{
            ComputerName = $env:COMPUTERNAME
            DomainJoined = $DomainJoined
            IsDomainController = $IsDomainController
            ActiveDirectoryModule = [PSCustomObject]@{
                Available = $ADAvailable
                Version =
                    if($ADModule){
                        $ADModule.Version.ToString()
                    }else{
                        $null
                    }
            }
            Forest = $null
            Domain = $null
            DomainControllers = @()
            Services = [PSCustomObject]@{
                SYSVOL = $null
                NETLOGON = $null
            }
        }

        # Standalone machine
        if(-not $DomainJoined){
            $Warnings += "Computer is not domain joined. Active Directory discovery skipped."
            return (
                New-ERMDetectionResult `
                    -Component "ActiveDirectory" `
                    -Status "Warning" `
                    -Data $ADData `
                    -Errors $Errors `
                    -Warnings $Warnings
            )
        }

        # Cannot continue without AD module
        if(-not $ADAvailable){
            return (
                New-ERMDetectionResult `
                    -Component "ActiveDirectory" `
                    -Status "Warning" `
                    -Data $ADData `
                    -Errors $Errors `
                    -Warnings $Warnings
            )
        }

        # Import module
        Import-Module ActiveDirectory -ErrorAction Stop

        # Forest information
        try{
            $Forest = Get-ADForest
            $ADData.Forest = [PSCustomObject]@{
                Name = $Forest.Name
                RootDomain = $Forest.RootDomain
                FunctionalLevel = $Forest.ForestMode
                Domains = @($Forest.Domains)
                Sites = @($Forest.Sites)
            }
        }catch{
            $Errors += "Unable to retrieve forest information: $($_.Exception.Message)"
        }

        # Domain information
        try{
            $Domain = Get-ADDomain
            $ADData.Domain = [PSCustomObject]@{
                Name = $Domain.DNSRoot
                FunctionalLevel = $Domain.DomainMode
                PDCEmulator = $Domain.PDCEmulator
                RIDMaster = $Domain.RIDMaster
                InfrastructureMaster = $Domain.InfrastructureMaster
            }
        }catch{
            $Errors += "Unable to retrieve domain information: $($_.Exception.Message)"
        }

        # Domain controller inventory
        try{
            $DomainControllers = Get-ADDomainController -Filter *
            $ADData.DomainControllers =
                @($DomainControllers | ForEach-Object {
                        [PSCustomObject]@{
                            HostName = $_.HostName
                            IPv4Address = $_.IPv4Address
                            Site = $_.Site
                            OperatingSystem = $_.OperatingSystem
                            GlobalCatalog = $_.IsGlobalCatalog
                        }
                    }
                )
        }catch{
            $Errors += "Unable to enumerate domain controllers: $($_.Exception.Message)"
        }

        # SYSVOL and NETLOGON validation
        try{
            $DomainName = $ComputerSystem.Domain
            $ADData.Services.SYSVOL = Test-Path "\\$DomainName\SYSVOL"
            $ADData.Services.NETLOGON = Test-Path "\\$DomainName\NETLOGON"

            # Check SYSVOL avaliability
            if(-not $ADData.Services.SYSVOL){
                $Warnings += "SYSVOL share is unavailable."
            }

            # Check NETLOGON avaliability
            if(-not $ADData.Services.NETLOGON){
                $Warnings += "NETLOGON share is unavailable."
            }
        }catch{
            $Warnings += "Unable to validate SYSVOL/NETLOGON availability."
        }

        # Determine detector health
        $Status = "Healthy"
        if($Errors.Count -gt 0){
            $Status = "Failed"
        }
        elseif($Warnings.Count -gt 0){
            $Status = "Warning"
        }

        # Return result
        New-ERMDetectionResult `
            -Component "ActiveDirectory" `
            -Status $Status `
            -Data $ADData `
            -Errors $Errors `
            -Warnings $Warnings
    }catch{
        New-ERMDetectionResult `
            -Component "ActiveDirectory" `
            -Status "Failed" `
            -Data $null `
            -Errors @($_.Exception.Message)
    }
}