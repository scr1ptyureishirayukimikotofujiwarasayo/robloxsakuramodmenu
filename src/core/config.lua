--!strict
-- core/config.luau
local S = ModMenu.Services
local HttpService = S.HttpService

local CONFIG_PATH = "ModMenuConfig.json"

-- Single source of truth for every remote asset the menu fetches (loader,
-- dex/reviz/shattervast payloads, background image). Change it here when the
-- repository moves instead of editing each feature file.
local REPO_BASE = "https://raw.githubusercontent.com/scr1ptyureishirayukimikotofujiwarasayo/robloxsakuramodmenu/main/"

local function safeRead(path: string): string?
	if isfile and isfile(path) then
		local ok, data = pcall(readfile, path)
		if ok and type(data) == "string" and data ~= "" then
			return data
		end
	end
	return nil
end

local function safeWrite(path: string, data: string)
	if writefile then
		pcall(writefile, path, data, true)
	end
end

ModMenu.Config = {
	path = CONFIG_PATH,
	repoBase = REPO_BASE,
	load = function()
		local raw = safeRead(CONFIG_PATH)
		if not raw then return end
		local ok, decoded = pcall(HttpService.JSONDecode, HttpService, raw)
		if not ok or type(decoded) ~= "table" then return end
		if type(decoded.autoSave) == "boolean" then
			ModMenu.State.settings.autoSave = decoded.autoSave
		end
		if type(decoded.rememberToggles) == "boolean" then
			ModMenu.State.settings.rememberToggles = decoded.rememberToggles
		end
		if type(decoded.openKey) == "string" then
			local k = Enum.KeyCode[decoded.openKey]
			if k then
				ModMenu.State.settings.openKey = k
			end
		end
		if type(decoded.accent) == "table" then
			local a = decoded.accent
			if type(a.r) == "number" and type(a.g) == "number" and type(a.b) == "number" then
				ModMenu.State.settings.accent = Color3.new(a.r, a.g, a.b)
			end
		end
		-- Feature toggles are only restored when the user opted in. Preferences
		-- ("settings.") are always restored so the background on/off choice
		-- survives a reload even with "Remember Toggles" left off.
		if type(decoded.toggles) == "table" then
			for k, v in decoded.toggles do
				if
					type(v) == "boolean"
					and (ModMenu.State.settings.rememberToggles or string.sub(k, 1, 9) == "settings.")
				then
					ModMenu.State.toggles[k] = v
				end
			end
		end
		if type(decoded.numbers) == "table" then
			for k, v in decoded.numbers do
				if type(v) == "number" then
					ModMenu.State.numbers[k] = v
				end
			end
		end
		if type(decoded.touched) == "table" then
			for k, v in decoded.touched do
				if type(k) == "string" and v == true then
					ModMenu.State.touched[k] = true
				end
			end
		end
		-- Dropdown selections (view target, player-info target, open key) were
		-- previously never serialized, so they reset every run.
		if type(decoded.strings) == "table" then
			for k, v in decoded.strings do
				if type(k) == "string" and type(v) == "string" then
					ModMenu.State.strings[k] = v
				end
			end
		end
		if type(decoded.savedPosition) == "table" then
			ModMenu.State.savedPosition = Vector3.new(decoded.savedPosition.x or 0, decoded.savedPosition.y or 0, decoded.savedPosition.z or 0)
			ModMenu.State.savedPositionName = decoded.savedPositionName
		end
		if type(decoded.waypoints) == "table" then
			table.clear(ModMenu.State.waypoints)
			for _, wp in decoded.waypoints do
				if type(wp) == "table" and type(wp.position) == "table" then
					local pos = wp.position
					table.insert(ModMenu.State.waypoints, {
						name = type(wp.name) == "string" and wp.name or ("WP " .. tostring(#ModMenu.State.waypoints + 1)),
						position = Vector3.new(pos.x or 0, pos.y or 0, pos.z or 0),
					})
				end
			end
		end
	end,
	save = function(force: boolean?)
		if not force and not ModMenu.State.settings.autoSave then
			return
		end
		local accent = ModMenu.State.settings.accent
		local openKey = ModMenu.State.settings.openKey
		local waypoints = {}
		for _, wp in ModMenu.State.waypoints do
			waypoints[#waypoints + 1] = {
				name = wp.name,
				position = { x = wp.position.X, y = wp.position.Y, z = wp.position.Z },
			}
		end
		local data = {
			openKey = typeof(openKey) == "EnumItem" and openKey.Name or tostring(openKey),
			accent = { r = accent.R, g = accent.G, b = accent.B },
			autoSave = ModMenu.State.settings.autoSave,
			rememberToggles = ModMenu.State.settings.rememberToggles,
			toggles = ModMenu.State.toggles,
			numbers = ModMenu.State.numbers,
			touched = ModMenu.State.touched,
			strings = ModMenu.State.strings,
			waypoints = waypoints,
			savedPosition = ModMenu.State.savedPosition and {
				x = ModMenu.State.savedPosition.X,
				y = ModMenu.State.savedPosition.Y,
				z = ModMenu.State.savedPosition.Z,
			} or nil,
			savedPositionName = ModMenu.State.savedPositionName,
		}
		local ok, encoded = pcall(HttpService.JSONEncode, HttpService, data)
		if ok then
			safeWrite(CONFIG_PATH, encoded)
		end
	end,
	reset = function()
		-- Back to first-run defaults in memory. Does not touch the file.
		ModMenu.State.settings.openKey = Enum.KeyCode.RightShift
		ModMenu.State.settings.accent = Color3.fromRGB(210, 50, 75)
		ModMenu.State.settings.autoSave = true
		ModMenu.State.settings.rememberToggles = false
		table.clear(ModMenu.State.toggles)
		table.clear(ModMenu.State.numbers)
		table.clear(ModMenu.State.strings)
		table.clear(ModMenu.State.touched)
		table.clear(ModMenu.State.waypoints)
		-- Re-seed the preference toggles so the Settings UI can be re-synced to
		-- the defaults after a wipe instead of showing stale values.
		ModMenu.State.toggles["settings.backgroundImage"] = true
		ModMenu.State.toggles["settings.autoSave"] = true
		ModMenu.State.toggles["settings.rememberToggles"] = false
		ModMenu.State.savedPosition = nil
		ModMenu.State.savedPositionName = nil
	end,
	wipe = function()
		-- Delete the saved file where the executor allows, else overwrite it empty,
		-- then reset the in-memory state so the running menu matches.
		-- `delfile` only exists on some executors; when it is missing (or the
		-- delete fails) fall back to overwriting the file with an empty config.
		local removed = false
		if type(delfile) == "function" then
			removed = (pcall(delfile, CONFIG_PATH))
		end
		if not removed then
			safeWrite(CONFIG_PATH, "{}")
		end
		ModMenu.Config.reset()
	end,
}

pcall(ModMenu.Config.load)
