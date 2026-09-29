# XR (Extended Reality)
---

![Evergine XR](images/xr.png)

## What is XR?

**XR** (Extended Reality) is an umbrella term that covers the following types of applications:

### **Virtual Reality (VR)**

The application simulates a completely different environment around the user.

![VR](images/vr.jpg)

### **Mixed Reality (MR)**

The application combines its own environment with the user's real-world environment and allows them to interact with each other.

![VR](images/mr.jpg)

### **Augmented Reality (AR)**

The application layers content over a digital view of the real world.

![AR](images/ar.jpg)


## Evergine XR

In Evergine, you can develop with different XR platforms and solutions, and Evergine XR helps users to handle multiple XR technologies.

**Evergine XR** is an abstraction layer that allows multiple XR implementations (OpenXR, Mixed Reality, etc.) to be used in a standardized way in your interactive applications.

**Evergine XR** is included by default in the **Evergine.Framework** and **Evergine.Components** NuGet packages, and it exposes an abstract service (XRPlatform), which is the entry point to start creating XR applications. Different XR technology integrations provide implementations of the XRPlatform service, and these are provided using Evergine extensions or add-ons.

This functionality will be covered in the following documents in this section.

## XR Integrations

Evergine includes several XR platform integrations.

### [OpenXR](openxr/index.md)

**OpenXR** is an open, royalty-free API standard from Khronos, designed to unify development across multiple VR/MR/AR (XR) devices.

This initiative is backed by companies like Meta, Microsoft, HTC, Steam, Varjo, and Magic Leap, enabling support for all their devices.

![OpenXR](openxr/images/openxr_logo.png)

## In this section

* [XR Platform](xrplatform.md)
* [OpenXR](openxr/index.md)
* [Input Devices](input_tracking/index.md)
* [Passthrough](passthrough.md)