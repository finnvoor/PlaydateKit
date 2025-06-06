<p align="center">
    <img src="https://github.com/finnvoor/PlaydateKit/assets/8284016/cc62d7bd-87bc-4f8e-9b0f-18998df28832" width="400" max-width="90%" alt="PlaydateKit Logo" />
</p>

<p align="center">
    <a href="https://www.swift.org/">
        <img src="https://img.shields.io/badge/Swift-6.0-f05237.svg" />
    </a>
    <a href="https://github.com/finnvoor/PlaydateKit/actions/workflows/Build.yml">
        <img src="https://github.com/finnvoor/PlaydateKit/actions/workflows/Build.yml/badge.svg" />
    </a>
</p>

# PlaydateKit

PlaydateKit provides easy to use Swift bindings for the [Playdate](https://play.date/) C API. PlaydateKit aims to be as Swift-y as possible, replacing error pointers with throwable functions, avoiding the use of pointers and memory management as much as possible, and adding documentation comments to all functions (copied from the Playdate SDK docs).

## Status

PlaydateKit provides (almost) full coverage of the Playdate C API. PlaydateKit adds wrapper types for some values (Sprite, Bitmap, FileHandle, etc) that automatically manage the allocation/deallocation of resources. While I have attempted to closely follow the C API specifications, much of it is untested, so if you run into an unexpected issue or can't do something with the Swift API, please open an issue!

## Usage

For detailed instructions and documentation on how to get started creating a game using PlaydateKit, see [here](https://finnvoor.github.io/PlaydateKit/documentation/playdatekit).

### Summary

1. Install a recent nightly Swift toolchain by installing [Swiftly](https://www.swift.org/swiftly/documentation/swiftlydocs) and running `swiftly install main-snapshot`.
2. Install the [Playdate SDK](https://play.date/dev/).
3. Create a new repository using the [PlaydateKitTemplate template](https://github.com/finnvoor/PlaydateKitTemplate).
5. Build and run directly in the simulator using Xcode, or build using the command `swift package pdc`. When built using `swift package pdc`, the built `pdx` game file will be located at `.build/plugins/PDCPlugin/outputs/PlaydateKitTemplate.pdx` and can be opened in the Playdate simulator.

Your `PlaydateGame` object manages the game lifecycle, receiving events such as `gameWillPause` and `deviceWillSleep`. 

```swift
import PlaydateKit

final class Game: PlaydateGame {
    init() {
        System.addCheckmarkMenuItem(title: "check me") { isChecked in
            print(isChecked ? "checked!" : "not checked")
        }
    }

    func update() -> Bool {
        System.drawFPS()
        return true
    }

    func gameWillPause() {
        print("Paused!")
    }
}
```

## Contributing

I'm happy to accept contributions on this project, whether it's bug fixes, implementing missing features, or opening an issue. Please try to follow the existing conventions/style in the project.

If you create a game using PlaydateKit and would like it featured here, please open an issue or pull request! If you would like to demake a retro game or create a new one that demonstrates PlaydateKit's capabilities, feel free to add an example game in the `Examples/` directory.

## Acknowledgements

PlaydateKit was inspired by and would not be possible without the excellent work done by [@rauhul](https://github.com/rauhul) on [swift-playdate-examples](https://github.com/apple/swift-playdate-examples) as well as the ongoing work by the rest of the Embedded Swift team.
