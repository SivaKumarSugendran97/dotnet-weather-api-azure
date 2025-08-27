# Phase 3: GitHub Actions CI/CD Setup & Deployment Guide

## 🎯 Objective
Set up automated deployment from GitHub to Azure App Service using GitHub Actions.

## 📋 Step 1: Set up GitHub Secrets

You need to add the Azure publish profile as a secret in your GitHub repository:

### 1.1 Get Publish Profile
The publish profile has been retrieved from Azure. You'll need to:

1. Go to [Azure Portal](https://portal.azure.com)
2. Navigate to your App Service: `webapp-netapi-poc-1756280788`
3. Click **"Get publish profile"** to download the `.publishsettings` file
4. Open the file and copy its entire contents

### 1.2 Add GitHub Secret
1. Go to your GitHub repository: `https://github.com/SivaKumarSugendran97/dotnet-weather-api-azure`
2. Click **Settings** tab
3. Click **Secrets and variables** → **Actions**
4. Click **New repository secret**
5. Add the following secret:
   - **Name**: `AZURE_WEBAPP_PUBLISH_PROFILE`
   - **Value**: [Paste the entire contents of the .publishsettings file]

## 📋 Step 2: Update GitHub Actions Workflow

The workflow file `.github/workflows/deploy.yml` is already created and ready to use. It will:
- ✅ Build the .NET application
- ✅ Run tests (if any)
- ✅ Deploy to Azure App Service
- ✅ Only deploy on pushes to main branch

## 📋 Step 3: Configure Application Insights

Run this script to configure Application Insights in Azure:

```powershell
.\scripts\configure-app-insights.ps1
```

## 📋 Step 4: Test the Deployment

### Option A: Trigger via Git Push
1. Make a small change to your code
2. Commit and push to main branch
3. GitHub Actions will automatically deploy

### Option B: Manual Deploy using Script
```powershell
.\scripts\deploy-api.ps1
```

## 📋 Step 5: Verify Deployment

After deployment, test your endpoints:

1. **Web App URL**: https://webapp-netapi-poc-1756280788.azurewebsites.net
2. **Health Check**: https://webapp-netapi-poc-1756280788.azurewebsites.net/health
3. **Weather API**: https://webapp-netapi-poc-1756280788.azurewebsites.net/weatherforecast
4. **Swagger UI**: https://webapp-netapi-poc-1756280788.azurewebsites.net/swagger

### Test Script
```powershell
.\scripts\test-api.ps1
```

## 📋 Step 6: Monitor with Application Insights

1. Go to [Azure Portal](https://portal.azure.com)
2. Navigate to Application Insights: `ai-netapi-poc`
3. Check **Live Metrics** for real-time monitoring
4. View **Logs** to see your custom telemetry

## 🔧 Troubleshooting

### If GitHub Actions Fails:
- Check that `AZURE_WEBAPP_PUBLISH_PROFILE` secret is correctly set
- Verify the workflow file has correct app name
- Check Azure App Service logs in the portal

### If Application Insights Not Working:
- Verify connection string is set in App Service settings
- Check that the NuGet package is installed
- Ensure telemetry is being sent in application logs

## 📊 What You'll Have After Phase 3

- ✅ Automated CI/CD pipeline from GitHub to Azure
- ✅ Application Insights monitoring with custom telemetry
- ✅ Production-ready .NET API hosted on Azure
- ✅ Health checks and API documentation
- ✅ Complete DevOps workflow

---

## 🚀 Ready to Execute?

Let me know when you're ready to proceed with each step, and I'll help you through the process!
