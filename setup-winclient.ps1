param(
    [string]$domainName,
    [string]$domainAdminUsername,
    [securestring]$domainAdminPassword,
    [string]$dnsServer
)

# Konfigurer DNS
$interface = Get-NetAdapter | Where-Object { $_.Status -eq "Up" } | Select-Object -First 1
Set-DnsClientServerAddress -InterfaceAlias $interface.Name -ServerAddresses $dnsServer

# Join domæne
$domainCredential = New-Object System.Management.Automation.PSCredential ($domainAdminUsername, $domainAdminPassword)
Add-Computer -DomainName $domainName -Credential $domainCredential -Force -Restart