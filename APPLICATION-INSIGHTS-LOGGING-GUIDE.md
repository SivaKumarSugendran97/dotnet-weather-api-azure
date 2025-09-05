# 📊 Application Insights Logging Guide

## 🎯 Your Logging Code
```csharp
logger.LogInformation("Weather forecast requested at {RequestTime}", DateTime.UtcNow);
```

This creates **structured logs** that are sent to Application Insights with telemetry data.

---

## 🔍 **How to View Your Logs in Azure**

### **Step 1: Access Application Insights**
1. Go to **Azure Portal**: https://portal.azure.com
2. Search for "Application Insights" or navigate to **All Resources**
3. Click on **`ai-netapi-poc`** (your Application Insights resource)

### **Step 2: View Logs (Multiple Options)**

#### **📈 Option A: Logs (KQL Query) - RECOMMENDED**
1. Click **"Logs"** in the left navigation menu
2. Use this query to see your weather forecast logs:

```kusto
traces
| where message contains "Weather forecast requested"
| project timestamp, message, severityLevel, operation_Name, cloud_RoleName
| order by timestamp desc
| take 50
```

3. **Advanced Query for All Your Custom Logs:**
```kusto
traces
| where message contains "Weather forecast requested" or message contains "Health check requested" or message contains "Generated"
| project timestamp, message, severityLevel, operation_Name, customDimensions
| order by timestamp desc
| take 100
```

#### **⚡ Option B: Live Metrics**
1. Click **"Live Metrics"** in left menu
2. Make requests to your API: http://webapp-netapi-poc-1756280788.azurewebsites.net/weatherforecast
3. **Watch logs appear in real-time!**

#### **🔍 Option C: Transaction Search**
1. Click **"Transaction search"** in left menu
2. Set **Event types** to "Trace"
3. Search for: `"Weather forecast requested"`
4. Filter by time range (last hour, day, etc.)

#### **📊 Option D: Application Map**
1. Click **"Application Map"** to see request flow
2. Click on your application node to see performance metrics

---

## 🎯 **What You'll See in the Logs**

### **Log Entry Example:**
```json
{
  "timestamp": "2025-08-27T09:20:23.386Z",
  "message": "Weather forecast requested at 08/27/2025 09:20:23",
  "severityLevel": "Information",
  "operation_Name": "GET /weatherforecast",
  "cloud_RoleName": "webapp-netapi-poc-1756280788",
  "customDimensions": {
    "RequestTime": "2025-08-27T09:20:23.3861194Z"
  }
}
```

### **What Each Field Means:**
- **timestamp**: When the log was created
- **message**: Your custom log message
- **severityLevel**: Information, Warning, Error, etc.
- **operation_Name**: HTTP method and endpoint
- **cloud_RoleName**: Your Azure App Service name
- **customDimensions**: Structured data from your {RequestTime} parameter

---

## 🔥 **Advanced Queries for Your Logs**

### **1. Count Requests by Hour**
```kusto
traces
| where message contains "Weather forecast requested"
| summarize RequestCount = count() by bin(timestamp, 1h)
| order by timestamp desc
```

### **2. Recent API Activity**
```kusto
requests
| where name == "GET /weatherforecast"
| project timestamp, duration, resultCode, url
| order by timestamp desc
| take 20
```

### **3. Performance Analysis**
```kusto
requests
| where name == "GET /weatherforecast"
| summarize 
    AvgDuration = avg(duration),
    MaxDuration = max(duration),
    RequestCount = count()
by bin(timestamp, 5m)
| order by timestamp desc
```

### **4. Error Tracking**
```kusto
traces
| where severityLevel >= 3  // Warning and above
| project timestamp, message, severityLevel, operation_Name
| order by timestamp desc
```

---

## 📱 **Quick Access Links**

### **Direct Azure Portal Links:**
1. **Application Insights Overview**: 
   - Go to: Azure Portal → All Resources → `ai-netapi-poc`

2. **Live Metrics (Real-time)**:
   - Application Insights → Monitoring → Live Metrics

3. **Logs (KQL Queries)**:
   - Application Insights → Monitoring → Logs

4. **Transaction Search**:
   - Application Insights → Investigate → Transaction search

---

## 🎯 **Pro Tips**

### **Real-time Monitoring:**
1. Keep **Live Metrics** open in a browser tab
2. Make API requests to see immediate feedback
3. Watch for request counts, response times, and dependencies

### **Alerting Setup:**
1. Go to **Alerts** in Application Insights
2. Create alert rules for:
   - High error rates
   - Slow response times
   - Low availability

### **Custom Dashboards:**
1. Create **Azure Dashboard** with your most important metrics
2. Pin charts from Application Insights to the dashboard
3. Share with your team

---

## 🎊 **Test Your Logging Right Now!**

1. **Make some API calls**:
   ```
   http://webapp-netapi-poc-1756280788.azurewebsites.net/weatherforecast
   http://webapp-netapi-poc-1756280788.azurewebsites.net/health
   ```

2. **Wait 2-3 minutes** for data to appear

3. **Run this query in Application Insights Logs**:
   ```kusto
   traces
   | where timestamp > ago(10m)
   | where message contains "Weather forecast requested"
   | order by timestamp desc
   ```

4. **You should see your logs with timestamps!** 🎯

---

## 📊 **Your Application Insights Details**
- **Resource Name**: `ai-netapi-poc`
- **Instrumentation Key**: `4dd21a16-45a4-492a-8016-342c7c4c5b4f`
- **Connection String**: Configured in App Service settings
- **Location**: Central US
- **Status**: ✅ Active and receiving telemetry
