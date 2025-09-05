# Azure Service Bus and Function App Creation Script (Updated for Basic Tier)
# This script extends the existing infrastructure with Service Bus and Azure Functions
# Uses Service Bus Queue instead of Topic/Subscription for Visual Studio subscriptions

param(
    [string]$ResourceGroupName = "rg-netapi-poc-new",
    [string]$Location = "Central US",
    [string]$ServiceBusNamespace = "sb-netapi-poc-$([DateTimeOffset]::UtcNow.ToUnixTimeSeconds())",
    [string]$QueueName = "weather-updates-queue",
    [string]$FunctionAppName = "func-netapi-poc-$([DateTimeOffset]::UtcNow.ToUnixTimeSeconds())",
    [string]$StorageAccountName = "stnetapipoc$([DateTimeOffset]::UtcNow.ToUnixTimeSeconds())",
    [string]$AppInsightsName = "ai-netapi-poc",
    [switch]$UseStandardTier = $false  # Set to $true if you want to use Topics/Subscriptions
)

# Azure CLI path
$azPath = "C:\Program Files\Microsoft SDKs\Azure\CLI2\wbin\az.cmd"

if ($UseStandardTier) {
    $serviceBusSku = "Standard"
    $messagingType = "Topic/Subscription"
    Write-Host "Using Standard tier for Topics and Subscriptions" -ForegroundColor Cyan
} else {
    $serviceBusSku = "Basic"
    $messagingType = "Queue"
    Write-Host "Using Basic tier with Queue (more cost-effective)" -ForegroundColor Cyan
}

Write-Host "Starting Service Bus and Function App resource creation..." -ForegroundColor Green
Write-Host "Resource Group: $ResourceGroupName"
Write-Host "Location: $Location"
Write-Host "Service Bus Namespace: $ServiceBusNamespace"
Write-Host "Service Bus SKU: $serviceBusSku"
Write-Host "Messaging Type: $messagingType"
Write-Host "Function App: $FunctionAppName"

try {
    # Verify resource group exists
    Write-Host "`nVerifying resource group exists..." -ForegroundColor Yellow
    $rgExists = & $azPath group exists --name $ResourceGroupName
    
    if ($rgExists -eq "false") {
        Write-Host "Creating resource group..." -ForegroundColor Yellow
        & $azPath group create --name $ResourceGroupName --location $Location
        if ($LASTEXITCODE -ne 0) { throw "Failed to create resource group" }
    }
    Write-Host "✓ Resource group verified" -ForegroundColor Green

    # Step 1: Create Storage Account for Function App (if not exists)
    Write-Host "`nChecking Storage Account for Function App..." -ForegroundColor Yellow
    $storageExists = & $azPath storage account show --name $StorageAccountName --resource-group $ResourceGroupName --query "name" --output tsv 2>$null
    
    if (-not $storageExists) {
        Write-Host "Creating Storage Account for Function App..." -ForegroundColor Yellow
        & $azPath storage account create `
            --name $StorageAccountName `
            --resource-group $ResourceGroupName `
            --location $Location `
            --sku Standard_LRS `
            --kind StorageV2

        if ($LASTEXITCODE -eq 0) {
            Write-Host "✓ Storage Account created successfully" -ForegroundColor Green
        } else {
            throw "Failed to create Storage Account"
        }
    } else {
        Write-Host "✓ Storage Account already exists" -ForegroundColor Green
    }

    # Step 2: Create Service Bus Namespace
    Write-Host "`nCreating Service Bus Namespace..." -ForegroundColor Yellow
    & $azPath servicebus namespace create `
        --name $ServiceBusNamespace `
        --resource-group $ResourceGroupName `
        --location $Location `
        --sku $serviceBusSku

    if ($LASTEXITCODE -eq 0) {
        Write-Host "✓ Service Bus Namespace created successfully" -ForegroundColor Green
    } else {
        throw "Failed to create Service Bus Namespace"
    }

    # Step 3: Create Service Bus Queue OR Topic/Subscription based on tier
    if ($UseStandardTier) {
        # Create Topic and Subscription (Standard tier)
        $TopicName = "weather-updates"
        $SubscriptionName = "processing-subscription"
        
        Write-Host "`nCreating Service Bus Topic..." -ForegroundColor Yellow
        & $azPath servicebus topic create `
            --name $TopicName `
            --namespace-name $ServiceBusNamespace `
            --resource-group $ResourceGroupName

        if ($LASTEXITCODE -eq 0) {
            Write-Host "✓ Service Bus Topic created successfully" -ForegroundColor Green
        } else {
            throw "Failed to create Service Bus Topic"
        }

        Write-Host "`nCreating Service Bus Subscription..." -ForegroundColor Yellow
        & $azPath servicebus topic subscription create `
            --name $SubscriptionName `
            --topic-name $TopicName `
            --namespace-name $ServiceBusNamespace `
            --resource-group $ResourceGroupName

        if ($LASTEXITCODE -eq 0) {
            Write-Host "✓ Service Bus Subscription created successfully" -ForegroundColor Green
        } else {
            throw "Failed to create Service Bus Subscription"
        }
        
        $messagingEntity = "Topic: $TopicName, Subscription: $SubscriptionName"
    } else {
        # Create Queue (Basic tier)
        Write-Host "`nCreating Service Bus Queue..." -ForegroundColor Yellow
        & $azPath servicebus queue create `
            --name $QueueName `
            --namespace-name $ServiceBusNamespace `
            --resource-group $ResourceGroupName

        if ($LASTEXITCODE -eq 0) {
            Write-Host "✓ Service Bus Queue created successfully" -ForegroundColor Green
        } else {
            throw "Failed to create Service Bus Queue"
        }
        
        $messagingEntity = "Queue: $QueueName"
    }

    # Step 4: Get Service Bus Connection String
    Write-Host "`nRetrieving Service Bus connection string..." -ForegroundColor Yellow
    $serviceBusConnectionString = & $azPath servicebus namespace authorization-rule keys list `
        --namespace-name $ServiceBusNamespace `
        --resource-group $ResourceGroupName `
        --name RootManageSharedAccessKey `
        --query primaryConnectionString `
        --output tsv

    if ($serviceBusConnectionString) {
        Write-Host "✓ Service Bus connection string retrieved" -ForegroundColor Green
    } else {
        throw "Failed to retrieve Service Bus connection string"
    }

    # Step 5: Get Application Insights Connection String (if exists)
    Write-Host "`nRetrieving Application Insights connection string..." -ForegroundColor Yellow
    $aiConnectionString = & $azPath monitor app-insights component show `
        --app $AppInsightsName `
        --resource-group $ResourceGroupName `
        --query connectionString `
        --output tsv 2>$null

    if (-not $aiConnectionString) {
        Write-Host "Application Insights not found, creating new one..." -ForegroundColor Yellow
        & $azPath monitor app-insights component create `
            --app $AppInsightsName `
            --location $Location `
            --resource-group $ResourceGroupName `
            --kind web `
            --application-type web

        $aiConnectionString = & $azPath monitor app-insights component show `
            --app $AppInsightsName `
            --resource-group $ResourceGroupName `
            --query connectionString `
            --output tsv
    }

    # Step 6: Create Function App (Consumption plan - pay per execution)
    Write-Host "`nCreating Function App..." -ForegroundColor Yellow
    & $azPath functionapp create `
        --name $FunctionAppName `
        --resource-group $ResourceGroupName `
        --storage-account $StorageAccountName `
        --consumption-plan-location $Location `
        --runtime dotnet-isolated `
        --runtime-version 8 `
        --functions-version 4

    if ($LASTEXITCODE -eq 0) {
        Write-Host "✓ Function App created successfully" -ForegroundColor Green
    } else {
        throw "Failed to create Function App"
    }

    # Step 7: Configure Function App Settings
    Write-Host "`nConfiguring Function App settings..." -ForegroundColor Yellow
    
    if ($UseStandardTier) {
        $settings = @(
            "ServiceBusConnectionString=$serviceBusConnectionString"
            "APPLICATIONINSIGHTS_CONNECTION_STRING=$aiConnectionString"
            "TopicName=$TopicName"
            "SubscriptionName=$SubscriptionName"
            "MessagingType=Topic"
        )
    } else {
        $settings = @(
            "ServiceBusConnectionString=$serviceBusConnectionString"
            "APPLICATIONINSIGHTS_CONNECTION_STRING=$aiConnectionString"
            "QueueName=$QueueName"
            "MessagingType=Queue"
        )
    }

    & $azPath functionapp config appsettings set `
        --name $FunctionAppName `
        --resource-group $ResourceGroupName `
        --settings $settings

    if ($LASTEXITCODE -eq 0) {
        Write-Host "✓ Function App configured successfully" -ForegroundColor Green
    } else {
        throw "Failed to configure Function App"
    }

    # Display summary
    Write-Host "`n==================== SERVICE BUS & FUNCTIONS DEPLOYMENT SUMMARY ====================" -ForegroundColor Cyan
    Write-Host "Resource Group: $ResourceGroupName"
    Write-Host "Service Bus Namespace: $ServiceBusNamespace"
    Write-Host "Service Bus SKU: $serviceBusSku"
    Write-Host "Messaging Entity: $messagingEntity"
    Write-Host "Function App: $FunctionAppName"
    Write-Host "Function App URL: https://$FunctionAppName.azurewebsites.net"
    Write-Host "Storage Account: $StorageAccountName"
    Write-Host "Location: $Location"
    Write-Host "===================================================================================" -ForegroundColor Cyan
    Write-Host "`nAll Service Bus and Function App resources created successfully!" -ForegroundColor Green

    # Load existing config and append new values
    $existingConfig = ""
    if (Test-Path "azure-config.env") {
        $existingConfig = Get-Content "azure-config.env" -Raw
    }

    # Append new configuration
    if ($UseStandardTier) {
        $newConfig = @"
SERVICE_BUS_NAMESPACE=$ServiceBusNamespace
SERVICE_BUS_CONNECTION_STRING=$serviceBusConnectionString
SERVICE_BUS_SKU=$serviceBusSku
TOPIC_NAME=$TopicName
SUBSCRIPTION_NAME=$SubscriptionName
MESSAGING_TYPE=Topic
FUNCTION_APP_NAME=$FunctionAppName
FUNCTION_APP_URL=https://$FunctionAppName.azurewebsites.net
STORAGE_ACCOUNT_NAME=$StorageAccountName
"@
    } else {
        $newConfig = @"
SERVICE_BUS_NAMESPACE=$ServiceBusNamespace
SERVICE_BUS_CONNECTION_STRING=$serviceBusConnectionString
SERVICE_BUS_SKU=$serviceBusSku
QUEUE_NAME=$QueueName
MESSAGING_TYPE=Queue
FUNCTION_APP_NAME=$FunctionAppName
FUNCTION_APP_URL=https://$FunctionAppName.azurewebsites.net
STORAGE_ACCOUNT_NAME=$StorageAccountName
"@
    }

    # Combine existing and new config
    $fullConfig = $existingConfig + "`n" + $newConfig
    $fullConfig | Out-File -FilePath "azure-config.env" -Encoding UTF8
    Write-Host "`nConfiguration updated in azure-config.env" -ForegroundColor Green

    Write-Host "`nNext steps:" -ForegroundColor Yellow
    Write-Host "1. Create Azure Function App project"
    Write-Host "2. Implement publisher and consumer functions"
    Write-Host "3. Update GitHub Actions for Function App deployment"
    Write-Host "4. Test message publishing and consumption"

    Write-Host "`n💡 Cost-effective setup complete!" -ForegroundColor Cyan
    Write-Host "   Using Service Bus $serviceBusSku tier with $messagingType" -ForegroundColor Cyan
    Write-Host "   Function App on Consumption plan (pay-per-execution)" -ForegroundColor Cyan

} catch {
    Write-Host "`n✗ Error: $_" -ForegroundColor Red
    Write-Host "Please check your Azure CLI login and permissions." -ForegroundColor Yellow
    
    # Show some troubleshooting info
    Write-Host "`nTroubleshooting information:" -ForegroundColor Yellow
    Write-Host "- Ensure you're logged into Azure CLI: az login"
    Write-Host "- Check your subscription: az account show"
    Write-Host "- Verify you have Contributor access to the resource group"
    Write-Host "- For Visual Studio subscriptions, ensure you're within spending limits"
    Write-Host "- Basic tier supports Queues only; Standard tier supports Topics/Subscriptions"
    
    exit 1
}

Write-Host "`n🎉 Phase 1 Complete! Service Bus and Function App infrastructure is ready." -ForegroundColor Green
Write-Host "💡 All resources use cost-effective tiers suitable for Visual Studio subscriptions." -ForegroundColor Cyan
