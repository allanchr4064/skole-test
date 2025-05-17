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

# Sæt en statisk IP, hvis ikke allerede sat
$existingIP = Get-NetIPAddress -InterfaceAlias $interface.Name -ErrorAction SilentlyContinue
if ($null -eq $existingIP) {
    New-NetIPAddress -InterfaceAlias $interface.Name -IPAddress $ipAddress -PrefixLength $prefixLength -DefaultGateway $gateway
} else {
    Write-Host "IP-adresse $ipAddress er allerede konfigureret."
}

# Indstil DNS-serveradresse
Set-DnsClientServerAddress -InterfaceAlias $interface.Name -ServerAddresses $ipAddress

# Installer DNS og AD DS
Install-WindowsFeature DNS -IncludeManagementTools
Install-WindowsFeature AD-Domain-Services -IncludeManagementTools

# Opret DNS-zone og A-records
if ($zoneName) {
    if (-not (Get-DnsServerZone -Name $zoneName -ErrorAction SilentlyContinue)) {
        Add-DnsServerPrimaryZone -Name $zoneName -ZoneFile "$zoneName.dns"
    }

    foreach ($record in $dnsRecords) {
        $existingRecord = Get-DnsServerResourceRecord -ZoneName $zoneName | Where-Object { $_.HostName -eq $record.Name }
        if ($null -eq $existingRecord) {
            Add-DnsServerResourceRecordA -Name $record.Name -ZoneName $zoneName -IPv4Address $record.IP
        } else {
            Write-Host "DNS-posten $($record.Name) eksisterer allerede."
        }
    }
}

# Skift fra Workgroup til Domain og promover til Domain Controller
$computerSystem = Get-WmiObject -Class Win32_ComputerSystem
if ($computerSystem.Domain -ne $domainName) {
    Write-Host "Maskinen er ikke medlem af domænet $domainName. Tilføjer nu til domænet..."
    Add-Computer -DomainName $domainName -Credential (New-Object System.Management.Automation.PSCredential("Administrator", $safeModePwd)) -Force -Restart
    Write-Host "Maskinen er nu medlem af domænet $domainName."
}

# Opret domæne, hvis maskinen ikke er en domænecontroller allerede
$existingDC = Get-WmiObject -Class Win32_ComputerSystem | Select-Object -ExpandProperty DomainRole
if ($existingDC -ne 5) {
    try {
        Install-ADDSForest -DomainName $domainName -DomainNetbiosName $netbios -SafeModeAdministratorPassword $safeModePwd -InstallDNS -Force -NoRebootOnCompletion
    } catch {
        Write-Host "Fejl ved oprettelse af domæne. Tjek eventuelle eksisterende domæneindstillinger."
    }
} else {
    Write-Host "Maskinen er allerede en domænecontroller."
}

# Del netværksmappe
if (!(Test-Path $sharePath)) {
    New-Item -Path $sharePath -ItemType Directory -Force | Out-Null
}
$existingShare = Get-SmbShare | Where-Object { $_.Name -eq $shareName }
if ($null -eq $existingShare) {
    New-SmbShare -Name $shareName -Path $sharePath -FullAccess "Domain Admins"
} else {
    Write-Host "Netværksmappen $shareName er allerede delt."
}

Write-Host "✅ Setup fuldført. Genstarter maskinen for at afslutte installationen."
Restart-Computer -Force