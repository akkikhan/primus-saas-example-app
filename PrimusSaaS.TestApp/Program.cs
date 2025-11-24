using Microsoft.Extensions.Logging;
using PrimusSaaS.Identity.Validator;

var builder = WebApplication.CreateBuilder(args);

// Use Microsoft logging for now (PrimusSaaS.Logging v1.2.1 has different API - testing separately)
builder.Logging.ClearProviders();
builder.Logging.AddConsole();
builder.Logging.AddDebug();
builder.Logging.SetMinimumLevel(LogLevel.Information);

// Configure PrimusSaaS.Identity.Validator v1.3.0 - NEW API
builder.Services.AddPrimusIdentity(options =>
{
    options.Issuers = new()
    {
        new IssuerConfig
        {
            Name = "LocalAuth",
            Type = IssuerType.Jwt,  // JWT type stays the same
            Issuer = "https://localhost:5001",  // Match actual port
            Secret = "ThisIsAVerySecureSecretKeyForTestingPurposes123456!",
            Audiences = new List<string> { "api://primus-test-app" }
        },
        new IssuerConfig
        {
            Name = "AzureAD",
            Type = IssuerType.AzureAD,  // CHANGED: was Oidc, now AzureAD
            Authority = "https://login.microsoftonline.com/cbd15a9b-cd52-4ccc-916a-00e2edb13043",
            Issuer = "https://login.microsoftonline.com/cbd15a9b-cd52-4ccc-916a-00e2edb13043/v2.0",
            Audiences = new List<string> 
            { 
                "api://32979413-dcc7-4efa-b8b2-47a7208be405",
                "32979413-dcc7-4efa-b8b2-47a7208be405" 
            }
        }
    };

    options.ValidateLifetime = true;
    options.RequireHttpsMetadata = false; // For local testing
    options.ClockSkew = TimeSpan.FromMinutes(5);
    options.JwksCacheTtl = TimeSpan.FromHours(24);
    
    // Optional: Enable rate limiting
    // options.RateLimiting = new RateLimitOptions
    // {
    //     Enable = true,
    //     MaxFailuresPerWindow = 5,
    //     MaxGlobalFailuresPerWindow = 100,
    //     Window = TimeSpan.FromMinutes(5)
    // };
    
    // Optional: Enable token refresh (dev mode)
    // options.TokenRefresh = new TokenRefreshOptions
    // {
    //     Enable = true,
    //     UseInMemoryStore = true,  // DEV ONLY!
    //     AccessTokenTtl = TimeSpan.FromMinutes(15),
    //     RefreshTokenTtl = TimeSpan.FromDays(7)
    // };
    
    // NOTE: TenantResolver removed in v1.3.0
    // Claims mapping is now left to the developer
    // Implement in controllers/middleware as needed
});

builder.Services.AddAuthorization();
builder.Services.AddControllers();
builder.Services.AddEndpointsApiExplorer();
builder.Services.AddSwaggerGen();

// Add CORS configuration
builder.Services.AddCors(options =>
{
    options.AddDefaultPolicy(policy =>
    {
        policy.WithOrigins("http://localhost:4200", "https://localhost:4200")
              .AllowAnyHeader()
              .AllowAnyMethod()
              .AllowCredentials()
              .SetIsOriginAllowedToAllowWildcardSubdomains();
    });
});

var app = builder.Build();

// Configure the HTTP request pipeline
if (app.Environment.IsDevelopment())
{
    app.UseSwagger();
    app.UseSwaggerUI();
}

app.UseHttpsRedirection();

// Use CORS
app.UseCors();

// Use PrimusSaaS.Identity.Validator authentication
app.UseAuthentication();

app.UseAuthorization();

app.MapControllers();

// Map Primus Identity diagnostics endpoint (NEW in v1.3.0)
app.MapPrimusIdentityDiagnostics(); // GET /primus/diagnostics

app.Run();

