# Install the Microsoft.Graph module if not already installed
if (-not (Get-Module -ListAvailable -Name Microsoft.Graph)) {
    Install-Module Microsoft.Graph -Scope CurrentUser -Force
}

# Connect to Microsoft Graph
Connect-MgGraph -Scopes "Group.Read.All", "User.Read.All" -TenantId "046fdb9a-2f6c-4537-b033-148bc37eae80" -NoWelcome

# Get all M365 Groups
$groups = Get-MgGroup -Filter "groupTypes/any(c:c eq 'Unified')"

# Create an array to hold group details
$groupDetails = @()

# Loop through each group and get details
foreach ($group in $groups) {
    $groupId = $group.Id
    $groupName = $group.DisplayName
    $groupEmail = $group.Mail

    # Get group owners
    $owners = Get-MgGroupOwner -GroupId $groupId | Select-Object @{label="DisplayName";expression = {$.AdditionalProperties.displayName} }, @{label="UserPrincipalName";expression = {$_.AdditionalProperties.userPrincipalName} }

    # Get group members
    $members = Get-MgGroupMember -GroupId $groupId | Select-Object @{label="DisplayName";expression = {$.AdditionalProperties.displayName} }, @{label="UserPrincipalName";expression = {$_.AdditionalProperties.userPrincipalName} }

    # Format owners and members as strings
    $ownersString = ($owners | ForEach-Object { "$($_.DisplayName) <$($_.UserPrincipalName)>" }) -join "; "
    $membersString = ($members | ForEach-Object { "$($_.DisplayName) <$($_.UserPrincipalName)>" }) -join "; "

    # Add group details to the array
    $groupDetails += [PSCustomObject]@{
        Name    = $groupName
        Email   = $groupEmail
        Owners  = $ownersString
        Members = $membersString
    }
}

# Export the group details to a CSV file
$groupDetails | Export-Csv -Path "C:\temp\m365groups.csv" -NoTypeInformation