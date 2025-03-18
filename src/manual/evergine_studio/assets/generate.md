# Generate AI-Driven Assets

To integrate AI-driven 3D model generation within Evergine Studio, a dedicated tab has been introduced. Below are the steps to utilize this functionality:

## Accessing the AI Model Generation Feature

Navigate to the AI Generation Tab by clicking on the "Generative assets" menu item located under the "Assets" menu of the main toolbar.

![Assets](images/generativeAssets.png)

## Gallery

The first screen is the Gallery, where you can find the generated assets you have saved.

![Assets](images/generateGallery.jpg)

### Filter and sort

At the top of the gallery, you will find filters and sorting options to help you locate assets within the gallery.

### Reuse the prompt

The left button of a gallery item allows you to reuse the prompt. Clicking it will display the generation view with the prompt pre-filled using the data from the selected gallery item.

### Add to current project

The right button of a gallery item adds the item to the current project. Clicking it will add the gallery item to the current folder you have opened in the asset details view of the project.

## Create asset

Currently, Evergine supports the creation of 3D models using Tripo AI. Future updates may introduce support for additional AI providers and the possibility to generate other types of assets such as textures, cubemaps, and more.

![Assets](images/generateCreate.jpg)

### Initial Setup

Enter Your TripoAI API Key:
   - Before generating models, you must provide a valid Tripo AI API key.
   - Within the AI Generation view, click the "Manage API key" button.
   - Create a Tripo AI API key from its platform: https://platform.tripo3d.ai/api-keys
   - Input your TripoAI API key in the designated field and click "Save key".

![Assets](images/generateTripoAI.png)

### Monitoring TripoAI Credits

Evergine integrates with TripoAI APIs to display your real-time credit balance.
This feature helps you plan and manage model generation according to your available resources.

### Methods for Generating 3D Models

Evergine offers three methods for AI-driven 3D model generation:

1. **Text Generation**:
   - Select the "Text" tab.
   - Provide a detailed description of the desired model in the positive prompt field.
   - Optionally, use a negative prompt to exclude specific features.

2. **Image Generation**:
   - Choose the "Image" tab.
   - Upload a reference image from your device using the upload function or by dragging and dropping the image into the designated area.

3. **Multiview Generation**:
   - Choose the "Multiview" tab.
   - Upload up to 4 images from your device using the upload function or by dragging and dropping the image into the designated area.

![Assets](images/generateTripoAI2.png)

#### Additional options

- All three generation methods support the option to enable HD Texture.
- The Text and Image generation methods provide options to select a desired style, defining the artistic style or transformation to be applied to the 3D model, altering its appearance according to preset options.

#### Generating Multiple Proposals

![Assets](images/generateProposals.png)

- To expedite the creative process, Evergine allows simultaneous generation of multiple proposals (1, 2, or 4).
- Each proposal is processed in parallel with individual progress indicators.
- Be aware that each generation consumes credits from your TripoAI account.

### Managing Models

You can save each generated model in the current project and the gallery by clicking the "Save asset" button and providing a name.