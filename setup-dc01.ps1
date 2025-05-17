param(
    [string]$ipAddress,
    [string]$subnetMask,
    [string]$gateway,
    [string]$zoneName,
    [string]$domainName,
    [string]$netbios,
    [securestring]$safeModePwd,
    [array]$dnsRecords,
    [string]$sharePath,
    [string]$shareName
)

# Beregn prefix og netværk
$prefixLength = ($subnetMask -split '\.').Where({$_ -eq "255"}).Count * 8
$interface = Get-NetAdapter | Where-Object { $_.Status -eq "Up" } | Select-Object -First 1

# Sæt statisk IP hvis nødvendigt
$currentIP = (Get-NetIPAddress -InterfaceAlias $interface.Name -AddressFamily IPv4 -PrefixOrigin Manual -ErrorAction SilentlyContinue).IPAddress
if ($currentIP -ne $ipAddress) {
    Write-Host "Ændrer IP-konfiguration..."
    Remove-NetIPAddress -InterfaceAlias $interface.Name -Confirm:$false -ErrorAction SilentlyContinue
    New-NetIPAddress -InterfaceAlias $interface.Name -IPAddress $ipAddress -PrefixLength $prefixLength -DefaultGateway $gateway
    Set-DnsClientServerAddress -InterfaceAlias $interface.Name -ServerAddresses $ipAddress
} else {
    Write-Host "IP-adresse $ipAddress er allerede konfigureret."
}

# Installer DNS og AD DS
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
        } else {
            Write-Host "DNS-posten $($record.Name) eksisterer allerede."
        }
    }
}

# Opret domæne hvis ikke allerede domain controller
if (-not (Get-ADDomainController -ErrorAction SilentlyContinue)) {
    Install-ADDSForest -DomainName $domainName -DomainNetbiosName $netbios -SafeModeAdministratorPassword $safeModePwd -InstallDNS -Force -NoRebootOnCompletion
} else {
    Write-Host "Maskinen er allerede en domænecontroller."
}

# Del netværksmappe
if (!(Test-Path $sharePath)) { New-Item -Path $sharePath -ItemType Directory -Force | Out-Null }

if (-not (Get-SmbShare -Name $shareName -ErrorAction SilentlyContinue)) {
    New-SmbShare -Name $shareName -Path $sharePath -FullAccess "Domain Admins"
} else {
    Write-Host "Netværksmappen $shareName er allerede delt."
}

Write-Host "✅ Setup fuldført. Genstart sker via Ansible."