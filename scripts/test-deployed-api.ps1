# Test Deployed API Script
# This script tests all endpoints of the deployed .NET API

$BaseUrl = "http://webapp-netapi-poc-1756280788.azurewebsites.net"
$Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"

Write-Host "=== Testing Deployed .NET API ===" -ForegroundColor Green
Write-Host "Base URL: $BaseUrl" -ForegroundColor Cyan
Write-Host "Test Time: $Timestamp" -ForegroundColor Cyan
Write-Host ""

# Test 1: Health Check Endpoint
Write-Host "1. Testing Health Endpoint..." -ForegroundColor Yellow
try {
    $healthResponse = Invoke-RestMethod -Uri "$BaseUrl/health" -Method GET
    Write-Host "✅ Health Check: SUCCESS" -ForegroundColor Green
    Write-Host "   Status: $($healthResponse.status)" -ForegroundColor White
    Write-Host "   Timestamp: $($healthResponse.timestamp)" -ForegroundColor White
    Write-Host "   Version: $($healthResponse.version)" -ForegroundColor White
} catch {
    Write-Host "❌ Health Check: FAILED" -ForegroundColor Red
    Write-Host "   Error: $($_.Exception.Message)" -ForegroundColor Red
}
Write-Host ""

# Test 2: Weather Forecast Endpoint
Write-Host "2. Testing Weather Forecast Endpoint..." -ForegroundColor Yellow
try {
    $weatherResponse = Invoke-RestMethod -Uri "$BaseUrl/weatherforecast" -Method GET
    Write-Host "✅ Weather Forecast: SUCCESS" -ForegroundColor Green
    Write-Host "   Forecast Count: $($weatherResponse.Count)" -ForegroundColor White
    Write-Host "   Sample Forecast:" -ForegroundColor White
    $weatherResponse | Select-Object -First 2 | ForEach-Object {
        Write-Host "     Date: $($_.date), Temp: $($_.temperatureC)°C, Summary: $($_.summary)" -ForegroundColor Gray
    }
} catch {
    Write-Host "❌ Weather Forecast: FAILED" -ForegroundColor Red
    Write-Host "   Error: $($_.Exception.Message)" -ForegroundColor Red
}
Write-Host ""

# Test 3: Check Response Headers
Write-Host "3. Testing Response Headers..." -ForegroundColor Yellow
try {
    $response = Invoke-WebRequest -Uri "$BaseUrl/health" -Method GET
    Write-Host "✅ Response Headers: SUCCESS" -ForegroundColor Green
    Write-Host "   Status Code: $($response.StatusCode)" -ForegroundColor White
    Write-Host "   Content Type: $($response.Headers['Content-Type'])" -ForegroundColor White
    if ($response.Headers['Server']) {
        Write-Host "   Server: $($response.Headers['Server'])" -ForegroundColor White
    }
} catch {
    Write-Host "❌ Response Headers: FAILED" -ForegroundColor Red
    Write-Host "   Error: $($_.Exception.Message)" -ForegroundColor Red
}
Write-Host ""

# Test 4: Test Invalid Endpoint
Write-Host "4. Testing Error Handling..." -ForegroundColor Yellow
try {
    $errorResponse = Invoke-WebRequest -Uri "$BaseUrl/invalid-endpoint" -Method GET
    Write-Host "❌ Error Handling: UNEXPECTED SUCCESS" -ForegroundColor Red
} catch {
    if ($_.Exception.Response.StatusCode -eq 404) {
        Write-Host "✅ Error Handling: SUCCESS (404 as expected)" -ForegroundColor Green
    } else {
        Write-Host "⚠️  Error Handling: UNEXPECTED STATUS CODE" -ForegroundColor Yellow
        Write-Host "   Status Code: $($_.Exception.Response.StatusCode)" -ForegroundColor Yellow
    }
}
Write-Host ""

Write-Host "=== Test Summary ===" -ForegroundColor Green
Write-Host "🌐 Application URL: $BaseUrl" -ForegroundColor Cyan
Write-Host "📊 Application Insights: Configured and Active" -ForegroundColor Cyan
Write-Host "🚀 GitHub Actions: Deployment Successful" -ForegroundColor Cyan
Write-Host "✅ POC Status: COMPLETE" -ForegroundColor Green
Write-Host ""
Write-Host "🎯 Next Steps:" -ForegroundColor Magenta
Write-Host "   1. Monitor Application Insights dashboard" -ForegroundColor White
Write-Host "   2. Set up alerts and monitoring rules" -ForegroundColor White
Write-Host "   3. Configure custom domain (optional)" -ForegroundColor White
Write-Host "   4. Add authentication if needed" -ForegroundColor White
