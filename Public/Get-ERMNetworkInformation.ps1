function Get-ERMNetworkInformation {

    [CmdletBinding()]

    param()

    try{
        # Network adapters
        $Adapters =
            Get-NetAdapter |
            Where-Object {
                $_.Status -eq "Up"
            } |
            Select-Object `
                Name,
                InterfaceDescription,
                MacAddress,
                LinkSpeed

        # IP Configuration
        $IPConfiguration =
            Get-NetIPConfiguration |
            Where-Object {
                $_.NetAdapter.Status -eq "Up"
            } |
            ForEach-Object {
                [PSCustomObject]@{
                    Interface =
                        $_.InterfaceAlias
                    IPv4Address =
                        @($_.IPv4Address.IPAddress)
                    IPv6Address =
                        @($_.IPv6Address.IPAddress)
                    DefaultGateway =
                        @($_.IPv4DefaultGateway.NextHop)
                }
            }

        $GatewayAvailable =
            $false

        $Gateway =
            @($IPConfiguration.DefaultGateway |
                Where-Object {
                    $_
                })

        if($Gateway.Count -gt 0){
            $GatewayAvailable =
                $true
        }

        # DNS Configuration
        $DNS =
            Get-DnsClientServerAddress |
            Where-Object {

                $_.InterfaceAlias -in
                (
                    Get-NetAdapter |
                    Where-Object Status -eq "Up" |
                    Select-Object -ExpandProperty Name
                )

            } |
            Where-Object {
                $_.ServerAddresses.Count -gt 0
            } |
            Select-Object `
                InterfaceAlias,
                AddressFamily,
                ServerAddresses

        # Network Profiles
        $Profiles =
            Get-NetConnectionProfile | ForEach-Object {
                $Adapter =
                    Get-NetAdapter `
                        -Name $_.InterfaceAlias `
                        -ErrorAction SilentlyContinue

                [PSCustomObject]@{
                    Name =
                        $_.Name
                    InterfaceAlias =
                        $_.InterfaceAlias
                    Status =
                        $Adapter.Status
                    NetworkCategory =
                        $_.NetworkCategory
                    IPv4Connectivity =
                        $_.IPv4Connectivity
                    IPv6Connectivity =
                        $_.IPv6Connectivity
                }
            }

        # Domain connectivity check
        $DomainConnectivity =
        [PSCustomObject]@{
            DomainJoined =
                $false
            Domain =
                $null
            Site =
                $null
            DomainController =
                $null
            Reachable =
                $false
        }

        try{
            $ComputerSystem =
                Get-CimInstance `
                    Win32_ComputerSystem

            if($ComputerSystem.PartOfDomain){
                $DomainConnectivity.DomainJoined =
                    $true
                $DomainConnectivity.Domain =
                    $ComputerSystem.Domain

                # Discover domain controller
                $DCDiscovery =
                    nltest /dsgetdc:$($ComputerSystem.Domain) 2>&1
                if($LASTEXITCODE -eq 0){
                    $DomainConnectivity.Reachable =
                        $true
                    $DCName =
                        $DCDiscovery |
                        Select-String "DC:" |
                        ForEach-Object {
                            $_.Line.Replace("DC:","").Trim()
                        }
                    $DCAddress =
                        $DCDiscovery |
                        Select-String "Address:" |
                        ForEach-Object {
                            $_.Line.Replace("Address:","").Trim()
                        }
                    $DomainConnectivity.DomainController =
                    [PSCustomObject]@{
                        Hostname =
                            if($DCName){
                                $DCName.TrimStart("\")
                            }else{
                                $null
                            }
                        Address =
                            if($DCAddress){
                                $DCAddress.TrimStart("\")
                            }else{
                                $null
                            }
                    }
                }

                # Discover AD Site
                $SiteDiscovery =
                    nltest /dsgetsite 2>&1
                if($LASTEXITCODE -eq 0){
                    $DomainConnectivity.Site =
                        ($SiteDiscovery |
                        Select-Object -First 1).Trim()
                }
            }
        }catch{
            $DomainConnectivity.Reachable =
                $false
        }

        # DNS resolution test
        $DNSResolution =
            $false

        try{
            if($DomainConnectivity.Domain){
                Resolve-DnsName `
                    -Name $DomainConnectivity.Domain `
                    -ErrorAction Stop |
                    Out-Null
                $DNSResolution = $true
            }
        } catch {
            $DNSResolution = $false
        }

        # Build detector data
        $NetworkData =
        [PSCustomObject]@{
            ComputerName =
                $env:COMPUTERNAME
            Adapters =
                @($Adapters)
            IPConfiguration =
                @($IPConfiguration)
            DNS =
                @($DNS)
            Profiles =
                @($Profiles)
            Connectivity =
            [PSCustomObject]@{
                Domain =
                    $DomainConnectivity
                DNSResolution =
                    $DNSResolution
                GatewayAvailable =
                    $GatewayAvailable
            }
        }

        # Detector evaluation
        $Errors =
            @()

        $Warnings =
            @()

        # Adapter validation
        if($Adapters.Count -eq 0){
            $Errors +=
                "No active network adapters detected."
        }

        # IP validation
        $ValidIP =
            $IPConfiguration.IPv4Address |
            Where-Object {
                $_ -and
                $_ -notlike "169.254*"
            }


        if(-not $ValidIP){
            $Errors +=
                "No valid IPv4 address detected."
        }

        # DNS validation
        if(-not $DNSResolution){
            $Warnings +=
                "DNS resolution failed."
        }

        # Domain validation
        if($DomainConnectivity.DomainJoined -and
            -not $DomainConnectivity.Reachable){
            $Warnings +=
                "Domain joined computer cannot locate a domain controller."
        }

        # Gateway validation
        if(-not $GatewayAvailable)
            {
                $Warnings +=
                    "No default gateway detected."
            }

        # Determine status
        $Status =
            "Healthy"


        if($Errors.Count -gt 0){
            $Status =
                "Failed"
        }
        elseif($Warnings.Count -gt 0){
            $Status =
                "Warning"
        }


        New-ERMDetectionResult `
            -Component "Network" `
            -Status $Status `
            -Data $NetworkData `
            -Errors $Errors `
            -Warnings $Warnings
    }catch{
        New-ERMDetectionResult `
            -Component "Network" `
            -Status "Failed" `
            -Data $null `
            -Errors @(
                $_.Exception.Message
            )
    }
}