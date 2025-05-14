<#
.SYNOPSIS
    Automatisk setup af en Windows Server 2019 som Domain Controller med DNS og fildeling.

.DESCRIPTION
    - Sætter statisk IP
    - Installerer og konfigurerer DNS og AD DS
    - Opsætter domæne eller tilføjer til eksisterende
    - Opretter DNS A-records
    - Opretter delt mappe for administratorer
    - Opretter brugere og tilføjer til Domain Admins

.AUTHOR
    DinOrganisation / GitHub Project
#>

Clear-Host
Write-Host "===== DC01 Setup Starter =====`n" -ForegroundColor Cyan

# ===================== Statisk IP-konfiguration =====================
$ipAddress = Read-Host "Indtast statisk IP-adresse til denne server (f.eks. 192.168.1.10)"
$subnetMask = Read-Host "Indtast subnetmaske (f.eks. 255.255.255.0)"
$prefixLength = ($subnetMask -split '\.').Where({$_ -eq "255"}).Count * 8
$gateway = Read-Host "Indtast gateway IP (f.eks. 192.168.1.1)"
$dnsServer = $ipAddress

$interface = Get-NetAdapter | Where-Object { $_.Status -eq "Up" } | Select-Object -First 1
New-NetIPAddress -InterfaceAlias $interface.Name -IPAddress $ipAddress -PrefixLength $prefixLength -DefaultGateway $gateway
Set-DnsClientServerAddress -InterfaceAlias $interface.Name -ServerAddresses $dnsServer
Write-Host "✅ Statisk IP sat til $ipAddress" -ForegroundColor Green

# ===================== Installation af DNS og AD DS =====================
if (-not (Get-WindowsFeature DNS).Installed) {
    Install-WindowsFeature DNS -IncludeManagementTools
    Write-Host "✅ DNS Rolle installeret."
}
if (-not (Get-WindowsFeature AD-Domain-Services).Installed) {
    Install-WindowsFeature AD-Domain-Services -IncludeManagementTools
    Write-Host "✅ Active Directory Domain Services installeret."
}

# ===================== DNS Konfiguration =====================
$useDns = Read-Host "Skal denne server fungere som DNS for andre enheder? (ja/nej)"
if ($useDns -eq "ja") {
    $zoneName = Read-Host "Indtast DNS-zonenavn (f.eks. allan.ninja)"
    if (-not (Get-DnsServerZone -Name $zoneName -ErrorAction SilentlyContinue)) {
        Add-DnsServerPrimaryZone -Name $zoneName -ZoneFile "$zoneName.dns"
        Write-Host "✅ DNS Zone '$zoneName' oprettet."
    }

    $aCount = Read-Host "Hvor mange A-records vil du oprette?"
    for ($i = 1; $i -le [int]$aCount; $i++) {
        $aName = Read-Host "[$i/$aCount] Indtast hostname (f.eks. win01)"
        $aIP = Read-Host "Indtast IP for '$aName'"
        Add-DnsServerResourceRecordA -Name $aName -ZoneName $zoneName -IPv4Address $aIP
        Write-Host "✅ A-record '$aName.$zoneName' -> $aIP oprettet."
    }
}

# ===================== Domæne Setup =====================
$createDomain = Read-Host "Skal denne server oprette et nyt domæne? (ja/nej)"
if ($createDomain -eq "ja") {
    $domainName = Read-Host "Indtast domænenavn (f.eks. allan.ninja)"
    $netbios = Read-Host "Indtast NetBIOS-navn (f.eks. ALLAN)"
    $safeModePwd = Read-Host "Indtast DSRM password (bliver ikke vist)" -AsSecureString

    Install-ADDSForest -DomainName $domainName -DomainNetbiosName $netbios -SafeModeAdministratorPassword $safeModePwd -InstallDNS -Force -NoRebootOnCompletion

    Write-Host "✅ Domæne '$domainName' oprettet med denne maskine som Domain Controller." -ForegroundColor Green
} else {
    Write-Host "ℹ️ Oprettelse af domæne blev sprunget over."
    $domainName = (Get-ADDomain).DNSRoot  # Hent det eksisterende domænenavn
}

# ===================== Delt mappe Setup =====================
$shareConfirm = Read-Host "Vil du oprette en delt netværksmappe til administratorer? (ja/nej)"
if ($shareConfirm -eq "ja") {
    $sharePath = Read-Host "Indtast sti til mappen der skal deles (f.eks. C:\HotelShare)"
    $shareName = Read-Host "Indtast navn på det delte drev (f.eks. HotelShare)"

    # Kontrollér om mappen findes, hvis ikke, opret den
    if (-not (Test-Path $sharePath)) {
        New-Item -Path $sharePath -ItemType Directory -Force | Out-Null
    }

    # Kontrollér om den delte mappe allerede findes
    $existingShare = Get-SmbShare | Where-Object { $_.Name -eq $shareName }
    if ($existingShare) {
        Write-Host "ℹ️ Delt mappe '$shareName' findes allerede."
    } else {
        New-SmbShare -Name $shareName -Path $sharePath -FullAccess "Domain Admins"
        Write-Host "✅ Netværksdrev '$shareName' delt fra '$sharePath' til Domain Admins."
    }
}

# ===================== Oprettelse af brugere =====================
$addUsers = Read-Host "Vil du oprette brugere nu? (ja/nej)"
if ($addUsers -eq "ja") {
    $userCount = Read-Host "Hvor mange brugere vil du oprette?"

    for ($u = 1; $u -le [int]$userCount; $u++) {
        $username = Read-Host "[$u/$userCount] Brugernavn"
        $password = Read-Host "Adgangskode til '$username'" -AsSecureString
        $upn = "$username@$domainName"

        New-ADUser -Name $username -SamAccountName $username -UserPrincipalName $upn `
                   -Path "CN=Users,DC=$($domainName -replace '\.',',DC=')" `
                   -AccountPassword $password -Enabled $true

        Write-Host "✅ Bruger '$username' oprettet."

        $addToAdmins = Read-Host "Tilføj '$username' til Domain Admins? (ja/nej)"
        if ($addToAdmins -eq "ja") {
            Add-ADGroupMember -Identity "Domain Admins" -Members $username
            Write-Host "🔐 '$username' tilføjet til Domain Admins."
        }
    }
}

Write-Host "`n🎉 Færdig! Husk at genstarte serveren manuelt for at fuldføre domæne-opsætningen." -ForegroundColor Cyan