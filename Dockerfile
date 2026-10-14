FROM mcr.microsoft.com/dotnet/sdk:10.0 AS build
WORKDIR /src
COPY ["DashCash.csproj", "./"]
RUN dotnet restore "DashCash.csproj"
COPY . .
RUN dotnet publish "DashCash.csproj" -c Release -o /app/publish

FROM mcr.microsoft.com/dotnet/aspnet:10.0 AS final
WORKDIR /app
COPY --from=build /app/publish .
ENTRYPOINT ["dotnet", "DashCash.dll"]