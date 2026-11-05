# Mod Menu 0.4.1

Client-side Roblox mod menu generated from the supplied source files.

## Files

- `src/` - modular development source.
- `dist/ModMenu.lua` - runnable single-file bundle for an executor.
- `build.py` - rebuilds the bundle from `src/*.luau`.
- `docs/` - usage notes.

## Usage

1. Open your executor.
2. Inject into a Roblox client.
3. Execute `dist/ModMenu.lua`.
4. Press the configured open key (default `RightShift`) to show/hide the menu.
5. Use the `Settings` tab to change the open key and save settings.
6. Use the `Console` tab for SakuraVibes999's Reviz Admin commands.

## Features

- **Reviz Admin Remake (Toggleable + Console tab)** - SakuraVibes999's Reviz Admin
  (133 commands) can be toggled on/off as the original standalone command bar + commands window under `Utility > Scripts & Explorer` (or `Console`), and also driven directly from the `Console` tab with a command box, live log and quick actions.
- **Protection tab** - `Anti-Fling` (watchdog that zeroes runaway velocity, unseats fling
  seats and snaps you back to your last safe position) and `Anti-Teleport` (reverts
  single-frame moves larger than the slider). The menu's own teleports are exempted through
  an internal bypass window.
- **Utility > Interactions** - `Auto Click Detectors` and `Auto Touch Parts` fire every
  ClickDetector / TouchTransmitter in the workspace on a configurable interval (toggleable).
  Requires the `fireclickdetector` / `firetouchinterest` executor globals; the toggles turn
  themselves back off with a notification if the executor lacks them.

## Notes

- Effects are client-local unless the game deliberately exposes server behavior.
- Server-authoritative values cannot be permanently changed from the client.
- The Console command set is faithful to the original Reviz Admin, including
  legacy/destructive commands; nothing runs until you enter one.
- The `GetObjects` GUI loaders degrade with a warning when their legacy asset is
  gone; `explorer` also tries a local `Dex Explorer (Embedded).lua`.

## Credits

- Command engine and branding: SakuraVibes999's Reviz Admin.
- Service/capability/config approach adapted from Infinite Yield.
- Window/container approach adapted from TopKek.
- Animation entries adapted from ROBLOX Animation Gui V1.
