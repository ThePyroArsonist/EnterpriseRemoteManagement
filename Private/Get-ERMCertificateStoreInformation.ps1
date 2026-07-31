function Get-ERMCertificateStoreInformation {
    [CmdletBinding()]

    param()

    $Stores = @(
            "Cert:\LocalMachine\My"
            "Cert:\LocalMachine\Root"
            "Cert:\LocalMachine\CA"
            )

    $Results = @()

    foreach($Store in $Stores){
        try {
            if(Test-Path $Store){
                $Certificates = Get-ChildItem -Path $Store -ErrorAction Stop
                foreach($Certificate in $Certificates){
                    $Results += [PSCustomObject]@{
                        Store = $Store
                        Subject = $Certificate.Subject
                        Issuer = $Certificate.Issuer
                        Thumbprint = $Certificate.Thumbprint
                        FriendlyName = $Certificate.FriendlyName
                        SerialNumber = $Certificate.SerialNumber
                        NotBefore = $Certificate.NotBefore
                        NotAfter = $Certificate.NotAfter
                        HasPrivateKey = $Certificate.HasPrivateKey
                        EnhancedKeyUsage = @($Certificate.EnhancedKeyUsageList |
                                ForEach-Object {
                                    $_.FriendlyName
                                })
                        DNSNames = @($Certificate.DnsNameList |
                                ForEach-Object {
                                    $_.Unicode
                                })
                        CertificateDetails = [PSCustomObject]@{
                            Version = $Certificate.Version
                            SignatureAlgorithm = $Certificate.SignatureAlgorithm.FriendlyName
                            PublicKeyAlgorithm = $Certificate.PublicKey.Oid.FriendlyName
                        }
                    }
                }
            }
        } catch {
            Write-ERMLog -Level Warning -Message ("Unable to read certificate store {0}: {1}" -f $Store, $_.Exception.Message)
        }
    }

    Write-Host "DEBUG Results Count: $($Results.Count)"

    $Results[0] | Format-List *

    [PSCustomObject]@{
        ComputerName = $env:COMPUTERNAME
        StoresChecked = $Stores
        CertificateCount = $Results.Count
        CertificateStores = $Results | Group-Object Store |
            ForEach-Object {
                [PSCustomObject]@{
                    Store = $_.Name
                    Count = $_.Count
                }
            }
        Certificates = @($Results)
    }
}