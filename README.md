# Mod Menu 0.4.6

Client-side Roblox mod menu generated from the supplied source files.

## Files

- `src/` - modular development source.
- `dist/ModMenu.lua` - runnable single-file bundle for an executor.
- `build.py` - rebuilds the bundle from `src/*.lua` (`python build.py [version]`).
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
- **Character** - Hip Height, `Platform Stand`, `Invisible`, `No Limbs` / `No Arms` / `No Legs`
  (hidden with transparency rather than unparenting, so the rig stays intact),
  `Block Hats`, View Player, Unview, Reset Movement. Character toggles re-apply
  automatically after you respawn.
- **Protection** - `Anti-Fling` (watchdog that zeroes runaway velocity, unseats fling
  seats and snaps you back to your last safe position), `Anti-Teleport` (reverts
  single-frame moves larger than the slider) and `Player Guard` (while AFK, escapes away
  from any player that comes near - see Notes). The menu's own teleports are exempted
  through an internal bypass window.
- **Utility** - Dex Explorer, SakuraVibes999's Reviz Admin, Grac3Haz3Lion's ShatterVast Admin, Click Teleport, Save / Load Position, Workspace Visibility,
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
- **Player Guard (AFK):** after the configured timeout without input (keyboard, mouse,
  touch, gamepad - menu clicks count) you are considered AFK and the guard watches for
  other players inside the detect radius. The nearest one within range triggers an escape
  teleport (default 150 studs) directly away from them, with a 3 s cooldown between
  escapes. Destinations are raycast-validated - mostly clear path plus walkable ground -
  so the escape never drops you into the void; when no direction qualifies it recovers to
  the last spot where you stood on solid ground (and stays put if even that is gone). An
  anti-void watchdog restores you to that safe spot if you start falling while AFK.
  `Trigger: Always` keeps the escape guard running while you are active.
  `Test: Escape Nearest Player` performs one escape on demand so landing spots can be
  checked in-game. Server anti-cheat can rubber-band client teleports, same as the other
  teleport features.
- **Persistence:** by default `Remember Toggles on Load` is **off**, so every run (including a
  server hop) starts with all feature toggles off - only non-feature settings (open key,
  accent, background, waypoints, saved position) persist. Slider values you actually drag
  (WalkSpeed, JumpPower, Gravity, FOV, Clock Time, Workspace Visibility, ...) are saved and
  re-applied on load and after respawn, so the numbers you set stick; sliders you never touch
  keep their defaults and are not forced on the game. Turn `Remember Toggles on Load` on to
  restore active features across runs. `Auto-Save` (default on) writes `ModMenuConfig.json` on
  every change; turn it off to persist only when you press `Save Now`. `Reset Toggles Now`
  switches every feature off immediately, and `Wipe Saved Config` deletes the file and resets
  in-memory state.
- **SakuraVibes999's Reviz Admin:** Utilities > `SakuraVibes999's Reviz Admin` fetches `reviz.lua` from the repo and runs it
  through `loadstring`, dropping in the revived Reviz command bar (prefix `;`). Turning the
  toggle off calls the script's own `RevizAdminUnload` hook. Press `;` to focus the bar, or
  `;cmds` for the command list. Requires network access and `reviz.lua` at the repo root.
- **Grac3Haz3Lion's ShatterVast Admin:** Utilities > `Grac3Haz3Lion's ShatterVast Admin` is a separate, optional admin script
  (independent from Reviz). It fetches `shattervast.lua` from the repo and runs the improved
  ShatterVast command bar (prefix `;`). Turning it off calls the script's `ShatterVastUnload`
  hook; re-enabling cleans up the previous run first, so bars never stack. Press `;` to focus
  the bar, or `;cmds` for the command list. Both ShatterVast and Reviz use the `;` prefix, so
  enable only one at a time.
- **Background image:** the menu loads `ModMenuBackground.png` (or `picture.png`) from the
  executor's workspace folder via `getcustomasset`, auto-downloading `picture.png` if
  missing. If `getcustomasset` is unavailable it falls back to the uploaded decal id in
  `BACKGROUND_ASSET_ID` (`src/ui/menu.lua`), then to a solid themed background.
- **Remote assets:** every download (loader, Dex / Reviz / ShatterVast payloads, background image)
  uses `ModMenu.Config.repoBase` in `src/core/config.lua`. If the repository moves, change that
  single value instead of editing each feature file.

## What's new in 0.4.6

- **Player Guard (AFK)** (Protection tab): auto-escapes away from nearby players while
  you are AFK, with raycast-validated escape destinations, anti-void fallback to your
  last grounded spot, and an optional `Always` trigger mode.

## Fixes in 0.4.5

- Re-executing the menu now **reverts every active effect** before `State` is replaced
  (Noclip, Lock Workspace, Workspace Visibility, Fullbright, Invisible, Click Delete hidden
  parts, Block Hats, Hide Other GUIs, Tool Reach, a running exploiter payload), instead of
  leaving them applied and un-togglable.
- `Fly` and `Float Platform` recreate their BodyMover on the new character after a respawn
  instead of re-parenting a destroyed instance (which errored every frame and killed the
  feature until it was toggled off/on).
- `Click Teleport` and `Click Delete` use `UserInputService` with the `gameProcessed` filter,
  so clicking the menu (or any game GUI) no longer teleports you or deletes the part behind
  the window.
- `Block Hats` now also hides MeshPart-based (modern) hats, not just classic `SpecialMesh` hats.
- `Invisible` also zeroes the Humanoid name/health display, so the floating nametag is hidden.
- `No Limbs` combined with `No Arms` / `No Legs` no longer desyncs: the limb groups are
  recomputed from the toggles in one pass.
- `Reset Movement` pushes the restored values back into the sliders, and `Wipe Saved Config`
  re-syncs the Settings UI (open-key dropdown, preference toggles, background).
- `Copy Position` no longer claims "Copied" on executors without a clipboard function, and
  `Anti-Lag` restores the original rendering quality when switched off.
- Dex / Reviz / ShatterVast no longer stay loaded if you switch the toggle off before the
  remote script finishes loading.

## Fixes in 0.4.4

- `Auto Click Detectors` now passes a numeric distance to `fireclickdetector`, and
  `Auto Touch Parts` passes args in the correct `(part, toucher, state)` order, so touches
  actually land on the target part.
- `Lock Workspace` and `Workspace Visibility` no longer touch character/NPC rigs, so locking
  no longer freezes you.
- `Noclip` restores each part's original `CanCollide` instead of forcing it on, and
  `Float Platform` re-attaches after respawn.
- Movement-stat sliders and all character toggles re-apply after respawn.
- `Fullbright` / `Remove Fog` snapshot and restore Lighting (Brightness, ClockTime,
  GlobalShadows, FogEnd, FogStart) instead of clobbering it.
- `No Limbs` / `No Arms` / `No Legs` hide limbs safely without breaking the rig.
- `Teleport to Spawn` finds spawns anywhere in the workspace and reports when none exist.
- Player dropdowns refresh as players join/leave; re-executing the menu reverts the active
  features (see 0.4.5), disconnects the old feature loops/connections, and destroys the old
  window, so re-running never stacks menus; `Hide Other GUIs` only re-enables GUIs it disabled.

## Credits

- Service / capability / config approach adapted from Infinite Yield.
- Window / container approach adapted from TopKek.
