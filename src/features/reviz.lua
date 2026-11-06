--!strict
-- features/reviz.luau
-- Toggleable Reviz Admin: fetches the script from the repo on enable and runs
-- it through loadstring, then calls the unload hook the script exposes
-- (getgenv().RevizAdminUnload) on disable. The script is reload-safe: running
-- it again unloads the previous run, so activating twice never stacks bars.
local S = ModMenu.Services
local Players = S.Players

local REVIZ_URL = "https://raw.githubusercontent.com/scr1ptyureishirayukimikotofujiwarasayo/robloxsakuramodmenu/main/reviz.lua"
local REVIZ_GUI_NAMES = { "RevizAdmin", "RevizAdminCMDS", "RevizAdminIntro" }

ModMenu.Features = ModMenu.Features or {}
ModMenu.Features.Reviz = {}

local revizLoaded = false

local function candidateParents(): { Instance }
	local parents: { Instance } = {}
	if gethui then
		local ok, ui = pcall(gethui)
		if ok and ui and ui:IsA("Instance") then
			table.insert(parents, ui)
		end
	end
	local okCore, coreGui = pcall(function() return game:GetService("CoreGui") end)
	if okCore and coreGui then
		table.insert(parents, coreGui)
	end
	local lp = Players.LocalPlayer
	if lp then
		local pg = lp:FindFirstChild("PlayerGui")
		if pg then
			table.insert(parents, pg)
		end
	end
	return parents
end

local function findGuis(): { Instance }
	local found: { Instance } = {}
	for _, parent in candidateParents() do
		for _, name in REVIZ_GUI_NAMES do
			local g = parent:FindFirstChild(name, true)
			if g and (g:IsA("ScreenGui") or g:IsA("GuiObject")) then
				table.insert(found, g)
			end
		end
	end
	return found
end

ModMenu.Features.Reviz.isOpen = function(): boolean
	return #findGuis() > 0
end

-- Call the script's own unload hook (stored in getgenv/_G) and, as a fallback,
-- destroy any GUIs it left behind.
local function unloadExisting()
	local hook
	-- The payload writes the hook to _G (and getgenv). Real's getgenv() views are
	-- not table-stable, so prefer the plain global and only fall back to getgenv.
	if type(_G) == "table" and type(_G.RevizAdminUnload) == "function" then
		hook = _G.RevizAdminUnload
	end
	if type(hook) ~= "function" then
		local okEnv, env = pcall(function() return getgenv() end)
		if okEnv and type(env) == "table" and type(env.RevizAdminUnload) == "function" then
			hook = env.RevizAdminUnload
		end
	end
	if type(hook) == "function" then
		pcall(hook)
	end
	for _, gui in findGuis() do
		pcall(function() gui:Destroy() end)
	end
	revizLoaded = false
end

ModMenu.Features.Reviz.close = function()
	unloadExisting()
	ModMenu.Notify("Reviz Admin", "Closed.")
end

ModMenu.Features.Reviz.open = function()
	if revizLoaded and ModMenu.Features.Reviz.isOpen() then
		return -- already running; avoid stacking a second copy
	end
	unloadExisting()
	task.spawn(function()
		local ok, err = pcall(function()
			local source = game:HttpGet(REVIZ_URL, true)
			local chunk = loadstring(source)
			if not chunk then
				error("failed to compile reviz.lua")
			end
			chunk()
		end)
		if ok then
			revizLoaded = true
			-- A finished chunk with no GUI means it ran but could not parent its
			-- ScreenGui anywhere. Never let that be silent.
			if ModMenu.Features.Reviz.isOpen() then
				ModMenu.Notify("Reviz Admin", "Loaded. Press ; for the command bar.")
			else
				warn("[ModMenu] reviz.lua ran but no RevizAdmin GUI was found")
				ModMenu.Notify("Reviz Admin", "Ran, but no command bar appeared (see console).")
			end
		else
			revizLoaded = false
			warn("[ModMenu] Reviz load failed: " .. tostring(err))
			ModMenu.Notify("Reviz Admin", "Failed to load: " .. tostring(err))
		end
	end)
end

-- Toggle entry point: pass true to load, false to unload.
ModMenu.Features.Reviz.toggle = function(state: boolean)
	if state then
		ModMenu.Features.Reviz.open()
	else
		ModMenu.Features.Reviz.close()
	end
end

-- A re-executed menu may leave a previous Reviz running; clean it up on load.
-- init.luau re-activates it afterwards if the saved toggle is on.
unloadExisting()
