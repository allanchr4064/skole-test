param(
    [string]$domainName,
    [string]$domainNetbios,
    [string]$domainAdminUser,
    [SecureString]$domainAdminPassword,
    [SecureString]$safeModePassword,
    [string]$dc01IPAddress,
    [string]$subnetMask,
    [string]$gateway
)

# Installer AD-Domain-Services og DNS
Install-WindowsFeature -Name AD-Domain-Services, DNS

# Opret domænet og promover serveren til Domain Controller
$securePassword = ConvertTo-SecureString $domainAdminPassword -AsPlainText -Force
$secureSafeModePassword = ConvertTo-SecureString $safeModePassword -AsPlainText -Force

$domainAdminCredential = New-Object System.Management.Automation.PSCredential ($domainAdminUser, $securePassword)

# Installer Domain Controller og konfigurer DNS
Install-ADDSDomainController `
    -DomainName $domainName `
    -DomainNetbiosName $domainNetbios `
    -SafeModeAdministratorPassword $secureSafeModePassword `
    -Credential $domainAdminCredential `
    -InstallDns `
    -NoRebootOnCompletion $false `
    -Force

# Konfigurer netværksindstillinger (IP, Subnet, Gateway)
New-NetIPAddress -InterfaceAlias "Ethernet" -IPAddress $dc01IPAddress -PrefixLength 24 -DefaultGateway $gateway
Set-DnsClientServerAddress -InterfaceAlias "Ethernet" -ServerAddresses 127.0.0.1

# Genstart for at fuldføre promotionen
Restart-Computer -Force