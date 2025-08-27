# Azure Resource Cleanup Script
# This script removes all resources created for the .NET API POC

param(
    [string]$ResourceGroupName = "rg-netapi-poc",
    [switch]$Force = $false
)

Write-Host "Azure Resource Cleanup Script" -ForegroundColor Red
Write-Host "This will delete the entire resource group: $ResourceGroupName" -ForegroundColor Yellow

if (-not $Force) {
    $confirmation = Read-Host "Are you sure you want to delete all resources? (yes/no)"
    if ($confirmation -ne "yes") {
        Write-Host "Cleanup cancelled." -ForegroundColor Yellow
        exit 0
    }
}

try {
    Write-Host "`nDeleting resource group: $ResourceGroupName..." -ForegroundColor Yellow
    
    az group delete --name $ResourceGroupName --yes --no-wait
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host "✓ Resource group deletion initiated successfully" -ForegroundColor Green
        Write-Host "Note: Deletion is running in the background and may take a few minutes to complete." -ForegroundColor Yellow
        
        # Remove the config file if it exists
        if (Test-Path "azure-config.env") {
            Remove-Item "azure-config.env"
            Write-Host "✓ Configuration file removed" -ForegroundColor Green
        }
    } else {
        throw "Failed to delete resource group"
    }

} catch {
    Write-Host "`n✗ Error: $_" -ForegroundColor Red
    Write-Host "Please check your Azure CLI login and permissions." -ForegroundColor Yellow
    exit 1
}
