---
description: "C# / .NET 10 + ASP.NET Core + EF Core standards"
paths:
  - "**/*.cs"
  - "**/*.csproj"
  - "**/*.sln"
  - "**/*.slnx"
  - "**/Directory.Build.props"
  - "**/appsettings*.json"
---

# C# / .NET

## Language & Project
- New projects: `<Nullable>enable</Nullable>`, `<ImplicitUsings>enable</ImplicitUsings>`, `<TreatWarningsAsErrors>true</TreatWarningsAsErrors>`. Fix nullable warnings; don't silence them with `!`.
- Use records for DTOs and value objects; `required` + `init` for mandatory properties; file-scoped namespaces; pattern matching over type checks and casts.
- Async all the way down: never `.Result`/`.Wait()`/`async void` (except event handlers). Accept and pass a `CancellationToken` through every async call chain.
- Money is `decimal`, never `double`.
- Log with `ILogger` message templates (`logger.LogInformation("Order {OrderId} placed", id)`), never interpolated strings; use `[LoggerMessage]` source generators on hot paths.

## ASP.NET Core
- Constructor/primary-constructor DI. Choose lifetimes deliberately; never capture a scoped service (e.g. `DbContext`) in a singleton.
- Options pattern: `services.AddOptions<T>().BindConfiguration(...).ValidateDataAnnotations().ValidateOnStart()`.
- Return `TypedResults`/`Results<...>` from minimal APIs (or `ActionResult<T>` in controllers); register `AddProblemDetails()` so errors are RFC 9457 `ProblemDetails`.
- Validate every request body; never bind EF entities directly to requests or responses — map to DTO records.
- Require authorization explicitly (`RequireAuthorization()` / a fallback policy); auth on the page/route is not enough for APIs.
- Use `IHttpClientFactory` / typed clients; never `new HttpClient()` per request.
- Secrets: `dotnet user-secrets` in development, environment variables or a vault in production; never secrets in `appsettings*.json`.

## EF Core
- Read paths: `AsNoTracking()` and project with `Select` into DTOs; avoid N+1 with projection or deliberate `Include`.
- Schema changes only via `dotnet ef migrations add <Name>`; read the generated migration before applying; never mix `EnsureCreated()` with migrations.
- Raw SQL only through `FromSql`/`ExecuteSql` with interpolated parameters (parameterized). Never `FromSqlRaw` with string concatenation.
- Use `ExecuteUpdateAsync`/`ExecuteDeleteAsync` for set-based changes instead of load-modify-save loops.

## Dependencies & Testing
- Don't add MediatR, AutoMapper, or MassTransit v9+ by reflex: they moved to commercial licenses in 2025. Plain services and explicit mapping are fine. FluentAssertions 8+ also needs a commercial license; prefer AwesomeAssertions or Shouldly.
- xUnit + `WebApplicationFactory<Program>` for API integration tests; Testcontainers for a real Postgres.
- Verify with `dotnet build -warnaserror` and `dotnet test`; format with `dotnet format`.
