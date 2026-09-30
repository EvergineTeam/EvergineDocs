# Storage

---

When your application needs files from an external repository, such as 3D models or images, XRV's storage system gives you one API for all of them. `FileAccess` is the abstract base class: its implementations read and write files in local storage, Azure Blob Storage, or Azure Files, and you can derive your own for other repositories. Modules like the [Model Viewer](modules/modelViewer/index.md) and the [Image Gallery](modules/imageGallery/index.md) take a `FileAccess` as their data source.

The storage types live in the `Evergine.Xrv.Core.Storage` namespace, and the disk cache in `Evergine.Xrv.Core.Storage.Cache`.

## File access

Every `FileAccess` implementation offers these operations. Paths are relative to `BaseDirectory`, and every method accepts an optional `CancellationToken`.

| Method | Description |
| --- | --- |
| `ClearAsync` | Deletes all the files and directories. |
| `CreateBaseDirectoryIfNotExistsAsync` | Creates the directory set in `BaseDirectory` if it does not exist. |
| `CreateDirectoryAsync` | Creates a directory. |
| `DeleteDirectoryAsync` | Deletes a directory. |
| `DeleteFileAsync` | Deletes a file. |
| `EnumerateDirectoriesAsync` | Lists the directories in the base directory or in a relative path. Returns `DirectoryItem` objects. |
| `EnumerateFilesAsync` | Lists the files in the base directory or in a relative path. Returns `FileItem` objects, with name, path, size, dates, and MD5 hash when available. |
| `ExistsDirectoryAsync` | Checks whether a directory exists. |
| `ExistsFileAsync` | Checks whether a file exists. |
| `GetFileAsync` | Opens a file and returns its content as a `Stream`. |
| `GetFileItemAsync` | Returns the metadata of a file as a `FileItem`. |
| `WriteFileAsync` | Writes a `Stream` to a file. |

| Property | Default | Description |
| --- | --- | --- |
| `BaseDirectory` | `null` | Directory, inside the storage, that relative paths start from. |
| `Cache` | `null` | Optional [disk cache](#disk-cache). |
| `IsCachingEnabled` | `false` | Read-only. `true` when `Cache` is set. |

For example, this method lists the files of a repository and reads the first one:

```csharp
using System.IO;
using System.Linq;
using System.Threading.Tasks;
using Evergine.Xrv.Core.Storage;

public static class StorageSample
{
    public static async Task<long> ReadFirstFileAsync(FileAccess fileAccess)
    {
        var files = await fileAccess.EnumerateFilesAsync();
        var first = files.FirstOrDefault();
        if (first == null)
        {
            return 0;
        }

        using (Stream stream = await fileAccess.GetFileAsync(first.Path))
        using (var memory = new MemoryStream())
        {
            await stream.CopyToAsync(memory);
            return memory.Length;
        }
    }
}
```

## Local application data

`ApplicationDataFileAccess` stores files in the local application data folder of the device (`System.Environment.SpecialFolder.LocalApplicationData`, whose location depends on the platform). Set `BaseDirectory` to the folder you want to use. It suits caches and temporary files; depending on the platform, other applications may not be able to see these files.

```csharp
var fileAccess = new ApplicationDataFileAccess()
{
    BaseDirectory = "my-folder",
};
```

The constructor that takes a `rootPath` stores the files under that path instead.

> [!NOTE]
> XRV uses some folders internally. Do not use `cache` as the base directory name.

## Azure Blob Storage

`AzureBlobFileAccess` reads and writes blobs in an Azure Storage container. Create it from a connection string, from a container URI, or from a URI and a separate SAS token. Blob Storage has no real directories, so the directory methods may not behave as they do in a file system. If you authenticate with a SAS, give it the permissions for every operation you need.

```csharp
using System;
using Evergine.Xrv.Core.Storage;

// From a connection string and a container name.
var fromConnectionString = AzureBlobFileAccess.CreateFromConnectionString("<connection string>", "<container name>");

// From a container URI that includes the SAS token. A public container needs no SAS for read-only access.
var fromUri = AzureBlobFileAccess.CreateFromUri(new Uri("https://<ACCOUNT>.blob.core.windows.net/<container>?sv=..."));

// From a container URI and a separate SAS token.
var fromSignature = AzureBlobFileAccess.CreateFromSignature(new Uri("https://<ACCOUNT>.blob.core.windows.net/<container>"), "sv=...");
```

## Azure Files

`AzureFileShareFileAccess` works the same way with an Azure Files share:

```csharp
using System;
using Evergine.Xrv.Core.Storage;

var fromConnectionString = AzureFileShareFileAccess.CreateFromConnectionString("<connection string>", "<share name>");

var fromUri = AzureFileShareFileAccess.CreateFromUri(new Uri("https://<ACCOUNT>.file.core.windows.net/<share>?sv=..."));

var fromSignature = AzureFileShareFileAccess.CreateFromSignature(new Uri("https://<ACCOUNT>.file.core.windows.net/<share>"), "sv=...");
```

## Disk cache

Any `FileAccess` can use a disk cache. When it is enabled, `GetFileAsync` looks for the file in the cache before downloading it again. Create a `DiskCache` with a name that is unique in your application and assign it to the `Cache` property:

```csharp
var fileAccess = AzureFileShareFileAccess.CreateFromUri(new Uri("https://<ACCOUNT>.file.core.windows.net/<share>?sv=..."));
fileAccess.Cache = new DiskCache("images");
```

| `DiskCache` property | Default | Description |
| --- | --- | --- |
| `SizeLimit` | 100 MB | Maximum size of the cache, in bytes. When it is exceeded, the least recently used files are removed. |
| `SlidingExpiration` | `TimeSpan.MaxValue` | Time a file stays in the cache without being accessed. The default keeps files until the size limit removes them. |
| `CurrentCacheSize` | | Read-only. Current size of the cache, in bytes. |
