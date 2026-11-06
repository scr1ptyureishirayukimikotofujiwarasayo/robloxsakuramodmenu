# Mod Menu 0.4.4

Client-side Roblox mod menu generated from the supplied source files.

## Files

- `src/` - modular development source.
- `dist/ModMenu.lua` - runnable single-file bundle for an executor.
- `build.py` - rebuilds the bundle from `src/*.luau` (`python build.py [version]`).
- `loader.lua` - fetches and runs each module from this repository.
- `docs/` - usage notes.

## Usage

1. Open your executor.
2. Inject into a Roblox client.
3. Execute `dist/ModMenu.lua`.
4. Press the configured open key (default `RightShift`) to show/hide the menu.
5. Use the `Settings` tab to change the open key and save settings.

## Features

The menu is organised into tabs. What each one currently does:

- **Home** - About text, `Copy Position`, `Fullbright` shortcut.
- **Player** - `WalkSpeed`, `JumpPower` and `Gravity` sliders, plus waypoint save / teleport to last.
- **Movement** - `Fly` (with a fly-speed slider), `Noclip`, `Float Platform`.
- **Visual** - Player ESP (Highlight), `Fullbright`, `Remove Fog`, Field of View, Clock Time.
- **World** - `Anti-Lag / Low Graphics`, `Rejoin`.
- **Teleport** - `Teleport to Spawn`, `Copy Position`, `Rejoin Server`.
- **Character** - Hip Height, `Platform Stand`, `Invisible`, `No Limbs` / `No Arms` / `No Legs`,
  `Block Hats`, View Player, Unview, Reset Movement.
- **Protection** - `Anti-Fling` (watchdog that zeroes runaway velocity, unseats fling
  seats and snaps you back to your last safe position) and `Anti-Teleport` (reverts
  single-frame moves larger than the slider). The menu's own teleports are exempted
  through an internal bypass window.
- **Utility** - Dex Explorer, Reviz Admin, Click Teleport, Save / Load Position, Workspace Visibility,
  Restore Workspace, Click Delete (reversible), Lock Workspace, Tool Grabber, Tool Reach,
  plus `Interactions` (`Auto Click Detectors` and `Auto Touch Parts`) and diagnostics
  (`FE Check`, `Player Info`).
- **Settings** - Open Key, Hide Other GUIs, Background Image on/off and brightness,
  and Persistence: `Auto-Save`, `Remember Toggles on Load`, `Save Now`,
  `Reset Toggles Now`, `Wipe Saved Config`.

## Notes

- Effects are client-local unless the game deliberately exposes server behavior.
- Server-authoritative values cannot be permanently changed from the client.
- `Auto Click Detectors` / `Auto Touch Parts` fire every ClickDetector / TouchTransmitter in
  the workspace on a configurable interval. They require the `fireclickdetector` /
  `firetouchinterest` executor globals; the toggles turn themselves back off with a
  notification if the executor lacks them.
- **Persistence:** by default `Remember Toggles on Load` is **off**, so every run (including a
  server hop) starts with all feature toggles off - only non-feature settings (open key,
  accent, background, waypoints, saved position) persist. Turn `Remember Toggles on Load` on to
  restore active features across runs. `Auto-Save` (default on) writes `ModMenuConfig.json` on
  every change; turn it off to persist only when you press `Save Now`. `Reset Toggles Now`
  switches every feature off immediately, and `Wipe Saved Config` deletes the file and resets
  in-memory state.
- **Reviz Admin:** Utilities > `Reviz Admin` fetches `reviz.lua` from the repo and runs it
  through `loadstring`, dropping in the revived Reviz command bar (prefix `;`). Turning the
  toggle off calls the script's own `RevizAdminUnload` hook. Press `;` to focus the bar, or
  `;cmds` for the command list. Requires network access and `reviz.lua` at the repo root.
- **Background image:** the menu loads `ModMenuBackground.png` (or `picture.png`) from the
  executor's workspace folder via `getcustomasset`, auto-downloading `picture.png` if
  missing. If `getcustomasset` is unavailable it falls back to the uploaded decal id in
  `BACKGROUND_ASSET_ID` (`src/ui/menu.luau`), then to a solid themed background.

## Credits

- Service / capability / config approach adapted from Infinite Yield.
- Window / container approach adapted from TopKek.
