# Building the Template

This article guides you through running your first game on the Playdate simulator using Swift.

## Overview

By the end of this article you'll have the PlaydateKit example running on the Playdate simulator and will be ready to start creating your game.

### Duplicate the PlaydateKit Template

1. Navigate to the [PlaydateKitTemplate](https://github.com/finnvoor/PlaydateKitTemplate) GitHub repository.
2. Select **Use this Template > Create a new repository**.
3. Give your new repository a name and select **Create repository**.
4. Clone your new repository locally on your computer.

@TabNavigator {
   @Tab("Step 1") {
      ![A screenshot of the PlaydateKitTemplate repository](PlaydateKitTemplate)
   }

   @Tab("Step 2") {
       ![A screenshot of the PlaydateKitTemplate repository](PlaydateKitTemplate-Duplicate)
   }

   @Tab("Step 3") {
       ![A screenshot of the PlaydateKitTemplate repository template info](PlaydateKitTemplate-New)
   }
}

### Rename Your Game Package

While you can stick with the snazzy "PlaydateKitTemplate" name, you probably want to rename your Swift package to the name of your game.

1. Open **Package.swift** in your preferred editor.
2. Find and replace **PlaydateKitTemplate** with the name of your game. This should change the package name, product name and target, and target name. You should end up with a diff that looks like this:

```diff
diff --git a/Package.swift b/Package.swift
index c6f109c..2aa5985 100644
--- a/Package.swift
+++ b/Package.swift
@@ -14,14 +14,14 @@ if let path = Context.environment["PLAYDATE_SDK_PATH"] {
 }
 
 let package = Package(
-    name: "PlaydateKitTemplate",
-    products: [.library(name: "PlaydateKitTemplate", targets: ["PlaydateKitTemplate"])],
+    name: "MyGame",
+    products: [.library(name: "MyGame", targets: ["MyGame"])],
     dependencies: [
         .package(url: "https://github.com/finnvoor/PlaydateKit.git", branch: "main")
     ],
     targets: [
         .target(
-            name: "PlaydateKitTemplate",
+            name: "MyGame",
             dependencies: [.product(name: "PlaydateKit", package: "PlaydateKit")],
             swiftSettings: [
                 .enableExperimentalFeature("Embedded"),
```

3. Rename the **Sources > PlaydateKitTemplate** directory to the name chosen above.
4. *(Optional)* If you will be running your game from Xcode, you will need to modify the default xcschemes.
    1. Rename the existing xcscheme file located at `.swiftpm/xcode/xcshareddata/xcschemes/PlaydateKitTemplate.xcscheme`
    2. Open the xcscheme and change all occurences of **PlaydateKitTemplate** to the name of your game. You should end up with a diff that looks like this:

```diff
diff --git a/.swiftpm/xcode/xcshareddata/xcschemes/PlaydateKitTemplate.xcscheme b/.swiftpm/xcode/xcshareddata/xcschemes/MyGame.xcscheme
index b18125c..b3c2a4e 100644
--- a/.swiftpm/xcode/xcshareddata/xcschemes/PlaydateKitTemplate.xcscheme
+++ b/.swiftpm/xcode/xcshareddata/xcschemes/MyGame.xcscheme
@@ -15,9 +15,9 @@
             buildForAnalyzing = "YES">
             <BuildableReference
                BuildableIdentifier = "primary"
-               BlueprintIdentifier = "PlaydateKitTemplate"
-               BuildableName = "PlaydateKitTemplate"
-               BlueprintName = "PlaydateKitTemplate"
+               BlueprintIdentifier = "MyGame"
+               BuildableName = "MyGame"
+               BlueprintName = "MyGame"
                ReferencedContainer = "container:">
             </BuildableReference>
          </BuildActionEntry>
@@ -48,9 +48,9 @@
       <MacroExpansion>
          <BuildableReference
             BuildableIdentifier = "primary"
-            BlueprintIdentifier = "PlaydateKitTemplate"
-            BuildableName = "PlaydateKitTemplate"
-            BlueprintName = "PlaydateKitTemplate"
+            BlueprintIdentifier = "MyGame"
+            BuildableName = "MyGame"
+            BlueprintName = "MyGame"
             ReferencedContainer = "container:">
          </BuildableReference>
       </MacroExpansion>
```

### Running on the Playdate Simulator

#### Building From the Command Line

To build your package into a `pdx` file that can be run on the Playdate simulator, PlaydateKit comes with a `pdc` package plugin. To run this plugin, navigate to the root of your project and run the plugin.

```console
$ swift package pdc
```

Your package should be compiled into a `pdx` file located at `.build/plugins/PDCPlugin/outputs/PlaydateKitTemplate.pdx`, where PlaydateKitTemplate will be the name specified above. You can then open this `pdx` file directly in the Playdate simulator.

#### Building and Running From Xcode

To build using Xcode you will need to ensure Xcode is using the nightly Swift toolchain downloaded previously. Navigate to the **Xcode > Toolchains** menu item and select the Development Snapshot toolchain.

If you followed the xcscheme instructions above, your package should be ready to run from Xcode. Select the Run icon in the toolbar or press Cmd+R on your keyboard to start building. This will automatically run the `pdc` package plugin and launch the Playdate simulator with your newly build game.

> Tip: If your game doesn't launch when run from Xcode, try running `swift package pdc` from the command line to debug any build issues.

If everything worked, you should now see the default PlaydateKit game running on the Playdate simulator.

![A screenshot of the PlaydateKitTemplate game running on the Playdate simulator](PlaydateKitTemplate-Simulator)
