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

[Swiftly](https://www.swift.org/swiftly/documentation/swiftlydocs) is the recommended way to install the nightly toolchain.

1. Install Swiftly by running the following commands in your terminal:

```console
curl -O https://download.swift.org/swiftly/darwin/swiftly.pkg
installer -pkg swiftly.pkg -target CurrentUserHomeDirectory
~/.swiftly/bin/swiftly init --quiet-shell-followup
. ~/.swiftly/env.sh
hash -r
```

2. Install the latest Swift nightly toolchain by running:

```console
swiftly install main-snapshot
```

> Note: Swift toolchains can also be downloaded and installed manually from the [Swift Development Snapshots section](https://www.swift.org/install/macos/#development-snapshots) on swift.org, but using Swiftly is recommended as it simplifies the installation and management of toolchains.
