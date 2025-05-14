# Spørg om input fra brugeren

$domainAdminUser = Read-Host -Prompt "Indtast domæneadministrator brugernavn"
$domainAdminPassword = Read-Host -Prompt "Indtast domæneadministrator adgangskode" -AsSecureString
$domainName = Read-Host -Prompt "Indtast domænenavnet"
$winIp = Read-Host -Prompt "Indtast IP-adressen for Windows-klienten"

# Opret PSCredential objekt for at tilslutte til domænet
$credential = New-Object System.Management.Automation.PSCredential("$domainName\$domainAdminUser", $domainAdminPassword)

# Tilslut Windows-klient til domænet
Add-Computer -DomainName $domainName -Credential $credential -Restart
Write-Host "Windows-klienten er nu tilsluttet domænet $domainName."

# Opret DNS-record for Windows-klient
Add-DnsServerResourceRecordA -Name "win" -ZoneName $domainName -IPv4Address $winIp
Write-Host "DNS-record for Windows-klient oprettet med IP-adresse $winIp."