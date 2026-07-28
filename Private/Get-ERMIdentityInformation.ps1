function Get-ERMIdentityInformation {
    [CmdletBinding()]
    param()

    $CurrentIdentity = [Security.Principal.WindowsIdentity]::GetCurrent()
    $Principal = New-Object Security.Principal.WindowsPrincipal($CurrentIdentity)
    $ComputerSystem = Get-CimInstance -ClassName Win32_ComputerSystem
    $IdentityData = [PSCustomObject]@{
        Execution = [PSCustomObject]@{
            Username = $CurrentIdentity.Name
            SID = $CurrentIdentity.User.Value
            IsAdministrator = $Principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
            AuthenticationType = $CurrentIdentity.AuthenticationType
        }
        Interactive = [PSCustomObject]@{
            Username = $ComputerSystem.UserName
            SessionType =
                if($ComputerSystem.UserName){
                    "Console"
                }else{
                    "None"
                }
        }
        ComputerName = $env:COMPUTERNAME
    }

    New-ERMDetectionResult `
        -Component "Identity" `
        -Data $IdentityData
}