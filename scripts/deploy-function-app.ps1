# Deploy Function App to Azure
# This script builds and deploys the Function App to Azure

param(
    [string]$ConfigFile = "azure-config.env",
    [switch]$SkipBuild = $false
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

$functionAppName = $config['FUNCTION_APP_NAME']
$resourceGroupName = $config['RESOURCE_GROUP_NAME']

if (-not $functionAppName -or -not $resourceGroupName) {
    Write-Host "Function App configuration not found!" -ForegroundColor Red
    exit 1
}

$azPath = "C:\Program Files\Microsoft SDKs\Azure\CLI2\wbin\az.cmd"
$projectPath = "src/MessageFunctions"

Write-Host "`nDeploying Function App: $functionAppName" -ForegroundColor Green
Write-Host "Resource Group: $resourceGroupName" -ForegroundColor Cyan
Write-Host "Project Path: $projectPath" -ForegroundColor Cyan

try {
    # Step 1: Build the project (unless skipped)
    if (-not $SkipBuild) {
        Write-Host "`nBuilding Function App project..." -ForegroundColor Yellow
        dotnet build $projectPath/MessageFunctions.csproj --configuration Release
        
        if ($LASTEXITCODE -ne 0) {
            throw "Build failed"
        }
        Write-Host "✓ Build successful" -ForegroundColor Green
    } else {
        Write-Host "`nSkipping build step..." -ForegroundColor Yellow
    }

    # Step 2: Publish the project
    Write-Host "`nPublishing Function App..." -ForegroundColor Yellow
    dotnet publish $projectPath/MessageFunctions.csproj --configuration Release --output ./publish-functions
    
    if ($LASTEXITCODE -ne 0) {
        throw "Publish failed"
    }
    Write-Host "✓ Publish successful" -ForegroundColor Green

    # Step 3: Create deployment package
    Write-Host "`nCreating deployment package..." -ForegroundColor Yellow
    
    if (Test-Path "./deploy-functions.zip") {
        Remove-Item "./deploy-functions.zip" -Force
    }
    
    # Create zip file for deployment
    Compress-Archive -Path "./publish-functions/*" -DestinationPath "./deploy-functions.zip" -Force
    Write-Host "✓ Deployment package created: deploy-functions.zip" -ForegroundColor Green

    # Step 4: Deploy to Azure
    Write-Host "`nDeploying to Azure Function App..." -ForegroundColor Yellow
    
    & $azPath functionapp deployment source config-zip `
        --name $functionAppName `
        --resource-group $resourceGroupName `
        --src "./deploy-functions.zip"

    if ($LASTEXITCODE -eq 0) {
        Write-Host "✓ Deployment successful!" -ForegroundColor Green
    } else {
        throw "Deployment failed"
    }

    # Step 5: Restart Function App to ensure new deployment is loaded
    Write-Host "`nRestarting Function App..." -ForegroundColor Yellow
    & $azPath functionapp restart `
        --name $functionAppName `
        --resource-group $resourceGroupName

    if ($LASTEXITCODE -eq 0) {
        Write-Host "✓ Function App restarted" -ForegroundColor Green
    }

    # Display summary
    Write-Host "`n==================== DEPLOYMENT SUMMARY ====================" -ForegroundColor Cyan
    Write-Host "Function App: $functionAppName" -ForegroundColor White
    Write-Host "Function App URL: $($config['FUNCTION_APP_URL'])" -ForegroundColor White
    Write-Host "Resource Group: $resourceGroupName" -ForegroundColor White
    Write-Host "Deployment Status: ✓ SUCCESS" -ForegroundColor Green
    Write-Host "==========================================================" -ForegroundColor Cyan

    Write-Host "`nAvailable Functions:" -ForegroundColor Yellow
    Write-Host "1. POST $($config['FUNCTION_APP_URL'])/api/weather/publish - Publish custom weather"
    Write-Host "2. POST $($config['FUNCTION_APP_URL'])/api/weather/publish-random - Publish random weather"
    Write-Host "3. ProcessWeatherUpdate - Triggered by Service Bus messages (automatic)"
    Write-Host "4. ProcessDeadLetterMessages - Handles failed messages (automatic)"

    Write-Host "`nNext steps:" -ForegroundColor Yellow
    Write-Host "1. Test the functions using: .\scripts\test-function-app.ps1"
    Write-Host "2. Monitor logs in Application Insights"
    Write-Host "3. Check Service Bus queue for message processing"

    # Cleanup
    if (Test-Path "./publish-functions") {
        Remove-Item "./publish-functions" -Recurse -Force
    }
    if (Test-Path "./deploy-functions.zip") {
        Remove-Item "./deploy-functions.zip" -Force
    }

} catch {
    Write-Host "`n✗ Deployment Error: $_" -ForegroundColor Red
    Write-Host "Please check your Azure CLI login and permissions." -ForegroundColor Yellow
    
    # Cleanup on error
    if (Test-Path "./publish-functions") {
        Remove-Item "./publish-functions" -Recurse -Force -ErrorAction SilentlyContinue
    }
    if (Test-Path "./deploy-functions.zip") {
        Remove-Item "./deploy-functions.zip" -Force -ErrorAction SilentlyContinue
    }
    
    exit 1
}

Write-Host "`n🎉 Function App deployment completed successfully!" -ForegroundColor Green
