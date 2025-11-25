using PrimusSaaS.Logging.Core;
using System.Reflection;

// Discover Logger API
var loggerType = typeof(Logger);
Console.WriteLine("Logger Methods:");
foreach (var method in loggerType.GetMethods(BindingFlags.Public | BindingFlags.Instance | BindingFlags.DeclaredOnly))
{
    Console.WriteLine($"  {method.Name}({string.Join(", ", method.GetParameters().Select(p => $"{p.ParameterType.Name} {p.Name}"))})");
}

Console.WriteLine("\nLoggerOptions Properties:");
var optionsType = typeof(LoggerOptions);
foreach (var prop in optionsType.GetProperties(BindingFlags.Public | BindingFlags.Instance))
{
    Console.WriteLine($"  {prop.Name}: {prop.PropertyType.Name}");
}

Console.WriteLine("\nTargetConfig Properties:");
var targetType = typeof(TargetConfig);
foreach (var prop in targetType.GetProperties(BindingFlags.Public | BindingFlags.Instance))
{
    Console.WriteLine($"  {prop.Name}: {prop.PropertyType.Name}");
}
