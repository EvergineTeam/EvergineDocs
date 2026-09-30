# Logging

---

XRV includes a logging service that implements `Microsoft.Extensions.Logging.ILogger` and writes through [Serilog](https://serilog.net/). Once you enable it, XRV logs its own initialization steps, and your components and services can log through the same `ILogger`, to the debug output and optionally to a file.

## Enable logging

Call `WithLogging` on `XrvService` with a `LoggingConfiguration`, before you call `Initialize`, so the initialization of XRV and its modules is logged too:

```csharp
using Evergine.Xrv.Core;
using Evergine.Xrv.Core.Services.Logging;
using Microsoft.Extensions.Logging;

var xrv = new XrvService()
    .WithLogging(new LoggingConfiguration
    {
        LogLevel = LogLevel.Debug,
        FileOptions = new FileLoggingOptions
        {
            FileName = "xrv.log",
            MaxFileSize = 10 * 1024 * 1024,
        },
    });

this.Container.RegisterInstance(xrv);
```

`WithLogging` registers the logger as an `ILogger` instance in the application container and exposes it as `XrvService.Services.Logging`.

| `LoggingConfiguration` property | Default | Description |
| --- | --- | --- |
| `LogLevel` | `LogLevel.Information` | Minimum level of the messages that are logged. |
| `FileOptions` | `null` | File logging options. Leave it `null` to skip file logging. |
| `EnableFileLogging` | `false` | Read-only. `true` when `FileOptions` is set. |

| `FileLoggingOptions` property | Description |
| --- | --- |
| `FileName` | Name of the log file. It is created in the `logs` folder of the local application data folder of the device. |
| `MaxFileSize` | Maximum size of each log file, in bytes. When a file reaches it, logging continues in a new file. |

> [!IMPORTANT]
> File logging only starts when `MaxFileSize` has a value. Log files also roll every day, and the ten most recent files are kept.

## Use the logger

Resolve the logger from the container anywhere in your code:

```csharp
var log = Application.Current.Container.Resolve<ILogger>();
```

or bind it in a component:

```csharp
using Evergine.Framework;
using Microsoft.Extensions.Logging;

public class LoggedComponent : Component
{
    [BindService]
    private ILogger log = null;

    protected override void Start()
    {
        base.Start();

        this.log.LogDebug("Component started");
        this.log.LogWarning("Something looks odd");
        this.log.Log(LogLevel.Error, "Something failed");
    }
}
```
