# Spørg brugeren om domæneadministratorens brugernavn og adgangskode
$domainAdminUser = Read-Host "Indtast domæneadministratorens brugernavn"
$domainAdminPassword = Read-Host "Indtast domæneadministratorens adgangskode" -AsSecureString
$domainName = Read-Host "Indtast domænenavnet"

# Spørg brugeren om Ubuntu-serverens IP-adresse
$ubuntuIp = Read-Host "Indtast Ubuntu-serverens IP-adresse"

# Konverter adgangskoden fra SecureString til klartekst
$domainAdminPasswordPlain = [System.Net.NetworkCredential]::new("", $domainAdminPassword).Password

# Tilslut Ubuntu-serveren til domænet
# Brug Write-Output i stedet for echo og undgå brug af alias
Write-Output $domainAdminPasswordPlain | sudo realm join --user=$domainAdminUser $domainName
Write-Host "Ubuntu-serveren er nu tilsluttet domænet $domainName."

# Opret DNS-record for Ubuntu-serveren
Add-DnsServerResourceRecordA -Name "ubu" -ZoneName $domainName -IPv4Address $ubuntuIp
Write-Host "DNS-record for Ubuntu-server oprettet med IP-adresse $ubuntuIp."