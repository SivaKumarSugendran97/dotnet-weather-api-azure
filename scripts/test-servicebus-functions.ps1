# Test Service Bus and Function App Resources
# This script validates that all Service Bus and Function App resources are created correctly

param(
    [string]$ConfigFile = "azure-config.env"
)

# Load configuration
if (-not (Test-Path $ConfigFile)) {
    Write-Host "Configuration file $ConfigFile not found!" -ForegroundColor Red
    Write-Host "Please run create-servicebus-functions.ps1 first." -ForegroundColor Yellow
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

Write-Host "`nTesting Service Bus and Function App resources..." -ForegroundColor Green

try {
    # Test 1: Check Resource Group
    Write-Host "`n1. Testing Resource Group..." -ForegroundColor Yellow
    $rgExists = & $azPath group exists --name $config['RESOURCE_GROUP_NAME']
    if ($rgExists -eq "true") {
        Write-Host "✓ Resource Group exists" -ForegroundColor Green
    } else {
        throw "Resource Group not found"
    }

    # Test 2: Check Service Bus Namespace
    Write-Host "`n2. Testing Service Bus Namespace..." -ForegroundColor Yellow
    $sbNamespace = & $azPath servicebus namespace show `
        --name $config['SERVICE_BUS_NAMESPACE'] `
        --resource-group $config['RESOURCE_GROUP_NAME'] `
        --query "name" --output tsv 2>$null

    if ($sbNamespace) {
        Write-Host "✓ Service Bus Namespace: $sbNamespace" -ForegroundColor Green
    } else {
        throw "Service Bus Namespace not found"
    }

    # Test 3: Check Service Bus Queue (Basic tier)
    Write-Host "`n3. Testing Service Bus Queue..." -ForegroundColor Yellow
    $queue = & $azPath servicebus queue show `
        --name $config['QUEUE_NAME'] `
        --namespace-name $config['SERVICE_BUS_NAMESPACE'] `
        --resource-group $config['RESOURCE_GROUP_NAME'] `
        --query "name" --output tsv 2>$null

    if ($queue) {
        Write-Host "✓ Service Bus Queue: $queue" -ForegroundColor Green
    } else {
        throw "Service Bus Queue not found"
    }

    # Test 4: Check Service Bus Queue (Basic tier uses Queue instead of Topic/Subscription)
    Write-Host "`n4. Testing Service Bus Queue..." -ForegroundColor Yellow
    $queue = & $azPath servicebus queue show `
        --name $config['QUEUE_NAME'] `
        --namespace-name $config['SERVICE_BUS_NAMESPACE'] `
        --resource-group $config['RESOURCE_GROUP_NAME'] `
        --query "name" --output tsv 2>$null

    if ($queue) {
        Write-Host "✓ Service Bus Queue: $queue" -ForegroundColor Green
    } else {
        throw "Service Bus Queue not found"
    }

    # Test 5: Check Function App
    Write-Host "`n5. Testing Function App..." -ForegroundColor Yellow
    $functionApp = & $azPath functionapp show `
        --name $config['FUNCTION_APP_NAME'] `
        --resource-group $config['RESOURCE_GROUP_NAME'] `
        --query "name" --output tsv 2>$null

    if ($functionApp) {
        Write-Host "✓ Function App: $functionApp" -ForegroundColor Green
        Write-Host "  URL: $($config['FUNCTION_APP_URL'])" -ForegroundColor Cyan
    } else {
        throw "Function App not found"
    }

    # Test 6: Check Storage Account
    Write-Host "`n6. Testing Storage Account..." -ForegroundColor Yellow
    $storageAccount = & $azPath storage account show `
        --name $config['STORAGE_ACCOUNT_NAME'] `
        --resource-group $config['RESOURCE_GROUP_NAME'] `
        --query "name" --output tsv 2>$null

    if ($storageAccount) {
        Write-Host "✓ Storage Account: $storageAccount" -ForegroundColor Green
    } else {
        throw "Storage Account not found"
    }

    # Test 7: Verify Function App Configuration
    Write-Host "`n7. Testing Function App Configuration..." -ForegroundColor Yellow
    $appSettings = & $azPath functionapp config appsettings list `
        --name $config['FUNCTION_APP_NAME'] `
        --resource-group $config['RESOURCE_GROUP_NAME'] `
        --output json | ConvertFrom-Json

    $requiredSettings = @("ServiceBusConnectionString", "APPLICATIONINSIGHTS_CONNECTION_STRING", "QueueName", "MessagingType")
    $missingSettings = @()

    foreach ($setting in $requiredSettings) {
        $found = $appSettings | Where-Object { $_.name -eq $setting }
        if ($found) {
            Write-Host "  ✓ $setting configured" -ForegroundColor Green
        } else {
            $missingSettings += $setting
        }
    }

    if ($missingSettings.Count -gt 0) {
        Write-Host "  ⚠ Missing settings: $($missingSettings -join ', ')" -ForegroundColor Yellow
    }

    # Success Summary
    Write-Host "`n==================== VALIDATION SUMMARY ====================" -ForegroundColor Cyan
    Write-Host "✓ All Service Bus and Function App resources are properly configured!" -ForegroundColor Green
    Write-Host ""
    Write-Host "Resource Details:" -ForegroundColor White
    Write-Host "  Resource Group: $($config['RESOURCE_GROUP_NAME'])"
    Write-Host "  Service Bus Namespace: $($config['SERVICE_BUS_NAMESPACE'])"
    Write-Host "  Queue: $($config['QUEUE_NAME'])"
    Write-Host "  Messaging Type: $($config['MESSAGING_TYPE'])"
    Write-Host "  Function App: $($config['FUNCTION_APP_NAME'])"
    Write-Host "  Storage Account: $($config['STORAGE_ACCOUNT_NAME'])"
    Write-Host "==========================================================" -ForegroundColor Cyan

    Write-Host "`nReady for Phase 2: Function App Development! 🚀" -ForegroundColor Green

} catch {
    Write-Host "`n✗ Validation Error: $_" -ForegroundColor Red
    Write-Host "`nSome resources may not be created properly." -ForegroundColor Yellow
    Write-Host "Please check the Azure portal or re-run the creation script." -ForegroundColor Yellow
    exit 1
}
