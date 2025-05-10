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

While you can stick with the "PlaydateKitTemplate" name, you probably want to rename your Swift package to the name of your game. PlaydateKit comes with a package plugin to ensure all the necessary files are renamed correctly.

To rename your game package, run:

```console
swift package rename --allow-writing-to-package-directory --from PlaydateKitTemplate --to <new-name>
```

### Running on the Playdate Simulator

#### Building From the Command Line

Ensure you are using a recent nightly Swift toolchain. You can configure Swiftly to use the latest nightly toolchain by running the following command in your project's root directory:

```console
swiftly install --use main-snapshot
```

This will ensure all `swift` commands run in this directory will use a compatible Swift toolchain. If you have manually installed a swift toolchain, you can replace `swift` with `$(xcrun -f swift -toolchain "swift latest")` in the command below.

To build your package into a `pdx` file that can be run on the Playdate simulator, PlaydateKit comes with a `pdc` package plugin. To run this plugin, navigate to the root of your project and run the plugin.

```console
swift package pdc
```

Your package should be compiled into a `pdx` file located at `.build/plugins/PDCPlugin/outputs/PlaydateKitTemplate.pdx`, where PlaydateKitTemplate will be the name specified above. You can then open this `pdx` file directly in the Playdate simulator.

#### Building and Running From Xcode

To build using Xcode you will need to ensure Xcode is using the nightly Swift toolchain downloaded previously. Navigate to the **Xcode > Toolchains** menu item and select the Development Snapshot toolchain.

If you followed the xcscheme instructions above, your package should be ready to run from Xcode. Select the Run icon in the toolbar or press Cmd+R on your keyboard to start building. This will automatically run the `pdc` package plugin and launch the Playdate simulator with your newly build game.

> Tip: If your game doesn't launch when run from Xcode, try running `swift package pdc` from the command line to debug any build issues.

If everything worked, you should now see the default PlaydateKit game running on the Playdate simulator.

![A screenshot of the PlaydateKitTemplate game running on the Playdate simulator](PlaydateKitTemplate-Simulator)

> Note: While the Xcode-selected Swift toolchain is used for **building** in Xcode, when **running** from Xcode the latest Swift toolchain installed is used (`xcrun -f swift -toolchain "swift latest"`).
