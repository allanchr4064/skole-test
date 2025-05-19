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

# Beregn prefix length fra subnetmask
function Get-PrefixLength($subnetMask) {
    $binary = ($subnetMask -split '\.') | ForEach-Object {
        [Convert]::ToString([int]$_, 2).PadLeft(8, '0')
    }
    return ($binary -join '').ToCharArray() | Where-Object { $_ -eq '1' } | Measure-Object | Select-Object -ExpandProperty Count
}

$prefixLength = Get-PrefixLength $subnetMask

# Tjek om IP-adressen allerede er sat
$ipExists = Get-NetIPAddress -IPAddress $dc01IPAddress -ErrorAction SilentlyContinue

if (-not $ipExists) {
    try {
        New-NetIPAddress -InterfaceAlias $interface.Name -IPAddress $dc01IPAddress -PrefixLength $prefixLength -DefaultGateway $gateway -ErrorAction Stop
        Write-Host "✅ IP-adresse $dc01IPAddress sat på $($interface.Name)"
    } catch {
        Write-Error "❌ Fejl ved opsætning af IP: $($_)"
        exit 1
    }
} else {
    Write-Host "ℹ️ IP-adresse $dc01IPAddress findes allerede – springer IP-opsætning over."
}

# Sæt DNS og suffix (kan overskrive eksisterende DNS uden fejl)
try {
    Set-DnsClientServerAddress -InterfaceAlias $interface.Name -ServerAddresses $dc01IPAddress -ErrorAction Stop
    Set-DnsClient -InterfaceAlias $interface.Name -ConnectionSpecificSuffix $domainName -ErrorAction Stop
} catch {
    Write-Error "❌ Fejl ved DNS-opsætning: $($_)"
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
