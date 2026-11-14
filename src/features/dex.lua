--!strict
-- features/dex.luau
-- Toggleable Dex Explorer: loads the self-contained embedded build from the
-- repo on open, and destroys the ScreenGuis it creates on close.
--
-- Dex parents several top-level ScreenGuis to one holder: the "MainMenu"
-- launcher, the "Intro" splash (self-destructs ~1s after load), the
-- Explorer/Properties "Window" guis, an UNNAMED side-panel gui, plus
-- lazily-created helpers ("Context", "BrickColor", "ExplorerSelections").
-- Names cannot cover all of them ("Window" is too generic to destroy blindly,
-- the side gui has no name), so on top of the name sweep every run records the
-- ScreenGuis that appeared under Dex's holder while it loaded (before/after
-- snapshot) and close() removes exactly those.
local S = ModMenu.Services
local Players = S.Players

local DEX_URL = ModMenu.Config.repoBase .. "dex.lua"

-- Guis that identify "dex is open" plus helpers Dex creates lazily, after the
-- load snapshot was taken (context menu, colour picker, selection highlights).
-- Matching those by name on close is deliberate: the names are Dex-specific.
local DEX_OPEN_MARKERS = { "MainMenu", "Intro" }
local DEX_LAZY_GUIS = { "Context", "BrickColor", "ExplorerSelections" }

ModMenu.Features = ModMenu.Features or {}
ModMenu.Features.Dex = {}

local dexLoaded = false
local dexGen = 0
local loading = false
local pendingOpen = false
-- ScreenGuis created by the current run (snapshot diff), plus lazily-created
-- guis recorded by the name sweep below.
local trackedGuis: { [Instance]: boolean } = {}

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

-- All ScreenGuis currently under the holders Dex can parent to.
local function collectScreenGuis(): { [Instance]: boolean }
	local set: { [Instance]: boolean } = {}
	for _, parent in candidateParents() do
		local ok, descendants = pcall(function() return parent:GetDescendants() end)
		if ok then
			for _, child in descendants do
				if child:IsA("ScreenGui") then
					set[child] = true
				end
			end
		end
	end
	return set
end

local function findGuisByName(names: { string }): { Instance }
	local found: { Instance } = {}
	for _, parent in candidateParents() do
		for _, name in names do
			local gui = parent:FindFirstChild(name, true)
			if gui and gui:IsA("ScreenGui") then
				table.insert(found, gui)
			end
		end
	end
	return found
end

-- Diff the holder's ScreenGuis around the load. Dex's holder is found via the
-- always-created markers, so unrelated guis that appear during the load are
-- ignored: only guis parented to that same holder are adopted.
local function trackNewGuis(before: { [Instance]: boolean }): { Instance }
	local after = collectScreenGuis()

	local holder: Instance? = nil
	for gui in after do
		if not before[gui] and (gui.Name == "MainMenu" or gui.Name == "Intro") then
			holder = gui.Parent
			break
		end
	end

	local created: { Instance } = {}
	if holder == nil then
		return created
	end
	for gui in after do
		if not before[gui] and gui.Parent == holder then
			trackedGuis[gui] = true
			created[#created + 1] = gui
		end
	end
	return created
end

local function removeGuis(guis: { Instance })
	for _, gui in guis do
		trackedGuis[gui] = nil
		pcall(function() gui:Destroy() end)
	end
end

-- Tracked guis + the by-name sweep (covers lazily-created helpers and anything
-- left behind by a run that died before its snapshot was recorded).
local function removeAllDexGuis()
	local all: { Instance } = {}
	for gui in trackedGuis do
		all[#all + 1] = gui
	end
	table.clear(trackedGuis)

	local names = table.clone(DEX_OPEN_MARKERS)
	for _, name in DEX_LAZY_GUIS do
		names[#names + 1] = name
	end
	for _, gui in findGuisByName(names) do
		all[#all + 1] = gui
	end

	removeGuis(all)
end

ModMenu.Features.Dex.isOpen = function(): boolean
	for gui in trackedGuis do
		if gui.Parent ~= nil then
			return true
		end
	end
	return #findGuisByName(DEX_OPEN_MARKERS) > 0
end

ModMenu.Features.Dex.close = function()
	pendingOpen = false
	dexGen += 1
	removeAllDexGuis()
	dexLoaded = false
end

local requestLoad: () -> ()

requestLoad = function()
	if dexLoaded and ModMenu.Features.Dex.isOpen() then
		return -- already running; avoid stacking a second copy
	end

	-- Supersede whatever is current or in flight, then drop every gui it made.
	dexGen += 1
	removeAllDexGuis()
	dexLoaded = false

	if loading then
		-- A load is already in flight: it sees the generation bump, cleans up
		-- its own guis and re-runs this request once it finishes. Two loads
		-- never overlap, so a slow run cannot destroy the newer run's guis.
		pendingOpen = true
		return
	end

	loading = true
	local gen = dexGen
	task.spawn(function()
		local before = collectScreenGuis()
		local ok, err = pcall(function()
			local source = game:HttpGet(DEX_URL, true)
			local chunk = loadstring(source)
			if not chunk then
				error("failed to compile dex.lua")
			end
			chunk()
		end)
		local created = trackNewGuis(before)
		loading = false

		if gen ~= dexGen then
			-- Superseded (or toggled off) while the payload was still loading.
			removeGuis(created)
		elseif ok then
			dexLoaded = true
			ModMenu.Notify("Dex Explorer", "Opened.")
		else
			-- A failed load can leave the "Intro" splash on screen; remove
			-- everything this run created instead of stranding it.
			removeGuis(created)
			ModMenu.Notify("Dex Explorer", "Failed to load: " .. tostring(err))
		end

		if pendingOpen then
			pendingOpen = false
			requestLoad()
		end
	end)
end

ModMenu.Features.Dex.open = function()
	requestLoad()
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
