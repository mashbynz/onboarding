Import-Module Microsoft.Graph.Applications

# Connect to Microsoft Graph
Connect-MgGraph -Scopes "Application.Read.All"

# Get all enterprise applications
$enterpriseApps = Get-MgServicePrincipal -All

# Display the enterprise applications
$enterpriseApps | Select-Object DisplayName, Description, Homepage | Export-csv -Path "C:\temp\enterpriseapps.csv" -NoTypeInformation