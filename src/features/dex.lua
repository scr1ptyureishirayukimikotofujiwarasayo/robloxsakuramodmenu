--!strict
-- features/dex.luau
-- Toggleable Dex Explorer: loads the self-contained embedded build from the
-- repo on open, and destroys the ScreenGuis it creates on close.
local S = ModMenu.Services
local Players = S.Players

local DEX_URL = "https://raw.githubusercontent.com/scr1ptyureishirayukimikotofujiwarasayo/robloxsakuramodmenu/main/dex.lua"
local DEX_GUI_NAMES = { "MainMenu", "Intro" }

ModMenu.Features = ModMenu.Features or {}
ModMenu.Features.Dex = {}

local dexLoaded = false
local dexGen = 0

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

local function findDexGuis(): { Instance }
	local found: { Instance } = {}
	for _, parent in candidateParents() do
		for _, name in DEX_GUI_NAMES do
			local g = parent:FindFirstChild(name, true)
			if g and g:IsA("ScreenGui") then
				table.insert(found, g)
			end
		end
	end
	return found
end

ModMenu.Features.Dex.isOpen = function(): boolean
	return #findDexGuis() > 0
end

ModMenu.Features.Dex.close = function()
	dexGen += 1
	for _, gui in findDexGuis() do
		pcall(function() gui:Destroy() end)
	end
	dexLoaded = false
end

ModMenu.Features.Dex.open = function()
	if dexLoaded and ModMenu.Features.Dex.isOpen() then
		return -- already running; avoid stacking a second copy
	end
	ModMenu.Features.Dex.close() -- also bumps dexGen
	local gen = dexGen
	task.spawn(function()
		local ok, err = pcall(function()
			local source = game:HttpGet(DEX_URL, true)
			local chunk = loadstring(source)
			if not chunk then
				error("failed to compile dex.lua")
			end
			chunk()
		end)
		if gen ~= dexGen then
			-- Toggled off while the payload was still loading: undo it now.
			if ok then
				for _, gui in findDexGuis() do
					pcall(function() gui:Destroy() end)
				end
			end
			dexLoaded = false
			return
		end
		if ok then
			dexLoaded = true
			ModMenu.Notify("Dex Explorer", "Opened.")
		else
			dexLoaded = false
			ModMenu.Notify("Dex Explorer", "Failed to load: " .. tostring(err))
		end
	end)
end

-- Toggle entry point: pass true to open, false to close.
ModMenu.Features.Dex.toggle = function(state: boolean)
	if state then
		ModMenu.Features.Dex.open()
	else
		ModMenu.Features.Dex.close()
		ModMenu.Notify("Dex Explorer", "Closed.")
	end
end
