// Minimal ASP.NET Core "hello" API used by the Cloud-Native Blueprint.
// Endpoints:
//   GET /        -> greeting JSON (message comes from APP_GREETING env var)
//   GET /healthz -> liveness/readiness probe target for Kubernetes
using System.Net;

var builder = WebApplication.CreateBuilder(args);
var app = builder.Build();

// Greeting is injected via the hello-api-config ConfigMap (APP_GREETING).
var greeting = app.Configuration["APP_GREETING"] ?? "Hello, world!";
var version = app.Configuration["APP_VERSION"] ?? "dev";

app.MapGet("/", () => Results.Json(new
{
    message = greeting,
    version,
    hostname = Dns.GetHostName(), // shows which pod served the request
    timestamp = DateTimeOffset.UtcNow
}));

app.MapGet("/healthz", () => Results.Ok(new { status = "healthy" }));

app.Run();
