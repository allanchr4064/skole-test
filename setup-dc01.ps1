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

# Sæt IP og DNS
$currentIP = (Get-NetIPAddress -InterfaceAlias $interface.Name -AddressFamily IPv4 -PrefixOrigin Manual -ErrorAction SilentlyContinue).IPAddress
if ($currentIP -ne $ipAddress) {
    Write-Host "Sætter IP-konfiguration..."
    Remove-NetIPAddress -InterfaceAlias $interface.Name -Confirm:$false -ErrorAction SilentlyContinue
    New-NetIPAddress -InterfaceAlias $interface.Name -IPAddress $ipAddress -PrefixLength $prefixLength -DefaultGateway $gateway
    Set-DnsClientServerAddress -InterfaceAlias $interface.Name -ServerAddresses $ipAddress
} else {
    Write-Host "IP-adresse $ipAddress er allerede sat."
}

# Installer roller
Install-WindowsFeature DNS -IncludeManagementTools
Install-WindowsFeature AD-Domain-Services -IncludeManagementTools

# Tilføj DNS-forwarder
if (-not (Get-DnsServerForwarder -ErrorAction SilentlyContinue)) {
    Add-DnsServerForwarder -IPAddress 8.8.8.8
    Write-Host "✅ DNS-forwarder tilføjet (8.8.8.8)"
}

# Opret DNS-zone og A-records
if ($zoneName) {
    if (-not (Get-DnsServerZone -Name $zoneName -ErrorAction SilentlyContinue)) {
        Add-DnsServerPrimaryZone -Name $zoneName -ZoneFile "$zoneName.dns"
    }

    foreach ($record in $dnsRecords) {
        if (-not (Get-DnsServerResourceRecord -ZoneName $zoneName -Name $record.Name -ErrorAction SilentlyContinue)) {
            Add-DnsServerResourceRecordA -Name $record.Name -ZoneName $zoneName -IPv4Address $record.IP
        } else {
            Write-Host "DNS-post $($record.Name) findes allerede."
        }
    }
}

# Promover til Domain Controller
if (-not (Get-ADDomainController -ErrorAction SilentlyContinue)) {
    Install-ADDSForest -DomainName $domainName -DomainNetbiosName $netbios -SafeModeAdministratorPassword $safeModePwd -InstallDNS -Force -NoRebootOnCompletion
} else {
    Write-Host "Allerede Domain Controller."
}

Write-Host "`n✅ Setup fuldført. Genstart sker via Ansible."