# Test Function App Endpoints
# This script tests the publisher and consumer functions

param(
    [string]$ConfigFile = "azure-config.env",
    [int]$TestCount = 3,
    [int]$DelayBetweenTests = 2
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

$functionAppUrl = $config['FUNCTION_APP_URL']

if (-not $functionAppUrl) {
    Write-Host "Function App URL not found in configuration!" -ForegroundColor Red
    exit 1
}

Write-Host "`nTesting Function App: $functionAppUrl" -ForegroundColor Green
Write-Host "Number of tests: $TestCount" -ForegroundColor Cyan
Write-Host "Delay between tests: $DelayBetweenTests seconds" -ForegroundColor Cyan

try {
    # Test 1: Random Weather Publisher
    Write-Host "`n==================== TESTING RANDOM WEATHER PUBLISHER ====================" -ForegroundColor Cyan
    
    for ($i = 1; $i -le $TestCount; $i++) {
        Write-Host "`nTest $i - Publishing random weather update..." -ForegroundColor Yellow
        
        $publishUrl = "$functionAppUrl/api/weather/publish-random"
        
        try {
            $response = Invoke-RestMethod -Uri $publishUrl -Method POST -ContentType "application/json"
            
            Write-Host "✓ Success: $($response.message)" -ForegroundColor Green
            Write-Host "  Message ID: $($response.messageId)" -ForegroundColor Cyan
            Write-Host "  Timestamp: $($response.timestamp)" -ForegroundColor Cyan
            
        } catch {
            Write-Host "✗ Failed: $($_.Exception.Message)" -ForegroundColor Red
            if ($_.Exception.Response) {
                $errorDetails = $_.Exception.Response | ConvertFrom-Json -ErrorAction SilentlyContinue
                if ($errorDetails) {
                    Write-Host "  Error Details: $($errorDetails.message)" -ForegroundColor Red
                }
            }
        }
        
        if ($i -lt $TestCount) {
            Write-Host "  Waiting $DelayBetweenTests seconds..." -ForegroundColor Gray
            Start-Sleep -Seconds $DelayBetweenTests
        }
    }

    # Test 2: Custom Weather Publisher
    Write-Host "`n==================== TESTING CUSTOM WEATHER PUBLISHER ====================" -ForegroundColor Cyan
    
    $customWeatherData = @(
        @{ location = "Seattle"; temperatureC = 15; summary = "Rainy" }
        @{ location = "Phoenix"; temperatureC = 38; summary = "Scorching" }
        @{ location = "Chicago"; temperatureC = -5; summary = "Freezing" }
    )
    
    foreach ($weather in $customWeatherData) {
        Write-Host "`nPublishing custom weather for $($weather.location)..." -ForegroundColor Yellow
        
        $publishUrl = "$functionAppUrl/api/weather/publish"
        $body = $weather | ConvertTo-Json
        
        try {
            $response = Invoke-RestMethod -Uri $publishUrl -Method POST -Body $body -ContentType "application/json"
            
            Write-Host "✓ Success: $($response.message)" -ForegroundColor Green
            Write-Host "  Message ID: $($response.messageId)" -ForegroundColor Cyan
            Write-Host "  Location: $($weather.location)" -ForegroundColor Cyan
            Write-Host "  Temperature: $($weather.temperatureC)°C" -ForegroundColor Cyan
            
        } catch {
            Write-Host "✗ Failed: $($_.Exception.Message)" -ForegroundColor Red
        }
        
        Write-Host "  Waiting $DelayBetweenTests seconds for processing..." -ForegroundColor Gray
        Start-Sleep -Seconds $DelayBetweenTests
    }

    # Summary
    Write-Host "`n==================== TEST SUMMARY ====================" -ForegroundColor Cyan
    Write-Host "Function App Testing Complete!" -ForegroundColor Green
    Write-Host ""
    Write-Host "What to check next:" -ForegroundColor White
    Write-Host "1. Check Application Insights logs for message processing"
    Write-Host "2. Verify Service Bus queue is processing messages"
    Write-Host "3. Look for consumer function execution in Azure portal"
    Write-Host "4. Check for any dead letter messages"
    Write-Host ""
    Write-Host "Application Insights Query:" -ForegroundColor Yellow
    Write-Host "traces | where message contains 'Weather' | order by timestamp desc | limit 50"
    Write-Host "=======================================================" -ForegroundColor Cyan

} catch {
    Write-Host "`n✗ Error during testing: $_" -ForegroundColor Red
    Write-Host "Please check that the Function App is running and accessible." -ForegroundColor Yellow
    exit 1
}

Write-Host "`n🎉 Function App testing completed!" -ForegroundColor Green
Write-Host "💡 Check Azure portal and Application Insights for detailed logs and metrics." -ForegroundColor Cyan
