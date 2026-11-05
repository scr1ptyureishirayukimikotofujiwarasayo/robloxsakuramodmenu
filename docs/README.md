# Mod Menu 0.3.0

Client-side Roblox mod menu generated from the supplied source files.

## Files

- `src/` - modular development source.
- `dist/ModMenu.lua` - runnable single-file bundle for an executor.
- `docs/` - usage notes.

## Usage

1. Open your executor.
2. Inject into a Roblox client.
3. Execute `dist/ModMenu.lua`.
4. Press the configured open key (default `RightShift`) to show/hide the menu.
5. Use the `Settings` tab to change the open key and save settings.

## Notes

- **Background image:** the menu loads `ModMenuBackground.png` from the
  executor's workspace folder via `getcustomasset` (Real: its Workspace
  folder). If the file isn't found it falls back to the uploaded decal id in
  `BACKGROUND_ASSET_ID` (src/ui/menu.luau), then to a solid background.
  No Roblox upload is needed on Real.
- **Background controls:** Settings > Background has an on/off toggle and a
  brightness slider (0-255, default 80). Both persist in `ModMenuConfig.json`.
  Lower = darker photo = more text contrast.
- **Layering gotcha (fixed):** ZIndex is sorted across the whole ScreenGui, so
  the photo must sit at ZIndex 0 with the root frame's background transparent;
  an opaque root paints over the photo and the menu looks black. Widgets get
  depth-based ZIndex values from `ModMenu.Menu.applyZOrder()` so children draw
  above their parents — call it after adding new widgets. Dimming uses
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
- **Utility > Interactions:** the auto loops fire every ClickDetector (`fireclickdetector`,
  passing the part position) and every other part with a TouchTransmitter
  (`firetouchinterest` begin+end pair from your root part) in the workspace once per interval
  (slider, default 1s). Your own character is skipped. If the executor lacks either global,
  the toggle switches itself back off with a notification.
- Effects are client-local unless the game deliberately exposes server behavior.
- Server-authoritative values cannot be permanently changed from the client.
- Integration from third-party sources was sanitized; destructive/global exploits were removed.

## Credits

- Service/capability/config approach adapted from Infinite Yield.
- Window/container approach adapted from TopKek.
- Animation entries adapted from ROBLOX Animation Gui V1.
