# Simple API Test Script
# This script tests the WeatherApi endpoints

Write-Host "Testing WeatherApi endpoints..." -ForegroundColor Green

# Test URLs
$baseUrl = "https://webapp-netapi-poc-1756280788.azurewebsites.net"
$healthUrl = "$baseUrl/health"
$weatherUrl = "$baseUrl/weatherforecast"

try {
    Write-Host "`nTesting Health Endpoint..." -ForegroundColor Yellow
    $healthResponse = Invoke-RestMethod -Uri $healthUrl -Method Get -ErrorAction Stop
    Write-Host "✓ Health Check Response:" -ForegroundColor Green
    $healthResponse | ConvertTo-Json -Depth 3
    
    Write-Host "`nTesting Weather Forecast Endpoint..." -ForegroundColor Yellow
    $weatherResponse = Invoke-RestMethod -Uri $weatherUrl -Method Get -ErrorAction Stop
    Write-Host "✓ Weather Forecast Response:" -ForegroundColor Green
    $weatherResponse | ConvertTo-Json -Depth 3
    
    Write-Host "`n✓ All API endpoints are working!" -ForegroundColor Green
    
} catch {
    Write-Host "✗ Error testing APIs: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host "Note: The API might not be deployed yet or still starting up." -ForegroundColor Yellow
}
