# Detailed Information to Develop, Debug, and Deploy Evergine for the Web

## Build

Use VS2022 or VSCode/Terminal. You can build and test only the client project (web); the server is only needed for publishing with compression (see below).

`dotnet build -c [Debug|Release] ./sample.web/sample.web.[Server.]csproj`

## Run

From VS2022, you can run the profile `sample.web[.Server]`. There is also an IIS Express profile for each client and server project, but it is usually slower.

Additionally, you can publish the app using the following command:

`dotnet publish -c [Debug|Release] ./sample.web/sample.web.csproj`

Then, run the app by populating the folder `./sample.web/bin/[Debug|Release]/net10.0/publish/wwwroot`. In this second case, we recommend using VSCode Live Server instead of Fenix, as the latter has known issues with Web Assembly.

### Debug

Debugging is now possible from VS2022 by running the application in debug mode only on the __Chrome__ browser.

## Publish with Compression

To publish the application with automatic compression (Brotli & GZip), the AspNetCore server is needed. Use VS2022 or Terminal:

`dotnet publish -c Release -r win-x86 --self-contained ./sample.web.Server/sample.web.Server.csproj`

If done from the terminal, you can publish the files in `sample.web.Server/bin/Release/net10.0/win-x86/publish` to an AspNetCore server, either from VSCode or manually.