# 🚀 Demo Commands Cheat Sheet

Quick reference for all commands needed during the demo. Copy-paste ready!

---

## 🏁 Pre-Demo Setup

### 1. Start Backend Server
```powershell
cd C:\Users\aakib\PrimusSaaS.TestApp\PrimusSaaS.TestApp
dotnet restore
dotnet run
```

**Expected Output:**
```
info: Microsoft.Hosting.Lifetime[14]
      Now listening on: http://localhost:5001
info: Microsoft.Hosting.Lifetime[0]
      Application started. Press Ctrl+C to shut down.
```

---

### 2. Start Frontend Server
```powershell
cd C:\Users\aakib\PrimusSaaS.TestApp\PrimusSaaS.TestApp\primus-frontend
npm install
npm start
```

**Expected Output:**
```
** Angular Live Development Server is listening on localhost:4200 **
✔ Compiled successfully.
```

---

### 3. Monitor Logs in Real-Time
```powershell
cd C:\Users\aakib\PrimusSaaS.TestApp\PrimusSaaS.TestApp
Get-Content logs\primus-app.log -Wait -Tail 20
```

---

## 🧪 API Testing Commands

### Test 1: Public Endpoint (No Auth Required)
```powershell
Invoke-RestMethod -Uri "http://localhost:5001/api/secure/public" -Method GET
```

**Expected Response:**
```json
{
  "message": "This is a public endpoint",
  "timestamp": "2025-11-25T09:00:00Z"
}
```

---

### Test 2: Generate JWT Token
```powershell
$body = @{
    userId = "test-user-123"
    email = "john.doe@example.com"
    name = "John Doe"
    roles = @("User", "Admin")
    tenantId = "tenant-acme-corp"
} | ConvertTo-Json

$response = Invoke-RestMethod -Uri "http://localhost:5001/api/token/generate" `
    -Method POST `
    -ContentType "application/json" `
    -Body $body

$token = $response.token
Write-Host "Token: $token"
```

**Save the token for next tests!**

---

### Test 3: Protected Endpoint (With Token)
```powershell
$headers = @{
    "Authorization" = "Bearer $token"
}

Invoke-RestMethod -Uri "http://localhost:5001/api/secure/protected" `
    -Method GET `
    -Headers $headers
```

**Expected Response:**
```json
{
  "message": "This is protected data",
  "user": {
    "userId": "test-user-123",
    "email": "john.doe@example.com",
    "name": "John Doe",
    "roles": ["User", "Admin"],
    "tenantId": "tenant-acme-corp"
  }
}
```

---

### Test 4: Admin Endpoint (Requires Admin Role)
```powershell
Invoke-RestMethod -Uri "http://localhost:5001/api/secure/admin" `
    -Method GET `
    -Headers $headers
```

**Expected Response:**
```json
{
  "message": "Admin access granted",
  "user": {
    "userId": "test-user-123",
    "roles": ["User", "Admin"]
  }
}
```

---

### Test 5: User Details
```powershell
Invoke-RestMethod -Uri "http://localhost:5001/api/secure/user-details" `
    -Method GET `
    -Headers $headers
```

---

## 📊 Diagnostics Endpoints

### Identity Validator Diagnostics
```powershell
Invoke-RestMethod -Uri "http://localhost:5001/primus/diagnostics" -Method GET | ConvertTo-Json -Depth 10
```

**Expected Response:**
```json
{
  "issuers": [
    {
      "name": "LocalAuth",
      "type": "Jwt",
      "status": "Healthy",
      "issuer": "https://localhost:5001",
      "audiences": ["api://primus-test-app"]
    },
    {
      "name": "AzureAD",
      "type": "AzureAD",
      "status": "Healthy",
      "authority": "https://login.microsoftonline.com/...",
      "jwksLastFetched": "2025-11-25T08:30:00Z"
    }
  ],
  "timestamp": "2025-11-25T09:00:00Z"
}
```

---

### Logging Metrics
```powershell
Invoke-RestMethod -Uri "http://localhost:5001/primus/logging/metrics" -Method GET | ConvertTo-Json -Depth 10
```

**Expected Response:**
```json
{
  "totalLogs": 1523,
  "logsByLevel": {
    "debug": 450,
    "info": 890,
    "warning": 120,
    "error": 63,
    "critical": 0
  },
  "writeFailures": 0,
  "avgWriteTimeMs": 2.3,
  "bufferUtilization": 0.15
}
```

---

### Logging Health
```powershell
Invoke-RestMethod -Uri "http://localhost:5001/primus/logging/health" -Method GET | ConvertTo-Json -Depth 10
```

---

## 🔒 Logging Feature Tests

### Test All Log Levels
```powershell
Invoke-RestMethod -Uri "http://localhost:5001/api/loggingtest/test-all-levels" -Method GET
```

---

### Test Structured Logging
```powershell
Invoke-RestMethod -Uri "http://localhost:5001/api/loggingtest/test-structured-logging" -Method GET
```

---

### Test PII Masking (THE WOW MOMENT!)
```powershell
$piiData = @{
    email = "john.doe@example.com"
    ssn = "123-45-6789"
    creditCard = "4532-1234-5678-9010"
    password = "SuperSecret123!"
    apiKey = "sk_live_1234567890abcdef"
} | ConvertTo-Json

Invoke-RestMethod -Uri "http://localhost:5001/api/loggingtest/test-pii-masking" `
    -Method POST `
    -ContentType "application/json" `
    -Body $piiData
```

**Then show the log file:**
```powershell
Get-Content logs\primus-app.log -Tail 10
```

**You'll see masked data:**
```json
{
  "level": "INFO",
  "message": "PII data received",
  "data": {
    "email": "j***@example.com",
    "ssn": "***-**-6789",
    "creditCard": "****-****-****-9010",
    "password": "***",
    "apiKey": "***"
  }
}
```

---

### Test Correlation ID
```powershell
Invoke-RestMethod -Uri "http://localhost:5001/api/loggingtest/test-correlation-id" -Method GET
```

---

### Test Exception Logging
```powershell
Invoke-RestMethod -Uri "http://localhost:5001/api/loggingtest/test-exception" -Method GET
```

---

### Test Performance Timing
```powershell
Invoke-RestMethod -Uri "http://localhost:5001/api/loggingtest/test-performance-timing" -Method GET
```

---

## 🎭 Demo Scenarios

### Scenario 1: Email/Password Login (Frontend)
1. Navigate to `http://localhost:4200`
2. Enter email: `admin@claimportal.com`
3. Enter password: `password`
4. Click "Sign In"
5. Observe redirect to dashboard

---

### Scenario 2: Azure AD Login (Frontend)
1. Navigate to `http://localhost:4200`
2. Click "Azure AD" tab
3. Click "Sign in with Microsoft"
4. Complete authentication in popup
5. Observe redirect to dashboard with user details

---

### Scenario 3: Show JWT Token in Browser
1. Open DevTools (F12)
2. Go to Network tab
3. Perform login
4. Find `/api/secure/user-details` request
5. Show Authorization header with Bearer token
6. Show response with user data

---

### Scenario 4: Demonstrate Feature Toggle

#### Disable PII Masking:
1. Open `Program.cs`
2. Comment out lines 42-49 (PII configuration)
3. Restart backend
4. Run PII masking test again
5. Show unmasked data in logs
6. Uncomment to restore

#### Disable Azure AD:
1. Open `Program.cs`
2. Comment out lines 78-89 (Azure AD issuer)
3. Restart backend
4. Try Azure AD login
5. Show 401 Unauthorized error
6. Uncomment to restore

---

## 🔍 Troubleshooting Commands

### Check if Backend is Running
```powershell
Test-NetConnection -ComputerName localhost -Port 5001
```

---

### Check if Frontend is Running
```powershell
Test-NetConnection -ComputerName localhost -Port 4200
```

---

### View Recent Logs
```powershell
Get-Content logs\primus-app.log -Tail 50
```

---

### Clear Logs (Fresh Start)
```powershell
Remove-Item logs\*.log -Force
Remove-Item logs\*.gz -Force
```

---

### Restart Backend Quickly
```powershell
# Press Ctrl+C in backend terminal, then:
dotnet run
```

---

### Clear Browser Cache
```javascript
// In browser console (F12):
localStorage.clear();
sessionStorage.clear();
location.reload();
```

---

## 📦 Package Installation Commands

### Install Identity Validator
```powershell
dotnet add package PrimusSaaS.Identity.Validator --version 1.3.0
```

---

### Install Logging
```powershell
dotnet add package PrimusSaaS.Logging --version 1.2.1
```

---

### Verify Package Installation
```powershell
dotnet list package
```

---

## 🎯 Quick Demo Reset

If you need to reset everything quickly:

```powershell
# Stop all servers (Ctrl+C in each terminal)

# Clear logs
Remove-Item C:\Users\aakib\PrimusSaaS.TestApp\PrimusSaaS.TestApp\logs\*.log -Force

# Clear browser data (run in browser console)
# localStorage.clear(); sessionStorage.clear(); location.reload();

# Restart backend
cd C:\Users\aakib\PrimusSaaS.TestApp\PrimusSaaS.TestApp
dotnet run

# Restart frontend
cd C:\Users\aakib\PrimusSaaS.TestApp\PrimusSaaS.TestApp\primus-frontend
npm start
```

---

## 📊 Performance Benchmarking

### Measure API Response Time
```powershell
Measure-Command {
    Invoke-RestMethod -Uri "http://localhost:5001/api/secure/protected" `
        -Method GET `
        -Headers @{ "Authorization" = "Bearer $token" }
}
```

---

### Load Test (Simple)
```powershell
1..100 | ForEach-Object -Parallel {
    Invoke-RestMethod -Uri "http://localhost:5001/api/secure/public" -Method GET
} -ThrottleLimit 10
```

---

## 🎨 Pretty Print JSON Responses

```powershell
# Add this function to your PowerShell profile for better JSON display
function Show-Json {
    param([string]$Url)
    Invoke-RestMethod -Uri $Url | ConvertTo-Json -Depth 10 | Write-Host -ForegroundColor Cyan
}

# Usage:
Show-Json "http://localhost:5001/primus/diagnostics"
```

---

## 📝 Notes for Presenter

### Before Each Demo Run:
1. ✅ Clear logs folder
2. ✅ Clear browser localStorage
3. ✅ Restart both servers
4. ✅ Test one endpoint to verify everything works
5. ✅ Have this cheat sheet visible on second monitor

### During Demo:
- Copy commands from this file (don't type live)
- Explain what you're doing BEFORE running the command
- Show the response, then explain what it means
- Keep terminal font size large (14-16pt)

### Emergency Contacts:
- If live demo fails, have screenshots ready
- If API is down, use Postman with saved responses
- If frontend crashes, demo backend only

---

**Quick Access URLs:**
- Frontend: http://localhost:4200
- Backend: http://localhost:5001
- Swagger: http://localhost:5001/swagger
- Diagnostics: http://localhost:5001/primus/diagnostics
- Metrics: http://localhost:5001/primus/logging/metrics

---

**Prepared By**: Aakib Khan  
**Last Updated**: November 25, 2025
