param(
    [string]$ipAddress,
    [string]$subnetMask,
    [string]$gateway,
    [string]$zoneName,
    [string]$domainName,
    [string]$netbios,
    [securestring]$safeModePwd,
    [array]$dnsRecords,
    [array]$users,
    [string]$sharePath,
    [string]$shareName
)

# Beregn prefix og netværk
$prefixLength = ($subnetMask -split '\.').Where({$_ -eq "255"}).Count * 8
$interface = Get-NetAdapter | Where-Object { $_.Status -eq "Up" } | Select-Object -First 1
New-NetIPAddress -InterfaceAlias $interface.Name -IPAddress $ipAddress -PrefixLength $prefixLength -DefaultGateway $gateway
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
        Add-DnsServerResourceRecordA -Name $record.Name -ZoneName $zoneName -IPv4Address $record.IP
    }
}

# Opret domæne
Install-ADDSForest -DomainName $domainName -DomainNetbiosName $netbios -SafeModeAdministratorPassword $safeModePwd -InstallDNS -Force -NoRebootOnCompletion

# Del netværksmappe
if (!(Test-Path $sharePath)) { New-Item -Path $sharePath -ItemType Directory -Force | Out-Null }
New-SmbShare -Name $shareName -Path $sharePath -FullAccess "Domain Admins"

# Opret brugere
foreach ($user in $users) {
    $upn = "$($user.Name)@$domainName"

    New-ADUser -Name $user.Name -SamAccountName $user.Name -UserPrincipalName $upn `
               -Path "CN=Users,DC=$($domainName -replace '\.',',DC=')" `
               -AccountPassword $user.Password -Enabled $true

    if ($user.IsAdmin) {
        Add-ADGroupMember -Identity "Domain Admins" -Members $user.Name
    }
}

Write-Host "✅ Setup fuldført. Genstart manuelt for at færdiggøre domæneinstallationen."