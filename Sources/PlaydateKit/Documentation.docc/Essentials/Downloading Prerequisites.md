# Downloading Prerequisites

This article guides you through downloading and installing the required tools needed to build games for Playdate using Swift.

## Overview

Building games using PlaydateKit requires installing both the Playdate SDK and a recent nightly version of the Swift toolchain.

### Install the Playdate SDK

1. Navigate to the [Playdate Developer page](https://play.date/dev/).
2. Agree to the Playdate SDK License, and select **Download Playdate SDK**.
3. Open and install the downloaded **PlaydateSDK.pkg**.

@TabNavigator {
   @Tab("Step 1") {
      ![A screenshot of the Playdate SDK download page](Playdate-SDK)
   }

   @Tab("Step 2") {
       ![A screenshot of the Playdate SDK download page](Playdate-SDK-Download)
   }

   @Tab("Step 3") {
       ![A screenshot of the Playdate SDK package](Playdate-SDK-Finder)
   }
}

### Install a Supported Swift Toolchain

PlaydateKit currently requires a recent nightly version of the Swift toolchain that has support for the Embedded Swift experimental language feature.

1. Navigate to the [Swift.org downloads page](https://www.swift.org/download/#snapshots).
2. Scroll to the **Trunk Development (main)** subsection, and select the **Xcode "Universal"** link to download the latest version of the Swift nightly toolchain.
3. Open and install the downloaded **swift-DEVELOPMENT-SNAPSHOT-202X-XX-XX-a-osx.pkg**.

@TabNavigator {
   @Tab("Step 1") {
      ![A screenshot of the Swift toolchain download page](Swift-Toolchain)
   }

   @Tab("Step 2") {
       ![A screenshot of the Swift toolchain download page](Swift-Toolchain-Download)
   }

   @Tab("Step 3") {
       ![A screenshot of the downloaded Swift toolchain](Swift-Toolchain-Finder)
   }
}
