# Install the Microsoft.Graph module if not already installed
if (-not (Get-Module -ListAvailable -Name Microsoft.Graph)) {
    Install-Module Microsoft.Graph -Scope CurrentUser -Force
}

# Connect to Microsoft Graph
Connect-MgGraph -Scopes "Application.Read.All"

# Get all enterprise applications
$enterpriseApps = Get-MgServicePrincipal -Filter "tags/Any(x: x eq 'WindowsAzureActiveDirectoryIntegratedApp')"

# Display the enterprise applications
$enterpriseApps | Select-Object DisplayName, Description, Homepage | Export-csv -Path "C:\temp\enterpriseapps.csv" -NoTypeInformation