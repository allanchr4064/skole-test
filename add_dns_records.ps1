# DNS-records tilføjelse

$zoneName = "allan.ninja"
$dnsRecords = @(
    @{ Name = "dc01"; IPAddress = "192.168.1.10" },
    @{ Name = "ubu"; IPAddress = "192.168.1.20" },
    @{ Name = "win"; IPAddress = "192.168.1.30" }
)

# Opret DNS-records for hver maskine
foreach ($record in $dnsRecords) {
    $name = $record.Name
    $ipAddress = $record.IPAddress
    Add-DnsServerResourceRecordA -Name $name -ZoneName $zoneName -IPv4Address $ipAddress
    Write-Host "DNS-record for $name oprettet med IP-adresse $ipAddress."
}

# Bekræft DNS-records
$dnsRecords | ForEach-Object {
    Get-DnsServerResourceRecord -Name $_.Name -ZoneName $zoneName
}