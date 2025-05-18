param(
    [string]$domainName,
    [string]$domainAdminUser,
    [securestring]$domainAdminPassword,
    [string]$dcIPAddress
)

# Find netværkskortet
$interface = Get-NetAdapter | Where-Object { $_.Status -eq "Up" } | Select-Object -First 1

# Sæt DNS til at pege på din DC01
Set-DnsClientServerAddress -InterfaceAlias $interface.Name -ServerAddresses $dcIPAddress

# Vent lidt for at sikre DNS bliver opdateret
Start-Sleep -Seconds 5

# Join domænet
try {
    $cred = New-Object System.Management.Automation.PSCredential("$domainName\$domainAdminUser", $domainAdminPassword)
    Add-Computer -DomainName $domainName -Credential $cred -Force -Restart
} catch {
    $_ | Out-File -FilePath C:\Temp\domain-join-error.txt -Encoding utf8
    throw $_
}
