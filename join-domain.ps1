param(
    [string]$domainName,
    [string]$domainAdminUser,
    [securestring]$domainAdminPassword,
    [string]$dcIPAddress
)

# Find netværksinterface
$interface = Get-NetAdapter | Where-Object { $_.Status -eq "Up" } | Select-Object -First 1

# Sæt DNS til DC01
Set-DnsClientServerAddress -InterfaceAlias $interface.Name -ServerAddresses $dcIPAddress

# Join domænet
$cred = New-Object System.Management.Automation.PSCredential("$domainName\$domainAdminUser", $domainAdminPassword)
Add-Computer -DomainName $domainName -Credential $cred -Force -Restart