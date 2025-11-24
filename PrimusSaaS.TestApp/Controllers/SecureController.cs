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
        var primusUser = HttpContext.GetPrimusUser();

        if (primusUser == null)
        {
            return Unauthorized(new { error = "No user context found" });
        }

        _logger.LogInformation("User details requested for {UserId}", primusUser.UserId);

        // Log all claims for testing
        _logger.LogDebug("User claims: {@Claims}", primusUser.AdditionalClaims);

        return Ok(new
        {
            userId = primusUser.UserId,
            email = primusUser.Email,
            name = primusUser.Name,
            roles = primusUser.Roles,
            tenantContext = new
            {
                tenantId = primusUser.AdditionalClaims.ContainsKey("tid") 
                    ? primusUser.AdditionalClaims["tid"] 
                    : "N/A"
            },
            allClaims = primusUser.AdditionalClaims,
            authenticatedAt = DateTime.UtcNow
        });
    }
}
