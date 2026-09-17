# Manage services

The **Services** section in **Project Settings** allows you to manage the application services used by your project directly from Evergine Studio. Services provide application-wide functionality and can be accessed from scenes, components, behaviors, and other parts of your application.

![Manage services](images/services_manage.png)

## Add and remove services

Click **Add** to display the available service types and add a new service to the project. Services added from this panel are automatically registered in the application, so no additional registration code is required.

To remove one or more services, select them from the list and click **Remove**. Removing a service from this list also prevents it from being automatically registered by Evergine.

Services can still be registered manually from your application code. If the same service is configured in **Project Settings** and also registered explicitly from code, the registration performed from your code takes precedence over the automatically registered service. This allows you to override the Editor configuration when custom initialization or registration logic is required.

## Configure services

When you select a service from the list, its configurable properties are displayed on the right side of the window.

You can modify these properties using the standard property editors provided by Evergine Studio. The appropriate editor is displayed according to the property type, allowing services to expose configuration that can be edited directly from the project settings.

Changes made to the service configuration are automatically serialized into the project's `.weservices` file. This file stores the services configured for the project together with their property values.

When the application starts, Evergine uses this configuration to instantiate and automatically register the configured services, making them available through the standard Evergine service mechanisms.

This provides a convenient way to configure application services without writing registration code while still allowing manual code registration whenever more control over the service initialization is needed.