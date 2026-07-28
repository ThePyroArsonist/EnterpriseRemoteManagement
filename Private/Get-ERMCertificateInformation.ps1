function Get-ERMCertificateInformation {
    [CmdletBinding()]
    param()

    $StartTime = Get-Date
    $Errors = @()
    $Warnings = @()

    try {
        Write-ERMLog -Message "Starting certificate detection"

        # Certificate stores
        $MachineStore = @()

        try {
            $Certificates = Get-ChildItem Cert:\LocalMachine\My -ErrorAction Stop

            foreach($Certificate in $Certificates) {
                # Enhanced Key Usage
                $EKU = @($Certificate.EnhancedKeyUsageList |
                        ForEach-Object {
                            $_.FriendlyName
                        })

                # DNS names from SAN
                $DNSNames = @()

                if($Certificate.DnsNameList) {
                    $DNSNames = @($Certificate.DnsNameList |
                            ForEach-Object {
                                $_.Unicode
                            })
                }

                # Certificate template
                $Template = $null

                $TemplateExtension = $Certificate.Extensions |
                    Where-Object {
                        $_.Oid.Value -eq "1.3.6.1.4.1.311.21.7"
                    }

                if($TemplateExtension) {
                    $Template = $TemplateExtension.Format($false)
                }

                # WinRM suitability evaluation
                $HasServerAuth = $false

                if($EKU -contains "Server Authentication"){
                    $HasServerAuth = $true
                }

                $HasPrivateKey = $Certificate.HasPrivateKey
                $NotExpired = ($Certificate.NotAfter -gt (Get-Date))
                $HostnameMatch = $false
                $ComputerNames = @($env:COMPUTERNAME 
                    "$env:COMPUTERNAME.$((Get-CimInstance Win32_ComputerSystem).Domain)")

                foreach($Name in $ComputerNames) {
                    if($DNSNames -contains $Name){
                        $HostnameMatch = $true
                    }

                    if($Certificate.Subject -like "*$Name*"){
                        $HostnameMatch = $true
                    }
                }

                $SuitableForWinRM = ($HasServerAuth -and $HasPrivateKey -and $NotExpired)
                $Reason = @()
                if(-not $HasServerAuth){
                    $Reason += "Missing Server Authentication EKU"
                }

                if(-not $HasPrivateKey){
                    $Reason += "Missing private key"
                }

                if(-not $NotExpired){
                    $Reason += "Certificate expired"
                }

                if(-not $HostnameMatch){
                    $Reason += "Certificate name does not match computer"
                }
                $MachineStore += [PSCustomObject]@{
                        Subject = $Certificate.Subject
                        Issuer = $Certificate.Issuer
                        Thumbprint = $Certificate.Thumbprint
                        FriendlyName = $Certificate.FriendlyName
                        DNSNames = $DNSNames
                        NotBefore = $Certificate.NotBefore
                        NotAfter = $Certificate.NotAfter
                        HasPrivateKey = $HasPrivateKey
                        EnhancedKeyUsage = $EKU
                        Template = $Template
                        SuitableForWinRM = $SuitableForWinRM
                        Reason = $Reason
                    }
            }
        } catch {
            $Errors += "Unable to read LocalMachine certificate store: $($_.Exception.Message)"
        }

        # WinRM certificate candidates
        $WinRMCertificates = @($MachineStore |
                Where-Object {
                    $_.SuitableForWinRM -eq $true
                })

        # Certificate statistics
        $Statistics = [PSCustomObject]@{
            Total = $MachineStore.Count
            Expired = @($MachineStore |
                    Where-Object {
                        $_.NotAfter -lt (Get-Date)
                    }).Count
            WithPrivateKey = @($MachineStore |
                    Where-Object {
                        $_.HasPrivateKey
                    }).Count
            ServerAuthentication = @($MachineStore |
                    Where-Object {
                        $_.EnhancedKeyUsage -contains
                        "Server Authentication"
                    }).Count
            WinRMCandidates = $WinRMCertificates.Count
        }

        # Enterprise CA detection
        $CertificateAuthority = [PSCustomObject]@{
            Available = $false
            Reachable = $false
            Configuration = $null
        }
        try {
            $CAConfig = certutil -config - -ping 2>$null
            if($LASTEXITCODE -eq 0) {
                $CertificateAuthority.Available = $true
                $CertificateAuthority.Reachable = $true
                $CertificateAuthority.Configuration = $CAConfig
            }
        } catch {
            $Warnings += "Enterprise Certificate Authority could not be detected."
        }

        # Auto enrollment detection
        $AutoEnrollment = [PSCustomObject]@{
            Enabled = $false
        }
        try {
            $AutoEnrollmentPolicy = Get-ItemProperty "HKLM:\Software\Microsoft\Cryptography\AutoEnrollment" -ErrorAction SilentlyContinue
            if($AutoEnrollmentPolicy){
                $AutoEnrollment.Enabled = $true
            }
        } catch {
            $Warnings += "Unable to determine certificate auto enrollment status."
        }

        # Build output
        $CertificateData = [PSCustomObject]@{
            ComputerName = $env:COMPUTERNAME
            MachineCertificateStore = @($MachineStore)
            WinRMCertificates = @($WinRMCertificates)
            CertificateAuthority = $CertificateAuthority
            AutoEnrollment = $AutoEnrollment
            Statistics = $Statistics
        }

        # Detector evaluation
        if($WinRMCertificates.Count -eq 0){
            $Warnings += "No valid certificate suitable for WinRM HTTPS was found."
        }

        $Status = "Healthy"
        if($Errors.Count -gt 0){
            $Status = "Failed"
        }
        elseif($Warnings.Count -gt 0){
            $Status = "Warning"
        }

        $Duration =(Get-Date) - $StartTime

        New-ERMDetectionResult `
            -Component "Certificate" `
            -Status $Status `
            -Data $CertificateData `
            -Errors $Errors `
            -Warnings $Warnings

        Write-ERMLog -Message "Certificate detection completed"
    }catch {
        Write-ERMLog -Level Error -Message $_.Exception.Message
        New-ERMDetectionResult `
            -Component "Certificate" `
            -Status "Failed" `
            -Data $null `
            -Errors @($_.Exception.Message)
    }
}