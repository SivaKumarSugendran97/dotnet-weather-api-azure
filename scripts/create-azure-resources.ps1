# Azure Resource Creation Script for .NET API POC
# This script creates all necessary Azure resources for hosting a .NET API with monitoring

param(
    [string]$ResourceGroupName = "rg-netapi-poc",
    [string]$Location = "East US",
    [string]$AppServicePlanName = "plan-netapi-poc",
    [string]$WebAppName = "webapp-netapi-poc-$([DateTimeOffset]::UtcNow.ToUnixTimeSeconds())",
    [string]$AppInsightsName = "ai-netapi-poc",
    [string]$Sku = "F1"
)

# Azure CLI path
$azPath = "C:\Program Files\Microsoft SDKs\Azure\CLI2\wbin\az.cmd"

Write-Host "Starting Azure resource creation..." -ForegroundColor Green
Write-Host "Resource Group: $ResourceGroupName"
Write-Host "Location: $Location"
Write-Host "Web App Name: $WebAppName"

try {
    # Step 1: Create Resource Group
    Write-Host "`nCreating resource group..." -ForegroundColor Yellow
    & $azPath group create --name $ResourceGroupName --location $Location
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host "✓ Resource group created successfully" -ForegroundColor Green
    } else {
        throw "Failed to create resource group"
    }

    # Step 2: Create App Service Plan
    Write-Host "`nCreating App Service Plan..." -ForegroundColor Yellow
    & $azPath appservice plan create `
        --name $AppServicePlanName `
        --resource-group $ResourceGroupName `
        --sku $Sku

    if ($LASTEXITCODE -eq 0) {
        Write-Host "✓ App Service Plan created successfully" -ForegroundColor Green
    } else {
        throw "Failed to create App Service Plan"
    }

    # Step 3: Create Web App
    Write-Host "`nCreating Web App..." -ForegroundColor Yellow
    & $azPath webapp create `
        --name $WebAppName `
        --resource-group $ResourceGroupName `
        --plan $AppServicePlanName `
        --runtime "dotnet:8"

    if ($LASTEXITCODE -eq 0) {
        Write-Host "✓ Web App created successfully" -ForegroundColor Green
    } else {
        throw "Failed to create Web App"
    }

    # Step 4: Create Application Insights
    Write-Host "`nCreating Application Insights..." -ForegroundColor Yellow
    & $azPath monitor app-insights component create `
        --app $AppInsightsName `
        --location $Location `
        --resource-group $ResourceGroupName `
        --kind web `
        --application-type web

    if ($LASTEXITCODE -eq 0) {
        Write-Host "✓ Application Insights created successfully" -ForegroundColor Green
    } else {
        throw "Failed to create Application Insights"
    }

    # Step 5: Get Application Insights Connection String
    Write-Host "`nRetrieving Application Insights connection string..." -ForegroundColor Yellow
    $aiConnectionString = & $azPath monitor app-insights component show `
        --app $AppInsightsName `
        --resource-group $ResourceGroupName `
        --query connectionString `
        --output tsv

    if ($aiConnectionString) {
        Write-Host "✓ Application Insights connection string retrieved" -ForegroundColor Green
    } else {
        throw "Failed to retrieve Application Insights connection string"
    }

    # Step 6: Configure Web App with Application Insights
    Write-Host "`nConfiguring Web App with Application Insights..." -ForegroundColor Yellow
    & $azPath webapp config appsettings set `
        --name $WebAppName `
        --resource-group $ResourceGroupName `
        --settings "APPLICATIONINSIGHTS_CONNECTION_STRING=$aiConnectionString"

    if ($LASTEXITCODE -eq 0) {
        Write-Host "✓ Web App configured with Application Insights" -ForegroundColor Green
    } else {
        throw "Failed to configure Web App with Application Insights"
    }

    # Step 7: Get Instrumentation Key and set it as well
    Write-Host "`nEnabling Application Insights integration..." -ForegroundColor Yellow
    $instrumentationKey = & $azPath monitor app-insights component show `
        --app $AppInsightsName `
        --resource-group $ResourceGroupName `
        --query instrumentationKey `
        --output tsv

    & $azPath webapp config appsettings set `
        --name $WebAppName `
        --resource-group $ResourceGroupName `
        --settings "APPINSIGHTS_INSTRUMENTATIONKEY=$instrumentationKey"

    if ($LASTEXITCODE -eq 0) {
        Write-Host "✓ Application Insights integration enabled" -ForegroundColor Green
    }

    # Display summary
    Write-Host "`n==================== DEPLOYMENT SUMMARY ====================" -ForegroundColor Cyan
    Write-Host "Resource Group: $ResourceGroupName"
    Write-Host "App Service Plan: $AppServicePlanName"
    Write-Host "Web App: $WebAppName"
    Write-Host "Web App URL: https://$WebAppName.azurewebsites.net"
    Write-Host "Application Insights: $AppInsightsName"
    Write-Host "Location: $Location"
    Write-Host "==========================================================" -ForegroundColor Cyan
    Write-Host "`nAll Azure resources have been created successfully!" -ForegroundColor Green

    Write-Host "`nNext steps:" -ForegroundColor Yellow
    Write-Host "1. Create your .NET API application"
    Write-Host "2. Set up GitHub Actions for CI/CD"
    Write-Host "3. Deploy your application"

    # Save important values to a file for later use
    $configContent = @"
RESOURCE_GROUP_NAME=$ResourceGroupName
WEB_APP_NAME=$WebAppName
APP_INSIGHTS_NAME=$AppInsightsName
AI_CONNECTION_STRING=$aiConnectionString
WEB_APP_URL=https://$WebAppName.azurewebsites.net
INSTRUMENTATION_KEY=$instrumentationKey
"@

    $configContent | Out-File -FilePath "azure-config.env" -Encoding UTF8
    Write-Host "`nConfiguration saved to azure-config.env" -ForegroundColor Green

} catch {
    Write-Host "`n✗ Error: $_" -ForegroundColor Red
    Write-Host "Please check your Azure CLI login and permissions." -ForegroundColor Yellow
    exit 1
}
