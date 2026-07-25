# ===========================
# Build Stage
# ===========================
FROM mcr.microsoft.com/dotnet/sdk:8.0 AS build

WORKDIR /src

COPY Directory.Packages.props .
COPY nuget.config .

COPY BusinessLayer/BusinessLayer.csproj BusinessLayer/
COPY DataLayer/DataLayer.csproj DataLayer/
COPY RasAlSouqPresentaionLayer/RasAlSouqPresentaionLayer.csproj RasAlSouqPresentaionLayer/

# nuget.config references .nuget-cache for local offline restores; create it for Docker.
RUN mkdir -p .nuget-cache \
    && dotnet restore RasAlSouqPresentaionLayer/RasAlSouqPresentaionLayer.csproj

COPY . .

WORKDIR /src/RasAlSouqPresentaionLayer

RUN dotnet publish -c Release -o /app/publish --no-restore

# ===========================
# Runtime Stage
# ===========================
FROM mcr.microsoft.com/dotnet/aspnet:8.0

WORKDIR /app

COPY --from=build /app/publish .

EXPOSE 8080

ENTRYPOINT ["dotnet", "RasAlSouqPresentaionLayer.dll"]