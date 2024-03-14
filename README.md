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

PlaydateKit provides easy to use Swift bindings for the Playdate C API. PlaydateKit aims to be as Swift-y as possible, replacing error pointers with throwable functions, avoiding the use of pointers as much as possible, and adding documentation comments to all functions (taken directly from the Playdate SDK docs).

PlaydateKit is still very much WIP. 

## Status

PlaydateKit aims to provide full coverage of the Playdate C API. To start out with, the Swift API closely follows the C API, meaning it is completely functional. I would like to make it more object-oriented soon, meaning wrapper types for things like frames, bitmaps, sprites, etc. 

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

Besides the complicated build setup, this is all it takes to create a simple "game" that adds a menu item:

```swift
public import CPlaydate
import PlaydateKit

@_cdecl("update") func update(_: UnsafeMutableRawPointer!) -> Int32 { 1 }

@_cdecl("eventHandler") public func eventHandler(
    pointer: UnsafeMutableRawPointer!,
    event: PDSystemEvent,
    _: UInt32
) -> Int32 {
    let playdate = pointer.bindMemory(to: PlaydateAPI.self, capacity: 1)
    if event == .initialize {
        Playdate.initialize(with: playdate)
        Playdate.System.setUpdateCallback(update: update, userdata: nil)

        _ = Playdate.System.addMenuItem(title: "PlaydateKit") { _ in
            Playdate.System.logToConsole(format: "PlaydateKit selected!")
        }
    }
    return 0
}
```

I would like to investigate ways to avoid this boilerplate, perhaps providing a macro similar to [SwiftGodot](https://github.com/migueldeicaza/SwiftGodot).

The Makefile in the example project requires compiling the PlaydateKit source files, meaning you will need to have PlaydateKit checked out locally and update your Makefile to point to it (you can't just add PlaydateKit as a package dependency). I am investigating ways to improve this, for now you could probably add a git submodule or something 🤷‍♂️

## Acknowledgements

PlaydateKit was inspired by and would not be possible without the excellent work done by [@rauhul](https://github.com/rauhul) on [swift-playdate-examples](https://github.com/apple/swift-playdate-examples). Specifically, PlaydateKit was created due to the note in the swift-playdate-examples repo: 
> It is not intended to be a full-featured Playdate SDK so please do not raise PRs to extend the Playdate Swift overlay to new areas.

The example project build scripts as well as most of CPlaydate were copied from swift-playdate-examples, and as such fall under the Apache License 2.0 found [here](https://github.com/apple/swift-playdate-examples/blob/main/LICENSE.txt).
