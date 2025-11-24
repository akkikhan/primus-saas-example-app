using Microsoft.Extensions.Logging;
using PrimusSaaS.Identity.Validator;

var builder = WebApplication.CreateBuilder(args);

// Configure logging - Use standard console logging for now to avoid serialization issues
builder.Logging.ClearProviders();
builder.Logging.AddConsole();
builder.Logging.AddDebug();
builder.Logging.SetMinimumLevel(Microsoft.Extensions.Logging.LogLevel.Information);

// Configure PrimusSaaS.Identity.Validator v1.2.2 - Multi-issuer JWT/OIDC validation
builder.Services.AddPrimusIdentity(options =>
{
    options.Issuers = new()
    {
        new IssuerConfig
        {
            Name = "LocalAuth",
            Type = IssuerType.Jwt,
            Issuer = "https://localhost:5001",
            Secret = "ThisIsAVerySecureSecretKeyForTestingPurposes123456!",
            Audiences = new List<string> { "api://primus-test-app" }
        },
        new IssuerConfig
        {
            Name = "AzureAD",
            Type = IssuerType.Oidc,
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

    // Optional: map claims to tenant context
    options.TenantResolver = claims => 
    {
        try 
        {
            return new TenantContext
            {
                TenantId = claims?.Get("tid") ?? claims?.Get("tenantId") ?? "default",
                Roles = claims?.Get<List<string>>("roles") ?? new List<string>()
            };
        }
        catch
        {
            return new TenantContext { TenantId = "default", Roles = new List<string>() };
        }
    };
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

app.Run();

