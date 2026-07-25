# Debugging

Use the Playdate Simulator's built in debugging tools with a PlaydateKit game.

## Overview

The Simulator's debugging tools were built with Lua in mind, and several of them need debug info that
a PlaydateKit build has to go out of its way to publish. `swift package pdc` does that automatically.

This article covers which tools work with a compiled Swift game, which don't, and why.

## Setting breakpoints with LLDB

Simulator builds keep the full DWARF that SwiftPM's `-g` produces, and `swift package pdc` copies the
`dSYM` bundle into the pdx next to `pdex.dylib` — the one place LLDB looks for it. Attach to the
running Simulator:

```console
$ lldb -p $(pgrep -f 'MacOS/Playdate Simulator')
(lldb) breakpoint set --file Game.swift --line 111
Breakpoint 1: where = pdex.dylib`Ball.update() + 100 at Game.swift:111:19
```

Breakpoints, backtraces across the Swift/C boundary, and variable inspection all work:

```text
(lldb) thread backtrace
  * frame #0: pdex.dylib`Ball.update() at Game.swift:111:19
    frame #1: pdex.dylib`closure #1 in Sprite.Sprite.init(...) at Sprite.swift:21:24
    frame #3: Playdate Simulator`pc_sprite_updateSprites + 392
    frame #6: pdex.dylib`Game.update() at Game.swift:47:20

(lldb) frame variable
(Pong.Ball) self = 0x00000072e8807700 {
  velocity = (x = 4, y = 5)
}
```

The Simulator also supports the
[debug adapter protocol](https://microsoft.github.io/debug-adapter-protocol/), so editors like Nova
can drive this too.

Pass `--no-dsym` to keep the bundle out of the pdx.

## Profiling with the Sampler

The Sampler can sample `Simulator - Lua`, `Device - Lua` and `Device - C`. A PlaydateKit game is C,
so **`Device - C`**, with the game running on hardware, is the mode to use.

> Important: There is no `Simulator - C` option. Native code cannot be sampled in the Simulator at
all — this is a Simulator limitation, not something a game can opt into.

`Device - C` symbolizes by shelling out to the SDK's `arm-none-eabi-addr2line` and asks you to choose
a game. Select the **`.elf` file**, not the pdx bundle. `pdc` only keeps the stripped `pdex.bin`
inside the pdx, so `swift package pdc` writes an unstripped copy next to it:

```text
.build/plugins/PDCPlugin/outputs/MyGame.pdx
.build/plugins/PDCPlugin/outputs/MyGame.elf   ← choose this one
```

Device builds are also pinned to DWARF 4. The `arm-none-eabi-addr2line` that ships with the Playdate
SDK is binutils 2.32 and cannot parse the DWARF 5 that Clang emits by default — with DWARF 5 it fails
outright and every sample resolves to no source location.

> Note: The Sampler runs `addr2line -f` without `-C`, and reads function names out of DWARF, so Swift
frames appear as mangled names like `$e4Pong4BallC6updateyyF` alongside the correct file and line.
Run a name through `swift demangle` to read it.

## Inspecting memory with the Malloc Log

**View ▸ Show Malloc Log** shows the memory your game allocates. Because PlaydateKit routes the
Embedded Swift runtime's allocations through the Playdate allocator, every Swift object appears here.

1. Choose **Playdate ▸ Malloc Pool ▸ 16 MB** — the Malloc Log needs pooling to be active.
2. Choose **View ▸ Show Malloc Log**.

The window reports total heap used, active bytes and a live item count, and lists every allocation by
address and size. The `Source` column is not populated in SDK 3.1.1, for Lua or C, so allocations
can't be attributed back to the code that made them.

> Warning: While Malloc Pool is enabled the Simulator retains every allocation in order to show
history, so its own memory use grows without bound. Only turn it on while investigating.

**Lua Memory** is Lua-only and stays empty for a PlaydateKit game.

## Drawing debug overlays

The Simulator composites a separate debug framebuffer over the display in 50% transparent red.
``Graphics/getDebugBitmap()`` returns it, and it works with the normal drawing API by pushing it as
the current context:

```swift
if let debugBitmap = Graphics.getDebugBitmap() {
    Graphics.pushContext(debugBitmap)
    Graphics.clear(color: .black)
    for enemy in enemies {
        Graphics.drawRect(enemy.hitbox, color: .white)
    }
    Graphics.popContext()
}
```

Only white pixels show up in the overlay. Toggle it with **View ▸ Enable Debug Drawing**. On device
`getDebugBitmap()` returns `nil`, so this is safe to leave in shipping code.

> Important: The Simulator owns this bitmap and reuses it every frame — never free it. PlaydateKit
returns it with ownership disabled for exactly this reason.

## Tools that need nothing from your game

- **Console** — ``System/log(_:)`` and Swift's `print` both write here. The input field also accepts
  `!msg <message>`, delivered to ``System/setSerialMessageCallback(callback:)``.
- **Highlight Screen Updates** and **Show Sprite Collision Rects** work automatically through the
  sprite system that ``Sprite`` wraps.
- **Device Info** graphs performance and memory of a connected device.
- **Event Recorder** records and replays input.
