function Get-ERMCapabilityInformation {
    [CmdletBinding()]
    param()

    try{
        $OS = Get-CimInstance -ClassName Win32_OperatingSystem -ErrorAction Stop
        $Computer = Get-CimInstance -ClassName Win32_ComputerSystem -ErrorAction Stop
        $WinRMService = Get-Service -Name WinRM -ErrorAction SilentlyContinue
        $Identity = [Security.Principal.WindowsIdentity]::GetCurrent()
        $Principal = New-Object Security.Principal.WindowsPrincipal($Identity)
        $CapabilityData = [PSCustomObject]@{
            ComputerName = $env:COMPUTERNAME
            OperatingSystem = $OS.Caption
            Version = $OS.Version
            Architecture = $OS.OSArchitecture
            DomainJoined = $Computer.PartOfDomain
            ComputerRole =
                switch($Computer.DomainRole){
                    0 {"Standalone Workstation"}
                    1 {"Member Workstation"}
                    2 {"Standalone Server"}
                    3 {"Member Server"}
                    4 {"Domain Controller"}
                    5 {"Domain Controller"}
                    default {"Unknown"}
                }
            IsAdministrator = $Principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
            PowerShellVersion = $PSVersionTable.PSVersion.ToString()
            WinRMInstalled = ($null -ne $WinRMService)
            WinRMRunning =
                if($WinRMService){
                    $WinRMService.Status -eq "Running"
                }else{
                    $false
                }
        }
        New-ERMDetectionResult `
            -Component "Capability" `
            -Data $CapabilityData
    }catch{
        New-ERMDetectionResult `
            -Component "Capability" `
            -Status "Failed" `
            -Errors @($_.Exception.Message)
    }
}