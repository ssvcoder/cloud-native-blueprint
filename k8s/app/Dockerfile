# Multi-stage build: compile with the full SDK, ship only the runtime.
# Keeps the final image small and free of build tooling.

FROM mcr.microsoft.com/dotnet/sdk:8.0 AS build
WORKDIR /src
COPY ["HelloApi.csproj", "./"]
RUN dotnet restore "HelloApi.csproj"
COPY . .
RUN dotnet publish "HelloApi.csproj" -c Release -o /app/publish --no-restore

FROM mcr.microsoft.com/dotnet/aspnet:8.0 AS runtime
WORKDIR /app
# Run as a non-root user — least privilege inside the container.
USER app
EXPOSE 8080
ENV ASPNETCORE_URLS=http://+:8080
COPY --from=build /app/publish .
ENTRYPOINT ["dotnet", "HelloApi.dll"]
