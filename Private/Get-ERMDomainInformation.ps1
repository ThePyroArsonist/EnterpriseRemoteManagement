function Get-ERMDomainInformation {
    [CmdletBinding()]
    param()

    try{
        $Computer =
            Get-CimInstance `
                -ClassName Win32_ComputerSystem `
                -ErrorAction Stop
        $UserIdentity =
            [System.Security.Principal.WindowsIdentity]::GetCurrent()
        $DomainData =
        [PSCustomObject]@{
            ComputerName =
                $env:COMPUTERNAME
            DomainJoined =
                $Computer.PartOfDomain
            ComputerDomain =
                if($Computer.PartOfDomain){
                    $Computer.Domain
                }else{
                    "WORKGROUP"
                }
            ComputerRole =
                switch($Computer.DomainRole){
                    0 {"Standalone Workstation"}
                    1 {"Member Workstation"}
                    2 {"Standalone Server"}
                    3 {"Member Server"}
                    4 {"Backup Domain Controller"}
                    5 {"Primary Domain Controller"}
                    default {"Unknown"}
                }
            UserLogonName =
                $UserIdentity.Name
            UserLogonDomain =
                $env:USERDOMAIN
        }
        New-ERMDetectionResult `
            -Component "Domain" `
            -Data $DomainData
    }
    catch{
        New-ERMDetectionResult `
            -Component "Domain" `
            -Status "Failed" `
            -Data $null `
            -Errors @(
                $_.Exception.Message
            )
    }
}