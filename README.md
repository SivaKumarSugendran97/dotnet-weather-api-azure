# Azure .NET API POC Deployment Project

This project contains scripts and configurations for deploying a .NET API to Azure App Service with Application Insights monitoring and GitHub Actions CI/CD.

## Prerequisites

- Azure CLI installed and configured
- Azure subscription with available credits
- PowerShell (for Windows) or Bash (for Linux/Mac)
- .NET 8.0 SDK (for the API development phase)

### Installing Azure CLI

**For Windows:**
```powershell
# Option 1: Using winget
winget install -e --id Microsoft.AzureCLI

# Option 2: Using PowerShell (run as administrator)
Invoke-WebRequest -Uri https://aka.ms/installazurecliwindows -OutFile .\AzureCLI.msi; Start-Process msiexec.exe -Wait -ArgumentList '/I AzureCLI.msi /quiet'; rm .\AzureCLI.msi
```

**For Mac:**
```bash
brew install azure-cli
```

**For Linux:**
```bash
curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash
```

After installation, restart your terminal or PowerShell window.

## Phase 1: Azure Resource Creation

### Step 1: Login to Azure
```powershell
az login
```

### Step 2: Run the Resource Creation Script

**For Windows (PowerShell):**
```powershell
.\scripts\create-azure-resources.ps1
```

**For Linux/Mac (Bash):**
```bash
chmod +x scripts/create-azure-resources.sh
./scripts/create-azure-resources.sh
```

### What the Script Creates

1. **Resource Group**: `rg-netapi-poc`
2. **App Service Plan**: `plan-netapi-poc` (F1 - Free tier)
3. **Web App**: `webapp-netapi-poc-[timestamp]` (with .NET 8.0 runtime)
4. **Application Insights**: `ai-netapi-poc` (for monitoring)

### Configuration

The script automatically:
- Configures the Web App with Application Insights connection string
- Sets up the instrumentation key
- Saves configuration to `azure-config.env` file

### Customization

You can customize the script parameters:

```powershell
.\scripts\create-azure-resources.ps1 -ResourceGroupName "my-custom-rg" -Location "West US 2"
```

## Phase 2: .NET API Development (Coming Next)

- Create ASP.NET Core Web API project
- Add Application Insights SDK
- Configure logging and telemetry
- Add sample endpoints

## Phase 3: GitHub Actions CI/CD (Coming Next)

- Set up GitHub repository
- Configure GitHub secrets
- Create workflow for automated deployment

## Cleanup

To remove all Azure resources:

```powershell
.\scripts\cleanup-azure-resources.ps1
```

## Cost Considerations

- **App Service Plan (F1)**: Free tier - no cost
- **Application Insights**: 5GB free per month, then pay-per-use
- All resources are designed for POC/development use

## Next Steps

After running the resource creation script:

1. Note the Web App URL from the output
2. Save the `azure-config.env` file - you'll need it for deployment
3. Proceed to create the .NET API application

## Troubleshooting

### Common Issues

1. **Login Issues**: Ensure `az login` was successful and you have the correct subscription selected
2. **Permission Issues**: Verify you have Contributor access to the subscription
3. **Naming Conflicts**: Web app names must be globally unique (script adds timestamp to avoid this)

### Useful Commands

Check your current Azure subscription:
```bash
az account show
```

List all resource groups:
```bash
az group list --output table
```

Check if resources were created:
```bash
az resource list --resource-group rg-netapi-poc --output table
```

## File Structure

```
Azure/
├── scripts/
│   ├── create-azure-resources.ps1    # PowerShell script for Windows
│   ├── create-azure-resources.sh     # Bash script for Linux/Mac
│   └── cleanup-azure-resources.ps1   # Cleanup script
├── azure-config.env                  # Generated configuration file
└── README.md                         # This file
```
# GitHub Actions deployment test
