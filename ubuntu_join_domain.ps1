# Ubuntu til domænet

$domainAdminUser = "main"
$domainAdminPassword = "Oldboys1234!"
$domainName = "allan.ninja"

# Ubuntu tilslutning til domænet
echo $domainAdminPassword | sudo realm join --user=$domainAdminUser $domainName
Write-Host "Ubuntu-serveren er nu tilsluttet domænet $domainName."

# Opret DNS-record for Ubuntu
$ubuntuIp = "192.168.1.20"
Add-DnsServerResourceRecordA -Name "ubu" -ZoneName $domainName -IPv4Address $ubuntuIp
Write-Host "DNS-record for Ubuntu-server oprettet med IP-adresse $ubuntuIp."