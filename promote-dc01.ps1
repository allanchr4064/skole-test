param (
    [string]$domainAdminUser,
    [SecureString]$domainAdminPassword,
    [string]$domainName,
    [string]$dcIPAddress
)

# Sæt login credentials
$cred = New-Object System.Management.Automation.PSCredential ($domainAdminUser, $domainAdminPassword)

try {
    # Opretter domænet og konfigurerer serveren
    Write-Output "Opretter domænet og tilslutter serveren $dcIPAddress til $domainName"

    # Tilslut serveren til domænet
    Add-Computer -DomainName $domainName -Credential $cred -Force -Restart

    Write-Output "✅ Serveren er blevet tilsluttet domænet $domainName"
} catch {
    # Håndterer fejl
    Write-Error "❌ Der opstod en fejl under tilslutning til domænet: $_"
    # Gem fejlinformation i en log-fil
    $_ | Out-File -FilePath C:\Temp\domain-join-error.txt -Encoding utf8
    exit 1
}