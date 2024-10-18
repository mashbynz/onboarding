# Variables
$tenantId = "cacec02d-792e-4d29-9677-8ee7e6290752"
$appName = "SharePointSitesApp"
$certPassword = "P@ssw0rd!"

# Create a self-signed certificate
$cert = New-SelfSignedCertificate -CertStoreLocation Cert:\CurrentUser\My -Subject "CN=$appName" -KeySpec KeyExchange -KeyExportPolicy Exportable -KeyLength 2048 -NotAfter (Get-Date).AddYears(1)
$certPath = "Cert:\CurrentUser\My\$($cert.Thumbprint)"
$certBytes = [System.Convert]::ToBase64String($cert.Export([System.Security.Cryptography.X509Certificates.X509ContentType]::Pfx, $certPassword))

# Register the application in Azure AD
$app = New-AzADApplication -DisplayName $appName -IdentifierUris "https://$appName" -Password $certBytes
$sp = New-AzADServicePrincipal -ApplicationId $app.ApplicationId

# Assign API permissions to the application
$graphApi = Get-AzADServicePrincipal -DisplayName "Microsoft Graph"
New-AzADServicePrincipalOAuth2PermissionGrant -ClientId $sp.Id -ConsentType AllPrincipals -PrincipalId $sp.Id -ResourceId $graphApi.Id -Scope "Sites.Read.All"

# Save the certificate to a file
$certFilePath = "$env:TEMP\$appName.pfx"
Export-PfxCertificate -Cert $certPath -FilePath $certFilePath -Password (ConvertTo-SecureString -String $certPassword -Force -AsPlainText)

# Connect to Microsoft Graph using the application context
$clientId = $app.ApplicationId
$clientSecret = $certPassword
$tenantId = $tenantId

$token = (Invoke-RestMethod -Uri "https://login.microsoftonline.com/$tenantId/oauth2/v2.0/token" `
    -Method Post `
    -ContentType "application/x-www-form-urlencoded" `
    -Body @{
        client_id = $clientId
        scope = "https://graph.microsoft.com/.default"
        client_secret = $clientSecret
        grant_type = "client_credentials"
    }).access_token

# Set the access token for Microsoft Graph
$headers = @{
    Authorization = "Bearer $token"
}

# Function to get SharePoint sites information in app context
function Get-SharePointSites {
    $sites = Invoke-RestMethod -Uri "https://graph.microsoft.com/v1.0/sites" -Headers $headers
    $siteDetails = @()

    foreach ($site in $sites.value) {
        $siteInfo = @{
            SiteName = $site.displayName
            SiteUrl = $site.webUrl
            Owner = $site.createdBy.user.displayName
            StorageUsed = $site.quota.used
            LastActivityDateTime = $site.lastModifiedDateTime
        }
        $siteDetails += $siteInfo
    }

    return $siteDetails
}
# Install the required module
Install-Module -Name Microsoft.Graph -Scope AllUsers -Force -AllowClobber

# Import the module
$maximumfunctioncount = '32768'
Import-Module Microsoft.Graph.Sites

# Connect to Microsoft Graph
Connect-MgGraph -Scopes "Sites.Read.All" -ForceInteractive

# Function to get SharePoint sites information
function Get-SharePointSites {
    $sites = Get-MgSite -ConsistencyLevel eventual -CountVariable count -All
    $siteDetails = @()

    foreach ($site in $sites) {
        $siteInfo = @{
            SiteName = $site.DisplayName
            SiteUrl = $site.WebUrl
            Owner = $site.CreatedBy.User.DisplayName
            StorageUsed = $site.Quota.Used
            LastActivityDateTime = $site.LastModifiedDateTime
        }
        $siteDetails += $siteInfo
    }

    return $siteDetails
}

# Retrieve and display the SharePoint sites information
$sharePointSites = Get-SharePointSites
$sharePointSites | Format-Table -AutoSize