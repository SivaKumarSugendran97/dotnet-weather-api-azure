# Get Function App Publish Profile for GitHub Actions
# This script retrieves the publish profile needed for GitHub Actions deployment

param(
    [string]$ConfigFile = "azure-config.env"
)

# Load configuration
if (-not (Test-Path $ConfigFile)) {
    Write-Host "Configuration file $ConfigFile not found!" -ForegroundColor Red
    exit 1
}

Write-Host "Loading configuration from $ConfigFile..." -ForegroundColor Yellow
$config = @{}
Get-Content $ConfigFile | ForEach-Object {
    if ($_ -match '^([^=]+)=(.*)$') {
        $config[$matches[1]] = $matches[2]
    }
}

$azPath = "C:\Program Files\Microsoft SDKs\Azure\CLI2\wbin\az.cmd"

try {
    Write-Host "`nRetrieving Function App publish profile..." -ForegroundColor Green
    
    # Get the Function App publish profile
    $publishProfile = & $azPath functionapp deployment list-publishing-profiles `
        --name $config['FUNCTION_APP_NAME'] `
        --resource-group $config['RESOURCE_GROUP_NAME'] `
        --xml

    if ($publishProfile) {
        Write-Host "✓ Function App publish profile retrieved successfully" -ForegroundColor Green
        
        # Save to file for manual setup
        $publishProfile | Out-File -FilePath "function-app-publish-profile.xml" -Encoding UTF8
        Write-Host "✓ Publish profile saved to function-app-publish-profile.xml" -ForegroundColor Green
        
        Write-Host "`n==================== GITHUB ACTIONS SETUP ====================" -ForegroundColor Cyan
        Write-Host "To complete the CI/CD setup, add this secret to your GitHub repository:"
        Write-Host ""
        Write-Host "Secret Name: AZURE_FUNCTIONAPP_PUBLISH_PROFILE" -ForegroundColor Yellow
        Write-Host "Secret Value: (copy the content from function-app-publish-profile.xml)" -ForegroundColor Yellow
        Write-Host ""
        Write-Host "Steps to add the secret:" -ForegroundColor White
        Write-Host "1. Go to your GitHub repository"
        Write-Host "2. Navigate to Settings > Secrets and variables > Actions"
        Write-Host "3. Click 'New repository secret'"
        Write-Host "4. Name: AZURE_FUNCTIONAPP_PUBLISH_PROFILE"
        Write-Host "5. Value: Paste the entire XML content from function-app-publish-profile.xml"
        Write-Host "6. Click 'Add secret'"
        Write-Host "================================================================" -ForegroundColor Cyan
        
        Write-Host "`nFunction App Details:" -ForegroundColor White
        Write-Host "  App Name: $($config['FUNCTION_APP_NAME'])"
        Write-Host "  Resource Group: $($config['RESOURCE_GROUP_NAME'])"
        Write-Host "  Function App URL: $($config['FUNCTION_APP_URL'])"
        
    } else {
        throw "Failed to retrieve publish profile"
    }

} catch {
    Write-Host "`n✗ Error retrieving publish profile: $_" -ForegroundColor Red
    Write-Host "Please ensure you have access to the Function App and try again." -ForegroundColor Yellow
    exit 1
}
