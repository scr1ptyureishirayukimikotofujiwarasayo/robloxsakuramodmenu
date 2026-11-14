--!strict
-- features/shattervast.luau
-- Toggleable Grac3Haz3Lion's ShatterVast Admin: fetches the improved script from the repo on
-- enable and runs it through loadstring, then calls the unload hook the script
-- exposes (getgenv().ShatterVastUnload) on disable. The script unloads any
-- previous run before loading, so activating it never stacks command bars.
local S = ModMenu.Services
local Players = S.Players

local SHATTERVAST_URL = ModMenu.Config.repoBase .. "shattervast.lua"
local SHATTERVAST_GUI_NAMES = { "CommandBar", "CMDS_GUI_V2", "ChatLogsv2", "Notification", "Intro", "InfoGUIv2" }

ModMenu.Features = ModMenu.Features or {}
ModMenu.Features.Shattervast = {}

local shattervastLoaded = false
local shattervastGen = 0

local function candidateParents(): { Instance }
	local parents: { Instance } = {}
	if gethui then
		local ok, ui = pcall(gethui)
		if ok and ui and ui:IsA("Instance") then
			table.insert(parents, ui)
		end
	end
	local okCore, coreGui = pcall(function() return game:GetService("CoreGui") end)
	if okCore then
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
		for _, name in SHATTERVAST_GUI_NAMES do
			local g = parent:FindFirstChild(name, true)
			if g and (g:IsA("ScreenGui") or g:IsA("GuiObject")) then
				table.insert(found, g)
			end
		end
	end
	return found
end

ModMenu.Features.Shattervast.isOpen = function(): boolean
	return #findGuis() > 0
end

-- Call the script's own unload hook (stored in getgenv/_G) and, as a fallback,
-- destroy any GUIs it left behind.
local function unloadExisting()
	local hook
	local okEnv, env = pcall(function() return getgenv() end)
	if okEnv and type(env) == "table" then
		hook = env.ShatterVastUnload
	end
	if type(hook) ~= "function" and type(_G) == "table" then
		hook = _G.ShatterVastUnload
	end
	if type(hook) == "function" then
		pcall(hook)
	end
	for _, gui in findGuis() do
		pcall(function() gui:Destroy() end)
	end
	shattervastGen += 1
	shattervastLoaded = false
end

ModMenu.Features.Shattervast.close = function()
	unloadExisting()
	ModMenu.Notify("Grac3Haz3Lion's ShatterVast Admin", "Closed.")
end

ModMenu.Features.Shattervast.open = function()
	if shattervastLoaded and ModMenu.Features.Shattervast.isOpen() then
		return -- already running; avoid stacking a second copy
	end
	unloadExisting() -- also bumps shattervastGen
	local gen = shattervastGen
	task.spawn(function()
		local ok, err = pcall(function()
			local source = game:HttpGet(SHATTERVAST_URL, true)
			local chunk = loadstring(source)
			if not chunk then
				error("failed to compile shattervast.lua")
			end
			chunk()
		end)
		if gen ~= shattervastGen then
			-- Toggled off while the payload was still loading: undo it now.
			if ok then
				for _, gui in findGuis() do
					pcall(function() gui:Destroy() end)
				end
			end
			shattervastLoaded = false
			return
		end
		if ok then
			shattervastLoaded = true
			ModMenu.Notify("Grac3Haz3Lion's ShatterVast Admin", "Loaded. Press ; for the command bar.")
		else
			shattervastLoaded = false
			ModMenu.Notify("Grac3Haz3Lion's ShatterVast Admin", "Failed to load: " .. tostring(err))
		end
	end)
end

-- Toggle entry point: pass true to load, false to unload.
ModMenu.Features.Shattervast.toggle = function(state: boolean)
	if state then
		ModMenu.Features.Shattervast.open()
	else
		ModMenu.Features.Shattervast.close()
	end
end

-- A re-executed menu may leave a previous Grac3Haz3Lion's ShatterVast running; clean it up on load.
-- init.luau re-activates it afterwards if the saved toggle is on.
unloadExisting()
