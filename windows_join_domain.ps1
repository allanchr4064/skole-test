# Windows til domænet

$domainAdminUser = "main"
$domainAdminPassword = "Oldboys1234!"
$domainName = "allan.ninja"

# Opret PSCredential objekt for at tilslutte til domænet
$credential = New-Object System.Management.Automation.PSCredential("$domainName\$domainAdminUser", (ConvertTo-SecureString $domainAdminPassword -AsPlainText -Force))

# Tilslut Windows-klient til domænet
Add-Computer -DomainName $domainName -Credential $credential -Restart
Write-Host "Windows-klienten er nu tilsluttet domænet $domainName."

# Opret DNS-record for Windows-klient
$winIp = "192.168.1.30"
Add-DnsServerResourceRecordA -Name "win" -ZoneName $domainName -IPv4Address $winIp
Write-Host "DNS-record for Windows-klient oprettet med IP-adresse $winIp."