# Azure Deployment Script for WeatherApi
# This script builds and deploys the .NET API to Azure App Service

param(
    [string]$ResourceGroupName = "rg-netapi-poc-new",
    [string]$WebAppName = "webapp-netapi-poc-1756280788",
    [string]$ProjectPath = "src\WeatherApi\WeatherApi.csproj"
)

# Azure CLI path
$azPath = "C:\Program Files\Microsoft SDKs\Azure\CLI2\wbin\az.cmd"

Write-Host "Starting deployment to Azure App Service..." -ForegroundColor Green
Write-Host "Resource Group: $ResourceGroupName"
Write-Host "Web App: $WebAppName"
Write-Host "Project: $ProjectPath"

try {
    # Step 1: Build and publish the application
    Write-Host "`nBuilding and publishing application..." -ForegroundColor Yellow
    dotnet publish $ProjectPath --configuration Release --output publish --source https://api.nuget.org/v3/index.json
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host "✓ Application built and published successfully" -ForegroundColor Green
    } else {
        throw "Failed to build and publish application"
    }

    # Step 2: Create zip file for deployment
    Write-Host "`nCreating deployment package..." -ForegroundColor Yellow
    $zipPath = "deploy.zip"
    if (Test-Path $zipPath) {
        Remove-Item $zipPath
    }
    
    Compress-Archive -Path "publish\*" -DestinationPath $zipPath
    Write-Host "✓ Deployment package created: $zipPath" -ForegroundColor Green

    # Step 3: Deploy to Azure App Service
    Write-Host "`nDeploying to Azure App Service..." -ForegroundColor Yellow
    & $azPath webapp deployment source config-zip `
        --resource-group $ResourceGroupName `
        --name $WebAppName `
        --src $zipPath

    if ($LASTEXITCODE -eq 0) {
        Write-Host "✓ Deployment completed successfully" -ForegroundColor Green
    } else {
        throw "Failed to deploy to Azure App Service"
    }

    # Step 4: Configure Application Insights connection string
    Write-Host "`nConfiguring Application Insights..." -ForegroundColor Yellow
    $aiConnectionString = "InstrumentationKey=4dd21a16-45a4-492a-8016-342c7c4c5b4f;IngestionEndpoint=https://centralus-2.in.applicationinsights.azure.com/;LiveEndpoint=https://centralus.livediagnostics.monitor.azure.com/;ApplicationId=0ce1cf88-90fe-43bf-ad59-421774769939"
    
    & $azPath webapp config appsettings set `
        --resource-group $ResourceGroupName `
        --name $WebAppName `
        --settings "ApplicationInsights__ConnectionString=$aiConnectionString"

    if ($LASTEXITCODE -eq 0) {
        Write-Host "✓ Application Insights configured successfully" -ForegroundColor Green
    } else {
        Write-Host "⚠ Warning: Failed to configure Application Insights" -ForegroundColor Yellow
    }

    # Display deployment summary
    Write-Host "`n==================== DEPLOYMENT SUMMARY ====================" -ForegroundColor Cyan
    Write-Host "Web App: $WebAppName"
    Write-Host "Web App URL: https://$WebAppName.azurewebsites.net"
    Write-Host "API Health Check: https://$WebAppName.azurewebsites.net/health"
    Write-Host "Weather Forecast API: https://$WebAppName.azurewebsites.net/weatherforecast"
    Write-Host "Swagger UI: https://$WebAppName.azurewebsites.net/swagger"
    Write-Host "==========================================================" -ForegroundColor Cyan
    Write-Host "`n.NET API deployed successfully to Azure App Service!" -ForegroundColor Green

    # Clean up
    if (Test-Path $zipPath) {
        Remove-Item $zipPath
    }
    if (Test-Path "publish") {
        Remove-Item "publish" -Recurse -Force
    }

} catch {
    Write-Host "`n✗ Error: $_" -ForegroundColor Red
    Write-Host "Please check your Azure CLI login and permissions." -ForegroundColor Yellow
    exit 1
}
