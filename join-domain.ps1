param(
    [string]$domainName,
    [string]$domainAdminUser,
    [securestring]$domainAdminPassword,
    [string]$dcIPAddress
)

# Find aktivt netværkskort
$interface = Get-NetAdapter | Where-Object { $_.Status -eq "Up" } | Select-Object -First 1

if (-not $interface) {
    Write-Error "Intet aktivt netværkskort fundet"
    exit 1
}

# Sæt DNS til at pege på din Domain Controller
Set-DnsClientServerAddress -InterfaceAlias $interface.Name -ServerAddresses $dcIPAddress

# Vent lidt for at sikre DNS træder i kraft
Start-Sleep -Seconds 5

# Opret domænecredentials
$cred = New-Object System.Management.Automation.PSCredential ("$domainName\$domainAdminUser", $domainAdminPassword)

# Join domænet og genstart
try {
    Add-Computer -DomainName $domainName -Credential $cred -Force -Restart
} catch {
    $_ | Out-File -FilePath C:\Temp\domain-join-error.txt -Encoding utf8
    Write-Error "Fejl under domain join: $_"
    exit 1
}