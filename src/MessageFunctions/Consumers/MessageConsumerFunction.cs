using Azure.Messaging.ServiceBus;
using MessageFunctions.Models;
using Microsoft.Azure.Functions.Worker;
using Microsoft.Extensions.Logging;
using System.Text.Json;

namespace MessageFunctions.Consumers;

public class MessageConsumerFunction
{
    private readonly ILogger<MessageConsumerFunction> _logger;

    public MessageConsumerFunction(ILogger<MessageConsumerFunction> logger)
    {
        _logger = logger;
    }

    [Function("ProcessWeatherUpdate")]
    public async Task ProcessWeatherUpdate(
        [ServiceBusTrigger("weather-updates-queue", Connection = "ServiceBusConnectionString")] 
        ServiceBusReceivedMessage message,
        ServiceBusMessageActions messageActions)
    {
        try
        {
            _logger.LogInformation("Processing weather update message. MessageId: {MessageId}, DeliveryCount: {DeliveryCount}", 
                message.MessageId, message.DeliveryCount);

            // Log message metadata
            _logger.LogInformation("Message metadata - Subject: {Subject}, ContentType: {ContentType}, EnqueuedTime: {EnqueuedTime}", 
                message.Subject, message.ContentType, message.EnqueuedTime);

            // Parse the weather update message
            var messageBody = message.Body.ToString();
            var weatherUpdate = WeatherUpdateMessage.FromJson(messageBody);

            if (weatherUpdate == null)
            {
                _logger.LogError("Failed to deserialize weather update message. MessageId: {MessageId}, Body: {MessageBody}", 
                    message.MessageId, messageBody);
                
                // Dead letter the message if it can't be processed
                await messageActions.DeadLetterMessageAsync(message, deadLetterReason: "InvalidMessageFormat", deadLetterErrorDescription: "Unable to deserialize message body");
                return;
            }

            // Log the weather update details
            _logger.LogInformation("Weather update received - Location: {Location}, Temperature: {TemperatureC}°C ({TemperatureF}°F), Summary: {Summary}, Source: {Source}, Timestamp: {Timestamp}", 
                weatherUpdate.Location, 
                weatherUpdate.TemperatureC, 
                weatherUpdate.TemperatureF,
                weatherUpdate.Summary, 
                weatherUpdate.Source,
                weatherUpdate.Timestamp);

            // Log custom properties
            if (message.ApplicationProperties.Count > 0)
            {
                _logger.LogInformation("Message properties: {Properties}", 
                    string.Join(", ", message.ApplicationProperties.Select(kv => $"{kv.Key}={kv.Value}")));
            }

            // Simulate processing logic
            await ProcessWeatherData(weatherUpdate);

            // Log successful processing
            _logger.LogInformation("Weather update processed successfully. MessageId: {MessageId}, ProcessingTime: {ProcessingTime}ms", 
                message.MessageId, DateTime.UtcNow.Subtract(message.EnqueuedTime.DateTime).TotalMilliseconds);

            // Complete the message (this happens automatically with autoComplete: true in host.json)
        }
        catch (JsonException jsonEx)
        {
            _logger.LogError(jsonEx, "JSON parsing error for message {MessageId}: {ErrorMessage}", 
                message.MessageId, jsonEx.Message);
            
            // Dead letter messages with JSON parsing errors
            await messageActions.DeadLetterMessageAsync(message, deadLetterReason: "JsonParsingError", deadLetterErrorDescription: jsonEx.Message);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error processing weather update message {MessageId}: {ErrorMessage}", 
                message.MessageId, ex.Message);

            // For other errors, let the message retry (based on maxDeliveryCount in Service Bus)
            // The message will be automatically retried and eventually dead-lettered if it continues to fail
            throw; // Re-throw to trigger retry mechanism
        }
    }

    private async Task ProcessWeatherData(WeatherUpdateMessage weatherUpdate)
    {
        // Simulate weather data processing
        await Task.Delay(100); // Simulate some processing time

        // Log business logic
        if (weatherUpdate.TemperatureC > 30)
        {
            _logger.LogWarning("High temperature alert for {Location}: {Temperature}°C", 
                weatherUpdate.Location, weatherUpdate.TemperatureC);
        }
        else if (weatherUpdate.TemperatureC < 0)
        {
            _logger.LogWarning("Freezing temperature alert for {Location}: {Temperature}°C", 
                weatherUpdate.Location, weatherUpdate.TemperatureC);
        }

        // Custom telemetry for Application Insights
        var telemetryProperties = new Dictionary<string, string>
        {
            ["Location"] = weatherUpdate.Location,
            ["Source"] = weatherUpdate.Source,
            ["Summary"] = weatherUpdate.Summary
        };

        var telemetryMetrics = new Dictionary<string, double>
        {
            ["TemperatureC"] = weatherUpdate.TemperatureC,
            ["TemperatureF"] = weatherUpdate.TemperatureF,
            ["ProcessingDelay"] = (DateTime.UtcNow - weatherUpdate.Timestamp).TotalSeconds
        };

        _logger.LogInformation("Weather data processing completed for {Location}. Custom telemetry recorded.", 
            weatherUpdate.Location);

        // Simulate async operation
        await Task.CompletedTask;

        // Here you could add additional processing like:
        // - Save to database
        // - Send notifications
        // - Trigger other workflows
        // - Update caches
        // - Generate reports
    }

    [Function("ProcessDeadLetterMessages")]
    public async Task ProcessDeadLetterMessages(
        [ServiceBusTrigger("weather-updates-queue/$deadletterqueue", Connection = "ServiceBusConnectionString")] 
        ServiceBusReceivedMessage deadLetterMessage,
        ServiceBusMessageActions messageActions)
    {
        try
        {
            _logger.LogWarning("Processing dead letter message. MessageId: {MessageId}, DeadLetterReason: {DeadLetterReason}, DeadLetterDescription: {DeadLetterDescription}", 
                deadLetterMessage.MessageId, 
                deadLetterMessage.DeadLetterReason,
                deadLetterMessage.DeadLetterErrorDescription);

            // Log the original message content for investigation
            var messageBody = deadLetterMessage.Body.ToString();
            _logger.LogInformation("Dead letter message body: {MessageBody}", messageBody);

            // Simulate async processing of dead letter message
            await Task.Delay(50);

            // Here you could implement dead letter handling logic such as:
            // - Send alerts to administrators
            // - Store in a special database table for investigation
            // - Attempt manual processing with different logic
            // - Generate reports on failed messages

            _logger.LogInformation("Dead letter message logged for investigation. MessageId: {MessageId}", 
                deadLetterMessage.MessageId);

            // Complete the dead letter message to remove it from the queue
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error processing dead letter message {MessageId}: {ErrorMessage}", 
                deadLetterMessage.MessageId, ex.Message);
            
            // Re-throw to keep the dead letter message for further investigation
            throw;
        }
    }
}
