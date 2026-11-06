# Mod Menu 0.4.4

Client-side Roblox mod menu generated from the supplied source files.

## Files

- `src/` - modular development source.
- `dist/ModMenu.lua` - runnable single-file bundle for an executor.
- `build.py` - concatenates `src/*.luau` into the bundle (`python build.py [version]`).
- `loader.lua` - fetches and runs each module from this repository.
- `docs/` - usage notes.

## Usage

1. Open your executor.
2. Inject into a Roblox client.
3. Execute `dist/ModMenu.lua` (or `loader.lua`).
4. Press the configured open key (default `RightShift`) to show/hide the menu.
5. Use the `Settings` tab to change the open key and save settings.

## Tabs

- **Home** - About text, `Copy Position`, `Fullbright` shortcut.
- **Player** - `WalkSpeed`, `JumpPower` and `Gravity` sliders, plus waypoint save and
  "teleport to last".
- **Movement** - `Fly` (with a fly-speed slider), `Noclip`, `Float Platform`.
- **Visual** - Player ESP (Highlight), `Fullbright`, `Remove Fog`, Field of View, Clock Time.
- **World** - `Anti-Lag / Low Graphics`, `Rejoin`.
- **Teleport** - `Teleport to Spawn`, `Copy Position`, `Rejoin Server`.
- **Character** - Hip Height, `Platform Stand`, `Invisible`, `No Limbs` / `No Arms` / `No Legs`,
  `Block Hats`, View Player, Unview, Reset Movement.
- **Protection** - `Anti-Fling` and `Anti-Teleport` (see Notes).
- **Utility** - Dex Explorer, Reviz Admin, Grac3Haz3Lion's ShatterVast Admin, Click Teleport, Save / Load Position, Workspace Visibility,
  Restore Workspace, Click Delete (reversible), Lock Workspace, Tool Grabber, Tool Reach,
  `Interactions` and diagnostics (`FE Check`, `Player Info`).
- **Settings** - Open Key, Hide Other GUIs, Background Image on/off and brightness,
  and Persistence (`Auto-Save`, `Remember Toggles on Load`, `Save Now`,
  `Reset Toggles Now`, `Wipe Saved Config`).

## Notes

- **Background image:** the menu loads `ModMenuBackground.png` (or `picture.png`) from the
  executor's workspace folder via `getcustomasset` (Real: its Workspace
  folder), auto-downloading `picture.png` into `ModMenuBackground.png` if missing.
  If `getcustomasset` is unavailable it falls back to the uploaded decal id in
  `BACKGROUND_ASSET_ID` (src/ui/menu.luau), then to a solid background.
  No Roblox upload is needed on Real.
- **Background controls:** Settings > Background has an on/off toggle and a
  brightness slider (0-255, default 80). Both persist in `ModMenuConfig.json`.
  Lower = darker photo = more text contrast.
- **Layering gotcha (fixed):** ZIndex is sorted across the whole ScreenGui, so
  the photo must sit at ZIndex 0 with the root frame's background transparent;
  an opaque root paints over the photo and the menu looks black. Widgets get
  depth-based ZIndex values from `ModMenu.Menu.applyZOrder()` so children draw
  above their parents - call it after adding new widgets. Dimming uses
  `ImageColor3`, not a black overlay frame, which would darken the text too.
- **Reloads:** startup destroys any previous `ModMenu` ScreenGui and
  disconnects the previous run's input listeners, so re-executing the bundle
  never stacks two menus.
- **Protection tab:** anti-fling watches the root part each Heartbeat and, when linear velocity
  exceeds the slider (default 400 studs/s) or angular velocity exceeds 50 rad/s, zeroes the
  momentum, unseats you, and snaps you back to the last safe pose (if moved more than 5 studs).
  Anti-teleport reverts any single-frame displacement larger than its slider (default 50 studs),
  rate-limiting its notifications. Both re-baseline on respawn and pause while an internal
  bypass window is open, which Click TP, waypoints and saved positions set before moving you.
  Anti-teleport can rubber-band against legitimate server teleports - turn it off in games
  that teleport you by design.
- **Utility > Interactions:** the auto loops fire every ClickDetector (`fireclickdetector`)
  and every other part with a TouchTransmitter (`firetouchinterest` begin+end pair from your
  root part) in the workspace once per interval (slider, default 1s). Your own character is
  skipped. If the executor lacks either global, the toggle switches itself back off with a
  notification.
- **Persistence:** `Remember Toggles on Load` defaults **off**, so every run - including a
  server hop - starts with all feature toggles off; only non-feature settings (open key,
  accent, background, waypoints, saved position) persist. Turn it on to restore active features
  across runs. `Auto-Save` (default on) writes `ModMenuConfig.json` on every change; turn it
  off to persist only when you press `Save Now`. `Reset Toggles Now` switches every feature off
  immediately, and `Wipe Saved Config` deletes the file and resets in-memory state.
- **Reviz Admin:** Utilities > `Reviz Admin` fetches `reviz.lua` from the repo and runs it
  through `loadstring`, loading the revived Reviz command bar (prefix `;`). Turning it off
  calls the script's `RevizAdminUnload` hook. Press `;` to focus the bar, or `;cmds` for the
  command list. Requires network access and `reviz.lua` at the repo root.
- **Grac3Haz3Lion's ShatterVast Admin:** Utilities > `Grac3Haz3Lion's ShatterVast Admin` is a separate, optional admin script
  (independent from Reviz). It fetches `shattervast.lua` from the repo and runs the improved
  ShatterVast command bar (prefix `;`). Turning it off calls the script's `ShatterVastUnload`
  hook; re-enabling cleans up the previous run first, so bars never stack. Press `;` to focus
  the bar, or `;cmds` for the command list. Both ShatterVast and Reviz use the `;` prefix, so
  enable only one at a time.
- Effects are client-local unless the game deliberately exposes server behavior.
- Server-authoritative values cannot be permanently changed from the client.

## Credits

- Service / capability / config approach adapted from Infinite Yield.
- Window / container approach adapted from TopKek.
