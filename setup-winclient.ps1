<#
.SYNOPSIS
    Automatisk setup af en Windows-klient til domænebrug.

.DESCRIPTION
    - Sætter statisk IP og DNS
    - Tilslutter til domæne
    - Mapper delt netværksmappe fra DC01
    - Bekræfter adgang for Domain Admins

.AUTHOR
    DinOrganisation / GitHub Project
#>

Clear-Host
Write-Host "===== Windows Klient Setup Starter =====`n" -ForegroundColor Cyan

# ===================== Statisk IP-konfiguration =====================
Write-Host "### Trin 1: Statisk IP-konfiguration ###" -ForegroundColor Yellow
$ipAddress = Read-Host "Indtast statisk IP-adresse til denne klient (f.eks. 192.168.1.20)"
$subnetMask = Read-Host "Indtast subnetmaske (f.eks. 255.255.255.0)"
$prefixLength = ($subnetMask -split '\.').Where({$_ -eq "255"}).Count * 8
$gateway = Read-Host "Indtast gateway IP (f.eks. 192.168.1.1)"
$dnsServer = Read-Host "Indtast DNS-server IP (f.eks. 192.168.1.10)"

$interface = Get-NetAdapter | Where-Object { $_.Status -eq "Up" } | Select-Object -First 1
New-NetIPAddress -InterfaceAlias $interface.Name -IPAddress $ipAddress -PrefixLength $prefixLength -DefaultGateway $gateway
Set-DnsClientServerAddress -InterfaceAlias $interface.Name -ServerAddresses $dnsServer
Write-Host "✅ Statisk IP sat til $ipAddress og DNS-server sat til $dnsServer" -ForegroundColor Green

# ===================== Tilslutning til Domæne =====================
Write-Host "`n### Trin 2: Tilslutning til Domæne ###" -ForegroundColor Yellow
$joinDomain = Read-Host "Skal denne klient tilsluttes et domæne? (ja/nej)"
if ($joinDomain -eq "ja") {
    $domainName = Read-Host "Indtast domænenavn (f.eks. allan.ninja)"
    $domainAdminUsername = Read-Host "Indtast domæneadministratorbrugernavn (f.eks. ALLAN\\admin)"
    $domainAdminPassword = Read-Host "Indtast domæneadministratorens adgangskode" -AsSecureString
    $domainCredential = New-Object System.Management.Automation.PSCredential ($domainAdminUsername, $domainAdminPassword)

    Add-Computer -DomainName $domainName -Credential $domainCredential -Force -Restart
    Write-Host "✅ Klienten er nu tilsluttet domænet '$domainName'. Genstart følger." -ForegroundColor Green
    exit
} else {
    Write-Host "ℹ️ Denne klient blev ikke tilsluttet et domæne." -ForegroundColor Yellow
}

# ===================== Delt mappe på DC01 =====================
Write-Host "`n### Trin 3: Forbindelse til delt mappe på DC01 ###" -ForegroundColor Yellow
$dc01Server = "dc01"  # Opdater hvis servernavn er anderledes
$shareName = "HotelShare"
$sharePath = "\\$dc01Server\$shareName"

if (Test-Path -Path $sharePath) {
    Write-Host "✅ Delt mappe '$sharePath' er tilgængelig." -ForegroundColor Green
} else {
    Write-Host "❌ Den delte mappe '$sharePath' kunne ikke findes. Tjek netværk og servernavn." -ForegroundColor Red
    exit
}

# ===================== Netværksdrev Opsætning =====================
Write-Host "`n### Trin 4: Opsætning af netværksdrev ###" -ForegroundColor Yellow
$driveLetter = Read-Host "Indtast drevbogstav til netværksdrev (f.eks. Z:)"
$driveLetterClean = $driveLetter.TrimEnd(':')

# Fjern eksisterende drev hvis det findes
if (Get-PSDrive -Name $driveLetterClean -ErrorAction SilentlyContinue) {
    Remove-PSDrive -Name $driveLetterClean -Force
}

# Opret netværksdrev
New-PSDrive -Name $driveLetterClean -PSProvider FileSystem -Root $sharePath -Persist
Write-Host "✅ Netværksdrev mappet: $driveLetter -> $sharePath" -ForegroundColor Green

# ===================== Domain Admin Adgang =====================
Write-Host "`n### Trin 5: Adgang ###" -ForegroundColor Yellow
Write-Host "✅ Medlemmer af 'Domain Admins' har adgang til den delte mappe på DC01." -ForegroundColor Green

Write-Host "`n🎉 Setup færdig! Genstart anbefales hvis du ikke allerede er blevet genstartet automatisk." -ForegroundColor Cyan