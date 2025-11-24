using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Extensions.Logging;
using PrimusSaaS.Identity.Validator;

namespace PrimusSaaS.TestApp.Controllers;

[ApiController]
[Route("api/[controller]")]
public class SecureController : ControllerBase
{
    private readonly ILogger<SecureController> _logger;

    public SecureController(ILogger<SecureController> logger)
    {
        _logger = logger;
    }

    [HttpGet("public")]
    public IActionResult GetPublicData()
    {
        _logger.LogInformation("Public endpoint accessed - no authentication required");
        return Ok(new
        {
            message = "This is public data - no authentication required",
            timestamp = DateTime.UtcNow
        });
    }

    [HttpGet("protected")]
    [Authorize] // Requires valid token from configured issuer
    public IActionResult GetProtectedData()
    {
        // Get the authenticated Primus user using extension method
        var primusUser = HttpContext.GetPrimusUser();

        _logger.LogInformation("Protected endpoint accessed by user {UserId}", primusUser?.UserId);

        return Ok(new
        {
            message = "Secure data accessed successfully",
            user = new
            {
                userId = primusUser?.UserId,
                email = primusUser?.Email,
                name = primusUser?.Name,
                roles = primusUser?.Roles,
                additionalClaims = primusUser?.AdditionalClaims
            },
            timestamp = DateTime.UtcNow
        });
    }

    [HttpGet("admin")]
    [Authorize(Roles = "Admin")]
    public IActionResult GetAdminData()
    {
        var primusUser = HttpContext.GetPrimusUser();

        _logger.LogInformation("Admin endpoint accessed by user {UserId} with roles {Roles}", 
            primusUser?.UserId, 
            string.Join(", ", primusUser?.Roles ?? new List<string>()));

        return Ok(new
        {
            message = "Admin-only data",
            user = new
            {
                userId = primusUser?.UserId,
                email = primusUser?.Email,
                name = primusUser?.Name,
                roles = primusUser?.Roles
            }
        });
    }

    [HttpGet("user-details")]
    [Authorize]
    public IActionResult GetUserDetails()
    {
        _logger.LogInformation("=== USER DETAILS ENDPOINT CALLED ===");
        _logger.LogInformation("Authorization Header: {AuthHeader}", Request.Headers["Authorization"].FirstOrDefault() ?? "None");
        _logger.LogInformation("User Identity: {IsAuthenticated}, {Name}", User?.Identity?.IsAuthenticated, User?.Identity?.Name);
        
        try
        {
            var primusUser = HttpContext.GetPrimusUser();

            if (primusUser == null)
            {
                _logger.LogWarning("No Primus user context found in request");
                return Unauthorized(new { error = "No user context found" });
            }

            _logger.LogInformation("User details requested for {UserId}", primusUser.UserId ?? "Unknown");

            // Ensure collections are not null
            var roles = primusUser.Roles ?? new List<string>();
            var claims = primusUser.AdditionalClaims ?? new Dictionary<string, string>();

            // Log all claims for testing
            _logger.LogInformation("User claims count: {Count}", claims.Count);
            
            // Extract email from claims (Azure AD uses preferred_username)
            var email = primusUser.Email;
            if (string.IsNullOrEmpty(email))
            {
                email = claims.TryGetValue("preferred_username", out var preferredUsername) 
                    ? preferredUsername 
                    : claims.TryGetValue("email", out var emailClaim) 
                        ? emailClaim 
                        : "unknown@example.com";
            }

            // Extract name from claims
            var name = primusUser.Name;
            if (string.IsNullOrEmpty(name))
            {
                name = claims.TryGetValue("name", out var nameClaim) 
                    ? nameClaim 
                    : email.Split('@')[0];
            }

            // Extract tenant ID from claims
            var tenantId = "N/A";
            if (claims.ContainsKey("tid"))
            {
                tenantId = claims["tid"];
            }
            else if (claims.ContainsKey("http://schemas.microsoft.com/identity/claims/tenantid"))
            {
                tenantId = claims["http://schemas.microsoft.com/identity/claims/tenantid"];
            }
            else if (claims.ContainsKey("tenantId"))
            {
                tenantId = claims["tenantId"];
            }

            var response = new
            {
                userId = primusUser.UserId ?? "unknown",
                email = email,
                name = name,
                roles = roles,
                tenantContext = new
                {
                    tenantId = tenantId
                },
                allClaims = claims,
                authenticatedAt = DateTime.UtcNow
            };

            _logger.LogInformation("=== RETURNING USER DETAILS RESPONSE ===");
            _logger.LogInformation("UserId: {UserId}, Email: {Email}, Name: {Name}, TenantId: {TenantId}", 
                response.userId, response.email, response.name, response.tenantContext.tenantId);
            
            return Ok(response);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error retrieving user details");
            return StatusCode(500, new { error = "Internal Server Error", message = ex.Message });
        }
    }
}
