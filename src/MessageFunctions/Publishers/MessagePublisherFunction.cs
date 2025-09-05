using Azure.Messaging.ServiceBus;
using MessageFunctions.Models;
using Microsoft.Azure.Functions.Worker;
using Microsoft.Azure.Functions.Worker.Http;
using Microsoft.Extensions.Logging;
using System.Net;
using System.Text.Json;

namespace MessageFunctions.Publishers;

public class MessagePublisherFunction
{
    private readonly ILogger<MessagePublisherFunction> _logger;

    public MessagePublisherFunction(ILogger<MessagePublisherFunction> logger)
    {
        _logger = logger;
    }

    [Function("PublishWeatherUpdate")]
    public async Task<HttpResponseData> PublishWeatherUpdate(
        [HttpTrigger(AuthorizationLevel.Function, "post", Route = "weather/publish")] HttpRequestData req)
    {
        _logger.LogInformation("Weather update publish request received at {RequestTime}", DateTime.UtcNow);

        try
        {
            // Parse request body
            var requestBody = await new StreamReader(req.Body).ReadToEndAsync();
            
            if (string.IsNullOrEmpty(requestBody))
            {
                return await CreateErrorResponse(req, "Request body is empty", HttpStatusCode.BadRequest);
            }

            var publishRequest = JsonSerializer.Deserialize<PublishMessageRequest>(requestBody, 
                new JsonSerializerOptions { PropertyNamingPolicy = JsonNamingPolicy.CamelCase });

            if (publishRequest == null)
            {
                return await CreateErrorResponse(req, "Invalid request format", HttpStatusCode.BadRequest);
            }

            // Create weather update message
            var weatherMessage = new WeatherUpdateMessage
            {
                Location = publishRequest.Location,
                TemperatureC = publishRequest.TemperatureC,
                Summary = publishRequest.Summary,
                Timestamp = DateTime.UtcNow,
                Source = "HTTP-Publisher-Function"
            };

            // Get Service Bus configuration
            var connectionString = Environment.GetEnvironmentVariable("ServiceBusConnectionString");
            var queueName = Environment.GetEnvironmentVariable("QueueName");

            if (string.IsNullOrEmpty(connectionString))
            {
                _logger.LogError("ServiceBusConnectionString is not configured");
                return await CreateErrorResponse(req, "Service Bus not configured", HttpStatusCode.InternalServerError);
            }

            if (string.IsNullOrEmpty(queueName))
            {
                _logger.LogError("QueueName is not configured");
                return await CreateErrorResponse(req, "Queue name not configured", HttpStatusCode.InternalServerError);
            }

            // Send message to Service Bus
            await using var client = new ServiceBusClient(connectionString);
            var sender = client.CreateSender(queueName);

            var message = new ServiceBusMessage(weatherMessage.ToJson())
            {
                MessageId = weatherMessage.Id,
                ContentType = "application/json",
                Subject = "WeatherUpdate"
            };

            // Add custom properties for filtering/routing
            message.ApplicationProperties.Add("Location", weatherMessage.Location);
            message.ApplicationProperties.Add("Temperature", weatherMessage.TemperatureC);
            message.ApplicationProperties.Add("Source", weatherMessage.Source);

            await sender.SendMessageAsync(message);

            _logger.LogInformation("Weather update message published successfully. MessageId: {MessageId}, Location: {Location}, Temperature: {Temperature}°C", 
                weatherMessage.Id, weatherMessage.Location, weatherMessage.TemperatureC);

            // Create success response
            var response = req.CreateResponse(HttpStatusCode.OK);
            await response.WriteAsJsonAsync(new MessagePublishResponse
            {
                Success = true,
                MessageId = weatherMessage.Id,
                Message = $"Weather update for {weatherMessage.Location} published successfully",
                Timestamp = DateTime.UtcNow
            });

            return response;
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error publishing weather update message: {ErrorMessage}", ex.Message);
            return await CreateErrorResponse(req, $"Internal server error: {ex.Message}", HttpStatusCode.InternalServerError);
        }
    }

    [Function("PublishRandomWeather")]
    public async Task<HttpResponseData> PublishRandomWeather(
        [HttpTrigger(AuthorizationLevel.Function, "post", Route = "weather/publish-random")] HttpRequestData req)
    {
        _logger.LogInformation("Random weather update publish request received at {RequestTime}", DateTime.UtcNow);

        try
        {
            // Generate random weather data
            var locations = new[] { "New York", "London", "Tokyo", "Sydney", "Paris", "Berlin", "Mumbai", "Toronto" };
            var summaries = new[] { "Freezing", "Bracing", "Chilly", "Cool", "Mild", "Warm", "Balmy", "Hot", "Sweltering", "Scorching" };
            
            var random = new Random();
            var weatherMessage = new WeatherUpdateMessage
            {
                Location = locations[random.Next(locations.Length)],
                TemperatureC = random.Next(-20, 55),
                Summary = summaries[random.Next(summaries.Length)],
                Timestamp = DateTime.UtcNow,
                Source = "Random-Publisher-Function"
            };

            // Get Service Bus configuration
            var connectionString = Environment.GetEnvironmentVariable("ServiceBusConnectionString");
            var queueName = Environment.GetEnvironmentVariable("QueueName");

            if (string.IsNullOrEmpty(connectionString) || string.IsNullOrEmpty(queueName))
            {
                return await CreateErrorResponse(req, "Service Bus not properly configured", HttpStatusCode.InternalServerError);
            }

            // Send message to Service Bus
            await using var client = new ServiceBusClient(connectionString);
            var sender = client.CreateSender(queueName);

            var message = new ServiceBusMessage(weatherMessage.ToJson())
            {
                MessageId = weatherMessage.Id,
                ContentType = "application/json",
                Subject = "RandomWeatherUpdate"
            };

            message.ApplicationProperties.Add("Location", weatherMessage.Location);
            message.ApplicationProperties.Add("Temperature", weatherMessage.TemperatureC);
            message.ApplicationProperties.Add("Source", weatherMessage.Source);

            await sender.SendMessageAsync(message);

            _logger.LogInformation("Random weather update published. MessageId: {MessageId}, Location: {Location}, Temperature: {Temperature}°C, Summary: {Summary}", 
                weatherMessage.Id, weatherMessage.Location, weatherMessage.TemperatureC, weatherMessage.Summary);

            // Create success response
            var response = req.CreateResponse(HttpStatusCode.OK);
            await response.WriteAsJsonAsync(new MessagePublishResponse
            {
                Success = true,
                MessageId = weatherMessage.Id,
                Message = $"Random weather update for {weatherMessage.Location} published successfully",
                Timestamp = DateTime.UtcNow
            });

            return response;
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error publishing random weather update: {ErrorMessage}", ex.Message);
            return await CreateErrorResponse(req, $"Internal server error: {ex.Message}", HttpStatusCode.InternalServerError);
        }
    }

    private async Task<HttpResponseData> CreateErrorResponse(HttpRequestData req, string errorMessage, HttpStatusCode statusCode)
    {
        var response = req.CreateResponse(statusCode);
        await response.WriteAsJsonAsync(new MessagePublishResponse
        {
            Success = false,
            Message = errorMessage,
            Timestamp = DateTime.UtcNow,
            ErrorDetails = errorMessage
        });
        return response;
    }
}
