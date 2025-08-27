#!/bin/bash

# Azure Resource Creation Script for .NET API POC
# This script creates all necessary Azure resources for hosting a .NET API with monitoring

# Configuration Variables
RESOURCE_GROUP_NAME="rg-netapi-poc"
LOCATION="East US"
APP_SERVICE_PLAN_NAME="plan-netapi-poc"
WEB_APP_NAME="webapp-netapi-poc-$(date +%s)"  # Adding timestamp to ensure uniqueness
APP_INSIGHTS_NAME="ai-netapi-poc"
SKU="F1"  # Free tier for POC

echo "Starting Azure resource creation..."
echo "Resource Group: $RESOURCE_GROUP_NAME"
echo "Location: $LOCATION"
echo "Web App Name: $WEB_APP_NAME"

# Step 1: Create Resource Group
echo "Creating resource group..."
az group create \
    --name $RESOURCE_GROUP_NAME \
    --location "$LOCATION"

if [ $? -eq 0 ]; then
    echo "✓ Resource group created successfully"
else
    echo "✗ Failed to create resource group"
    exit 1
fi

# Step 2: Create App Service Plan
echo "Creating App Service Plan..."
az appservice plan create \
    --name $APP_SERVICE_PLAN_NAME \
    --resource-group $RESOURCE_GROUP_NAME \
    --sku $SKU \
    --is-linux false

if [ $? -eq 0 ]; then
    echo "✓ App Service Plan created successfully"
else
    echo "✗ Failed to create App Service Plan"
    exit 1
fi

# Step 3: Create Web App
echo "Creating Web App..."
az webapp create \
    --name $WEB_APP_NAME \
    --resource-group $RESOURCE_GROUP_NAME \
    --plan $APP_SERVICE_PLAN_NAME \
    --runtime "DOTNET|8.0"

if [ $? -eq 0 ]; then
    echo "✓ Web App created successfully"
else
    echo "✗ Failed to create Web App"
    exit 1
fi

# Step 4: Create Application Insights
echo "Creating Application Insights..."
az monitor app-insights component create \
    --app $APP_INSIGHTS_NAME \
    --location "$LOCATION" \
    --resource-group $RESOURCE_GROUP_NAME \
    --kind web \
    --application-type web

if [ $? -eq 0 ]; then
    echo "✓ Application Insights created successfully"
else
    echo "✗ Failed to create Application Insights"
    exit 1
fi

# Step 5: Get Application Insights Connection String
echo "Retrieving Application Insights connection string..."
AI_CONNECTION_STRING=$(az monitor app-insights component show \
    --app $APP_INSIGHTS_NAME \
    --resource-group $RESOURCE_GROUP_NAME \
    --query connectionString \
    --output tsv)

if [ -n "$AI_CONNECTION_STRING" ]; then
    echo "✓ Application Insights connection string retrieved"
else
    echo "✗ Failed to retrieve Application Insights connection string"
    exit 1
fi

# Step 6: Configure Web App with Application Insights
echo "Configuring Web App with Application Insights..."
az webapp config appsettings set \
    --name $WEB_APP_NAME \
    --resource-group $RESOURCE_GROUP_NAME \
    --settings "APPLICATIONINSIGHTS_CONNECTION_STRING=$AI_CONNECTION_STRING"

if [ $? -eq 0 ]; then
    echo "✓ Web App configured with Application Insights"
else
    echo "✗ Failed to configure Web App with Application Insights"
    exit 1
fi

# Step 7: Enable Application Insights for the Web App
echo "Enabling Application Insights integration..."
az webapp config appsettings set \
    --name $WEB_APP_NAME \
    --resource-group $RESOURCE_GROUP_NAME \
    --settings "APPINSIGHTS_INSTRUMENTATIONKEY=$(az monitor app-insights component show --app $APP_INSIGHTS_NAME --resource-group $RESOURCE_GROUP_NAME --query instrumentationKey --output tsv)"

if [ $? -eq 0 ]; then
    echo "✓ Application Insights integration enabled"
else
    echo "✗ Failed to enable Application Insights integration"
fi

# Display summary
echo ""
echo "==================== DEPLOYMENT SUMMARY ===================="
echo "Resource Group: $RESOURCE_GROUP_NAME"
echo "App Service Plan: $APP_SERVICE_PLAN_NAME"
echo "Web App: $WEB_APP_NAME"
echo "Web App URL: https://$WEB_APP_NAME.azurewebsites.net"
echo "Application Insights: $APP_INSIGHTS_NAME"
echo "Location: $LOCATION"
echo "=========================================================="
echo ""
echo "All Azure resources have been created successfully!"
echo "Next steps:"
echo "1. Create your .NET API application"
echo "2. Set up GitHub Actions for CI/CD"
echo "3. Deploy your application"

# Save important values to a file for later use
echo "RESOURCE_GROUP_NAME=$RESOURCE_GROUP_NAME" > azure-config.env
echo "WEB_APP_NAME=$WEB_APP_NAME" >> azure-config.env
echo "APP_INSIGHTS_NAME=$APP_INSIGHTS_NAME" >> azure-config.env
echo "AI_CONNECTION_STRING=$AI_CONNECTION_STRING" >> azure-config.env
echo "WEB_APP_URL=https://$WEB_APP_NAME.azurewebsites.net" >> azure-config.env

echo "Configuration saved to azure-config.env"
