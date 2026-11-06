"""Concatenate src modules into dist/ModMenu.lua.

The bundle is a plain concatenation in dependency order: every module assigns
onto the shared ModMenu table, and dist is executed as one chunk.

Source files may be `.luau` (local project) or `.lua` (the GitHub repo); the
resolver accepts either.

Usage:  python build.py [version]
"""
import os
import sys

ROOT = os.path.dirname(os.path.abspath(__file__))
VERSION = sys.argv[1] if len(sys.argv) > 1 else "0.4.2"

ORDER = [
    "core/compat",
    "core/services",
    "core/notify",
    "core/state",
    "core/config",
    "ui/theme",
    "ui/components",
    "ui/menu",
    "features/movement",
    "features/visual",
    "features/character",
    "features/utility",
    "features/teleport",
    "features/world",
    "features/protection",
    "features/interaction",
    "features/misc",
    "features/dex",
    "init",
]

out = [
    "--!strict",
    "-- Mod Menu (client) - generated from local sources",
    "-- Version: " + VERSION,
    "",
]

for rel in ORDER:
    base = os.path.join(ROOT, "src", rel.replace("/", os.sep))
    path = None
    for ext in (".luau", ".lua"):
        if os.path.exists(base + ext):
            path = base + ext
            break
    if path is None:
        raise SystemExit("missing source: src/%s(.luau|.lua)" % rel)
    with open(path, "r", encoding="utf-8") as f:
        content = f.read().replace("\r\n", "\n").rstrip("\n")
    out.append("-- ===== src\\" + rel.replace("/", "\\") + os.path.splitext(path)[1] + " =====")
    out.append(content)
    out.append("")

bundle = "\n".join(out)
dist_dir = os.path.join(ROOT, "dist")
os.makedirs(dist_dir, exist_ok=True)
target = os.path.join(dist_dir, "ModMenu.lua")
with open(target, "w", encoding="utf-8", newline="\n") as f:
    f.write(bundle)

print("wrote %s (%d bytes, %d lines)" % (target, len(bundle.encode("utf-8")), bundle.count("\n") + 1))
