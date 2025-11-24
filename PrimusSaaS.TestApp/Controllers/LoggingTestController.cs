using Microsoft.AspNetCore.Mvc;
using Microsoft.Extensions.Logging;
using PrimusSaaS.Logging.Core;

namespace PrimusSaaS.TestApp.Controllers;

[ApiController]
[Route("api/[controller]")]
public class LoggingTestController : ControllerBase
{
    private readonly ILogger<LoggingTestController> _logger;

    public LoggingTestController(ILogger<LoggingTestController> logger)
    {
        _logger = logger;
    }

    [HttpGet("test-all-levels")]
    public IActionResult TestAllLogLevels()
    {
        _logger.LogDebug("This is a DEBUG level message");
        _logger.LogInformation("This is an INFO level message");
        _logger.LogWarning("This is a WARNING level message");
        _logger.LogError("This is an ERROR level message");
        _logger.LogCritical("This is a CRITICAL level message");

        return Ok(new { message = "All log levels tested - check console and logs/app.log" });
    }

    [HttpGet("test-structured-logging")]
    public IActionResult TestStructuredLogging()
    {
        var userId = "user-12345";
        var orderId = "order-98765";
        var amount = 299.99;

        _logger.LogInformation("Order {OrderId} created for user {UserId} with amount {Amount:C}", 
            orderId, userId, amount);

        _logger.LogInformation("Structured data test with properties: {Properties}", new
        {
            userId,
            orderId,
            amount,
            timestamp = DateTime.UtcNow
        });

        return Ok(new
        {
            message = "Structured logging tested",
            data = new { userId, orderId, amount }
        });
    }

    [HttpPost("test-pii-masking")]
    public IActionResult TestPIIMasking([FromBody] SensitiveDataRequest request)
    {
        // These should be masked in logs
        _logger.LogInformation("User data received - Email: {Email}, Password: {Password}, SSN: {SSN}, ApiKey: {ApiKey}",
            request.Email,
            request.Password,
            request.SSN,
            request.ApiKey);

        _logger.LogInformation("Credit card: {CreditCard}", request.CreditCard);

        return Ok(new
        {
            message = "PII masking test completed - sensitive data should be masked in logs",
            note = "Check the console/log file to verify masking is working"
        });
    }

    [HttpGet("test-correlation-id")]
    public IActionResult TestCorrelationId()
    {
        var correlationId = Guid.NewGuid().ToString();

        _logger.LogInformation("Step 1 - Starting process with CorrelationId: {CorrelationId}", correlationId);
        _logger.LogInformation("Step 2 - Processing data with CorrelationId: {CorrelationId}", correlationId);
        _logger.LogInformation("Step 3 - Completing process with CorrelationId: {CorrelationId}", correlationId);

        return Ok(new
        {
            message = "Correlation ID test completed",
            correlationId
        });
    }

    [HttpGet("test-exception")]
    public IActionResult TestExceptionLogging()
    {
        try
        {
            // Simulate an error
            throw new InvalidOperationException("This is a test exception for logging purposes");
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Test exception caught - Error: {ErrorMessage}", ex.Message);

            return Ok(new
            {
                message = "Exception logged successfully",
                error = ex.Message
            });
        }
    }

    [HttpGet("test-performance-timing")]
    public async Task<IActionResult> TestPerformanceTiming()
    {
        var startTime = DateTime.UtcNow;
        
        _logger.LogInformation("Performance test started at {StartTime}", startTime);

        // Simulate some work
        await Task.Delay(500);

        var endTime = DateTime.UtcNow;
        var duration = (endTime - startTime).TotalMilliseconds;

        _logger.LogInformation("Performance test completed in {Duration}ms", duration);

        return Ok(new
        {
            message = "Performance timing test completed",
            startTime,
            endTime,
            durationMs = duration
        });
    }
}

public class SensitiveDataRequest
{
    public string Email { get; set; } = "john.doe@example.com";
    public string Password { get; set; } = "MySecretPassword123!";
    public string SSN { get; set; } = "123-45-6789";
    public string ApiKey { get; set; } = "sk_test_1234567890abcdef";
    public string CreditCard { get; set; } = "4532-1234-5678-9010";
}
