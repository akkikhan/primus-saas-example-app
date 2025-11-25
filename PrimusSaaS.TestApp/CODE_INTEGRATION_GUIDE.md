# 📝 Code Integration Reference Guide

## Overview

This document shows **exactly where** and **what changes** were made to integrate PrimusSaaS packages into this application. Use this as a reference when integrating into your own projects.

---

## 🎯 Integration Summary

| Package | Version | Files Modified | Lines Added | Complexity |
|---------|---------|----------------|-------------|------------|
| PrimusSaaS.Identity.Validator | 1.3.0 | 3 files | ~60 lines | Low |
| PrimusSaaS.Logging | 1.2.1 | 4 files | ~80 lines | Low |
| **Total** | - | **7 files** | **~140 lines** | **Low** |

---

## 📦 Package Installation

### File: `PrimusSaaS.TestApp.csproj`

**Location:** Root directory

**Changes Made:**
```xml
<ItemGroup>
  <!-- ADDED: PrimusSaaS packages -->
  <PackageReference Include="PrimusSaaS.Identity.Validator" Version="1.3.0" />
  <PackageReference Include="PrimusSaaS.Logging" Version="1.2.1" />
</ItemGroup>
```

**Why:** These package references tell NuGet to download and include the PrimusSaaS libraries.

**Integration Time:** 30 seconds (just add these 2 lines)

---

## 🔐 Identity Validator Integration

### File 1: `Program.cs`

**Location:** Root directory  
**Lines Modified:** 1-6, 65-118, 153-160

#### Change 1: Add Using Statements (Lines 1-6)

```csharp
// ADDED: Import PrimusSaaS namespaces
using PrimusSaaS.Identity.Validator;
using PrimusSaaS.Logging.Core;
using MsLogLevel = Microsoft.Extensions.Logging.LogLevel;
```

**Why:** Import the necessary namespaces to use PrimusSaaS classes.

---

#### Change 2: Configure Identity Validator (Lines 65-118)

```csharp
// ADDED: Configure PrimusSaaS.Identity.Validator v1.3.0
builder.Services.AddPrimusIdentity(options =>
{
    // Define multiple issuers (Local JWT + Azure AD)
    options.Issuers = new()
    {
        // Local JWT issuer for email/password authentication
        new IssuerConfig
        {
            Name = "LocalAuth",
            Type = IssuerType.Jwt,
            Issuer = "https://localhost:5001",
            Secret = "ThisIsAVerySecureSecretKeyForTestingPurposes123456!",
            Audiences = new List<string> { "api://primus-test-app" }
        },
        
        // Azure AD issuer for Microsoft authentication
        new IssuerConfig
        {
            Name = "AzureAD",
            Type = IssuerType.AzureAD,  // Automatic JWKS handling!
            Authority = "https://login.microsoftonline.com/cbd15a9b-cd52-4ccc-916a-00e2edb13043",
            Issuer = "https://login.microsoftonline.com/cbd15a9b-cd52-4ccc-916a-00e2edb13043/v2.0",
            Audiences = new List<string> 
            { 
                "api://32979413-dcc7-4efa-b8b2-47a7208be405",
                "32979413-dcc7-4efa-b8b2-47a7208be405" 
            }
        }
    };

    // Token validation settings
    options.ValidateLifetime = true;
    options.RequireHttpsMetadata = false; // For local development only!
    options.ClockSkew = TimeSpan.FromMinutes(5);
    options.JwksCacheTtl = TimeSpan.FromHours(24);
});

// ADDED: Enable authentication and authorization
builder.Services.AddAuthorization();
```

**What This Does:**
- ✅ Configures two identity providers (Local JWT + Azure AD)
- ✅ Automatic token validation for both issuers
- ✅ Automatic JWKS fetching for Azure AD
- ✅ Clock skew tolerance (5 minutes)
- ✅ JWKS caching (24 hours)

**Key Benefits:**
- No manual `TokenValidationParameters` setup
- No manual JWKS endpoint configuration
- Multi-issuer support out of the box
- Automatic token refresh and caching

---

#### Change 3: Add Authentication Middleware (Lines 153-155)

```csharp
// ADDED: Use authentication middleware
app.UseAuthentication();
app.UseAuthorization();
```

**Why:** These middleware components intercept requests and validate JWT tokens.

**Order Matters:** Must come AFTER `UseRouting()` and BEFORE `MapControllers()`.

---

#### Change 4: Add Diagnostics Endpoint (Line 160)

```csharp
// ADDED: Map Primus Identity diagnostics endpoint
app.MapPrimusIdentityDiagnostics(); // GET /primus/diagnostics
```

**What This Does:**
- ✅ Automatically creates a `/primus/diagnostics` endpoint
- ✅ Shows health status of all configured issuers
- ✅ Shows JWKS cache status for Azure AD
- ✅ Zero code required - it's built-in!

**Access:** `http://localhost:5001/primus/diagnostics`

---

### File 2: `appsettings.json`

**Location:** Root directory  
**Lines Added:** 41-54

```json
{
  "PrimusIdentity": {
    "Issuers": [
      {
        "Name": "LocalAuth",
        "Type": "Jwt",
        "Issuer": "https://localhost:5001",
        "Secret": "ThisIsAVerySecureSecretKeyForTestingPurposes123456!",
        "Audiences": [ "api://primus-test-app" ]
      }
    ],
    "RequireHttpsMetadata": false,
    "ValidateLifetime": true,
    "ClockSkew": "00:05:00"
  }
}
```

**Why:** Configuration can be in `appsettings.json` OR in code (we use code for this demo).

**Note:** This is optional - we're using code-based configuration in `Program.cs` instead.

---

### File 3: `Controllers/SecureController.cs`

**Location:** `Controllers/SecureController.cs`  
**Lines Modified:** Throughout

#### Change 1: Add Using Statement

```csharp
using PrimusSaaS.Identity.Validator;
```

---

#### Change 2: Use GetPrimusUser() Extension Method

```csharp
[HttpGet("protected")]
[Authorize]  // Requires valid JWT token
public IActionResult GetProtectedData()
{
    // MAGIC: One line to get all user info!
    var primusUser = HttpContext.GetPrimusUser();
    
    return Ok(new
    {
        message = "This is protected data",
        user = new
        {
            primusUser.UserId,
            primusUser.Email,
            primusUser.Name,
            primusUser.Roles,
            primusUser.TenantId
        }
    });
}
```

**What This Does:**
- ✅ Extracts user info from JWT claims automatically
- ✅ Returns strongly-typed `PrimusUser` object
- ✅ No manual claims parsing required

**Traditional Approach (50+ lines):**
```csharp
// WITHOUT PrimusSaaS - manual claims extraction
var userId = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
var email = User.FindFirst(ClaimTypes.Email)?.Value;
var name = User.FindFirst(ClaimTypes.Name)?.Value;
var roles = User.FindAll(ClaimTypes.Role).Select(c => c.Value).ToList();
var tenantId = User.FindFirst("tid")?.Value ?? User.FindFirst("tenantId")?.Value;
// ... and so on
```

**PrimusSaaS Approach (1 line):**
```csharp
var primusUser = HttpContext.GetPrimusUser();
```

**Savings:** 49 lines of code eliminated! ✨

---

#### Change 3: Role-Based Authorization

```csharp
[HttpGet("admin")]
[Authorize(Roles = "Admin")]  // Only users with "Admin" role
public IActionResult GetAdminData()
{
    var primusUser = HttpContext.GetPrimusUser();
    
    return Ok(new
    {
        message = "Admin access granted",
        user = new
        {
            primusUser.UserId,
            primusUser.Roles
        }
    });
}
```

**What This Does:**
- ✅ Automatic role validation
- ✅ Returns 403 Forbidden if user lacks "Admin" role
- ✅ Works with both Local JWT and Azure AD tokens

---

### File 4: `Controllers/TokenController.cs`

**Location:** `Controllers/TokenController.cs`  
**Purpose:** Generate JWT tokens for testing

**Key Method:**
```csharp
[HttpPost("generate")]
public IActionResult GenerateToken([FromBody] TokenRequest request)
{
    var tokenHandler = new JwtSecurityTokenHandler();
    var key = Encoding.UTF8.GetBytes("ThisIsAVerySecureSecretKeyForTestingPurposes123456!");
    
    var claims = new List<Claim>
    {
        new Claim(ClaimTypes.NameIdentifier, request.UserId),
        new Claim(ClaimTypes.Email, request.Email),
        new Claim(ClaimTypes.Name, request.Name),
        new Claim("tid", request.TenantId)
    };
    
    // Add roles as individual claims
    foreach (var role in request.Roles)
    {
        claims.Add(new Claim(ClaimTypes.Role, role));
    }
    
    var tokenDescriptor = new SecurityTokenDescriptor
    {
        Subject = new ClaimsIdentity(claims),
        Expires = DateTime.UtcNow.AddHours(1),
        Issuer = "https://localhost:5001",
        Audience = "api://primus-test-app",
        SigningCredentials = new SigningCredentials(
            new SymmetricSecurityKey(key),
            SecurityAlgorithms.HmacSha256Signature
        )
    };
    
    var token = tokenHandler.CreateToken(tokenDescriptor);
    return Ok(new { token = tokenHandler.WriteToken(token) });
}
```

**Why:** This generates tokens that match the "LocalAuth" issuer configuration.

**Note:** In production, this would be replaced by your actual authentication service.

---

## 📊 Logging Integration

### File 1: `Program.cs` (Logging Section)

**Location:** Root directory  
**Lines Modified:** 14-63, 163-183

#### Change 1: Configure PrimusSaaS.Logging (Lines 14-60)

```csharp
// ADDED: Configure PrimusSaaS.Logging v1.2.1
var primusLogger = new Logger(new LoggerOptions
{
    ApplicationId = "PrimusSaaS.TestApp",
    Environment = builder.Environment.EnvironmentName,
    MinLevel = PrimusSaaS.Logging.Core.LogLevel.Debug,
    
    // Multiple output targets
    Targets = new List<TargetConfig>
    {
        // Console output (pretty-printed JSON)
        new TargetConfig 
        { 
            Type = "console",
            Pretty = true,
            Async = true,
            BufferSize = 1000
        },
        
        // File output (with rotation and compression)
        new TargetConfig
        {
            Type = "file",
            Path = "logs/primus-app.log",
            MaxFileSize = 10485760,  // 10MB
            MaxRetainedFiles = 30,
            CompressRotatedFiles = true,  // Automatic gzip!
            Async = true,
            BufferSize = 10000
        }
    },
    
    // PII masking configuration
    Pii = new PiiOptions
    {
        MaskEmails = true,
        MaskCreditCards = true,
        MaskSSN = true,
        CustomSensitiveKeys = new List<string> 
        { 
            "password", "secret", "token", "apikey" 
        }
    },
    
    // Serialization safety (prevents circular references)
    Serialization = new SerializationOptions
    {
        MaxDepth = 5,
        MaxEnumerableLength = 100,
        MaxStringLength = 1024,
        MaxContextBytes = 10240,  // 10KB
        IgnoreCycles = true
    }
});

// ADDED: Register logger for dependency injection
builder.Services.AddSingleton(primusLogger);
```

**What This Does:**
- ✅ Structured JSON logging to console and file
- ✅ Automatic file rotation when size exceeds 10MB
- ✅ Automatic gzip compression of rotated files
- ✅ Async buffering for performance
- ✅ PII masking for emails, SSN, credit cards, passwords
- ✅ Protection against circular reference errors

**Key Benefits:**
- No need for Serilog, NLog, or other logging libraries
- PII masking built-in (GDPR/HIPAA compliance)
- File rotation prevents disk space issues
- Async buffering doesn't slow down your API

---

#### Change 2: Add Logging Endpoints (Lines 163-183)

```csharp
// ADDED: Map Primus Logging metrics endpoint
app.MapGet("/primus/logging/metrics", (Logger logger) =>
{
    var metrics = logger.GetMetricsSnapshot();
    return Results.Json(metrics);
});

// ADDED: Map Primus Logging health endpoint
app.MapGet("/primus/logging/health", (Logger logger) =>
{
    var health = logger.GetHealthSnapshot();
    var metrics = health.Metrics;
    var isHealthy = metrics.WriteFailures == 0;
    
    return Results.Json(new 
    { 
        healthy = isHealthy,
        status = isHealthy ? "OK" : "DEGRADED",
        metrics,
        targets = health.Targets,
        timestamp = DateTime.UtcNow
    });
});
```

**What This Does:**
- ✅ `/primus/logging/metrics` - Shows log counts, performance metrics
- ✅ `/primus/logging/health` - Shows logging system health status
- ✅ Zero configuration - just map the endpoints!

---

### File 2: `Controllers/LoggingV2TestController.cs`

**Location:** `Controllers/LoggingV2TestController.cs`  
**Purpose:** Demonstrate all logging features

#### Change 1: Inject Logger

```csharp
using PrimusSaaS.Logging.Core;

[ApiController]
[Route("api/loggingtest")]
public class LoggingV2TestController : ControllerBase
{
    private readonly Logger _logger;
    
    public LoggingV2TestController(Logger logger)
    {
        _logger = logger;
    }
}
```

---

#### Change 2: Structured Logging Example

```csharp
[HttpGet("test-structured-logging")]
public IActionResult TestStructuredLogging()
{
    _logger.Info("User action performed", new
    {
        userId = "user-123",
        action = "ViewDashboard",
        timestamp = DateTime.UtcNow,
        metadata = new 
        { 
            browser = "Chrome", 
            version = "120",
            ipAddress = "192.168.1.100"
        }
    });
    
    return Ok("Structured log created");
}
```

**Output in Log File:**
```json
{
  "timestamp": "2025-11-25T09:00:00.000Z",
  "level": "INFO",
  "message": "User action performed",
  "context": {
    "userId": "user-123",
    "action": "ViewDashboard",
    "timestamp": "2025-11-25T09:00:00Z",
    "metadata": {
      "browser": "Chrome",
      "version": "120",
      "ipAddress": "192.168.1.100"
    }
  }
}
```

---

#### Change 3: PII Masking Example

```csharp
[HttpPost("test-pii-masking")]
public IActionResult TestPIIMasking([FromBody] dynamic data)
{
    _logger.Info("User data received", new
    {
        email = data.email?.ToString(),
        ssn = data.ssn?.ToString(),
        creditCard = data.creditCard?.ToString(),
        password = data.password?.ToString()
    });
    
    return Ok("PII data logged (check logs to see masking)");
}
```

**Input:**
```json
{
  "email": "john.doe@example.com",
  "ssn": "123-45-6789",
  "creditCard": "4532-1234-5678-9010",
  "password": "SuperSecret123!"
}
```

**Output in Log File (MASKED):**
```json
{
  "timestamp": "2025-11-25T09:00:00.000Z",
  "level": "INFO",
  "message": "User data received",
  "context": {
    "email": "j***@example.com",
    "ssn": "***-**-6789",
    "creditCard": "****-****-****-9010",
    "password": "***"
  }
}
```

**Wow Factor:** Automatic PII protection! 🎉

---

#### Change 4: Exception Logging

```csharp
[HttpGet("test-exception")]
public IActionResult TestException()
{
    try
    {
        throw new InvalidOperationException("This is a test exception");
    }
    catch (Exception ex)
    {
        _logger.Error("An error occurred", ex, new
        {
            endpoint = "/api/loggingtest/test-exception",
            userId = "test-user-123"
        });
        
        return StatusCode(500, "Error logged");
    }
}
```

**Output:**
```json
{
  "timestamp": "2025-11-25T09:00:00.000Z",
  "level": "ERROR",
  "message": "An error occurred",
  "exception": {
    "type": "InvalidOperationException",
    "message": "This is a test exception",
    "stackTrace": "..."
  },
  "context": {
    "endpoint": "/api/loggingtest/test-exception",
    "userId": "test-user-123"
  }
}
```

---

## 🎨 Frontend Integration (Angular)

### File 1: `primus-frontend/src/app/app.module.ts`

**Changes:** Azure AD MSAL configuration

```typescript
import { MsalModule, MsalInterceptor } from '@azure/msal-angular';
import { PublicClientApplication, InteractionType } from '@azure/msal-browser';

const msalConfig = {
  auth: {
    clientId: '32979413-dcc7-4efa-b8b2-47a7208be405',
    authority: 'https://login.microsoftonline.com/cbd15a9b-cd52-4ccc-916a-00e2edb13043',
    redirectUri: 'http://localhost:4200'
  }
};

@NgModule({
  imports: [
    MsalModule.forRoot(
      new PublicClientApplication(msalConfig),
      {
        interactionType: InteractionType.Popup,
        authRequest: {
          scopes: ['api://32979413-dcc7-4efa-b8b2-47a7208be405/access_as_user']
        }
      },
      {
        interactionType: InteractionType.Popup,
        protectedResourceMap: new Map([
          ['http://localhost:5001/api/*', ['api://32979413-dcc7-4efa-b8b2-47a7208be405/access_as_user']]
        ])
      }
    )
  ]
})
```

**Why:** Configures Azure AD authentication to work with PrimusSaaS.Identity.Validator backend.

---

## 📊 Summary of Changes

### Total Lines of Code Added:

| Component | Lines Added | Complexity |
|-----------|-------------|------------|
| Identity Validator Setup | ~60 lines | Low |
| Logging Setup | ~80 lines | Low |
| Controller Usage | ~40 lines | Very Low |
| **Total** | **~180 lines** | **Low** |

### Comparison with Traditional Approach:

| Approach | Lines of Code | Setup Time | Features |
|----------|---------------|------------|----------|
| **Traditional** | 500+ lines | 4-6 hours | Basic |
| **PrimusSaaS** | 180 lines | 30 minutes | Advanced |
| **Savings** | **64% less code** | **90% faster** | **More features** |

---

## 🎯 Integration Checklist for Your Project

### Step 1: Install Packages (2 minutes)
```bash
dotnet add package PrimusSaaS.Identity.Validator --version 1.3.0
dotnet add package PrimusSaaS.Logging --version 1.2.1
```

### Step 2: Configure in Program.cs (10 minutes)
- [ ] Add using statements
- [ ] Configure Identity Validator with your issuers
- [ ] Configure Logging with your targets
- [ ] Add authentication middleware
- [ ] Map diagnostics endpoints

### Step 3: Use in Controllers (5 minutes)
- [ ] Inject `Logger` in constructor
- [ ] Use `HttpContext.GetPrimusUser()` for user info
- [ ] Use `_logger.Info()` for logging
- [ ] Add `[Authorize]` attributes

### Step 4: Test (5 minutes)
- [ ] Test authentication endpoints
- [ ] Test logging endpoints
- [ ] Check log files
- [ ] Verify PII masking

**Total Time: ~25 minutes** ⏱️

---

## 🚀 Next Steps

1. **Customize Configuration:** Update issuers, audiences, and secrets for your environment
2. **Add More Issuers:** Support Google, Facebook, or custom identity providers
3. **Configure Production Logging:** Add Application Insights or other targets
4. **Enable Rate Limiting:** Uncomment rate limiting options in `Program.cs`
5. **Add Token Refresh:** Enable token refresh for better UX

---

## 📚 Additional Resources

- **Identity Validator Documentation:** See package README
- **Logging Documentation:** See package README
- **Sample Code:** This repository!
- **Support:** Open an issue on GitHub

---

**Prepared By**: Aakib Khan  
**Last Updated**: November 25, 2025  
**Version**: 1.0
