var builder = WebApplication.CreateBuilder(args);

// Add services to the container.
// Learn more about configuring Swagger/OpenAPI at https://aka.ms/aspnetcore/swashbuckle
builder.Services.AddEndpointsApiExplorer();
builder.Services.AddSwaggerGen();

// Add Application Insights telemetry
builder.Services.AddApplicationInsightsTelemetry();

var app = builder.Build();

 
app.UseSwagger();
app.UseSwaggerUI();
app.UseHttpsRedirection();

var summaries = new[]
{
    "Freezing", "Bracing", "Chilly", "Cool", "Mild", "Warm", "Balmy", "Hot", "Sweltering", "Scorching"
};

app.MapGet("/weatherforecast", (ILogger<Program> logger) =>
{
    logger.LogInformation("Weather forecast requested at {RequestTime}", DateTime.UtcNow);
    
    var forecast =  Enumerable.Range(1, 5).Select(index =>
        new WeatherForecast
        (
            DateOnly.FromDateTime(DateTime.Now.AddDays(index)),
            Random.Shared.Next(-20, 55),
            summaries[Random.Shared.Next(summaries.Length)]
        ))
        .ToArray();
        
    logger.LogInformation("Generated {ForecastCount} weather forecasts", forecast.Length);
    return forecast;
})
.WithName("GetWeatherForecast")
.WithOpenApi();

app.MapGet("/health", (ILogger<Program> logger) =>
{
    logger.LogInformation("Health check requested at {RequestTime}", DateTime.UtcNow);
    return Results.Ok(new { Status = "Healthy", Timestamp = DateTime.UtcNow, Version = "1.0.0" });
})
.WithName("HealthCheck")
.WithOpenApi();

app.Run();

record WeatherForecast(DateOnly Date, int TemperatureC, string? Summary)
{
    public int TemperatureF => 32 + (int)(TemperatureC / 0.5556);
}
