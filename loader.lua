-- Sakura Mod Menu loader
-- Fetches and runs each organized module from this repository.
local BASE_URL = "https://raw.githubusercontent.com/scr1ptyureishirayukimikotofujiwarasayo/robloxsakuramodmenu/main/"

local function fetch(path)
    return game:HttpGet(BASE_URL .. path, true)
end

local function run(path)
    local source = fetch(path)
    local chunk, compileError = loadstring(source)
    if not chunk then
        warn("[ModMenu] Failed to compile " .. path .. ": " .. tostring(compileError))
        return nil
    end
    local ok, result = pcall(chunk)
    if not ok then
        warn("[ModMenu] Failed to run " .. path .. ": " .. tostring(result))
        return nil
    end
    return result
end

run("src/core/compat.lua")
run("src/core/services.lua")
run("src/core/notify.lua")
run("src/core/state.lua")
run("src/core/config.lua")
run("src/ui/theme.lua")
run("src/ui/components.lua")
run("src/ui/menu.lua")
run("src/features/movement.lua")
run("src/features/visual.lua")
run("src/features/character.lua")
run("src/features/utility.lua")
run("src/features/teleport.lua")
run("src/features/world.lua")
run("src/features/misc.lua")
run("src/features/dex.lua")
run("src/init.lua")

return _G.ModMenu
