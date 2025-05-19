param(
    [string]$domainName = "skoletræt.ninja",
    [string]$domainNetbios = "SKOLE",
    [string]$domainAdminUser = "main",
    [securestring]$domainAdminPassword,
    [securestring]$safeModePassword,
    [string]$dc01IPAddress = "192.168.1.111",
    [string]$subnetMask = "255.255.255.0",
    [string]$gateway = "192.168.1.1"
)

Set-ExecutionPolicy Bypass -Scope Process -Force

# Find aktivt netværkskort
$interface = Get-NetAdapter | Where-Object { $_.Status -eq "Up" } | Select-Object -First 1
if (-not $interface) {
    Write-Error "❌ Intet aktivt netværkskort fundet"
    exit 1
}

# Sæt IP, gateway og DNS
try {
    New-NetIPAddress -InterfaceAlias $interface.Name -IPAddress $dc01IPAddress -PrefixLength 24 -DefaultGateway $gateway -ErrorAction Stop
    Set-DnsClientServerAddress -InterfaceAlias $interface.Name -ServerAddresses $dc01IPAddress -ErrorAction Stop
    Set-DnsClient -InterfaceAlias $interface.Name -ConnectionSpecificSuffix $domainName -ErrorAction Stop
} catch {
    Write-Error "❌ Netværksopsætning fejlede: $($_)"
    exit 1
}

Start-Sleep -Seconds 5

# Promote til Domain Controller
try {
    Install-ADDSForest `
        -DomainName $domainName `
        -DomainNetbiosName $domainNetbios `
        -SafeModeAdministratorPassword $safeModePassword `
        -InstallDNS `
        -CreateDnsDelegation:$false `
        -DatabasePath "C:\Windows\NTDS" `
        -LogPath "C:\Windows\NTDS" `
        -SYSVOLPath "C:\Windows\SYSVOL" `
        -NoRebootOnCompletion:$false `
        -Force:$true

    Write-Output "✅ DC01 er nu Domain Controller for $domainName"
} catch {
    $_ | Out-File -FilePath C:\Temp\promote-error.txt -Encoding utf8
    Write-Error "❌ Fejl under domain promotion: $($_)"
    exit 1
}