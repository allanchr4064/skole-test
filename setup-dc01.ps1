param(
    [string]$ipAddress,
    [string]$subnetMask,
    [string]$gateway,
    [string]$zoneName,
    [string]$domainName,
    [string]$netbios,
    [securestring]$safeModePwd,
    [array]$dnsRecords
)

# Beregn prefix
$prefixLength = ($subnetMask -split '\.').Where({$_ -eq "255"}).Count * 8
$interface = Get-NetAdapter | Where-Object { $_.Status -eq "Up" } | Select-Object -First 1

# Sæt statisk IP
$currentIP = (Get-NetIPAddress -InterfaceAlias $interface.Name -AddressFamily IPv4 -PrefixOrigin Manual -ErrorAction SilentlyContinue).IPAddress
if ($currentIP -ne $ipAddress) {
    Remove-NetIPAddress -InterfaceAlias $interface.Name -Confirm:$false -ErrorAction SilentlyContinue
    New-NetIPAddress -InterfaceAlias $interface.Name -IPAddress $ipAddress -PrefixLength $prefixLength -DefaultGateway $gateway
    Set-DnsClientServerAddress -InterfaceAlias $interface.Name -ServerAddresses $ipAddress
}

# Installer roller
Install-WindowsFeature DNS -IncludeManagementTools
Install-WindowsFeature AD-Domain-Services -IncludeManagementTools

# Opret DNS-zone og A-records
if ($zoneName) {
    if (-not (Get-DnsServerZone -Name $zoneName -ErrorAction SilentlyContinue)) {
        Add-DnsServerPrimaryZone -Name $zoneName -ZoneFile "$zoneName.dns"
    }

    foreach ($record in $dnsRecords) {
        if (-not (Get-DnsServerResourceRecord -ZoneName $zoneName -Name $record.Name -ErrorAction SilentlyContinue)) {
            Add-DnsServerResourceRecordA -Name $record.Name -ZoneName $zoneName -IPv4Address $record.IP
        }
    }
}

# Promote til DC (kør promotionen)
if (-not (Get-ADDomainController -ErrorAction SilentlyContinue)) {
    Write-Host "Promoverer til Domain Controller..."
    Install-ADDSForest -DomainName $domainName -DomainNetbiosName $netbios -SafeModeAdministratorPassword $safeModePwd -InstallDNS -Force -NoRebootOnCompletion -Verbose

    # Hvis du ønsker at sikre, at serveren genstarter automatisk efter promotionen, kan du tilføje en kommando her:
    Write-Host "Domain controller promotion er afsluttet. Genstarter serveren..."
    Restart-Computer -Force
} else {
    Write-Host "Denne server er allerede en Domain Controller."
}
