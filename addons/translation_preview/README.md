<h1 align="center">
	<b>TranslationPreview</b> <br>
	<img alt="Logo" src="icon.svg">
</h1>
<p align="center">
A plugin for Godot to preview translations directly inside the editor.<br>
<a href="https://godotengine.org/download/archive/">
	<img alt="Static Badge" src="https://img.shields.io/badge/Godot-4.0%2B-blue">
</a>
<a href="LICENSE">
<img alt="GitHub License" src="https://img.shields.io/github/license/1MaxSon/translation_preview">
</a>
<img alt="Stars" src="https://img.shields.io/github/stars/1MaxSon/translation_preview">
</p>

## Features
- **Text translation inside the editor:** Allows you to view translated lines directly in the Godot editor, without having to start the game.
- **Support for custom nodes:** Support for custom nodes is easily added using the `tr_editor` function, which makes it possible to translate text in custom components.
- **Flexibility in configuration:** The ability to add additional translation handlers for different node types via the configuration file
  <p align="center"><img src="demo.gif"></p>

## Installation Guide
### Asset Library Installation
1. Open the "AssetLib" tab in the Godot Editor.
2. Search for "TranslationPreview" in the search bar.
3. Click the download button next to the TranslationPreview plugin.
4. In the installation window, select the files you want to install and click "Install".
5. Once the installation is complete, go to "Project" -> "Project Settings" -> "Plugins".
6. Find the TranslationPreview plugin in the list and enable it by checking the box next to it.
### Installation from GitHub
1. Visit the [TranslationPreview plugin GitHub repository](https://github.com/1MaxSon/translation_preview).
2. Navigate to the [Releases](https://github.com/1MaxSon/translation_preview/releases/latest) page.
3. Download the latest stable release version.
4. Extract the downloaded files into your Godot project's `addons` folder.

## Usage
After enabling the plugin, an option button will appear in the toolbar (top-right corner). If translations are uploaded to the project, you can click the button and select a language to preview.
> [!NOTE]
> After making changes to your translation file, you must **restart** the project in the Godot Editor for the changes to take effect
---
## Adding Previews for Custom Nodes
To add a translation preview to your node, you need to implement a method called `tr_editor`. This method handles the logic for switching between translation and original text modes. Below is a guide and example implementation.

### Method Overview: 
The `tr_editor` method takes two parameters:
- `translation_mode` (bool): Indicates whether translation mode is active.
- `nodes_data` (Dictionary): Stores the original text/data for nodes to allow toggling between translated and original versions.  

Return value:  
The method should return the updated `nodes_data`, which contains the state for each node, as well as the saved original texts, if necessary.

### Example Implementation
Here is an example implementation of `tr_editor`, designed to translate a Label's text:

```gd
func tr_editor(translation_mode: bool, nodes_data: Dictionary) -> Dictionary:
    if translation_mode:
        if not nodes_data.has(self):
            nodes_data[self] = text  # Save the original text
		# A custom TranslationService is used, since the built-in TranslationServer does not translate inside the editor
        text = TranslationService.translate(nodes_data[self])  # Translate the text
    else:
        if nodes_data.has(self):
            text = nodes_data[self]  # Restore the original text
            nodes_data.erase(self)  # Remove the entry from the dictionary
    return nodes_data
```
## Adding Translation Previews for Nodes from Addons
If you need to add translation support for nodes from addons, follow these steps:

1. **Create a Translation Handler File**  
   Create a file, for example `translation_handlers.gd`, and add the following content:

   ```gd
   @tool
   extends Object

   # A dictionary mapping node class names to their respective handlers
   var handlers := {
       "AddonNodeClassName": tr_addon_node,  # Replace with the actual class name of your addon node
   }

   # Translation handler function for addon nodes
   func tr_addon_node(node: AddonNode, translation_mode: bool, nodes_data: Dictionary) -> Dictionary:
       if translation_mode:
           if not nodes_data.has(node):
               nodes_data[node] = node.data  # Save the original node data
           # Use TranslationService because the built-in TranslationServer does not work inside the editor
           node.data = TranslationService.translate(nodes_data[node])  # Translate the node data
       else:
           if nodes_data.has(node):
               node.data = nodes_data[node]  # Restore the original node data
               nodes_data.erase(node)  # Remove the entry from the dictionary
       return nodes_data
   ```

2. **Configure the Handler Path in Project Settings**  
   In your project settings, navigate to `translation_preview/translation_handlers_path` and set the path to the file you created, for example:  
   ```
   res://addons/your_plugin/translation_handlers.gd
   ```

### Code Explanation
- **`handlers`**: A dictionary where the keys are the names of the addon node classes, and the values are functions that handle their translation logic.
- **`tr_addon_node`**: A translation handler function for addon nodes. It:
  1. Saves the node's original data when translation mode is enabled.
  2. Uses `TranslationService` to translate the node's data.
  3. Restores the original data when translation mode is disabled.
- **`nodes_data`**: A dictionary that maps nodes to their original data, ensuring the ability to toggle between translated and original text.
