Set-StrictMode -Version Latest

#region Private Helper Functions

function Get-ERMCertificateIdentity {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [System.Security.Cryptography.X509Certificates.X509Certificate2]
        $Certificate
    )

    $CommonName = $null

    try {
        if ($Certificate.Subject -match 'CN=([^,]+)') {
            $CommonName = $Matches[1]
        }
    } catch {
        Write-ERMLog -Level Warning -Message ("Unable to parse certificate common name: {0}" -f $_.Exception.Message)
    }

    [PSCustomObject]@{
        Subject         = $Certificate.Subject
        CommonName      = $CommonName
        Issuer          = $Certificate.Issuer
        Thumbprint      = $Certificate.Thumbprint
        SerialNumber    = $Certificate.SerialNumber
        FriendlyName    = $Certificate.FriendlyName
        Version         = $Certificate.Version
    }
}

function Get-ERMCertificateValidity {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [System.Security.Cryptography.X509Certificates.X509Certificate2]
        $Certificate
    )

    $Now = Get-Date
    $DaysRemaining =[math]::Floor(($Certificate.NotAfter - $Now).TotalDays)

    [PSCustomObject]@{
        NotBefore      = $Certificate.NotBefore
        NotAfter       = $Certificate.NotAfter
        DaysRemaining  = $DaysRemaining
        Expired        = ($Certificate.NotAfter -lt $Now)
        ExpiringSoon   = (($DaysRemaining -le 30) -and ($DaysRemaining -ge 0))
    }
}

function Get-ERMCertificateAlgorithms {
    <#
    .SYNOPSIS
        Retrieves cryptographic algorithm information for a certificate.
    .DESCRIPTION
        Normalizes public key, signature algorithm and cryptographic strength
        information into a consistent object.

        This function performs no validation. It only inventories the
        certificate's cryptographic characteristics.
    .OUTPUTS
        PSCustomObject
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [System.Security.Cryptography.X509Certificates.X509Certificate2]
        $Certificate
    )

    # Defaults
    $PublicKeyLength = $null
    $PublicKeyAlgorithm = $Certificate.PublicKey.Oid.FriendlyName
    $PublicKeyOID = $Certificate.PublicKey.Oid.Value
    $SignatureAlgorithm = $Certificate.SignatureAlgorithm.FriendlyName
    $SignatureOID = $Certificate.SignatureAlgorithm.Value

    # Determine key size
    try {
        if ($Certificate.PublicKey.Key) {
            $PublicKeyLength = $Certificate.PublicKey.Key.KeySize
        }
    } catch {
        Write-ERMLog -Level Debug -Message ("Unable to determine key length for certificate {0}" -f $Certificate.Thumbprint)
    }

    # Determine hash algorithm
    $HashAlgorithm = "Unknown"
    switch -Regex ($SignatureAlgorithm) {
        "MD5"     { $HashAlgorithm = "MD5" }
        "SHA1"    { $HashAlgorithm = "SHA1" }
        "SHA256"  { $HashAlgorithm = "SHA256" }
        "SHA384"  { $HashAlgorithm = "SHA384" }
        "SHA512"  { $HashAlgorithm = "SHA512" }
    }

    # Evaluate key strength
    $KeyStrength = "Unknown"
    $IsWeakKey = $false

    switch ($PublicKeyAlgorithm) {
        "RSA" {
            if ($PublicKeyLength -lt 2048) {
                $KeyStrength = "Weak"
                $IsWeakKey = $true
            } elseif ($PublicKeyLength -lt 3072) {
                $KeyStrength = "Acceptable"
            } elseif ($PublicKeyLength -lt 4096) {
                $KeyStrength = "Strong"
            } else {
                $KeyStrength = "Excellent"
            }
        } "ECC" {
            if ($PublicKeyLength -ge 384) {
                $KeyStrength = "Excellent"
            } elseif ($PublicKeyLength -ge 256) {
                $KeyStrength = "Strong"
            } else {
                $KeyStrength = "Weak"
                $IsWeakKey = $true
            }
        } "ECDSA" {
            if ($PublicKeyLength -ge 384) {
                $KeyStrength = "Excellent"
            } elseif ($PublicKeyLength -ge 256) {
                $KeyStrength = "Strong"
            } else {
                $KeyStrength = "Weak"
                $IsWeakKey = $true
            }
        } "DSA" {
            $KeyStrength = "Legacy"
            $IsWeakKey = $true
        } default {
            $KeyStrength = "Unknown"
        }
    }

    # Evaluate signature/hash strength
    $SignatureStrength = "Unknown"
    $IsWeakHash = $false

    switch ($HashAlgorithm) {
        "MD5" {
            $SignatureStrength = "Weak"
            $IsWeakHash = $true
        } "SHA1" {
            $SignatureStrength = "Weak"
            $IsWeakHash = $true
        } "SHA256" {
            $SignatureStrength = "Strong"
        } "SHA384" {
            $SignatureStrength = "Strong"
        } "SHA512" {
            $SignatureStrength = "Excellent"
        }
    }

    # Return normalized object
    return [PSCustomObject]@{
        PublicKey = [PSCustomObject]@{
            Algorithm = $PublicKeyAlgorithm
            OID = $PublicKeyOID
            KeyLength = $PublicKeyLength
        }

        Signature = [PSCustomObject]@{
            Algorithm = $SignatureAlgorithm
            OID = $SignatureOID
        }

        HashAlgorithm = $HashAlgorithm
        KeyStrength = $KeyStrength
        SignatureStrength = $SignatureStrength
        IsWeakKey = $IsWeakKey
        IsWeakHash = $IsWeakHash
        Summary = [PSCustomObject]@{
            ModernCryptography = (-not $IsWeakKey -and -not $IsWeakHash)
            RecommendedForEnterprise = ($KeyStrength -in @("Strong","Excellent") -and $SignatureStrength -in @("Strong","Excellent"))
        }
    }
}

function Get-ERMCertificateEKU {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [System.Security.Cryptography.X509Certificates.X509Certificate2]
        $Certificate
    )

    $FriendlyNames = @()
    $OIDs = @()

    foreach ($Usage in $Certificate.EnhancedKeyUsageList) {
        if ($Usage.FriendlyName) {
            $FriendlyNames += $Usage.FriendlyName
        }
        if ($null -ne $Usage.ObjectId) {
            if ($Usage.ObjectId -is [string]) {
                $OIDs += $Usage.ObjectId
            } elseif ($Usage.ObjectId.PSObject.Properties['Value']) {
                $OIDs += $Usage.ObjectId.Value
            } else {
                $OIDs += [string]$Usage.ObjectId
            }
        }
    }

    [PSCustomObject]@{
        FriendlyNames = @($FriendlyNames)
        OIDs = @($OIDs)
        ServerAuthentication = $FriendlyNames -contains "Server Authentication"
        ClientAuthentication = $FriendlyNames -contains "Client Authentication"
        CodeSigning = $FriendlyNames -contains "Code Signing"
        SmartCardLogon = $FriendlyNames -contains "Smart Card Logon"
        AnyPurpose = $FriendlyNames -contains "Any Purpose"
    }
}

function Get-ERMCertificateSAN {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [System.Security.Cryptography.X509Certificates.X509Certificate2]
        $Certificate
    )

    # Normalized collections
    $DNS = New-Object System.Collections.Generic.HashSet[string]
    $UPN = New-Object System.Collections.Generic.HashSet[string]
    $Email = New-Object System.Collections.Generic.HashSet[string]
    $URI = New-Object System.Collections.Generic.HashSet[string]
    $IP = New-Object System.Collections.Generic.HashSet[string]
    $Other = New-Object System.Collections.Generic.List[string]

    # Modern API (preferred)
    try {
        if ($Certificate.DnsNameList) {
            foreach ($Entry in $Certificate.DnsNameList) {
                if (-not [string]::IsNullOrWhiteSpace($Entry.Unicode)) {
                    $null = $DNS.Add($Entry.Unicode.ToLowerInvariant())
                }
            }
        }
    } catch {
        Write-ERMLog -Level Debug -Message ("DnsNameList unavailable for certificate {0}" -f $Certificate.Thumbprint)
    }

    # Parse SAN extension for additional name types
    foreach ($Extension in $Certificate.Extensions) {
        if ($Extension.Oid.Value -ne "2.5.29.17") {
            continue
        }
        try {
            $Lines = $Extension.Format($true) -split "[`r`n,]+"
            foreach ($Line in $Lines) {
                $Item = $Line.Trim()
                switch -Regex ($Item) {
                    '^DNS Name=(.+)$' {
                        $null = $DNS.Add($Matches[1].Trim().ToLowerInvariant())
                    } '^RFC822 Name=(.+)$' {
                        $null = $Email.Add($Matches[1].Trim())
                    } '^UPN=(.+)$' {
                        $null = $UPN.Add($Matches[1].Trim())
                    } '^URL=(.+)$' {
                        $null = $URI.Add($Matches[1].Trim())
                    } '^IP Address=(.+)$' {
                        $null = $IP.Add($Matches[1].Trim())
                    } default {
                        if ($Item) {
                            $Other.Add($Item)
                        }
                    }
                }
            }
        }
        catch {
            Write-ERMLog -Level Warning -Message ("Unable to parse SAN extension for certificate {0}: {1}" -f $Certificate.Thumbprint, $_.Exception.Message)
        }
    }

    [PSCustomObject]@{
        DNS = @($DNS)
        UPN = @($UPN)
        Email = @($Email)
        URI = @($URI)
        IP = @($IP)
        Other = @($Other)
        Counts = [PSCustomObject]@{
            DNS = $DNS.Count
            UPN = $UPN.Count
            Email = $Email.Count
            URI = $URI.Count
            IP = $IP.Count
            Other = $Other.Count
        }
        HasDNSNames = ($DNS.Count -gt 0)
        HasUPN = ($UPN.Count -gt 0)
        HasEmail = ($Email.Count -gt 0)
        HasURI = ($URI.Count -gt 0)
        HasIPAddresses = ($IP.Count -gt 0)
    }
}

function Get-ERMCertificateTemplate {
<#
.SYNOPSIS
    Retrieves certificate enrollment and template information.
.DESCRIPTION
    Parses Microsoft certificate template extensions and normalizes
    enrollment metadata.
    This function performs inventory only.
    It does not determine certificate suitability.
.OUTPUTS
    PSCustomObject
#>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [System.Security.Cryptography.X509Certificates.X509Certificate2]
        $Certificate
    )

    # Defaults
    $TemplatePresent = $false
    $TemplateName = $null
    $TemplateOID = $null
    $RawTemplate = $null
    foreach ($Extension in $Certificate.Extensions) {
        switch ($Extension.Oid.Value) {
            # Certificate Template Information
            "1.3.6.1.4.1.311.21.7" {
                try {
                    $RawTemplate = $Extension.Format($false)
                    $TemplatePresent = $true
                } catch {
                    Write-ERMLog -Level Debug -Message ("Unable to parse template information for certificate {0}" -f $Certificate.Thumbprint)
                }
            }

            # Certificate Template Name
            "1.3.6.1.4.1.311.20.2" {
                try {
                    $TemplateName = $Extension.Format($false)
                } catch {
                    Write-ERMLog -Level Debug -Message ("Unable to parse template name for certificate {0}" -f $Certificate.Thumbprint)
                }
            }
        }
    }

    # Extract OID from Template Information if possible
    if ($RawTemplate) {
        if ($RawTemplate -match '(\d+(\.\d+)+)') {
            $TemplateOID = $Matches[1]
        }
        if (-not $TemplateName) {
            if ($RawTemplate -match 'Template=([^,\r\n]+)') {
                $TemplateName = $Matches[1].Trim()
            }
        }
    }

    # Normalize template name
    $NormalizedTemplate = $null
    if ($TemplateName) {
        $NormalizedTemplate = $TemplateName.Trim()
    }

    # Classification
    $Purpose = "Unknown"
    $Classification = "Unknown"
    $MicrosoftTemplate = $false
    $EnterpriseTemplate = $false
    $CustomTemplate = $false
    $BuiltInTemplate = $false
    $RecommendedForWinRM = $false

    switch -Regex ($NormalizedTemplate) {
        "^Computer$" {
            $Purpose = "Computer"
            $MicrosoftTemplate = $true
            $EnterpriseTemplate = $true
            $BuiltInTemplate = $true
            $RecommendedForWinRM = $true
        } "^Workstation.*" {
            $Purpose = "Workstation"
            $MicrosoftTemplate = $true
            $EnterpriseTemplate = $true
            $BuiltInTemplate = $true
            $RecommendedForWinRM = $true
        } "^WebServer$" {
            $Purpose = "Web Server"
            $MicrosoftTemplate = $true
            $EnterpriseTemplate = $true
            $BuiltInTemplate = $true
            $RecommendedForWinRM = $true
        } "^DomainController$" {
            $Purpose = "Domain Controller"
            $MicrosoftTemplate = $true
            $EnterpriseTemplate = $true
            $BuiltInTemplate = $true
            $RecommendedForWinRM = $true
        } "^DomainControllerAuthentication$" {
            $Purpose = "Domain Controller Authentication"
            $MicrosoftTemplate = $true
            $EnterpriseTemplate = $true
            $BuiltInTemplate = $true
            $RecommendedForWinRM = $true
        } "^KerberosAuthentication$" {
            $Purpose = "Kerberos"
            $MicrosoftTemplate = $true
            $EnterpriseTemplate = $true
            $BuiltInTemplate = $true
            $RecommendedForWinRM = $true
        } "^User$" {
            $Purpose = "User"
            $MicrosoftTemplate = $true
            $EnterpriseTemplate = $true
            $BuiltInTemplate = $true
        } "^CodeSigning$" {
            $Purpose = "Code Signing"
            $MicrosoftTemplate = $true
            $EnterpriseTemplate = $true
            $BuiltInTemplate = $true
        } default {
            if ($NormalizedTemplate) {
                $Purpose = "Custom"
                $EnterpriseTemplate = $true
                $CustomTemplate = $true
                $RecommendedForWinRM = $true
            }
        }
    }
    if ($EnterpriseTemplate) {
        $Classification = "Enterprise"
    } elseif ($MicrosoftTemplate) {
        $Classification = "Microsoft"
    } elseif ($CustomTemplate) {
        $Classification = "Custom"
    }

    # Auto-enrollment heuristic
    $AutoEnrollmentLikely = ($EnterpriseTemplate -and $Certificate.HasPrivateKey)

    # Enterprise PKI heuristic
    $EnterprisePKI = ($EnterpriseTemplate -or $Certificate.Issuer -match "Certificate Authority|CA")

    # Notes
    $Notes = @()
    if (-not $TemplatePresent) {
        $Notes += "Certificate does not contain Microsoft template information."
    }
    if ($CustomTemplate) {
        $Notes += "Certificate uses a custom enterprise template."
    }
    if ($RecommendedForWinRM) {
        $Notes += "Template is appropriate for WinRM HTTPS."
    }

    return [PSCustomObject]@{
        Present = $TemplatePresent
        Template = [PSCustomObject]@{
            Name = $NormalizedTemplate
            DisplayName = $NormalizedTemplate
            OID = $TemplateOID
            RawValue = $RawTemplate
        }
        Classification = [PSCustomObject]@{
            Type = $Classification
            EnterpriseTemplate = $EnterpriseTemplate
            MicrosoftTemplate = $MicrosoftTemplate
            BuiltInTemplate = $BuiltInTemplate
            CustomTemplate = $CustomTemplate
        }
        Purpose = $Purpose
        EnterprisePKI = $EnterprisePKI
        AutoEnrollmentLikely = $AutoEnrollmentLikely
        RecommendedForWinRM = $RecommendedForWinRM
        Notes = @($Notes)
    }
}

function Get-ERMCertificateKeyUsage {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [System.Security.Cryptography.X509Certificates.X509Certificate2]
        $Certificate
    )

    $Usage = @()

    foreach ($Extension in $Certificate.Extensions) {
        if ($Extension -isnot [System.Security.Cryptography.X509Certificates.X509KeyUsageExtension]) {
            continue
        }
        foreach ($Flag in [System.Enum]::GetValues(
            [System.Security.Cryptography.X509Certificates.X509KeyUsageFlags])) {
            if (($Extension.KeyUsages -band $Flag) -eq $Flag) {
                $Usage += $Flag.ToString()
            }
        }
    }
    @($Usage)
}

function Get-ERMCertificatePrivateKey {
    <#
    .SYNOPSIS
        Retrieves private key information for a certificate.

    .DESCRIPTION
        Normalizes private key information into a consistent object regardless
        of whether the certificate uses a legacy CryptoAPI (CAPI) provider,
        a Cryptography Next Generation (CNG) provider, or another provider.

        This function is designed to be compatible with Windows PowerShell 5.1
        and newer PowerShell versions.

    .OUTPUTS
        PSCustomObject
    #>

    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [System.Security.Cryptography.X509Certificates.X509Certificate2]
        $Certificate
    )

    # Default object
    $Result = [PSCustomObject]@{
        Present         = $false
        Accessible      = $false
        Algorithm       = $null
        Provider        = $null
        ProviderType    = "Unknown"
        KeyLength       = $null
        HardwareBacked  = $false
        Exportable      = $null
    }
    if (-not $Certificate.HasPrivateKey) {
        return $Result
    }
    $Result.Present = $true

    try {
        $PrivateKey = $Certificate.PrivateKey
        if ($null -eq $PrivateKey) {
            return $Result
        }
        $Result.Accessible = $true

        # Runtime type
        $TypeName = $PrivateKey.GetType().FullName
        switch -Regex ($TypeName) {
            "RSACng" {
                $Result.Algorithm = "RSA"
                $Result.ProviderType = "CNG"
            } "RSACryptoServiceProvider" {
                $Result.Algorithm = "RSA"
                $Result.ProviderType = "CAPI"
            } "DSACryptoServiceProvider" {
                $Result.Algorithm = "DSA"
                $Result.ProviderType = "CAPI"
            }"ECDsa" {
                $Result.Algorithm = "ECDSA"
                $Result.ProviderType = "CNG"
            } default {
                $Result.Algorithm = $PrivateKey.SignatureAlgorithm
            }
        }

        # Key size
        try {
            if ($PrivateKey.KeySize) {
                $Result.KeyLength = $PrivateKey.KeySize
            }
        }
        catch {}

        # Crypto Service Provider (legacy)
        if ($PrivateKey -is [System.Security.Cryptography.RSACryptoServiceProvider]) {
            try {
                $Container = $PrivateKey.CspKeyContainerInfo
                if ($Container) {
                    $Result.Provider = $Container.ProviderName
                    $Result.HardwareBacked = $Container.HardwareDevice
                    $Result.Exportable = $Container.Exportable
                }
            }
            catch {}
        }

        # CNG provider
        elseif ($PrivateKey.PSObject.Properties.Match("Key").Count -gt 0) {
            try {
                if ($PrivateKey.Key.Provider) {
                    $Result.Provider = $PrivateKey.Key.Provider.Provider
                }
            }
            catch {}
        }
    }
    catch {
        Write-ERMLog -Level Warning -Message ("Unable to inspect private key for certificate {0}: {1}" -f $Certificate.Thumbprint, $_.Exception.Message)
    }
    return $Result
}

function ConvertTo-ERMCertificateObject {
<#
.SYNOPSIS
    Converts an X509 certificate into the normalized ERM certificate object.
.DESCRIPTION
    This function is the canonical normalization layer for the ERM
    Certificate Engine.
    It performs no validation, classification, scoring or suitability
    analysis.
    Those responsibilities belong to downstream pipeline stages.
#>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [System.Security.Cryptography.X509Certificates.X509Certificate2]
        $Certificate,
        [Parameter(Mandatory)]
        [string]
        $Store
    )
    $StoreParts = $Store -split "\\"
    $InventoryTime = Get-Date
    return [PSCustomObject]@{
        Metadata = [PSCustomObject]@{
            InventoryVersion = "2.0"
            InventoryTime = $InventoryTime
            Store = $Store
            StoreLocation = $StoreParts[1]
            StoreName = $StoreParts[2]
        }
        Identity = Get-ERMCertificateIdentity -Certificate $Certificate
        Names = Get-ERMCertificateSAN -Certificate $Certificate
        Validity = Get-ERMCertificateValidity -Certificate $Certificate
        Algorithms = Get-ERMCertificateAlgorithms -Certificate $Certificate
        PrivateKey = Get-ERMCertificatePrivateKey -Certificate $Certificate
        Usage = [PSCustomObject]@{
            EKU = Get-ERMCertificateEKU -Certificate $Certificate
            KeyUsage = Get-ERMCertificateKeyUsage -Certificate $Certificate
            BasicConstraints = Get-ERMCertificateBasicConstraints -Certificate $Certificate
            Policies = Get-ERMCertificatePolicies -Certificate $Certificate
        }

        Enrollment = Get-ERMCertificateTemplate -Certificate $Certificate
        Identifiers = Get-ERMCertificateIdentifiers -Certificate $Certificate
        AuthorityInformationAccess = Get-ERMCertificateAuthorityInformationAccess -Certificate $Certificate
        CRLDistributionPoints = Get-ERMCertificateCRLDistributionPoints -Certificate $Certificate
        
        # Populated by later pipeline stages.
        IdentityMatch = $null
        Classification = $null
        Validation = $null
        Suitability = $null
        Recommendation = $null
        WinRM = $null
        Internal = [PSCustomObject]@{
            Thumbprint = $Certificate.Thumbprint
            Store = $Store
            RawCertificate = $Certificate
        }
    }
}

#region Public Functions

function Get-ERMCertificateInventory {

    <#
    .SYNOPSIS
        Enumerates supported certificate stores and returns a normalized
        certificate inventory.

    .DESCRIPTION
        Inventories supported certificate stores and converts every discovered
        certificate into the ERM normalized certificate object.

        This function performs inventory only.

        It intentionally performs no certificate scoring or suitability
        evaluations.

    .OUTPUTS
        PSCustomObject

    #>

    [CmdletBinding()]
    param()

    $StartTime = Get-Date
    $ComputerIdentity = Get-ERMComputerCertificateIdentity

    Write-ERMLog -Message "Starting certificate inventory."

    # Stores currently supported by the Certificate Engine.
    $Stores = @(
        "Cert:\LocalMachine\My"
        "Cert:\LocalMachine\Root"
        "Cert:\LocalMachine\CA"
        "Cert:\LocalMachine\AuthRoot"
        "Cert:\LocalMachine\TrustedPeople"
        "Cert:\LocalMachine\TrustedPublisher"
    )

    $Inventory = @()
    $Errors = @()

    foreach ($Store in $Stores) {
        if (-not (Test-Path $Store)) {
            Write-ERMLog -Level Warning -Message ("Certificate store not found: {0}" -f $Store)
            continue
        }

        Write-ERMLog -Message ("Enumerating certificate store: {0}" -f $Store)

        try {
            $Certificates = Get-ChildItem -Path $Store -ErrorAction Stop
            foreach ($Certificate in $Certificates) {
                try {
                    $CertificateObject = ConvertTo-ERMCertificateObject -Certificate $Certificate -Store $Store
                    $CertificateObject.IdentityMatch = Get-ERMCertificateIdentityMatch -Certificate $CertificateObject -ComputerIdentity $ComputerIdentity
                    $CertificateObject.Classification = Get-ERMCertificateClassification -Certificate $CertificateObject
                    $Inventory += $CertificateObject
                } catch {

                    $Errors += "Failed processing certificate [$($Certificate.Thumbprint)]"

                    Write-ERMLog -Level Warning -Message "
                Failed to normalize certificate.
                Thumbprint:
                $($Certificate.Thumbprint)
                Subject:
                $($Certificate.Subject)
                Message:
                $($_.Exception.Message)
                Invocation:
                $($_.InvocationInfo.PositionMessage)
                ScriptStackTrace:
                $($_.ScriptStackTrace)"
                    throw
                }
            }
        }
        catch {
            $Errors += "Unable to enumerate certificate store [$Store]"
            Write-ERMLog -Level Warning -Message ("Unable to enumerate {0}: {1}" -f $Store, $_.Exception.Message)
        }
    }

    Write-ERMLog -Message ("Completed inventory of {0} certificates." -f $Inventory.Count)

    # Build inventory statistics.
    $Statistics = [PSCustomObject]@{
        TotalCertificates = $Inventory.Count 
        StoresEnumerated = $Stores.Count
        CertificatesWithPrivateKey = @($Inventory |
                Where-Object {
                    $_.PrivateKey.Present
                }).Count
        AccessiblePrivateKeys = @($Inventory |
                Where-Object {
                    $_.PrivateKey.Accessible
                }).Count
        ExpiredCertificates = @($Inventory |
                Where-Object {
                    $_.Validity.Expired
                }).Count
        ExpiringSoonCertificates = @($Inventory |
                Where-Object {
                    $_.Validity.ExpiringSoon
                }).Count
        CACertificates = @($Inventory |
                Where-Object {
                    $_.Usage.BasicConstraints.CertificateAuthority
                }).Count
        EndEntityCertificates = @($Inventory |
                Where-Object {
                    -not $_.Usage.BasicConstraints.CertificateAuthority
                }).Count
        ServerAuthenticationCertificates = @($Inventory |
                Where-Object {
                    $_.Usage.EKU.ServerAuthentication
                }).Count
        ClientAuthenticationCertificates = @($Inventory |
                Where-Object {
                    $_.Usage.EKU.ClientAuthentication
                }).Count
        Stores = @($Inventory |
            Group-Object {
                $_.Metadata.Store
            } |
            Sort-Object Name |
            ForEach-Object {
                [PSCustomObject]@{
                    Store = $_.Name
                    CertificateCount = $_.Count
                }
            }
        )
    }

    # Build engine metadata.
    $Metadata = [PSCustomObject]@{
        Engine = "ERM Certificate Engine"
        EngineVersion = "2.0.0"
        InventoryTime = $StartTime
        CompletionTime = Get-Date
        DurationMilliseconds = [math]::Round(((Get-Date) - $StartTime).TotalMilliseconds, 2)
        ComputerName = $env:COMPUTERNAME
        Stores = @($Stores)
    }

    # Build inventory environment.
    $Environment = [PSCustomObject]@{
        ComputerIdentity = $ComputerIdentity
        PowerShellVersion = $PSVersionTable.PSVersion.ToString()
        OperatingSystem =
            try {
                (Get-CimInstance Win32_OperatingSystem -ErrorAction Stop).Caption
            }
            catch {
                $null
            }
    }

    Write-ERMLog -Message ("Certificate inventory completed successfully. {0} certificates inventoried." -f $Inventory.Count)
    
    return [PSCustomObject]@{
        Metadata = $Metadata
        Environment = $Environment
        Statistics = $Statistics
        Certificates = @($Inventory)
        Errors = @($Errors)
    }
}

function Get-ERMCertificateBasicConstraints {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [System.Security.Cryptography.X509Certificates.X509Certificate2]
        $Certificate
    )

    $IsCA = $false
    $HasPathLengthConstraint = $false
    $PathLengthConstraint = $null

    foreach ($Extension in $Certificate.Extensions) {
        if ($Extension -is [System.Security.Cryptography.X509Certificates.X509BasicConstraintsExtension]) {
            $IsCA = $Extension.CertificateAuthority
            $HasPathLengthConstraint = $Extension.HasPathLengthConstraint
            if ($HasPathLengthConstraint) {
                $PathLengthConstraint = $Extension.PathLengthConstraint
            }
            break
        }
    }

    [PSCustomObject]@{
        CertificateAuthority = $IsCA
        HasPathLengthConstraint = $HasPathLengthConstraint
        PathLengthConstraint = $PathLengthConstraint
    }
}

function Get-ERMCertificatePolicies {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [System.Security.Cryptography.X509Certificates.X509Certificate2]
        $Certificate
    )
    $Policies = @()
    foreach ($Extension in $Certificate.Extensions) {
        if ($Extension.Oid.Value -ne "2.5.29.32") {
            continue
        }
        try {
            $Policies += $Extension.Format($false)
        }
        catch {
            Write-ERMLog -Level Warning -Message ("Unable to parse certificate policies for {0}: {1}" -f $Certificate.Thumbprint, $_.Exception.Message)
        }
    }
    @($Policies)
}

function Get-ERMCertificateAuthorityInformationAccess {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [System.Security.Cryptography.X509Certificates.X509Certificate2]
        $Certificate
    )
    $Locations = @()
    foreach ($Extension in $Certificate.Extensions) {
        if ($Extension.Oid.Value -ne "1.3.6.1.5.5.7.1.1") {
            continue
        }

        try {
            $Locations += ($Extension.Format($true) -split "`r?`n")
        }
        catch {
            Write-ERMLog -Level Warning -Message ("Unable to parse AIA extension for {0}: {1}" -f $Certificate.Thumbprint, $_.Exception.Message)
        }
    }
    @($Locations)
}

function Get-ERMCertificateCRLDistributionPoints {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [System.Security.Cryptography.X509Certificates.X509Certificate2]
        $Certificate
    )

    $DistributionPoints = @()

    foreach ($Extension in $Certificate.Extensions) {
        if ($Extension.Oid.Value -ne "2.5.29.31") {
            continue
        }
        try {
            $DistributionPoints += ($Extension.Format($true) -split "`r?`n")
        }
        catch {
            Write-ERMLog -Level Warning -Message ("Unable to parse CRL Distribution Points for {0}: {1}" -f $Certificate.Thumbprint, $_.Exception.Message)
        }
    }
    @($DistributionPoints)
}

function Get-ERMCertificateIdentifiers {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [System.Security.Cryptography.X509Certificates.X509Certificate2]
        $Certificate
    )

    $SubjectKeyIdentifier = $null
    $AuthorityKeyIdentifier = $null

    foreach ($Extension in $Certificate.Extensions) {
        switch ($Extension.Oid.Value) {
            # Subject Key Identifier
            "2.5.29.14" {
                try {
                    $SubjectKeyIdentifier = $Extension.Format($false)
                }
                catch { }
            }
            # Authority Key Identifier
            "2.5.29.35" {
                try {
                    $AuthorityKeyIdentifier = $Extension.Format($false)
                }
                catch { }
            }
        }
    }

    [PSCustomObject]@{
        SubjectKeyIdentifier = $SubjectKeyIdentifier
        AuthorityKeyIdentifier = $AuthorityKeyIdentifier
    }
}

function Get-ERMComputerCertificateIdentity {
    [CmdletBinding()]
    param()
    $ComputerSystem = Get-CimInstance -ClassName Win32_ComputerSystem -ErrorAction SilentlyContinue
    $DNSHostName = $env:COMPUTERNAME
    $Domain = $null
    $FQDN = $env:COMPUTERNAME
    if ($ComputerSystem) {
        if ($ComputerSystem.DNSHostName) {
            $DNSHostName = $ComputerSystem.DNSHostName
        }
        if ($ComputerSystem.Domain) {
            $Domain = $ComputerSystem.Domain
        }
        if ($DNSHostName -and $Domain) {
            $FQDN = "$DNSHostName.$Domain"
        }
    }

    [PSCustomObject]@{
        ComputerName = $env:COMPUTERNAME
        DNSHostName = $DNSHostName
        Domain = $Domain
        FQDN = $FQDN
        CandidateNames = @(
            $env:COMPUTERNAME
            $DNSHostName
            $FQDN
        ) | Sort-Object -Unique
    }
}

function Get-ERMCertificateIdentityMatch {
    <#
    .SYNOPSIS
        Evaluates how well a certificate represents the local computer.
    .DESCRIPTION
        Compares the certificate Subject, Common Name, and Subject Alternative
        Name entries against the computer identity.

        This function performs identity correlation only. It does not determine
        WinRM suitability.

    .OUTPUTS
        PSCustomObject
    #>

    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        $Certificate,
        [Parameter(Mandatory)]
        $ComputerIdentity
    )

    $MatchedNames = New-Object System.Collections.Generic.List[string]
    $UnmatchedNames = New-Object System.Collections.Generic.List[string]
    $SubjectMatch = $false
    $CommonNameMatch = $false
    $SANMatch = $false
    $WildcardMatch = $false
    $BestMatch = $null
    $MatchType = "None"
    $Score = 0

    foreach ($Candidate in $ComputerIdentity.CandidateNames) {
        if ([string]::IsNullOrWhiteSpace($Candidate)) {
            continue
        }
        $Matched = $false
        
        # SAN Exact Match (Highest confidence)
        if ($Certificate.Names.DNS -contains $Candidate.ToLowerInvariant()) {
            $Matched = $true
            $SANMatch = $true
            if ($Score -lt 100) {
                $Score = 100
                $BestMatch = $Candidate
                $MatchType = "SAN"
            }
        }

        # Common Name Exact Match
        elseif ($Certificate.Identity.CommonName -ieq $Candidate) {
            $Matched = $true
            $CommonNameMatch = $true
            if ($Score -lt 90) {
                $Score = 90
                $BestMatch = $Candidate
                $MatchType = "CommonName"
            }
        }

        # Subject Distinguished Name
        elseif ($Certificate.Identity.Subject -imatch [regex]::Escape($Candidate)) {
            $Matched = $true
            $SubjectMatch = $true
            if ($Score -lt 75) {
                $Score = 75
                $BestMatch = $Candidate
                $MatchType = "Subject"
            }
        }

        # Wildcard SAN
        else {
            foreach ($DNSName in $Certificate.Names.DNS) {
                if ($DNSName -like "*.*" -and $DNSName.StartsWith("*.")) {
                    $Suffix = $DNSName.Substring(1)
                    if ($Candidate.ToLowerInvariant().EndsWith($Suffix.ToLowerInvariant())) {
                        $Matched = $true
                        $WildcardMatch = $true
                        if ($Score -lt 80) {
                            $Score = 80
                            $BestMatch = $Candidate
                            $MatchType = "Wildcard"
                        }
                    }
                }
            }
        }

        if ($Matched) {
            $MatchedNames.Add($Candidate)
        } else {
            $UnmatchedNames.Add($Candidate)
        }
    }

    [PSCustomObject]@{
        ComputerName = $ComputerIdentity.ComputerName
        DNSHostName = $ComputerIdentity.DNSHostName
        Domain = $ComputerIdentity.Domain
        FQDN = $ComputerIdentity.FQDN
        CandidateNames = @($ComputerIdentity.CandidateNames)
        MatchedNames = @($MatchedNames)
        UnmatchedNames = @($UnmatchedNames)
        IdentityMatch = ($MatchedNames.Count -gt 0)
        MatchType = $MatchType
        MatchScore = $Score
        BestMatch = $BestMatch
        SubjectMatch = $SubjectMatch
        CommonNameMatch = $CommonNameMatch
        SANMatch = $SANMatch
        WildcardMatch = $WildcardMatch
    }
}