# Mod Menu 0.4.0

Client-side Roblox mod menu generated from the supplied source files.

## Files

- `src/` - modular development source.
- `dist/ModMenu.lua` - runnable single-file bundle for an executor.
- `build.py` - concatenates `src/*.luau` into the bundle (`python build.py 0.4.0`).
- `loader.lua` - fetches and runs each module from this repository.
- `docs/` - usage notes.

## Usage

1. Open your executor.
2. Inject into a Roblox client.
3. Execute `dist/ModMenu.lua` (or `loader.lua`).
4. Press the configured open key (default `RightShift`) to show/hide the menu.
5. Use the `Settings` tab to change the open key and save settings.
6. Use the `Console` tab for SakuraVibes999's Reviz Admin commands (see below).

## Console & Reviz Admin Remake (SakuraVibes999's Reviz Admin)

The verified Reviz Admin remake is embedded as `src/features/reviz.luau` and can be used both as a toggleable standalone GUI (`RevizAdmin` command bar + `RevizAdminCMDS` window) and from the `Console` tab:

- Toggle `Reviz Admin Remake` under `Utility > Scripts & Explorer` (or `Console`) to open/close the original draggable Reviz command bar and commands window.
- Type a command in the Console box (or Reviz command bar) and press Enter, or use the quick-command buttons.
- Press the prefix key (default `:`) to focus the Reviz command bar when open, or to open the Console tab and focus its box.
- `List Commands` opens the Reviz commands window (if enabled) and prints the full original command list into the panel.
- `Chat Commands` (on by default) keeps the admin behaviour where a chat
  message beginning with the prefix runs the command.
- Everything the commands report also appears in the panel log.

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
- The `Console` tab embeds SakuraVibes999's Reviz Admin command set faithfully,
  including legacy/destructive commands such as `shutdown`, `bang`, `spam` and
  `pmspam`. Those are opt-in: nothing runs until a command is entered.
- The four legacy `GetObjects` GUI loaders (`hypertotal`, `animgui`,
  `opfinality`, `explorer`) degrade with a warning when their asset is gone.
  `explorer` also tries a local `Dex Explorer (Embedded).lua` from the
  executor's workspace folder.

## Credits

- Command engine and branding: SakuraVibes999's Reviz Admin.
- Service/capability/config approach adapted from Infinite Yield.
- Window/container approach adapted from TopKek.
- Animation entries adapted from ROBLOX Animation Gui V1.
