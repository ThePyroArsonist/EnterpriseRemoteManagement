function Get-ERMCertificateClassification {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [array]
        $Certificates
    )

    $Results = @()

    foreach($Certificate in $Certificates){
        try {
            # Certificate source classification
            $Source = "Unknown"
            if($Certificate.Subject -eq $Certificate.Issuer){
                $Source = "SelfSigned"
            } elseif($Certificate.Issuer -match "MS-Organization-P2P|MS-Organization-Access"){
                $Source = "MicrosoftManaged"
            } elseif($Certificate.Issuer -match "CA|Certificate Authority"){
                $Source = "EnterpriseCA"
            } else {
                $Source = "ThirdParty"
            }

            # Expiration evaluation
            $ExpirationStatus = "Valid"
            if($ExpirationStatus -eq "Valid"){
                $Score += 20
            } elseif($ExpirationStatus -eq "ExpiringSoon"){
                $Reasons += "Certificate expires within 30 days"
            } else {
                $Reasons += "Certificate expired"
            }

            # EKU normalization
            $EKU = [PSCustomObject]@{
                ServerAuthentication = $false
                ClientAuthentication = $false
                CodeSigning = $false
                SmartCardLogon = $false
                AnyPurpose = $false
            }

            foreach($Purpose in $Certificate.EnhancedKeyUsage){
                switch -Wildcard ($Purpose){
                    "*Server Authentication*" {
                        $EKU.ServerAuthentication = $true
                    }

                    "*Client Authentication*" {
                        $EKU.ClientAuthentication = $true
                    }

                    "*Code Signing*" {
                        $EKU.CodeSigning = $true
                    }

                    "*Smart Card Logon*" {
                        $EKU.SmartCardLogon = $true
                    }

                    "*Any Purpose*" {
                        $EKU.AnyPurpose = $true
                    }
                }
            }

            # SAN processing
            $SAN = [PSCustomObject]@{
                DNS = @($Certificate.DNSNames)
                IP = @()
            }

            # WinRM evaluation
            $Score = 0
            $Reasons = @()

            # Computer identity
            $ComputerNames = @($env:COMPUTERNAME
                try {
                    (Get-CimInstance Win32_ComputerSystem).DNSHostName
                } catch {})

            $SANMatch = $false
            foreach($Name in $ComputerNames){
                if($Certificate.DNSNames -contains $Name){
                    $SANMatch = $true
                }
            }

            if($SANMatch){
                $Score += 10
            }else{
                $Reasons += "Certificate SAN does not contain computer identity"
            }

            if($Certificate.HasPrivateKey){
                $Score += 30
            } else {
                $Reasons += "Missing private key"
            }

            if($EKU.ServerAuthentication){
                $Score += 30
            } else {
                $Reasons += "Missing Server Authentication EKU"
            }

            if($ExpirationStatus -eq "Valid"){
                $Score += 20
            } elseif($ExpirationStatus -eq "ExpiringSoon"){
                $Score += 10
                $Reasons += "Certificate expires within 30 days"
            } else {
                $Reasons += "Certificate expired"
            }

            if($Source -eq "EnterpriseCA"){
                $Score += 10
            }elseif($Source -eq "MicrosoftManaged"){
                $Score -= 25
                $Reasons += "Certificate issued by Microsoft managed identity provider"
            }elseif($Source -eq "SelfSigned"){
                $Score -= 20
                $Reasons += "Self-signed certificate"
            }

            $PreferredCandidate = $true

            if($Source -eq "MicrosoftManaged"){
                $PreferredCandidate = $false
            }

            $WinRMUsable = ($HasPrivateKey -and $EKU.ServerAuthentication)
            $WinRMPreferred = ($Score -ge 75 -and $PreferredCandidate)

            if(-not $WinRMPreferred){
                $Reasons += "Certificate score below WinRM threshold"
            }

            # Output
            $Results += [PSCustomObject]@{
                Store = $Certificate.Store
                Subject = $Certificate.Subject
                Issuer = $Certificate.Issuer
                Thumbprint = $Certificate.Thumbprint
                Source = $Source
                Expiration = [PSCustomObject]@{
                    Status = $ExpirationStatus
                    DaysRemaining = $DaysRemaining
                }
                EKU = $EKU
                SAN = [PSCustomObject]@{
                    DNS = @($Certificate.DNSNames)
                    IdentityMatch = $SANMatch
                }
                HasPrivateKey = $Certificate.HasPrivateKey
                PreferredCandidate = $PreferredCandidate
                WinRM = [PSCustomObject]@{
                    Usable = $WinRMUsable
                    Preferred = $WinRMPreferred
                    Score = $Score
                    Reasons = $Reasons
                }
            }
        } catch {
            Write-ERMLog -Level Warning -Message ("Unable to classify certificate {0}: {1}" -f $Certificate.Subject, $_.Exception.Message)
        }
    }
    return @($Results)
}