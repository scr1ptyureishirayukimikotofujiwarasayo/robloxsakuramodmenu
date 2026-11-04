--!strict
-- core/config.luau
local S = ModMenu.Services
local HttpService = S.HttpService

local CONFIG_PATH = "ModMenuConfig.json"

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
	load = function()
		local raw = safeRead(CONFIG_PATH)
		if not raw then return end
		local ok, decoded = pcall(HttpService.JSONDecode, HttpService, raw)
		if not ok or type(decoded) ~= "table" then return end
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
		if type(decoded.toggles) == "table" then
			for k, v in decoded.toggles do
				if type(v) == "boolean" then
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
		if type(decoded.savedPosition) == "table" then
			ModMenu.State.savedPosition = Vector3.new(decoded.savedPosition.x or 0, decoded.savedPosition.y or 0, decoded.savedPosition.z or 0)
			ModMenu.State.savedPositionName = decoded.savedPositionName
		end
	end,
	save = function()
		local accent = ModMenu.State.settings.accent
		local data = {
			openKey = tostring(ModMenu.State.settings.openKey),
			accent = { r = accent.R, g = accent.G, b = accent.B },
			toggles = ModMenu.State.toggles,
			numbers = ModMenu.State.numbers,
			waypoints = ModMenu.State.waypoints,
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
}

pcall(ModMenu.Config.load)
