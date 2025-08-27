# Configure Application Insights in Azure App Service
$azPath = "C:\Program Files\Microsoft SDKs\Azure\CLI2\wbin\az.cmd"
$resourceGroup = "rg-netapi-poc-new"
$webAppName = "webapp-netapi-poc-1756280788"
$connectionString = "InstrumentationKey=4dd21a16-45a4-492a-8016-342c7c4c5b4f;IngestionEndpoint=https://centralus-2.in.applicationinsights.azure.com/;LiveEndpoint=https://centralus.livediagnostics.monitor.azure.com/;ApplicationId=0ce1cf88-90fe-43bf-ad59-421774769939"

Write-Host "Configuring Application Insights..." -ForegroundColor Yellow

# Set the connection string
& $azPath webapp config appsettings set --name $webAppName --resource-group $resourceGroup --settings @('ApplicationInsights:ConnectionString=' + $connectionString)

Write-Host "Application Insights configured!" -ForegroundColor Green
