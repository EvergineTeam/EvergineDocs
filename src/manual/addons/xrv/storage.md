# Storage

If your application requires an external repository for models, images, or other files, _XRV_ offers a flexible file storage system. The base class, _FileAccess_, can be extended to create custom implementations with full CRUD capabilities for files in various storage repositories.

## File Access

The following methods are available in any _FileAccess_ implementation and provide core functionalities for file and directory operations.

| Method | Description |
| ------ | ------------------- |
| **ClearAsync** | Clears all files and directories. |
| **CreateBaseDirectoryIfNotExistsAsync** | Ensures that the base directory defined by _BaseDirectory_ exists. If it does not exist, the directory is created. |
| **CreateDirectoryAsync** | Creates a directory, indicated by a relative path. |
| **DeleteDirectoryAsync** | Deletes a directory, indicated by a relative path. |
| **DeleteFileAsync** | Deletes a file, indicated by a relative path. |
| **GetFileAsync** | Gets file contents by relative path. |
| **GetFileItemAsync** | Gets file metadata by relative path. |
| **EnumerateDirectoriesAsync** | Enumerates directories existing in the base directory or a relative directory path. |
| **EnumerateFilesAsync** | Enumerates files existing in the base directory or a relative directory path. |
| **ExistsDirectoryAsync** | Checks if a directory, indicated by a relative path, exists or not. |
| **WriteFileAsync** | Writes file contents by relative path. |

### Local Application Data Folder Storage

The _ApplicationDataFileAccess_ implementation sets the base path to _System.Environment.SpecialFolder.LocalApplicationData_, which varies depending on the platform. To use this storage, set the _BaseDirectory_ to the desired folder name. This option is ideal for data caching or temporary file storage, but note that files may not be accessible outside of the application depending on the platform.

```csharp
var fileAccess = new ApplicationDataFileAccess()
{
    BaseDirectory = "my-folder",
};
```
> [!NOTE]
> Some folders are used internally. Avoid using _"cache"_ as the base directory name.

### Azure Blob Data Storage

_Azure Blob Storage_ can also be used for storing and retrieving files needed by your application. To set up an Azure Blob instance, provide storage account configuration details. Note that directory methods may not work here, as Azure Blob Storage does not support traditional directories. When using SAS (Shared Access Signature), ensure it includes permissions for full CRUD access if needed.

```csharp
var fileAccess = AzureBlobFileAccess.CreateFromConnectionString("Storage account connection string", "Container name"); //or
var fileAccess = AzureBlobFileAccess.CreateFromUri("https://<ACCOUNT>.blob.core.windows.net/container?sv=2021-08-06&st=2022-11-18T15%3A07%3A20Z&..."); // Container URI containing SAS (or without SAS for public containers, if you need read-only operations)
var fileAccess = AzureBlobFileAccess.CreateFromConnectionString("https://<ACCOUNT>.blob.core.windows.net/container", "sv=2021-08-06&st=2022-11-18T15%3A07%3A20Z&...");  // Container URI with separated SAS
```

### Azure Files Data Storage

_Azure Files_ is another supported storage option that uses similar configuration parameters. You can set up Azure Files using the connection configuration data provided.

```csharp
var fileAccess = AzureFileShareFileAccess.CreateFromConnectionString("Storage account connection string", "Share name"); //or
var fileAccess = AzureFileShareFileAccess.CreateFromUri("https://<ACCOUNT>.file.core.windows.net/share?sv=2021-08-06&st=2022-11-18T15%3A07%3A20Z&..."); // Share URI containing SAS
var fileAccess = AzureFileShareFileAccess.CreateFromConnectionString("https://<ACCOUNT>.file.core.windows.net/share", "sv=2021-08-06&st=2022-11-18T15%3A07%3A20Z&...");  // Share URI with separated SAS
```

## Disk Cache

Any _FileAccess_ instance can use an optional disk cache, which will check for and retrieve files locally before attempting to download them again. To enable caching, create a _DiskCache_ instance and assign it to the _FileAccess_ instance.

```csharp
var fileAccess = AzureFileShareFileAccess.CreateFromUri(...);
fileAccess.Cache = new DiskCache("images"); // indicate a unique cache name for your needs
```

Cache settings include the following options:

| Property | Description |
| ------ | ------------------- |
| SizeLimit | Cache size limit. Defaults to 100 MB. |
| SlidingExpiration | Maximum time an item remains in cache without being accessed. |
