# DNS, IP og domæneopsætning

$domainName = "allan.ninja"
$domainNetbiosName = "ALLAN"
$dnsForwarderIp = "8.8.8.8"
$domainAdminUser = "main"
$domainAdminPassword = "Oldboys1234!" # Erstat med et mere sikkert password i en produktionsmiljø
$ipAddress = "192.168.1.10"  # IP for DC01 (tilpas efter netværk)
$subnetMask = "255.255.255.0"
$gateway = "192.168.1.1"
$dnsServer = "192.168.1.10"  # DNS-serveren er DC01

# 1. Installér DNS-server og AD DS på DC01
if (-not (Get-WindowsFeature -Name DNS).Installed) {
    Install-WindowsFeature -Name DNS -IncludeManagementTools
    Write-Host "DNS-server er nu installeret."
} else {
    Write-Host "DNS-server er allerede installeret."
}

if (-not (Get-WindowsFeature -Name AD-Domain-Services).Installed) {
    Install-WindowsFeature -Name AD-Domain-Services -IncludeManagementTools
    Write-Host "Active Directory Domain Services er nu installeret."
} else {
    Write-Host "Active Directory Domain Services er allerede installeret."
}

# 2. Konfigurér DNS-server med forwarder
Set-DnsServerForwarder -IPAddress $dnsForwarderIp
Write-Host "DNS-server er konfigureret med forwarder til $dnsForwarderIp."

# 3. Opsæt statisk IP-adresse på DC01
New-NetIPAddress -InterfaceAlias "Ethernet" -IPAddress $ipAddress -PrefixLength 24 -DefaultGateway $gateway
Set-DnsClientServerAddress -InterfaceAlias "Ethernet" -ServerAddresses $dnsServer
Write-Host "Statisk IP-adresse $ipAddress er nu konfigureret på DC01."

# 4. Installér og konfigurer DC01 som domænecontroller
Install-ADDSForest -DomainName $domainName -DomainNetbiosName $domainNetbiosName -SafeModeAdministratorPassword (ConvertTo-SecureString $domainAdminPassword -AsPlainText -Force) -InstallDNS -Force -NoRebootOnCompletion
Write-Host "DC01 er nu konfigureret som domænecontroller for domænet $domainName."

# 5. Genstart serveren for at afslutte opsætningen af domænet
Restart-Computer -Force