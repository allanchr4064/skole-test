param(
    [string]$domainName,
    [string]$domainAdminUser,
    [securestring]$domainAdminPassword,
    [string]$dcIPAddress
)

# Sikr at scriptet kan køre
Set-ExecutionPolicy -ExecutionPolicy Bypass -Scope Process -Force

# Find aktivt netværkskort
$interface = Get-NetAdapter | Where-Object { $_.Status -eq "Up" } | Select-Object -First 1
if (-not $interface) {
    Write-Error "Intet aktivt netværkskort fundet"
    exit 1
}

# Sæt DNS til kun din Domain Controller
Set-DnsClientServerAddress -InterfaceAlias $interface.Name -ServerAddresses @($dcIPAddress)

# Vent lidt for at sikre DNS virker
Start-Sleep -Seconds 5

# Opret credentials
$cred = New-Object System.Management.Automation.PSCredential ("$domainName\$domainAdminUser", $domainAdminPassword)

# Join domænet
try {
    Add-Computer -DomainName $domainName -Credential $cred -Force -Restart
} catch {
    $_ | Out-File -FilePath C:\Temp\domain-join-error.txt -Encoding utf8
    Write-Error "Fejl under domain join: $_"
    exit 1
}