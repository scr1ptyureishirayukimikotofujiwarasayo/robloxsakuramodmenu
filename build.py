"""Concatenate src/*.luau into dist/ModMenu.lua.

The bundle is a plain concatenation in dependency order: every module assigns
onto the shared ModMenu table, and dist is executed as one chunk.

Usage:  python build.py [version]
"""
import os
import sys

ROOT = os.path.dirname(os.path.abspath(__file__))
VERSION = sys.argv[1] if len(sys.argv) > 1 else "0.4.0"

ORDER = [
    "core/compat.luau",
    "core/services.luau",
    "core/notify.luau",
    "core/state.luau",
    "core/config.luau",
    "ui/theme.luau",
    "ui/components.luau",
    "ui/menu.luau",
    "features/movement.luau",
    "features/visual.luau",
    "features/character.luau",
    "features/utility.luau",
    "features/teleport.luau",
    "features/world.luau",
    "features/protection.luau",
    "features/interaction.luau",
    "features/misc.luau",
    "features/dex.luau",
    "features/reviz.luau",
    "init.luau",
]

out = [
    "--!strict",
    "-- Mod Menu (client) - generated from local sources",
    "-- Version: " + VERSION,
    "",
]

for rel in ORDER:
    path = os.path.join(ROOT, "src", rel.replace("/", os.sep))
    with open(path, "r", encoding="utf-8") as f:
        content = f.read().replace("\r\n", "\n").rstrip("\n")
    out.append("-- ===== src\\" + rel.replace("/", "\\") + " =====")
    out.append(content)
    out.append("")

dist_dir = os.path.join(ROOT, "dist")
os.makedirs(dist_dir, exist_ok=True)
target = os.path.join(dist_dir, "ModMenu.lua")
bundle = "\n".join(out)
with open(target, "w", encoding="utf-8", newline="\n") as f:
    f.write(bundle)

print("wrote %s (%d bytes, %d lines)" % (target, len(bundle.encode("utf-8")), bundle.count("\n") + 1))
