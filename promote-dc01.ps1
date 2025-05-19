param(
    [string]$domainName = "skoletræt.ninja",
    [string]$domainAdminUser = "main",
    [securestring]$domainAdminPassword,
    [string]$dcIPAddress = "192.168.1.111"
)

Set-ExecutionPolicy Bypass -Scope Process -Force
$cred = New-Object System.Management.Automation.PSCredential ("$domainName\$domainAdminUser", $domainAdminPassword)

# Find aktivt netkort
$interface = Get-NetAdapter | Where-Object { $_.Status -eq "Up" } | Select-Object -First 1
if (-not $interface) {
    Write-Error "Intet aktivt netværkskort fundet"
    exit 1
}

# Sæt DNS
Set-DnsClientServerAddress -InterfaceAlias $interface.Name -ServerAddresses @($dcIPAddress)
Start-Sleep -Seconds 5

# Få info til DNS
$hostname = $env:COMPUTERNAME
$ip = (Get-NetIPAddress -AddressFamily IPv4 -InterfaceAlias $interface.Name | Where-Object { $_.PrefixOrigin -ne "WellKnown" }).IPAddress

# Tilføj A-record via remoting til DC
Invoke-Command -ComputerName $dcIPAddress -Credential $cred -ScriptBlock {
    param($hostname, $ip, $zone)
    try {
        Add-DnsServerResourceRecordA -Name $hostname -ZoneName $zone -IPv4Address $ip -TimeToLive 01:00:00 -ErrorAction Stop
        "✅ A-record tilføjet: $hostname -> $ip"
    } catch {
        "⚠️ Fejl ved A-record: $_"
    }
} -ArgumentList $hostname, $ip, $domainName

# Join domæne uden reboot
try {
    Add-Computer -DomainName $domainName -Credential $cred -Force
    Write-Output "✅ Domænejoin gennemført – genstart er påkrævet!"
} catch {
    $_ | Out-File -FilePath C:\Temp\domain-join-error.txt -Encoding utf8
    Write-Error "❌ Fejl under domain join: $_"
    exit 1
}