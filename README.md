<p align="center">
    <img src="https://github.com/finnvoor/PlaydateKit/assets/8284016/cc62d7bd-87bc-4f8e-9b0f-18998df28832" width="400" max-width="90%" alt="PlaydateKit Logo" />
</p>

<p align="center">
    <a href="https://www.swift.org/">
        <img src="https://img.shields.io/badge/Swift-5.9-f05237.svg" />
    </a>
    <a href="https://sdk.play.date">
        <img src="https://img.shields.io/badge/Playdate_SDK-2.4.1-ffc500.svg" />
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

For example usage, see the BasicExample [here](https://github.com/finnvoor/PlaydateKit/tree/main/Examples). I strongly recommend reading through the Swift Playdate Examples documentation [here](https://apple.github.io/swift-playdate-examples/documentation/playdate/) for information on downloading required tools, setting up build scripts, and compiling for Playdate.

Your `PlaydateGame` object manages the game lifecycle, receiving events such as `gameWillPause` and `deviceWillSleep`. 

```swift
import PlaydateKit

final class MyPlaydateGame: PlaydateGame {
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

The easiest way to set up a game with PlaydateKit is to add the boilerplate entry code somewhere in your source. This will ensure your `PlaydateGame` is created early in the game launch cycle and sets up the update and event callbacks for you.

```swift
/// Boilerplate entry code
nonisolated(unsafe) var game: MyPlaydateGame! // Replace with your PlaydateGame type
@_cdecl("eventHandler") func eventHandler(
    pointer: UnsafeMutableRawPointer!,
    event: System.Event,
    _: CUnsignedInt
) -> CInt {
    switch event {
    case .initialize:
        Playdate.initialize(with: pointer)
        game = MyPlaydateGame() // Replace with your PlaydateGame type
        System.updateCallback = game.update
    default: game.handle(event)
    }
    return 0
}
```

The Makefile in the example project requires compiling the PlaydateKit source files, meaning you will need to have PlaydateKit checked out locally and update your Makefile to point to it (you can't just add PlaydateKit as a package dependency). I am investigating ways to improve this, for now you could probably add a git submodule or something 🤷‍♂️

## Acknowledgements

PlaydateKit was inspired by and would not be possible without the excellent work done by [@rauhul](https://github.com/rauhul) on [swift-playdate-examples](https://github.com/apple/swift-playdate-examples). Specifically, PlaydateKit was created due to the note in the swift-playdate-examples repo: 
> It is not intended to be a full-featured Playdate SDK so please do not raise PRs to extend the Playdate Swift overlay to new areas.

The example project build scripts were mostly copied from swift-playdate-examples, and as such fall under the Apache License 2.0 found [here](https://github.com/apple/swift-playdate-examples/blob/main/LICENSE.txt).
