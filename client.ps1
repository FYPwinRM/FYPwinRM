 # Enable WinRM
    Set-NetConnectionProfile -InterfaceAlias "Ethernet0" -NetworkCategory Private
    # Enables the WinRM service and sets up the HTTP listener
    Enable-PSRemoting -Force

    # Opens port 5985 for all profiles
    $firewallParams = @{
        Action      = 'Allow'
        Description = 'Inbound rule for Windows Remote Management via WS-Management. [TCP 5985]'
        Direction   = 'Inbound'
        DisplayName = 'Windows Remote Management (HTTP-In)'
        LocalPort   = 5985
        Profile     = 'Any'
        Protocol    = 'TCP'
    }
    New-NetFirewallRule @firewallParams

    # Allows local user accounts to be used with WinRM
    # This can be ignored if using domain accounts
    $tokenFilterParams = @{
        Path         = 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System'
        Name         = 'LocalAccountTokenFilterPolicy'
        Value        = 1
        PropertyType = 'DWORD'
        Force        = $true
    }
    New-ItemProperty @tokenFilterParams

    # Create self-signed certificate
    $certParams = @{
        CertStoreLocation = 'Cert:\LocalMachine\My'
        DnsName           = $env:COMPUTERNAME
        NotAfter          = (Get-Date).AddYears(1)
        Provider          = 'Microsoft Software Key Storage Provider'
        Subject           = "CN=$env:COMPUTERNAME"
    }
    $cert = New-SelfSignedCertificate @certParams

    # Create HTTPS listener
    $httpsParams = @{
        ResourceURI = 'winrm/config/listener'
        SelectorSet = @{
            Transport = "HTTPS"
            Address   = "*"
        }
        ValueSet    = @{
            CertificateThumbprint = $cert.Thumbprint
            Enabled               = $true
        }
    }
    New-WSManInstance @httpsParams

    # Opens port 5986 for all profiles
    $firewallParams = @{
        Action      = 'Allow'
        Description = 'Inbound rule for Windows Remote Management via WS-Management. [TCP 5986]'
        Direction   = 'Inbound'
        DisplayName = 'Windows Remote Management (HTTPS-In)'
        LocalPort   = 5986
        Profile     = 'Any'
        Protocol    = 'TCP'
    }
    New-NetFirewallRule @firewallParams

    # Disable Windows Firewall
    # Turn off the firewall for the Private network profile
    Set-NetFirewallProfile -Profile Private -Enabled False

    # Turn off the firewall for the Public network profile
    Set-NetFirewallProfile -Profile Public -Enabled False

    # Set the Windows Update services to disabled (only for client OS)
    Set-Service -Name wuauserv -StartupType Disabled
    Set-Service -Name bits -StartupType Disabled
    Set-Service -Name dosvc -StartupType Disabled
    Set-Service -Name TrustedInstaller -StartupType Disabled
    Set-Service -Name UsoSvc -StartupType Disabled