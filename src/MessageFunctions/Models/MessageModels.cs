using System.Text.Json;

namespace MessageFunctions.Models;

/// <summary>
/// Weather update message model for Service Bus communication
/// </summary>
public class WeatherUpdateMessage
{
    public string Id { get; set; } = Guid.NewGuid().ToString();
    public string Location { get; set; } = string.Empty;
    public int TemperatureC { get; set; }
    public string Summary { get; set; } = string.Empty;
    public DateTime Timestamp { get; set; } = DateTime.UtcNow;
    public string Source { get; set; } = "WeatherAPI";
    
    public int TemperatureF => 32 + (int)(TemperatureC / 0.5556);
    
    public string ToJson()
    {
        return JsonSerializer.Serialize(this, new JsonSerializerOptions 
        { 
            PropertyNamingPolicy = JsonNamingPolicy.CamelCase,
            WriteIndented = true 
        });
    }
    
    public static WeatherUpdateMessage? FromJson(string json)
    {
        try
        {
            return JsonSerializer.Deserialize<WeatherUpdateMessage>(json, new JsonSerializerOptions 
            { 
                PropertyNamingPolicy = JsonNamingPolicy.CamelCase 
            });
        }
        catch
        {
            return null;
        }
    }
}

/// <summary>
/// Response model for publisher function
/// </summary>
public class MessagePublishResponse
{
    public bool Success { get; set; }
    public string MessageId { get; set; } = string.Empty;
    public string Message { get; set; } = string.Empty;
    public DateTime Timestamp { get; set; } = DateTime.UtcNow;
    public string? ErrorDetails { get; set; }
}

/// <summary>
/// Request model for publishing messages
/// </summary>
public class PublishMessageRequest
{
    public string Location { get; set; } = "Unknown";
    public int TemperatureC { get; set; }
    public string Summary { get; set; } = string.Empty;
}
