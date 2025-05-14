# =================== INPUT: INTERAKTIV OPSÆTNING ===================

$domainName = Read-Host "Indtast domænenavn (f.eks. allan.ninja)"
$domainNetbiosName = Read-Host "Indtast NetBIOS-navn (f.eks. ALLAN)"
$dnsForwarderIp = Read-Host "Indtast DNS-forwarder IP (f.eks. 8.8.8.8)"

$domainAdminUser = Read-Host "Indtast brugernavn til lokal admin-bruger (f.eks. main)"
$domainAdminPassword = Read-Host "Indtast adgangskode til brugeren '$domainAdminUser'" -AsSecureString

$ipAddress = Read-Host "Indtast statisk IP til serveren (f.eks. 192.168.1.10)"
$subnetMask = Read-Host "Indtast subnetmaske (f.eks. 255.255.255.0)"
$prefixLength = ($subnetMask -split '\.').Where({$_ -eq "255"}).Count * 8  # Udregn prefix
$gateway = Read-Host "Indtast gateway IP (f.eks. 192.168.1.1)"
$dnsServer = Read-Host "Indtast DNS-server IP (ofte serverens egen IP, f.eks. 192.168.1.10)"

# =================== 1. OPRET LOKAL BRUGER ===================
if (-not (Get-LocalUser -Name $domainAdminUser -ErrorAction SilentlyContinue)) {
    New-LocalUser -Name $domainAdminUser -Password $domainAdminPassword -FullName "Domæneadministrator" -Description "Lokal adminbruger"
    Write-Host "Bruger '$domainAdminUser' oprettet."
} else {
    Write-Host "Bruger '$domainAdminUser' findes allerede."
}

# =================== 2. TILFØJ BRUGER TIL ADMINISTRATORS ===================
if (-not (Get-LocalGroupMember -Group "Administrators" -Member $domainAdminUser -ErrorAction SilentlyContinue)) {
    Add-LocalGroupMember -Group "Administrators" -Member $domainAdminUser
    Write-Host "Bruger '$domainAdminUser' er tilføjet til Administrators-gruppen."
} else {
    Write-Host "Bruger '$domainAdminUser' er allerede i Administrators-gruppen."
}

# =================== 3. FIND NETVÆRKSINTERFACE ===================
$netInterface = Get-NetAdapter | Where-Object { $_.Status -eq "Up" -and $_.HardwareInterface -eq $true } | Select-Object -First 1

if ($null -eq $netInterface) {
    Write-Host "Fejl: Intet aktivt netværksinterface fundet. Scriptet stoppes."
    exit 1
}

$interfaceAlias = $netInterface.Name
Write-Host "Bruger netværksinterface: $interfaceAlias"

# =================== 4. INSTALLÉR DNS OG AD DS ===================
if (-not (Get-WindowsFeature -Name DNS).Installed) {
    Install-WindowsFeature -Name DNS -IncludeManagementTools
    Write-Host "DNS-server er nu installeret."
} else {
    Write-Host "DNS-server er allerede installeret."
}

if (-not (Get-WindowsFeature -Name AD-Domain-Services).Installed) {
    Install-WindowsFeature -Name AD-Domain-Services -IncludeManagementTools
    Write-Host "Active Directory Domain Services er nu installeret."
} else {
    Write-Host "Active Directory Domain Services er allerede installeret."
}

# =================== 5. DNS FORWARDER ===================
Set-DnsServerForwarder -IPAddress $dnsForwarderIp
Write-Host "DNS-server er konfigureret med forwarder til $dnsForwarderIp."

# =================== 6. OPSÆT STATISK IP ===================
New-NetIPAddress -InterfaceAlias $interfaceAlias -IPAddress $ipAddress -PrefixLength $prefixLength -DefaultGateway $gateway
Set-DnsClientServerAddress -InterfaceAlias $interfaceAlias -ServerAddresses $dnsServer
Write-Host "Statisk IP-adresse $ipAddress er nu konfigureret på $interfaceAlias."

# =================== 7. OPSÆT DOMÆNECONTROLLER ===================
Install-ADDSForest `
    -DomainName $domainName `
    -DomainNetbiosName $domainNetbiosName `
    -SafeModeAdministratorPassword $domainAdminPassword `
    -InstallDNS `
    -Force `
    -NoRebootOnCompletion

Write-Host "DC01 er nu konfigureret som domænecontroller for domænet $domainName."

# =================== 8. GENSTART SERVER ===================
Restart-Computer -Force