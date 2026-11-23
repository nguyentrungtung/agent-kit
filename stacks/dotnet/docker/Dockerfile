# syntax=docker/dockerfile:1
# agent-kit: ASP.NET Core — publish with the SDK, run on aspnet runtime as the built-in non-root "app" user.
FROM mcr.microsoft.com/dotnet/sdk:8.0 AS build
WORKDIR /src
COPY . .
RUN dotnet restore && dotnet publish -c Release -o /out --no-restore

FROM mcr.microsoft.com/dotnet/aspnet:8.0 AS runtime
WORKDIR /app
COPY --from=build /out .
USER app
EXPOSE 8080
ENTRYPOINT ["dotnet", "App.dll"]
