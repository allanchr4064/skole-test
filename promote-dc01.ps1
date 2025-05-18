param(
    [string]$domainName,
    [string]$domainAdminUser,
    [securestring]$domainAdminPassword,
    [securestring]$safeModePassword,
    [string]$dc01IPAddress,
    [string]$subnetMask,
    [string]$gateway
)

# Tjek om serveren allerede er en Domain Controller
$domainController = Get-ADDomainController -ErrorAction SilentlyContinue
if ($domainController) {
    Write-Host "Serveren er allerede en Domain Controller."
    exit
}

# Sæt statisk IP-adresse
$interface = Get-NetAdapter | Where-Object { $_.Status -eq "Up" } | Select-Object -First 1

# Fjern tidligere IP-konfigurationer og sæt den nye IP
Remove-NetIPAddress -InterfaceAlias $interface.Name -Confirm:$false -ErrorAction SilentlyContinue
$prefixLength = ($subnetMask -split '\.').Where({$_ -eq "255"}).Count * 8
New-NetIPAddress -InterfaceAlias $interface.Name -IPAddress $dc01IPAddress -PrefixLength $prefixLength -DefaultGateway $gateway
Set-DnsClientServerAddress -InterfaceAlias $interface.Name -ServerAddresses $dc01IPAddress

# Installer nødvendige Windows-features
Install-WindowsFeature AD-Domain-Services -IncludeManagementTools
Install-WindowsFeature DNS -IncludeManagementTools

# Opret en Domain Controller og DNS-server
Write-Host "Promoverer serveren til Domain Controller..."
Install-ADDSForest -DomainName $domainName `
    -DomainNetbiosName "SKOLE" `
    -SafeModeAdministratorPassword $safeModePassword `
    -InstallDNS `
    -Force `
    -NoRebootOnCompletion

# Konfigurationen er afsluttet, genstart serveren for at fuldføre promotionen
Write-Host "Domain Controller promotion er afsluttet. Genstarter serveren for at afslutte processen..."
Restart-Computer -Force