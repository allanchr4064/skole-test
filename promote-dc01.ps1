param(
    [string]$domainName = "skoletræt.ninja",
    [string]$domainAdminUser = "main",
    [securestring]$domainAdminPassword,
    [string]$dcIPAddress = "192.168.1.111"
)

# Find aktivt netværkskort
$interface = Get-NetAdapter | Where-Object { $_.Status -eq "Up" } | Select-Object -First 1
if (-not $interface) {
    Write-Error "Intet aktivt netværkskort fundet"
    exit 1
}

# Sæt DNS til kun din Domain Controller
Set-DnsClientServerAddress -InterfaceAlias $interface.Name -ServerAddresses @($dcIPAddress)

# Vent lidt så DNS når at virke
Start-Sleep -Seconds 5

# Hent computerens navn og IP
$hostname = $env:COMPUTERNAME
$ip = (Get-NetIPAddress -AddressFamily IPv4 -InterfaceAlias $interface.Name | Where-Object { $_.PrefixOrigin -ne "WellKnown" }).IPAddress

# Opret domænecredentials
$cred = New-Object System.Management.Automation.PSCredential ("$domainName\$domainAdminUser", $domainAdminPassword)

# Tilføj A-record til DNS på DC
Invoke-Command -ComputerName $dcIPAddress -Credential $cred -ScriptBlock {
    param($hostname, $ip, $zone)
    try {
        Add-DnsServerResourceRecordA -Name $hostname -ZoneName $zone -IPv4Address $ip -AllowUpdateAny -TimeToLive 01:00:00 -ErrorAction Stop
        "✅ A-record tilføjet: $hostname -> $ip"
    } catch {
        "⚠️ Fejl ved tilføjelse af A-record: $_"
    }
} -ArgumentList $hostname, $ip, $domainName

# Join domænet og genstart
try {
    Add-Computer -DomainName $domainName -Credential $cred -Force -Restart
} catch {
    $_ | Out-File -FilePath C:\Temp\domain-join-error.txt -Encoding utf8
    Write-Error "❌ Fejl under domain join: $_"
    exit 1
}