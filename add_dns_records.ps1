# =================== INTERAKTIV DNS A-RECORD OPSÆTNING ===================

# Indtast zonenavn (typisk dit domæne)
$zoneName = Read-Host "Indtast DNS-zonenavn (f.eks. allan.ninja)"

# Tjek om zonen findes på DNS-serveren
if (-not (Get-DnsServerZone -Name $zoneName -ErrorAction SilentlyContinue)) {
    Write-Host "❌ Zonen '$zoneName' findes ikke. Sørg for at domænet og DNS er oprettet." -ForegroundColor Red
    exit 1
}

# Spørg hvor mange DNS-records der ønskes oprettet
[int]$antalRecords = Read-Host "Hvor mange A-records vil du oprette?"

# Saml oplysninger om alle ønskede DNS-records
$dnsRecords = @()

for ($i = 1; $i -le $antalRecords; $i++) {
    $name = Read-Host "[$i/$antalRecords] Indtast navn for maskine (f.eks. dc01)"

    # Valider IP-adresse
    do {
        $ip = Read-Host "[$i/$antalRecords] Indtast IP-adresse til '$name' (f.eks. 192.168.1.10)"
        $isValidIP = [System.Net.IPAddress]::TryParse($ip, [ref]$null)
        if (-not $isValidIP) {
            Write-Host "❌ Ugyldig IP-adresse. Prøv igen." -ForegroundColor Red
        }
    } until ($isValidIP)

    $dnsRecords += [PSCustomObject]@{
        Name = $name
        IPAddress = $ip
    }
}

# Opret DNS A-records, hvis de ikke allerede findes
foreach ($record in $dnsRecords) {
    $name = $record.Name
    $ipAddress = $record.IPAddress

    $existing = Get-DnsServerResourceRecord -ZoneName $zoneName -Name $name -ErrorAction SilentlyContinue

    if ($null -eq $existing) {
        try {
            Add-DnsServerResourceRecordA -Name $name -ZoneName $zoneName -IPv4Address $ipAddress -ErrorAction Stop
            Write-Host "✅ DNS-record for '$name' oprettet med IP $ipAddress."
        } catch {
            Write-Host "❌ Fejl ved oprettelse af DNS-record for '$name': $_" -ForegroundColor Red
        }
    } else {
        Write-Host "⚠️ DNS-record for '$name' findes allerede – springer over." -ForegroundColor Yellow
    }
}

# Vis bekræftelse af alle records
Write-Host "`n📄 Bekræftelse:"
$dnsRecords | ForEach-Object {
    Get-DnsServerResourceRecord -ZoneName $zoneName -Name $_.Name
}