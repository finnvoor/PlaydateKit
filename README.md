<p align="center">
    <img src="https://github.com/finnvoor/PlaydateKit/assets/8284016/cc62d7bd-87bc-4f8e-9b0f-18998df28832" width="400" max-width="90%" alt="PlaydateKit Logo" />
</p>

<p align="center">
    <a href="https://www.swift.org/">
        <img src="https://img.shields.io/badge/Swift-5.10-f05237.svg" />
    </a>
    <a href="https://sdk.play.date">
        <img src="https://img.shields.io/badge/Playdate_SDK-2.4.2-ffc500.svg" />
    </a>
</p>

# PlaydateKit

PlaydateKit provides easy to use Swift bindings for the Playdate C API. PlaydateKit aims to be as Swift-y as possible, replacing error pointers with throwable functions, avoiding the use of pointers and memory management as much as possible, and adding documentation comments to all functions (copied from the Playdate SDK docs).

## Status

PlaydateKit aims to provide full coverage of the Playdate C API. PlaydateKit adds wrapper types for some values (Sprite, Bitmap, FileHandle, etc) that automatically manage the allocation/deallocation of resources. While I have attempted to closely follow the C API specifications, much of it is untested, so if you run into an unexpected issue or can't do something with the Swift API, please open an issue!

Currently, the following sections of the API are implemented:

- [x] Display
- [x] File
- [x] Graphics
- [x] JSON
- [ ] Lua
- [x] Scoreboards
- [ ] Sound
- [x] Sprite
- [x] System

## Usage
For detailed instructions on how to get started creating a game using PlaydateKit, see [here](https://finnvoor.github.io/PlaydateKit/documentation/playdatekit).

1. Install a nightly [Swift](https://www.swift.org/download/#snapshots) toolchain that supports the Embedded experimental feature.
2. Install the [Playdate SDK](https://play.date/dev/).
3. Create a new repository using the [PlaydateKitTemplate template](https://github.com/finnvoor/PlaydateKitTemplate).
4. (optional) Change the name of the package by renaming the product and target in `Package.swift` and renaming `Sources/PlaydateKitTemplate` to the new name.
5. Build and run directly in the simulator using Xcode, or build using the command `swift package pdc`. When built using `swift package pdc`, the built `pdx` game file will be located at `.build/plugins/PDCPlugin/outputs/PlaydateKitTemplate.pdx` and can be opened in the Playdate simulator.

Your `PlaydateGame` object manages the game lifecycle, receiving events such as `gameWillPause` and `deviceWillSleep`. 

```swift
import PlaydateKit

final class Game: PlaydateGame {
    init() {
        System.addMenuItem(title: "PlaydateKit") { _ in
            System.log("PlaydateKit selected!")
        }
    }

    func update() -> Bool {
        System.drawFPS()
        return true
    }

    func gameWillPause() {
        System.log("Paused!")
    }
}
```

## Acknowledgements

PlaydateKit was inspired by and would not be possible without the excellent work done by [@rauhul](https://github.com/rauhul) on [swift-playdate-examples](https://github.com/apple/swift-playdate-examples). Specifically, PlaydateKit was created due to the note in the swift-playdate-examples repo: 
> It is not intended to be a full-featured Playdate SDK so please do not raise PRs to extend the Playdate Swift overlay to new areas.
