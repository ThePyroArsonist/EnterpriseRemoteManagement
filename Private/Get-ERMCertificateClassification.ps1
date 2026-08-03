function Get-ERMCertificateClassification {
<#
.SYNOPSIS
    Classifies a normalized ERM certificate.
.DESCRIPTION
    Determines the certificate source, type, enrollment method and
    initial trust characteristics.
    This function performs classification only.
    It intentionally performs no validation, suitability analysis,
    recommendation generation or WinRM evaluation.
.NOTES
    ERM Certificate Engine v2
#>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [ValidateNotNull()]
        [psobject]
        $Certificate
    )

    Write-ERMLog -Message ("Classifying certificate [{0}]" -f $Certificate.Identity.Thumbprint)

    # Initialize
    $Tags = [System.Collections.Generic.List[string]]::new()
    $Notes = [System.Collections.Generic.List[string]]::new()
    $Confidence = 0

    # Source Classification
    $SourceType = "Unknown"
    $IsSelfSigned = $false
    $IsEnterpriseCA = $false
    $IsMicrosoftManaged = $false
    $IsThirdParty = $false

    # Self Signed
    if ($Certificate.Identity.Subject -eq $Certificate.Identity.Issuer) {
        $SourceType = "SelfSigned"
        $IsSelfSigned = $true
        $Confidence = 100
        $Tags.Add("SelfSigned")
        $Notes.Add("Subject and issuer are identical.")
    }

    # Microsoft managed identities
    elseif ($Certificate.Identity.Issuer -match 'MS-Organization|Microsoft Passport|Microsoft Device|Windows Hello|AAD|Entra') {
        $SourceType = "MicrosoftManaged"
        $IsMicrosoftManaged = $true
        $Confidence = 95
        $Tags.Add("MicrosoftManaged")
        $Notes.Add("Certificate issued by Microsoft managed identity infrastructure.")
    }

    # Enterprise CA
    elseif ($Certificate.Enrollment.Present -or $Certificate.Identity.Issuer -match 'Certificate Authority| CA\b|Enterprise') {
        $SourceType = "EnterpriseCA"
        $IsEnterpriseCA = $true
        $Confidence = 90
        $Tags.Add("EnterpriseCA")
        if ($Certificate.Enrollment.Present) {
            $Tags.Add("Template")
            if ($Certificate.Enrollment.Template) {
                $Notes.Add(("Certificate template detected: {0}" -f $Certificate.Enrollment.Template))
            }
        }
    }

    # Third-party certificate
    else {
        $SourceType = "ThirdParty"
        $IsThirdParty = $true
        $Confidence = 75
        $Tags.Add("ThirdParty")
        $Notes.Add("Certificate appears to originate from an external CA.")
    }

    # Certificate Type
    $CertificateType = "Unknown"
    $IsRootCA = $false
    $IsIntermediateCA = $false
    $IsEndEntity = $false
    $IsCrossSigned = $false

    switch ($Certificate.Metadata.StoreName) {
        "Root" {
            $CertificateType = "RootCA"
            $IsRootCA = $true
            $Tags.Add("RootCA")
            $Confidence += 5
            break
        } "CA" {
            $CertificateType = "IntermediateCA"
            $IsIntermediateCA = $true
            $Tags.Add("IntermediateCA")
            $Confidence += 5
            break
        } "My" {
            if ($Certificate.Usage.BasicConstraints.CertificateAuthority) {
                $CertificateType = "CrossSigned"
                $IsCrossSigned = $true
                $Tags.Add("CrossSigned")
                $Notes.Add("Certificate exists in Personal store but is marked as a CA certificate.")
            } else {
                $CertificateType = "EndEntity"
                $IsEndEntity = $true
                $Tags.Add("EndEntity")
            }
            break
        } default {
            if ($Certificate.Usage.BasicConstraints.CertificateAuthority) {
                $CertificateType = "CertificateAuthority"
                $Tags.Add("CertificateAuthority")
            } else {
                $CertificateType = "EndEntity"
                $Tags.Add("EndEntity")
            }
        }
    }

    # Enrollment Classification
    $EnrollmentType = "Unknown"
    $EnterpriseTemplate = $false
    $ManualEnrollment = $false
    $ImportedCertificate = $false

    if ($Certificate.Enrollment.Present) {
        $EnrollmentType = "Enterprise"
        $EnterpriseTemplate = $true
        $Confidence += 10
        $Tags.Add("EnterpriseEnrollment")
    } elseif ($Certificate.PrivateKey.Present) {
        $EnrollmentType = "Manual"
        $ManualEnrollment = $true
        $Tags.Add("ManualEnrollment")
        $Notes.Add("Certificate contains a private key but no enterprise template.")
    } else {
        $EnrollmentType = "Imported"
        $ImportedCertificate = $true
        $Tags.Add("ImportedCertificate")
        $Notes.Add("Certificate appears to have been imported.")
    }

    # Trust Classification
    $TrustType = "Unknown"
    $Trusted = $false
    $RootTrusted = $false
    $ChainTrusted = $false

    switch ($Certificate.Metadata.StoreName) {
        "Root" {
            $TrustType = "RootTrusted"
            $Trusted = $true
            $RootTrusted = $true
            $ChainTrusted = $true
            $Confidence += 5
            $Tags.Add("TrustedRoot")
            break
        } "CA" {
            $TrustType = "IntermediateTrusted"
            $Trusted = $true
            $ChainTrusted = $true
            $Confidence += 5
            $Tags.Add("TrustedIntermediate")
            break
        } "My" {
            $TrustType = "EndEntity"
            if ($Certificate.Identity.Subject -ne $Certificate.Identity.Issuer) {
                $Trusted = $true
            }
            break
        } default {
            $TrustType = "Unknown"
        }
    }

    # Intended Purpose
    $Purpose = [System.Collections.Generic.List[string]]::new()
    if ($Certificate.Usage.EKU.ServerAuthentication) {
        $Purpose.Add("ServerAuthentication")
        $Tags.Add("ServerAuthentication")
    }
    if ($Certificate.Usage.EKU.ClientAuthentication) {
        $Purpose.Add("ClientAuthentication")
        $Tags.Add("ClientAuthentication")
    }
    if ($Certificate.Usage.EKU.CodeSigning) {
        $Purpose.Add("CodeSigning")
        $Tags.Add("CodeSigning")
    }
    if ($Certificate.Usage.EKU.SmartCardLogon) {
        $Purpose.Add("SmartCardLogon")
        $Tags.Add("SmartCardLogon")
    }
    if ($Certificate.Usage.EKU.AnyPurpose) {
        $Purpose.Add("AnyPurpose")
        $Tags.Add("AnyPurpose")
    }
    if ($Certificate.Usage.BasicConstraints.CertificateAuthority) {
        $Purpose.Add("CertificateAuthority")
        $Tags.Add("CertificateAuthority")
    }
    if ($Purpose.Count -eq 0) {
        $Purpose.Add("Unknown")
        $Notes.Add("Unable to determine intended certificate purpose.")
    }

    # Additional Automatic Tags
    if ($Certificate.PrivateKey.Present) {
        $Tags.Add("PrivateKey")
    }

    if ($Certificate.PrivateKey.Accessible) {
        $Tags.Add("PrivateKeyAccessible")
    }

    if (-not $Certificate.Validity.Expired) {
        $Tags.Add("NotExpired")
    }

    if ($Certificate.Validity.ExpiringSoon) {
        $Tags.Add("ExpiringSoon")
    }

    if ($Certificate.IdentityMatch) {
        if ($Certificate.IdentityMatch.IdentityMatch) {
            $Tags.Add("IdentityMatch")
        } else {
            $Notes.Add("Certificate does not match the current computer identity.")
        }
    }

    # Confidence Normalization
    if ($Confidence -gt 100) {
        $Confidence = 100
    }
    if ($Confidence -lt 0) {
        $Confidence = 0
    }

    # Build Classification Object
    $Classification = [PSCustomObject]@{
        Source = [PSCustomObject]@{
            Type = $SourceType
            SelfSigned = $IsSelfSigned
            EnterpriseCA = $IsEnterpriseCA
            ThirdParty = $IsThirdParty
            MicrosoftManaged = $IsMicrosoftManaged
            Unknown = ($SourceType -eq "Unknown")
        }
        CertificateType = [PSCustomObject]@{
            Type = $CertificateType
            IsRootCA = $IsRootCA
            IsIntermediateCA = $IsIntermediateCA
            IsEndEntity = $IsEndEntity
            IsCrossSigned = $IsCrossSigned
        }
        Enrollment = [PSCustomObject]@{
            Type = $EnrollmentType
            EnterpriseTemplate = $EnterpriseTemplate
            Manual = $ManualEnrollment
            Imported = $ImportedCertificate
        }
        Trust = [PSCustomObject]@{
            Type = $TrustType
            Trusted = $Trusted
            RootTrusted = $RootTrusted
            ChainTrusted = $ChainTrusted
        }
        Purpose = @($Purpose)
        Tags = @($Tags | Sort-Object -Unique)
        Confidence = $Confidence
        Notes = @($Notes)
    }
    Write-ERMLog -Message ("Certificate [{0}] classified as [{1}] [{2}] with confidence [{3}]%%." -f $Certificate.Identity.Thumbprint, $SourceType, $CertificateType, $Confidence)
    return $Classification
}