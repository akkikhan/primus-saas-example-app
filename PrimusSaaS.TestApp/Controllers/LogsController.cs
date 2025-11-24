using Microsoft.AspNetCore.Mvc;
using System.Text.Json;

namespace PrimusSaaS.TestApp.Controllers;

[ApiController]
[Route("api/[controller]")]
public class LogsController : ControllerBase
{
    private readonly string _logFilePath;

    public LogsController(IWebHostEnvironment env)
    {
        _logFilePath = Path.Combine(env.ContentRootPath, "logs", "app.log");
    }

    [HttpGet]
    public async Task<IActionResult> GetLogs(
        [FromQuery] int page = 1,
        [FromQuery] int pageSize = 50,
        [FromQuery] string? level = null,
        [FromQuery] string? category = null,
        [FromQuery] string? search = null,
        [FromQuery] DateTime? startDate = null,
        [FromQuery] DateTime? endDate = null)
    {
        try
        {
            if (!System.IO.File.Exists(_logFilePath))
            {
                return Ok(new
                {
                    logs = new List<object>(),
                    total = 0,
                    page,
                    pageSize,
                    totalPages = 0
                });
            }

            var lines = await System.IO.File.ReadAllLinesAsync(_logFilePath);
            var logs = new List<LogEntry>();

            foreach (var line in lines)
            {
                if (string.IsNullOrWhiteSpace(line)) continue;

                try
                {
                    var logEntry = JsonSerializer.Deserialize<LogEntry>(line);
                    if (logEntry != null)
                    {
                        logs.Add(logEntry);
                    }
                }
                catch
                {
                    // Skip malformed log entries
                    continue;
                }
            }

            // Apply filters
            var filteredLogs = logs.AsEnumerable();

            if (!string.IsNullOrEmpty(level))
            {
                filteredLogs = filteredLogs.Where(l => l.Level?.Equals(level, StringComparison.OrdinalIgnoreCase) == true);
            }

            if (!string.IsNullOrEmpty(category))
            {
                filteredLogs = filteredLogs.Where(l => 
                    l.Context?.Category?.Contains(category, StringComparison.OrdinalIgnoreCase) == true);
            }

            if (!string.IsNullOrEmpty(search))
            {
                filteredLogs = filteredLogs.Where(l =>
                    l.Message?.Contains(search, StringComparison.OrdinalIgnoreCase) == true ||
                    l.Context?.Category?.Contains(search, StringComparison.OrdinalIgnoreCase) == true);
            }

            if (startDate.HasValue)
            {
                filteredLogs = filteredLogs.Where(l => l.Timestamp >= startDate.Value);
            }

            if (endDate.HasValue)
            {
                filteredLogs = filteredLogs.Where(l => l.Timestamp <= endDate.Value);
            }

            // Order by timestamp descending (newest first)
            var orderedLogs = filteredLogs.OrderByDescending(l => l.Timestamp).ToList();

            var total = orderedLogs.Count;
            var totalPages = (int)Math.Ceiling(total / (double)pageSize);

            var pagedLogs = orderedLogs
                .Skip((page - 1) * pageSize)
                .Take(pageSize)
                .ToList();

            return Ok(new
            {
                logs = pagedLogs,
                total,
                page,
                pageSize,
                totalPages
            });
        }
        catch (Exception ex)
        {
            return StatusCode(500, new { error = ex.Message });
        }
    }

    [HttpGet("stats")]
    public async Task<IActionResult> GetLogStats()
    {
        try
        {
            if (!System.IO.File.Exists(_logFilePath))
            {
                return Ok(new
                {
                    totalLogs = 0,
                    byLevel = new Dictionary<string, int>(),
                    byCategory = new Dictionary<string, int>(),
                    recentErrors = new List<object>()
                });
            }

            var lines = await System.IO.File.ReadAllLinesAsync(_logFilePath);
            var logs = new List<LogEntry>();

            foreach (var line in lines)
            {
                if (string.IsNullOrWhiteSpace(line)) continue;

                try
                {
                    var logEntry = JsonSerializer.Deserialize<LogEntry>(line);
                    if (logEntry != null)
                    {
                        logs.Add(logEntry);
                    }
                }
                catch
                {
                    continue;
                }
            }

            var byLevel = logs
                .GroupBy(l => l.Level ?? "UNKNOWN")
                .ToDictionary(g => g.Key, g => g.Count());

            var byCategory = logs
                .Where(l => !string.IsNullOrEmpty(l.Context?.Category))
                .GroupBy(l => l.Context!.Category!)
                .OrderByDescending(g => g.Count())
                .Take(10)
                .ToDictionary(g => g.Key, g => g.Count());

            var recentErrors = logs
                .Where(l => l.Level == "ERROR" || l.Level == "CRITICAL")
                .OrderByDescending(l => l.Timestamp)
                .Take(5)
                .ToList();

            return Ok(new
            {
                totalLogs = logs.Count,
                byLevel,
                byCategory,
                recentErrors
            });
        }
        catch (Exception ex)
        {
            return StatusCode(500, new { error = ex.Message });
        }
    }

    [HttpGet("categories")]
    public async Task<IActionResult> GetCategories()
    {
        try
        {
            if (!System.IO.File.Exists(_logFilePath))
            {
                return Ok(new List<string>());
            }

            var lines = await System.IO.File.ReadAllLinesAsync(_logFilePath);
            var categories = new HashSet<string>();

            foreach (var line in lines)
            {
                if (string.IsNullOrWhiteSpace(line)) continue;

                try
                {
                    var logEntry = JsonSerializer.Deserialize<LogEntry>(line);
                    if (logEntry?.Context?.Category != null)
                    {
                        categories.Add(logEntry.Context.Category);
                    }
                }
                catch
                {
                    continue;
                }
            }

            return Ok(categories.OrderBy(c => c).ToList());
        }
        catch (Exception ex)
        {
            return StatusCode(500, new { error = ex.Message });
        }
    }

    [HttpDelete]
    public IActionResult ClearLogs()
    {
        try
        {
            if (System.IO.File.Exists(_logFilePath))
            {
                System.IO.File.WriteAllText(_logFilePath, string.Empty);
            }

            return Ok(new { message = "Logs cleared successfully" });
        }
        catch (Exception ex)
        {
            return StatusCode(500, new { error = ex.Message });
        }
    }
}

public class LogEntry
{
    public DateTime Timestamp { get; set; }
    public string? Level { get; set; }
    public string? Message { get; set; }
    public LogContext? Context { get; set; }
}

public class LogContext
{
    public string? ApplicationId { get; set; }
    public string? Environment { get; set; }
    public string? Category { get; set; }
    public int? EventId { get; set; }
    public string? EventName { get; set; }
    public string? RequestId { get; set; }
    public string? Method { get; set; }
    public string? Path { get; set; }
    public int? StatusCode { get; set; }
    public double? Duration { get; set; }
}
