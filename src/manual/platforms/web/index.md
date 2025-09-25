# Evergine on the web with WebGL and WebAssembly

---
An Evergine application can be deployed as a web app, using **WebGL 2.0** or **WebGPU** as the rendering API.

Evergine web applications can run statically on the client side quite fast by using Blazor WebAssembly for native code execution. Furthermore, they are optimized for fast loading by parallelizing asset downloading and leveraging compression techniques such as Brotli and Zip. Finally, to improve loading as much as possible, which is crucial on websites, we also provide an optional ASP server application that implements some optimizations that can only be done from the server side.

## Prerequisites

- .NET 8.0 SDK
  - Install Visual Studio 2022 (Recommended)
  - Alternatively, [install](https://dotnet.microsoft.com/download/dotnet/8.0) the latest .NET SDK release.
- Install wasm-tools
  - From the Visual Studio Installer, add the _web development workload_ and the _.NET WebAssembly build tools_ individual component.
  - Additionally, install the `wasm-tools` workload in a root terminal: `dotnet workload install wasm-tools`

## Limitations

- WebGPU integration in Evergine is still an experimental feature, and some characteristics may not yet be well supported.

## In this section

- [Getting Started](getting_started.md)
- [DevOps](ops.md)
- [Tips](tips.md)
<!-- - [Working with inputs and outputs](io.md) -->
