using Microsoft.AspNetCore.Mvc;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.Logging;
using System.IdentityModel.Tokens.Jwt;
using System.Security.Claims;
using System.Text;
using Microsoft.IdentityModel.Tokens;

namespace PrimusSaaS.TestApp.Controllers;

[ApiController]
[Route("api/[controller]")]
public class TokenController : ControllerBase
{
    private readonly IConfiguration _config;
    private readonly ILogger<TokenController> _logger;

    public TokenController(IConfiguration config, ILogger<TokenController> logger)
    {
        _config = config;
        _logger = logger;
    }

    [HttpPost("generate")]
    public IActionResult GenerateToken([FromBody] TokenRequest request)
    {
        _logger.LogInformation("Generating token for user {UserId}", request.UserId);

        try
        {
            // Load configuration - MUST match validator settings
            var secret = _config["PrimusIdentity:Issuers:0:Secret"];
            var issuer = _config["PrimusIdentity:Issuers:0:Issuer"];
            var audience = _config["PrimusIdentity:Issuers:0:Audiences:0"];

            _logger.LogDebug("Token configuration - Issuer: {Issuer}, Audience: {Audience}", issuer, audience);

            var tokenHandler = new JwtSecurityTokenHandler();
            var key = Encoding.UTF8.GetBytes(secret!);

            var claims = new List<Claim>
            {
                new Claim("sub", request.UserId),
                new Claim("email", request.Email),
                new Claim("name", request.Name)
            };

            // Add roles if provided
            if (request.Roles != null && request.Roles.Any())
            {
                foreach (var role in request.Roles)
                {
                    claims.Add(new Claim(ClaimTypes.Role, role));
                }
                claims.Add(new Claim("roles", string.Join(",", request.Roles)));
            }

            // Add tenant ID if provided
            if (!string.IsNullOrEmpty(request.TenantId))
            {
                claims.Add(new Claim("tid", request.TenantId));
                claims.Add(new Claim("tenantId", request.TenantId));
            }

            var tokenDescriptor = new SecurityTokenDescriptor
            {
                Subject = new ClaimsIdentity(claims),
                Expires = DateTime.UtcNow.AddHours(1),
                Issuer = issuer,
                Audience = audience,
                SigningCredentials = new SigningCredentials(
                    new SymmetricSecurityKey(key),
                    SecurityAlgorithms.HmacSha256Signature
                )
            };

            var token = tokenHandler.CreateToken(tokenDescriptor);
            var tokenString = tokenHandler.WriteToken(token);

            _logger.LogInformation("Token generated successfully for user {UserId}", request.UserId);

            return Ok(new
            {
                token = tokenString,
                expiresAt = tokenDescriptor.Expires,
                message = "Token generated successfully. Use this in Authorization header as 'Bearer {token}'"
            });
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error generating token");
            return StatusCode(500, new { error = "Failed to generate token", details = ex.Message });
        }
    }
}

public class TokenRequest
{
    public string UserId { get; set; } = "test-user-123";
    public string Email { get; set; } = "test@example.com";
    public string Name { get; set; } = "Test User";
    public List<string>? Roles { get; set; }
    public string? TenantId { get; set; }
}
