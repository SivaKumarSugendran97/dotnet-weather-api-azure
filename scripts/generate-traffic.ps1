# Generate API Traffic for Application Insights Testing
# This script makes multiple API calls to generate telemetry data

$BaseUrl = "http://webapp-netapi-poc-1756280788.azurewebsites.net"

Write-Host "🚀 Generating API traffic for Application Insights testing..." -ForegroundColor Green
Write-Host "Base URL: $BaseUrl" -ForegroundColor Cyan
Write-Host ""

# Generate 10 weather forecast requests
Write-Host "📊 Making 10 Weather Forecast requests..." -ForegroundColor Yellow
for ($i = 1; $i -le 10; $i++) {
    try {
        Write-Host "Request $i..." -NoNewline
        $response = Invoke-RestMethod -Uri "$BaseUrl/weatherforecast" -Method GET
        Write-Host " ✅ Success (Got $($response.Count) forecasts)" -ForegroundColor Green
        Start-Sleep -Seconds 2  # Wait 2 seconds between requests
    } catch {
        Write-Host " ❌ Failed: $($_.Exception.Message)" -ForegroundColor Red
    }
}

Write-Host ""

# Generate 5 health check requests
Write-Host "🏥 Making 5 Health Check requests..." -ForegroundColor Yellow
for ($i = 1; $i -le 5; $i++) {
    try {
        Write-Host "Health Check $i..." -NoNewline
        $response = Invoke-RestMethod -Uri "$BaseUrl/health" -Method GET
        Write-Host " ✅ Success (Status: $($response.status))" -ForegroundColor Green
        Start-Sleep -Seconds 1  # Wait 1 second between requests
    } catch {
        Write-Host " ❌ Failed: $($_.Exception.Message)" -ForegroundColor Red
    }
}

Write-Host ""
Write-Host "🎯 Traffic generation complete!" -ForegroundColor Green
Write-Host ""
Write-Host "📈 Now check Application Insights:" -ForegroundColor Magenta
Write-Host "1. Go to Azure Portal → Application Insights → ai-netapi-poc" -ForegroundColor White
Write-Host "2. Click 'Logs' and run this query:" -ForegroundColor White
Write-Host ""
Write-Host "traces" -ForegroundColor Gray
Write-Host "| where message contains 'Weather forecast requested' or message contains 'Health check requested'" -ForegroundColor Gray
Write-Host "| order by timestamp desc" -ForegroundColor Gray
Write-Host "| take 20" -ForegroundColor Gray
Write-Host ""
Write-Host "🔍 You should see logs with timestamps from the requests above!" -ForegroundColor Cyan
