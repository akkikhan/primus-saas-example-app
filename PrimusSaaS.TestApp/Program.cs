using Microsoft.Extensions.Logging;
using PrimusSaaS.Identity.Validator;
using PrimusSaaS.Logging.Core;
using PrimusSaaS.Logging.Extensions;
using PrimusLogLevel = PrimusSaaS.Logging.Core.LogLevel;

var builder = WebApplication.CreateBuilder(args);

// Configure PrimusSaaS.Logging v1.1.1 - Direct configuration with LoggerOptions
builder.Logging.ClearProviders();
builder.Logging.AddPrimus(options =>
{
    options.ApplicationId = "PRIMUS-TEST-APP";
    options.Environment = "development";
    options.MinLevel = PrimusLogLevel.Debug;
    
    // Configure multiple output targets
    options.Targets = new List<TargetConfig>
    {
        // Console target with pretty printing
        new TargetConfig
        {
            Type = "console",
            Pretty = true
        },
        // File target with async writes and rotation
        new TargetConfig
        {
            Type = "file",
            Path = "logs/app.log",
            Async = true,
            MaxFileSize = 10 * 1024 * 1024,  // 10MB
            MaxRetainedFiles = 5,
            CompressRotatedFiles = true
        }
    };
    
    // Enable PII masking
    options.Pii = new PiiOptions
    {
        MaskEmails = true,
        MaskCreditCards = true,
        MaskSSN = true,
        CustomSensitiveKeys = new List<string> { "password", "apiKey", "secret", "token" }
    };
});

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
        }
    };

    options.ValidateLifetime = true;
    options.RequireHttpsMetadata = false; // For local testing
    options.ClockSkew = TimeSpan.FromMinutes(5);

    // Optional: map claims to tenant context
    options.TenantResolver = claims => new TenantContext
    {
        TenantId = claims.Get("tid") ?? claims.Get("tenantId") ?? "default",
        Roles = claims.Get<List<string>>("roles") ?? new List<string>()
    };
});

builder.Services.AddAuthorization();
builder.Services.AddControllers();
builder.Services.AddEndpointsApiExplorer();
builder.Services.AddSwaggerGen();

var app = builder.Build();

// Configure the HTTP request pipeline
if (app.Environment.IsDevelopment())
{
    app.UseSwagger();
    app.UseSwaggerUI();
}

app.UseHttpsRedirection();

// Use PrimusSaaS.Identity.Validator authentication
app.UseAuthentication();

// Use PrimusSaaS.Logging middleware for HTTP context enrichment
PrimusSaaS.Logging.Extensions.LoggingExtensions.UsePrimusLogging(app);

app.UseAuthorization();

app.MapControllers();

app.Run();

