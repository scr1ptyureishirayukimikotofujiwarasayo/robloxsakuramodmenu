--!strict
-- Mod Menu (client) - generated from local sources
-- Version: 0.4.2

-- ===== src\core\compat.lua =====
--!strict
-- core/compat.luau
local function missing(expectedType: string, value: any, fallback: any): any
	if type(value) == expectedType then
		return value
	end
	return fallback
end

getgenv = missing("function", getgenv, function(): any return {} end)
gethui = missing("function", gethui or get_hidden_gui)
syn = missing("table", syn, {}) :: any
syn_protect_gui = missing("function", syn and syn.protect_gui)
sethidden = missing("function", sethiddenproperty or set_hidden_property or set_hidden_prop)
gethidden = missing("function", gethiddenproperty or get_hidden_property or get_hidden_prop)
queueteleport = missing("function", queue_on_teleport or (syn and syn.queue_on_teleport) or (fluxus and fluxus.queue_on_teleport))
httprequest = missing("function", request or http_request or (syn and syn.request) or (http and http.request) or (fluxus and fluxus.request))
everyClipboard = missing("function", setclipboard or toclipboard or set_clipboard or (Clipboard and Clipboard.set))
firetouchinterest = missing("function", firetouchinterest)
waxwritefile, waxreadfile = writefile, readfile
writefile = missing("function", waxwritefile) and function(file: string, data: string, safe: boolean?)
	if safe == true then
		return pcall(waxwritefile, file, data)
	end
	waxwritefile(file, data)
end
readfile = missing("function", waxreadfile) and function(file: string, safe: boolean?)
	if safe == true then
		return pcall(waxreadfile, file)
	end
	return waxreadfile(file)
end
isfile = missing("function", isfile, readfile and function(file: string)
	local success, result = pcall(function()
		return readfile(file)
	end)
	return success and result ~= nil and result ~= ""
end)
makefolder = missing("function", makefolder)
isfolder = missing("function", isfolder)
getcustomasset = missing("function", getcustomasset or getsynasset)
hookfunction = missing("function", hookfunction)
hookmetamethod = missing("function", hookmetamethod)
getnamecallmethod = missing("function", getnamecallmethod or get_namecall_method)
checkcaller = missing("function", checkcaller, function(): boolean return false end)
newcclosure = missing("function", newcclosure, function(f: (...any) -> ...any, ...: any): ...any return f(...) end)
getgc = missing("function", getgc or get_gc_objects)
setthreadidentity = missing("function", setthreadidentity or (syn and syn.set_thread_identity) or syn_context_set or setthreadcontext)
replicatesignal = missing("function", replicatesignal)
getconnections = missing("function", getconnections or get_signal_cons)

ModMenu = (typeof(ModMenu) == "table" and ModMenu) or (_G and _G.ModMenu) or {}
_G = _G or {}
_G.ModMenu = ModMenu
ModMenu.Compat = { missing = missing }

-- ===== src\core\services.lua =====
--!strict
-- core/services.luau
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local StarterGui = game:GetService("StarterGui")
local Lighting = game:GetService("Lighting")
local TeleportService = game:GetService("TeleportService")
local HttpService = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local SoundService = game:GetService("SoundService")

local cachedServices = {
	Players = cloneref and cloneref(game:GetService("Players")) or game:GetService("Players"),
	RunService = cloneref and cloneref(game:GetService("RunService")) or game:GetService("RunService"),
	UserInputService = cloneref and cloneref(game:GetService("UserInputService")) or game:GetService("UserInputService"),
	TweenService = cloneref and cloneref(game:GetService("TweenService")) or game:GetService("TweenService"),
	StarterGui = cloneref and cloneref(game:GetService("StarterGui")) or game:GetService("StarterGui"),
	Lighting = cloneref and cloneref(game:GetService("Lighting")) or game:GetService("Lighting"),
	TeleportService = cloneref and cloneref(game:GetService("TeleportService")) or game:GetService("TeleportService"),
	HttpService = cloneref and cloneref(game:GetService("HttpService")) or game:GetService("HttpService"),
	ReplicatedStorage = cloneref and cloneref(game:GetService("ReplicatedStorage")) or game:GetService("ReplicatedStorage"),
	Workspace = cloneref and cloneref(game:GetService("Workspace")) or game:GetService("Workspace"),
	SoundService = cloneref and cloneref(game:GetService("SoundService")) or game:GetService("SoundService"),
}

ModMenu = ModMenu or {}
ModMenu.Services = cachedServices
ModMenu.LocalPlayer = cachedServices.Players.LocalPlayer
ModMenu.Camera = cachedServices.Workspace.CurrentCamera

-- ===== src\core\notify.lua =====
--!strict
-- core/notify.luau
local S = ModMenu.Services
local StarterGui = S.StarterGui

ModMenu.Notify = function(title: string, text: string, duration: number?)
	duration = duration or 4
	pcall(function()
		StarterGui:SetCore("SendNotification", {
			Title = title,
			Text = text,
			Duration = duration,
		})
	end)
end

-- ===== src\core\state.lua =====
--!strict
-- core/state.luau
ModMenu.State = {
	settings = {
		openKey = Enum.KeyCode.RightShift,
		accent = Color3.fromRGB(210, 50, 75),
		menuSize = UDim2.fromOffset(460, 340),
		-- Persistence policy:
		--   autoSave        - write ModMenuConfig.json on every change (Save Now forces it regardless)
		--   rememberToggles - restore saved feature toggles on load. OFF by default so a
		--                     server hop / re-run starts with every feature off.
		autoSave = true,
		rememberToggles = false,
	},
	toggles = {} :: { [string]: boolean },
	numbers = {} :: { [string]: number },
	strings = {} :: { [string]: string },
	connections = {} :: { [string]: { RBXScriptConnection } },
	waypoints = {} :: { { name: string, position: Vector3 } },
	savedPosition = nil :: Vector3?,
	savedPositionName = nil :: string?,
	hiddenParts = {},
	workspaceVisibilityOriginal = {},
	lockedPartsOriginal = {},
	reachOriginal = {},
	originalWalkSpeed = nil :: number?,
	originalJumpPower = nil :: number?,
	originalHipHeight = nil :: number?,
}

ModMenu.State.setToggle = function(id: string, value: boolean, apply: ((boolean) -> ())?)
	ModMenu.State.toggles[id] = value
	if apply then
		pcall(apply, value)
	end
end

ModMenu.State.getConnections = function(id: string): { RBXScriptConnection }
	if not ModMenu.State.connections[id] then
		ModMenu.State.connections[id] = {}
	end
	return ModMenu.State.connections[id]
end

ModMenu.State.clearConnections = function(id: string)
	local cons = ModMenu.State.connections[id]
	if cons then
		for _, c in cons do
			pcall(function() c:Disconnect() end)
		end
		table.clear(cons)
	end
end

-- ===== src\core\config.lua =====
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
		-- Feature toggles are only restored when the user opted in. Otherwise the
		-- widgets fall back to their defaults (off), so a server hop is clean.
		if ModMenu.State.settings.rememberToggles and type(decoded.toggles) == "table" then
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
		table.clear(ModMenu.State.waypoints)
		ModMenu.State.savedPosition = nil
		ModMenu.State.savedPositionName = nil
	end,
	wipe = function()
		-- Delete the saved file where the executor allows, else overwrite it empty,
		-- then reset the in-memory state so the running menu matches.
		local removed = false
		if type(delfile) == "function" then
			removed = pcall(delfile, CONFIG_PATH)
		end
		if not removed then
			safeWrite(CONFIG_PATH, "{}")
		end
		ModMenu.Config.reset()
	end,
}

pcall(ModMenu.Config.load)

-- ===== src\ui\theme.lua =====
--!strict
-- ui/theme.luau
ModMenu.Theme = {
	font = Enum.Font.Gotham,
	smallFont = Enum.Font.Gotham,
	normalText = 14,
	titleText = 16,
	padding = 6,
	radius = 8,
	background = Color3.fromRGB(18, 18, 22),
	panel = Color3.fromRGB(30, 30, 38),
	surface = Color3.fromRGB(42, 42, 54),
	text = Color3.fromRGB(250, 250, 255),
	textPrimary = Color3.fromRGB(250, 250, 255),
	textSecondary = Color3.fromRGB(205, 205, 220),
	textDisabled = Color3.fromRGB(140, 140, 155),
	accentText = Color3.fromRGB(255, 255, 255),
	successText = Color3.fromRGB(120, 235, 165),
	dangerText = Color3.fromRGB(255, 150, 160),
	muted = Color3.fromRGB(190, 190, 205),
	success = Color3.fromRGB(80, 200, 120),
	danger = Color3.fromRGB(220, 70, 80),
}

local function corner(instance: Instance, radius: number?)
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, radius or ModMenu.Theme.radius)
	c.Parent = instance
	return c
end

local function stroke(instance: Instance, color: Color3?, thickness: number?)
	local s = Instance.new("UIStroke")
	s.Color = color or Color3.fromRGB(0, 0, 0)
	s.Thickness = thickness or 1
	s.Transparency = 0.65
	s.Parent = instance
	return s
end

ModMenu.Theme.corner = corner
ModMenu.Theme.stroke = stroke
ModMenu.Theme.textStroke = function(instance: Instance, transparency: number?)
	local s = Instance.new("UIStroke")
	s.Color = Color3.new(0, 0, 0)
	s.Thickness = 1.1
	s.Transparency = transparency or 0.55
	s.Parent = instance
	return s
end
ModMenu.Theme.accent = function()
	return ModMenu.State.settings.accent
end

-- ===== src\ui\components.lua =====
--!strict
-- ui/components.luau
local S = ModMenu.Services
local Theme = ModMenu.Theme

local function button(parent: Instance, text: string, callback: (() -> ())?): TextButton
	local btn = Instance.new("TextButton")
	btn.Size = UDim2.new(1, -8, 0, 28)
	btn.BackgroundColor3 = Theme.surface
	btn.TextColor3 = Theme.text
	btn.Font = Theme.font
	btn.TextSize = Theme.normalText
	btn.Text = text
	btn.AutoButtonColor = true
	btn.BorderSizePixel = 0
	Theme.corner(btn, 6)
	Theme.textStroke(btn, 0.6)
	btn.Parent = parent
	if callback then
		btn.MouseButton1Click:Connect(function()
			pcall(callback)
		end)
	end
	return btn
end

local function toggle(parent: Instance, id: string, label: string, initial: boolean?, apply: ((boolean) -> ())?): Frame
	local row = Instance.new("Frame")
	row.Size = UDim2.new(1, -8, 0, 28)
	row.BackgroundTransparency = 1
	row.Parent = parent

	local lbl = Instance.new("TextLabel")
	lbl.Size = UDim2.new(1, -60, 1, 0)
	lbl.BackgroundTransparency = 1
	lbl.TextColor3 = Theme.text
	lbl.Font = Theme.font
	lbl.TextSize = Theme.normalText
	lbl.TextXAlignment = Enum.TextXAlignment.Left
	lbl.Text = label
	lbl.Parent = row
	Theme.textStroke(lbl, 0.65)
	local savedToggle = ModMenu.State.toggles[id]
	local state = if savedToggle ~= nil then savedToggle else (initial or false)
	local btn = Instance.new("TextButton")
	btn.Size = UDim2.new(0, 52, 0, 22)
	btn.Position = UDim2.new(1, -52, 0.5, -11)
	btn.BorderSizePixel = 0
	btn.Font = Theme.font
	btn.TextSize = 12
	btn.AutoButtonColor = true
	Theme.corner(btn, 11)
	Theme.textStroke(btn, 0.6)
	btn.Parent = row

	local function refresh()
		btn.Text = state and "ON" or "OFF"
		btn.BackgroundColor3 = state and Theme.success or Theme.surface
		btn.TextColor3 = Theme.text
	end
	refresh()

	-- Keep every toggle registered under the same id (e.g. the Home and Visual
	-- "Fullbright" switches) visually in sync.
	ModMenu.UI.toggleSync[id] = ModMenu.UI.toggleSync[id] or {}
	local syncers = ModMenu.UI.toggleSync[id]
	local selfSyncer = function(newState: boolean)
		if newState ~= state then
			state = newState
			refresh()
		end
	end
	table.insert(syncers, selfSyncer)

	btn.MouseButton1Click:Connect(function()
		state = not state
		ModMenu.State.toggles[id] = state
		refresh()
		for _, sync in syncers do
			sync(state)
		end
		if apply then
			pcall(apply, state)
		end
		pcall(ModMenu.Config.save)
	end)

	ModMenu.State.toggles[id] = state
	-- Do NOT run the feature at construction. init.luau builds every widget on
	-- every tab during load, so calling apply() here fired every default/saved
	-- value before the menu was even opened (gravity, FOV, clock time, camera
	-- target, Dex "closed", ...). Register the callback instead; init.luau
	-- re-applies only the toggles the user actually saved as ON.
	if apply then
		ModMenu.UI.toggleApply[id] = ModMenu.UI.toggleApply[id] or {}
		table.insert(ModMenu.UI.toggleApply[id], apply)
	end

	return row
end

local function slider(parent: Instance, id: string, label: string, min: number, max: number, initial: number?, apply: ((number) -> ())?): Frame
	local row = Instance.new("Frame")
	row.Size = UDim2.new(1, -8, 0, 38)
	row.BackgroundTransparency = 1
	row.Parent = parent

	local lbl = Instance.new("TextLabel")
	lbl.Size = UDim2.new(1, 0, 0, 16)
	lbl.BackgroundTransparency = 1
	lbl.TextColor3 = Theme.text
	lbl.Font = Theme.font
	lbl.TextSize = 13
	lbl.TextXAlignment = Enum.TextXAlignment.Left
	lbl.Text = label .. ": " .. tostring(initial or min)
	lbl.Parent = row
	Theme.textStroke(lbl, 0.65)

	local bar = Instance.new("Frame")
	bar.Size = UDim2.new(1, 0, 0, 8)
	bar.Position = UDim2.new(0, 0, 0, 20)
	bar.BackgroundColor3 = Theme.surface
	bar.BorderSizePixel = 0
	Theme.corner(bar, 4)
	bar.Parent = row

	local fill = Instance.new("Frame")
	fill.BorderSizePixel = 0
	Theme.corner(fill, 4)
	fill.Parent = bar

	local savedNumber = ModMenu.State.numbers[id]
	local value = if savedNumber ~= nil then savedNumber else (initial or min)
	local dragging = false

	local function render(v: number)
		value = math.clamp(v, min, max)
		ModMenu.State.numbers[id] = value
		local pct = (value - min) / (max - min)
		fill.Size = UDim2.new(pct, 0, 1, 0)
		fill.BackgroundColor3 = ModMenu.Theme.accent()
		lbl.Text = label .. ": " .. string.format("%.1f", value)
	end

	local function setValue(v: number)
		render(v)
		if apply then pcall(apply, value) end
	end

	local menuConns = ModMenu.State.getConnections("menu")
	table.insert(menuConns, bar.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			dragging = true
		end
	end))
	table.insert(menuConns, S.UserInputService.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			if dragging then
				dragging = false
				pcall(ModMenu.Config.save)
			end
		end
	end))
	table.insert(menuConns, S.UserInputService.InputChanged:Connect(function(input)
		if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
			local pct = math.clamp((input.Position.X - bar.AbsolutePosition.X) / bar.AbsoluteSize.X, 0, 1)
			setValue(min + (max - min) * pct)
		end
	end))

	-- Show the stored/default value without running the feature on load.
	render(value)
	return row
end

local function section(parent: Instance, text: string)
	local lbl = Instance.new("TextLabel")
	lbl.Size = UDim2.new(1, -8, 0, 22)
	lbl.BackgroundTransparency = 1
	lbl.TextColor3 = Theme.muted
	lbl.Font = Theme.font
	lbl.TextSize = 13
	lbl.TextXAlignment = Enum.TextXAlignment.Left
	lbl.Text = string.upper(text)
	lbl.Parent = parent
	Theme.textStroke(lbl, 0.7)
	return lbl
end

local function dropdown(parent: Instance, id: string, label: string, items: { string }, initial: string?, apply: ((string) -> ())?): Frame
	local row = Instance.new("Frame")
	row.Size = UDim2.new(1, -8, 0, 30)
	row.BackgroundTransparency = 1
	row.Parent = parent

	local lbl = Instance.new("TextLabel")
	lbl.Size = UDim2.new(0.4, 0, 1, 0)
	lbl.BackgroundTransparency = 1
	lbl.TextColor3 = Theme.text
	lbl.Font = Theme.font
	lbl.TextSize = 13
	lbl.TextXAlignment = Enum.TextXAlignment.Left
	lbl.Text = label
	lbl.Parent = row
	Theme.textStroke(lbl, 0.65)

	local btn = Instance.new("TextButton")
	btn.Size = UDim2.new(0.6, 0, 1, -4)
	btn.Position = UDim2.new(0.4, 0, 0, 2)
	btn.BackgroundColor3 = Theme.surface
	btn.TextColor3 = Theme.text
	btn.Font = Theme.font
	btn.TextSize = 13
	btn.BorderSizePixel = 0
	Theme.corner(btn, 6)
	Theme.textStroke(btn, 0.6)
	btn.Parent = row

	local savedString = ModMenu.State.strings[id]
	local selected = if savedString ~= nil then savedString else (initial or items[1] or "")
	btn.Text = selected
	local open = false
	local list = Instance.new("ScrollingFrame")
	list.Size = UDim2.new(0.6, 0, 0, math.min(#items * 22, 160))
	list.Position = UDim2.new(0.4, 0, 1, 0)
	list.BackgroundColor3 = Theme.panel
	list.BorderSizePixel = 0
	list.Visible = false
	list.ZIndex = 20
	list.ScrollBarThickness = 6
	list.AutomaticCanvasSize = Enum.AutomaticSize.Y
	list.CanvasSize = UDim2.new(0, 0, 0, #items * 22)
	Theme.corner(list, 6)
	local listLayout = Instance.new("UIListLayout")
	listLayout.Padding = UDim.new(0, 1)
	listLayout.SortOrder = Enum.SortOrder.LayoutOrder
	listLayout.Parent = list
	list.Parent = row

	for i, item in items do
		local b = Instance.new("TextButton")
		b.Size = UDim2.new(1, 0, 0, 22)
		b.LayoutOrder = i
		b.BackgroundColor3 = Theme.surface
		b.TextColor3 = Theme.text
		b.Font = Theme.font
		b.TextSize = 13
		b.Text = item
		b.BorderSizePixel = 0
		b.Parent = list
		Theme.textStroke(b, 0.6)
		b.MouseButton1Click:Connect(function()
			selected = item
			btn.Text = selected
			open = false
			list.Visible = false
			ModMenu.State.strings[id] = selected
			if apply then pcall(apply, selected) end
			pcall(ModMenu.Config.save)
		end)
	end

	btn.MouseButton1Click:Connect(function()
		open = not open
		list.Visible = open
	end)

	ModMenu.State.strings[id] = selected
	-- Do not run apply() at construction: a dropdown's default item was switching
	-- the camera to the first player and firing a player-info notification on load.
	return row
end

ModMenu.UI = ModMenu.UI or {}
ModMenu.UI.toggleSync = ModMenu.UI.toggleSync or {}
ModMenu.UI.toggleApply = ModMenu.UI.toggleApply or {}
ModMenu.UI.Components = {
	button = button,
	toggle = toggle,
	slider = slider,
	section = section,
	dropdown = dropdown,
}

-- ===== src\ui\menu.lua =====
--!strict
-- ui/menu.luau
local S = ModMenu.Services
local UserInputService = S.UserInputService
local Theme = ModMenu.Theme
local C = ModMenu.UI.Components
-- Background picture resolution chain (verified approach):
--   1) getcustomasset()/getsynasset() -> an rbxasset://ExtraContent/... content
--      id rendered from a LOCAL file. This is the only path known to render
--      in ImageLabels on the Real executor (rbxassetid decals never load
--      there). The file must sit in the executor's workspace folder
--      (Real: its Workspace folder). Missing file -> pcall error -> next step.
--   2) BACKGROUND_ASSET_ID: an uploaded Decal id. Works on executors whose
--      ImageLabel loads rbxassetid; a load timeout falls back to solid.
--   3) Solid themed background.
local BACKGROUND_FILES = { "ModMenuBackground.png", "picture.png" } -- files in the executor's workspace folder
local BACKGROUND_URL = "https://raw.githubusercontent.com/scr1ptyureishirayukimikotofujiwarasayo/robloxsakuramodmenu/main/picture.png"
local BACKGROUND_ASSET_ID = "86915755447721"
local PNG_MAGIC = "\137PNG\r\n\26\n"

local function hasValidPngFile(path: string): boolean
	if not readfile then return false end
	local ok, data = pcall(readfile, path)
	return ok and type(data) == "string" and data:sub(1, 8) == PNG_MAGIC
end

local function ensureLocalBackgroundFile(): string?
	for _, file in BACKGROUND_FILES do
		if hasValidPngFile(file) then
			return file
		end
	end
	-- Attempt to download picture.png into ModMenuBackground.png if missing
	local target = BACKGROUND_FILES[1]
	local body: string? = nil
	local okGet, got = pcall(function()
		return game:HttpGet(BACKGROUND_URL, true)
	end)
	if okGet and type(got) == "string" and got:sub(1, 8) == PNG_MAGIC then
		body = got
	elseif httprequest then
		local okReq, resp = pcall(httprequest, { Url = BACKGROUND_URL, Method = "GET" })
		if okReq and resp then
			local raw = if type(resp) == "string" then resp elseif type(resp) == "table" then (resp.Body or resp.body or resp.Content or resp.content or resp.data) else nil
			if type(raw) == "string" and raw:sub(1, 8) == PNG_MAGIC then
				body = raw
			end
		end
	end
	if body and writefile then
		pcall(function()
			local ok = pcall(writefile, target, body, true)
			if not ok then
				writefile(target, body)
			end
		end)
		if hasValidPngFile(target) then
			return target
		end
	end
	return nil
end

-- Returns (content id or nil, source tag "custom" | "rbxassetid" | "none").
local function resolveBackgroundImage(): (string?, string)
	local custom = getcustomasset or getsynasset
	if custom then
		-- Try existing local files first without blocking on network
		for _, file in BACKGROUND_FILES do
			if not readfile or hasValidPngFile(file) then
				local ok, cid = pcall(custom, file)
				if ok and type(cid) == "string" and cid ~= "" then
					return cid, "custom"
				end
			end
		end
		-- Download if missing and try again
		local downloaded = ensureLocalBackgroundFile()
		if downloaded then
			local ok, cid = pcall(custom, downloaded)
			if ok and type(cid) == "string" and cid ~= "" then
				return cid, "custom"
			end
		end
	end
	if BACKGROUND_ASSET_ID ~= "" then
		return "rbxassetid://" .. BACKGROUND_ASSET_ID, "rbxassetid"
	end
	return nil, "none"
end

-- Always create our own ScreenGui. gethui() and syn.protect_gui() return a
-- *container* (CoreGui or a hidden folder), not a ScreenGui, so ScreenGui-only
-- properties must never be set on their result.
local function destroyExistingGui()
	local containers = {}
	local okCore, coreGui = pcall(function() return game:GetService("CoreGui") end)
	if okCore and coreGui then table.insert(containers, coreGui) end
	local lp = ModMenu.Services.Players.LocalPlayer
	local pg = lp and lp:FindFirstChild("PlayerGui")
	if pg then table.insert(containers, pg) end
	for _, holder in containers do
		for _, d in holder:GetDescendants() do
			if d:IsA("ScreenGui") and d.Name == "ModMenu" then
				pcall(function() d:Destroy() end)
			end
		end
	end
	-- Drop last run's global input listeners too, or every reload doubles them.
	ModMenu.State.clearConnections("menu")
end
destroyExistingGui()

local function trackConnection(conn: RBXScriptConnection)
	table.insert(ModMenu.State.getConnections("menu"), conn)
	return conn
end

local function makeScreenGui(): ScreenGui
	local g = Instance.new("ScreenGui")
	g.Name = "ModMenu"
	g.ResetOnSpawn = false
	g.DisplayOrder = 2147483647
	return g
end

local function preferredContainer(): Instance?
	if gethui then
		local ok, container = pcall(gethui)
		if ok and typeof(container) == "Instance" then
			return container
		end
	end
	local okCore, coreGui = pcall(function() return game:GetService("CoreGui") end)
	if okCore and coreGui then
		return coreGui
	end
	return nil
end

local parentGui = makeScreenGui()
if syn_protect_gui then
	pcall(syn_protect_gui, parentGui)
end
local container = preferredContainer()
local parented = false
if container then
	parented = pcall(function() parentGui.Parent = container end)
end
if not parented then
	local lp = ModMenu.Services.Players.LocalPlayer
	local pg = lp and lp:FindFirstChild("PlayerGui")
	if not pg and lp then
		pg = lp:WaitForChild("PlayerGui", 10)
	end
	if pg then
		parented = pcall(function() parentGui.Parent = pg end)
	end
end
if not parented then
	warn("[ModMenu] could not parent UI; menu will not be visible")
end

-- live-reload tears down STATE on the next deploy; make that destroy the GUI
-- as well so a reload never leaves a ghost window behind.
if STATE and STATE.onCleanup then
	STATE.onCleanup(function()
		pcall(function() parentGui:Destroy() end)
		ModMenu.State.clearConnections("menu")
	end)
end

ModMenu.Menu = { ScreenGui = parentGui, Open = false }

local screen = ModMenu.Menu.ScreenGui
screen.Name = "ModMenu"
screen.ResetOnSpawn = false

local root = Instance.new("Frame")
root.Name = "Root"
root.Size = ModMenu.State.settings.menuSize
root.Position = UDim2.new(0.5, -230, 0.5, -170)
root.BackgroundColor3 = Theme.background
root.BackgroundTransparency = 0
root.BorderSizePixel = 0
root.ZIndex = 0
root.ClipsDescendants = true -- keeps the photo inside the rounded corners
Theme.corner(root, 10)
root.Visible = false
root.Parent = screen
ModMenu.Menu.Root = root
Theme.stroke(root, Theme.accent(), 1.5)

-- Rendering rules below were verified live on the Real executor:
--  * ZIndex is sorted across the WHOLE ScreenGui, not per subtree. A photo
--    behind the UI therefore needs ZIndex 0 AND a transparent root background,
--    otherwise the opaque root frame paints straight over it (this is what
--    made the menu look "black" even with a valid image).
--  * Widgets default to ZIndex 1, so without an explicit pass they end up
--    under their own panels. applyZOrder() assigns depth-based ZIndex values
--    so children always draw above their parents. Call it again after adding
--    new widgets (init.luau does this once the panels are populated).
--  * Dim the photo with ImageColor3, never a black overlay frame: any overlay
--    above ZIndex 0 also darkens the text sitting on top of it.
local backgroundImage = Instance.new("ImageLabel")
backgroundImage.Name = "BackgroundImage"
backgroundImage.Size = UDim2.fromScale(1, 1)
backgroundImage.Position = UDim2.fromOffset(0, 0)
backgroundImage.BackgroundTransparency = 1
backgroundImage.BorderSizePixel = 0
backgroundImage.ScaleType = Enum.ScaleType.Crop
backgroundImage.ZIndex = 0
backgroundImage.Visible = false
backgroundImage.Parent = root
ModMenu.Menu.BackgroundImage = backgroundImage

local imageId, imageSource = resolveBackgroundImage()
local hasImage = imageId ~= nil

local function applyBackground()
	local on = hasImage and ModMenu.State.toggles["settings.backgroundImage"] ~= false
	local brightness = math.clamp(ModMenu.State.numbers["settings.bgBrightness"] or 80, 0, 255)
	backgroundImage.Visible = on
	backgroundImage.ImageColor3 = Color3.fromRGB(brightness, brightness, brightness)
	root.BackgroundTransparency = if on then 1 else 0
end
ModMenu.Menu.applyBackground = applyBackground

if hasImage then
	backgroundImage.Image = imageId
	if imageSource == "rbxassetid" then
		-- Uploaded decals may never load on some executors; fall back to solid.
		task.spawn(function()
			for _ = 1, 8 do
				local ok, isLoaded = pcall(function()
					return backgroundImage.IsLoaded
				end)
				if not ok then return end -- member missing: leave the image alone
				if isLoaded then return end
				task.wait(1)
			end
			hasImage = false
			applyBackground()
			warn(`[ModMenu] bg: rbxassetid {BACKGROUND_ASSET_ID} did not load; using solid background`)
		end)
	end
end
applyBackground()

local function applyZOrder()
	local function walk(inst: Instance, depth: number)
		for _, child in inst:GetChildren() do
			if child:IsA("GuiObject") then
				child.ZIndex = if child == backgroundImage then 0 else depth
				walk(child, depth + 1)
			end
		end
	end
	root.ZIndex = 0
	walk(root, 1)
end
ModMenu.Menu.applyZOrder = applyZOrder

local topBar = Instance.new("Frame")
topBar.Size = UDim2.new(1, 0, 0, 30)
topBar.BackgroundColor3 = Theme.panel
topBar.BackgroundTransparency = 0.3
topBar.BorderSizePixel = 0
topBar.ZIndex = 2
Theme.corner(topBar, 10)
topBar.Parent = root

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, -90, 1, 0)
title.Position = UDim2.new(0, 12, 0, 0)
title.BackgroundTransparency = 1
title.Text = "MOD MENU"
title.TextColor3 = Theme.text
title.Font = Theme.font
title.TextSize = Theme.titleText
title.TextXAlignment = Enum.TextXAlignment.Left
title.Parent = topBar
Theme.textStroke(title, 0.6)

local closeBtn = Instance.new("TextButton")
closeBtn.Size = UDim2.new(0, 24, 0, 24)
closeBtn.Position = UDim2.new(1, -28, 0, 3)
closeBtn.BackgroundColor3 = Theme.danger
closeBtn.Text = "X"
closeBtn.TextColor3 = Theme.text
closeBtn.Font = Theme.font
closeBtn.TextSize = 14
closeBtn.BorderSizePixel = 0
Theme.corner(closeBtn, 6)
closeBtn.Parent = topBar

local minBtn = Instance.new("TextButton")
minBtn.Size = UDim2.new(0, 24, 0, 24)
minBtn.Position = UDim2.new(1, -56, 0, 3)
minBtn.BackgroundColor3 = Theme.surface
minBtn.Text = "-"
minBtn.TextColor3 = Theme.text
minBtn.Font = Theme.font
minBtn.TextSize = 18
minBtn.BorderSizePixel = 0
Theme.corner(minBtn, 6)
minBtn.Parent = topBar

local sidebar = Instance.new("ScrollingFrame")
sidebar.Size = UDim2.new(0, 120, 1, -30)
sidebar.Position = UDim2.new(0, 0, 0, 30)
sidebar.BackgroundColor3 = Theme.panel
sidebar.BackgroundTransparency = 0.3
sidebar.BorderSizePixel = 0
sidebar.ScrollBarThickness = 4
sidebar.AutomaticCanvasSize = Enum.AutomaticSize.Y
sidebar.CanvasSize = UDim2.new(0, 0, 0, 0)
sidebar.ZIndex = 2
sidebar.Parent = root
local sidebarLayout = Instance.new("UIListLayout")
sidebarLayout.Padding = UDim.new(0, 4)
sidebarLayout.SortOrder = Enum.SortOrder.LayoutOrder
sidebarLayout.Parent = sidebar
local sidebarPad = Instance.new("UIPadding")
sidebarPad.PaddingTop = UDim.new(0, 4)
sidebarPad.PaddingLeft = UDim.new(0, 4)
sidebarPad.PaddingRight = UDim.new(0, 4)
sidebarPad.PaddingBottom = UDim.new(0, 6)
sidebarPad.Parent = sidebar

local contentArea = Instance.new("Frame")
contentArea.Size = UDim2.new(1, -120, 1, -30)
contentArea.Position = UDim2.new(0, 120, 0, 30)
contentArea.BackgroundTransparency = 1
contentArea.ClipsDescendants = true
contentArea.ZIndex = 2
contentArea.Parent = root

local categories = {
	{ id = "home", name = "Home" },
	{ id = "player", name = "Player" },
	{ id = "movement", name = "Movement" },
	{ id = "visual", name = "Visual" },
	{ id = "world", name = "World" },
	{ id = "teleport", name = "Teleport" },
	{ id = "character", name = "Character" },
	{ id = "protection", name = "Protection" },
	{ id = "utility", name = "Utility" },
	{ id = "settings", name = "Settings" },
}

ModMenu.Menu.Panels = {}
ModMenu.Menu.Buttons = {}

local function makePanel(id: string)
	local p = Instance.new("ScrollingFrame")
	p.Name = id
	p.Size = UDim2.new(1, 0, 1, 0)
	p.Position = UDim2.new(0, 0, 0, 0)
	p.BackgroundTransparency = 1
	p.BorderSizePixel = 0
	p.ScrollBarThickness = 6
	p.AutomaticCanvasSize = Enum.AutomaticSize.Y
	p.Visible = false
	p.ZIndex = 3
	p.Parent = contentArea
	local layout = Instance.new("UIListLayout")
	layout.Padding = UDim.new(0, 4)
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Parent = p
	local pad = Instance.new("UIPadding")
	pad.PaddingTop = UDim.new(0, 6)
	pad.PaddingLeft = UDim.new(0, 6)
	pad.PaddingRight = UDim.new(0, 8)
	pad.PaddingBottom = UDim.new(0, 6)
	pad.Parent = p
	ModMenu.Menu.Panels[id] = p
	return p
end

local function switchTab(id: string)
	for _, cat in categories do
		local panel = ModMenu.Menu.Panels[cat.id]
		if panel then panel.Visible = (cat.id == id) end
		local btn = ModMenu.Menu.Buttons[cat.id]
		if btn then
			btn.BackgroundColor3 = (cat.id == id) and Theme.accent() or Theme.surface
		end
	end
end
ModMenu.Menu.switchTab = switchTab

for i, cat in categories do
	local btn = Instance.new("TextButton")
	btn.Size = UDim2.new(1, 0, 0, 26)
	btn.LayoutOrder = i
	btn.BackgroundColor3 = Theme.surface
	btn.Text = cat.name
	btn.TextColor3 = Theme.text
	btn.Font = Theme.font
	btn.TextSize = 13
	btn.BorderSizePixel = 0
	Theme.corner(btn, 6)
	btn.Parent = sidebar
	Theme.textStroke(btn, 0.55)
	ModMenu.Menu.Buttons[cat.id] = btn
	btn.MouseButton1Click:Connect(function() switchTab(cat.id) end)
	makePanel(cat.id)
end

local floating = Instance.new("TextButton")
floating.Size = UDim2.new(0, 44, 0, 44)
floating.Position = UDim2.new(0, 20, 0.5, -22)
floating.BackgroundColor3 = Theme.accent()
floating.Text = "MM"
floating.TextColor3 = Theme.text
floating.Font = Theme.font
floating.TextSize = 16
floating.Visible = false
floating.Parent = screen
Theme.corner(floating, 22)
Theme.textStroke(floating, 0.45)
ModMenu.Menu.Floating = floating

local dragging = false
local dragStart, startPos
trackConnection(topBar.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
		dragging = true
		dragStart = input.Position
		startPos = root.Position
	end
end))
trackConnection(UserInputService.InputChanged:Connect(function(input)
	if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
		local delta = input.Position - dragStart
		root.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
	end
end))
trackConnection(UserInputService.InputEnded:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
		dragging = false
	end
end))

local function setOpen(value: boolean)
	ModMenu.Menu.Open = value
	root.Visible = value
	floating.Visible = not value
end
ModMenu.Menu.setOpen = setOpen

closeBtn.MouseButton1Click:Connect(function() setOpen(false) end)
minBtn.MouseButton1Click:Connect(function() setOpen(false) end)
floating.MouseButton1Click:Connect(function() setOpen(true) end)

trackConnection(S.UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then return end
	if input.KeyCode == ModMenu.State.settings.openKey then
		setOpen(not ModMenu.Menu.Open)
		return
	end
end))

switchTab("home")
setOpen(false)
applyZOrder()
-- UI built

-- ===== src\features\movement.lua =====
--!strict
-- features/movement.luau
local S = ModMenu.Services
local RunService = S.RunService
local UserInputService = S.UserInputService
local Workspace = S.Workspace

ModMenu.Features = ModMenu.Features or {}
ModMenu.Features.Movement = {}

local function char()
	return S.Players.LocalPlayer.Character
end
local function hum(): Humanoid?
	local c = char()
	if c then return c:FindFirstChildOfClass("Humanoid") end
	return nil
end
local function root(): BasePart?
	local c = char()
	if c then return c:FindFirstChild("HumanoidRootPart") :: BasePart? end
	return nil
end

-- Open the protection bypass window (when the Protection module is loaded)
-- so the menu's own teleports are never reverted by anti-teleport.
local function tpBypass(seconds: number?)
	local prot = ModMenu.Features and ModMenu.Features.Protection
	if prot and prot.bypass then
		pcall(prot.bypass, seconds)
	end
end

ModMenu.Features.Movement.setWalkSpeed = function(value: number)
	local h = hum()
	if h then
		if ModMenu.State.originalWalkSpeed == nil then
			ModMenu.State.originalWalkSpeed = h.WalkSpeed
		end
		h.WalkSpeed = value
	end
end

ModMenu.Features.Movement.setJumpPower = function(value: number)
	local h = hum()
	if h then
		if ModMenu.State.originalJumpPower == nil then
			ModMenu.State.originalJumpPower = h.JumpPower
		end
		h.JumpPower = value
	end
end

ModMenu.Features.Movement.setGravity = function(value: number)
	Workspace.Gravity = value
end

ModMenu.Features.Movement.fly = function(enabled: boolean)
	local id = "movement.fly"
	ModMenu.State.clearConnections(id)
	if not enabled then
		local h = hum()
		if h then
			h:ChangeState(Enum.HumanoidStateType.GettingUp)
		end
		local bv = root() and root():FindFirstChild("ModMenuFlyVelocity")
		if bv then bv:Destroy() end
		return
	end
	local bodyVelocity = Instance.new("BodyVelocity")
	bodyVelocity.Name = "ModMenuFlyVelocity"
	bodyVelocity.MaxForce = Vector3.new(1e5, 1e5, 1e5)
	bodyVelocity.Velocity = Vector3.zero
	local r = root()
	if r then bodyVelocity.Parent = r end

	local conn = RunService.RenderStepped:Connect(function()
		local r2 = root()
		local h2 = hum()
		if not r2 or not h2 then return end
		if not bodyVelocity.Parent then bodyVelocity.Parent = r2 end
		local cam = S.Workspace.CurrentCamera
		local direction = Vector3.zero
		if UserInputService:IsKeyDown(Enum.KeyCode.W) then direction += cam.CFrame.LookVector end
		if UserInputService:IsKeyDown(Enum.KeyCode.S) then direction -= cam.CFrame.LookVector end
		if UserInputService:IsKeyDown(Enum.KeyCode.A) then direction -= cam.CFrame.RightVector end
		if UserInputService:IsKeyDown(Enum.KeyCode.D) then direction += cam.CFrame.RightVector end
		if UserInputService:IsKeyDown(Enum.KeyCode.Space) then direction += Vector3.new(0, 1, 0) end
		if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then direction -= Vector3.new(0, 1, 0) end
		local speed = ModMenu.State.numbers["movement.flySpeed"] or 60
		if direction.Magnitude > 0 then
			bodyVelocity.Velocity = direction.Unit * speed
		else
			bodyVelocity.Velocity = Vector3.zero
		end
		h2:ChangeState(Enum.HumanoidStateType.Physics)
	end)
	table.insert(ModMenu.State.getConnections(id), conn)
end

ModMenu.Features.Movement.noclip = function(enabled: boolean)
	local id = "movement.noclip"
	ModMenu.State.clearConnections(id)
	if not enabled then
		local c = char()
		if c then
			for _, part in c:GetDescendants() do
				if part:IsA("BasePart") then
					part.CanCollide = true
				end
			end
		end
		return
	end
	local conn = RunService.Stepped:Connect(function()
		local c = char()
		if not c then return end
		for _, part in c:GetDescendants() do
			if part:IsA("BasePart") then
				part.CanCollide = false
			end
		end
	end)
	table.insert(ModMenu.State.getConnections(id), conn)
end

ModMenu.Features.Movement.float = function(enabled: boolean)
	local id = "movement.float"
	ModMenu.State.clearConnections(id)
	local r = root()
	if not r then return end
	if not enabled then
		local bp = r:FindFirstChild("ModMenuFloat")
		if bp then bp:Destroy() end
		return
	end
	local bodyPosition = Instance.new("BodyPosition")
	bodyPosition.Name = "ModMenuFloat"
	bodyPosition.MaxForce = Vector3.new(0, 1e5, 0)
	bodyPosition.Position = r.Position
	bodyPosition.Parent = r
	local conn = RunService.RenderStepped:Connect(function()
		local r2 = root()
		if r2 and bodyPosition.Parent then
			bodyPosition.Position = Vector3.new(r2.Position.X, bodyPosition.Position.Y, r2.Position.Z)
		end
	end)
	table.insert(ModMenu.State.getConnections(id), conn)
end

ModMenu.Features.Movement.getWaypoints = function()
	return ModMenu.State.waypoints
end

ModMenu.Features.Movement.saveWaypoint = function(name: string?)
	local r = root()
	if not r then return end
	name = name or ("WP " .. tostring(#ModMenu.State.waypoints + 1))
	table.insert(ModMenu.State.waypoints, { name = name, position = r.Position })
	pcall(ModMenu.Config.save)
	ModMenu.Notify("Waypoint", "Saved: " .. name)
end

ModMenu.Features.Movement.teleportWaypoint = function(index: number)
	local wp = ModMenu.State.waypoints[index]
	local r = root()
	if wp and r then
		tpBypass(1)
		r.CFrame = CFrame.new(wp.position)
	end
end

ModMenu.Features.Movement.setHipHeight = function(value: number)
	local h = hum()
	if h then
		if ModMenu.State.originalHipHeight == nil then
			ModMenu.State.originalHipHeight = h.HipHeight
		end
		h.HipHeight = value
	end
end

ModMenu.Features.Movement.clickTeleport = function(enabled: boolean)
	local id = "movement.clicktp"
	ModMenu.State.clearConnections(id)
	if not enabled then return end
	local mouse = S.Players.LocalPlayer:GetMouse()
	local conn = mouse.Button1Down:Connect(function()
		local r = root()
		if r then
			local target = mouse.Hit
			if target then
				tpBypass(0.5)
				r.CFrame = target * CFrame.new(0, 3, 0)
			end
		end
	end)
	table.insert(ModMenu.State.getConnections(id), conn)
end

ModMenu.Features.Movement.savePosition = function(name: string?)
	local r = root()
	if not r then return end
	name = name or "Saved Position"
	ModMenu.State.savedPosition = r.Position
	ModMenu.State.savedPositionName = name
	pcall(ModMenu.Config.save)
	ModMenu.Notify("Position", "Saved: " .. name)
end

ModMenu.Features.Movement.loadPosition = function()
	local r = root()
	if r and ModMenu.State.savedPosition then
		tpBypass(1)
		r.CFrame = CFrame.new(ModMenu.State.savedPosition)
	end
end

ModMenu.Features.Movement.resetMovement = function()
	local h = hum()
	if h then
		h.WalkSpeed = ModMenu.State.originalWalkSpeed or 16
		h.JumpPower = ModMenu.State.originalJumpPower or 50
		h.HipHeight = ModMenu.State.originalHipHeight or 0
	end
	ModMenu.Features.Movement.setGravity(196.2)
end

-- ===== src\features\visual.lua =====
--!strict
-- features/visual.luau
local S = ModMenu.Services
local Lighting = S.Lighting
local RunService = S.RunService
local Camera = S.Workspace.CurrentCamera

ModMenu.Features = ModMenu.Features or {}
ModMenu.Features.Visual = {}

ModMenu.Features.Visual.fullbright = function(enabled: boolean)
	if enabled then
		Lighting.Brightness = 2
		Lighting.ClockTime = 14
		Lighting.FogEnd = 1e5
		Lighting.GlobalShadows = false
	else
		Lighting.Brightness = 1
		Lighting.GlobalShadows = true
	end
end

ModMenu.Features.Visual.removeFog = function(enabled: boolean)
	if enabled then
		Lighting.FogEnd = 1e5
		Lighting.FogStart = 0
	else
		Lighting.FogEnd = 1000
	end
end

ModMenu.Features.Visual.setFOV = function(value: number)
	local cam = S.Workspace.CurrentCamera
	if cam then cam.FieldOfView = value end
end

ModMenu.Features.Visual.setClockTime = function(value: number)
	Lighting.ClockTime = value
end

ModMenu.Features.Visual.esp = function(enabled: boolean)
	local id = "visual.esp"
	ModMenu.State.clearConnections(id)
	if not enabled then
		for _, p in S.Players:GetPlayers() do
			if p.Character then
				local old = p.Character:FindFirstChild("ModMenuESP")
				if old then old:Destroy() end
			end
		end
		return
	end
	local function applyTo(char: Model)
		if not char:FindFirstChild("ModMenuESP") then
			local hl = Instance.new("Highlight")
			hl.Name = "ModMenuESP"
			hl.FillTransparency = 0.5
			hl.OutlineTransparency = 0
			hl.FillColor = ModMenu.Theme.accent()
			hl.Parent = char
		end
	end
	for _, p in S.Players:GetPlayers() do
		if p ~= S.Players.LocalPlayer and p.Character then applyTo(p.Character) end
	end
	local conn = S.Players.PlayerAdded:Connect(function(p)
		local cconn = p.CharacterAdded:Connect(function(c)
			if ModMenu.State.toggles["visual.esp"] then applyTo(c) end
		end)
		table.insert(ModMenu.State.getConnections(id), cconn)
	end)
	table.insert(ModMenu.State.getConnections(id), conn)
	local conn2 = RunService.Heartbeat:Connect(function()
		for _, p in S.Players:GetPlayers() do
			if p ~= S.Players.LocalPlayer and p.Character then
				if ModMenu.State.toggles["visual.esp"] then
					applyTo(p.Character)
				else
					local old = p.Character:FindFirstChild("ModMenuESP")
					if old then old:Destroy() end
				end
			end
		end
	end)
	table.insert(ModMenu.State.getConnections(id), conn2)
end

-- ===== src\features\character.lua =====
--!strict
-- features/character.luau
local S = ModMenu.Services

ModMenu.Features = ModMenu.Features or {}
ModMenu.Features.Character = {}

ModMenu.State.originalPlatformStand = ModMenu.State.originalPlatformStand or {}
ModMenu.State.invisibleOriginal = ModMenu.State.invisibleOriginal or {}
ModMenu.State.hiddenLimbOwner = ModMenu.State.hiddenLimbOwner or {}
ModMenu.State.hiddenLimbParent = ModMenu.State.hiddenLimbParent or {}
ModMenu.State.blockedHatMeshes = ModMenu.State.blockedHatMeshes or {}

local function char()
	return S.Players.LocalPlayer.Character
end
local function hum(): Humanoid?
	local c = char()
	if c then return c:FindFirstChildOfClass("Humanoid") end
	return nil
end

ModMenu.Features.Character.platformStand = function(enabled: boolean)
	local h = hum()
	if not h then return end
	if enabled then
		ModMenu.State.originalPlatformStand[h] = h.PlatformStand
		h.PlatformStand = true
	else
		local original = ModMenu.State.originalPlatformStand[h]
		h.PlatformStand = if original ~= nil then original else false
		ModMenu.State.originalPlatformStand[h] = nil
	end
end

ModMenu.Features.Character.view = function(tagetName: string?)
	local camera = S.Workspace.CurrentCamera
	if not camera then return end
	if not tagetName or tagetName == "" then
		if S.Players.LocalPlayer.Character then
			local h = S.Players.LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
			if h then camera.CameraSubject = h end
		end
		return
	end
	local target = S.Players:FindFirstChild(tagetName)
	if target and target.Character then
		local h = target.Character:FindFirstChildOfClass("Humanoid")
		if h then camera.CameraSubject = h end
	end
end

local limbNames = {
	all = {"Left Arm", "Right Arm", "Left Leg", "Right Leg"},
	arms = {"Left Arm", "Right Arm"},
	legs = {"Left Leg", "Right Leg"},
}

ModMenu.Features.Character.setLimbs = function(mode: string?, enabled: boolean)
	local c = char()
	if not c then return end
	local selected = limbNames[mode or "all"] or limbNames.all
	for _, limbName in selected do
		local limb = c:FindFirstChild(limbName)
		if not limb or not limb:IsA("BasePart") then continue end
		local owner = ModMenu.State.hiddenLimbOwner[limb]
		if enabled then
			if not owner then
				ModMenu.State.hiddenLimbParent[limb] = limb.Parent
				limb.Parent = nil
				ModMenu.State.hiddenLimbOwner[limb] = mode or "all"
			end
		else
			if owner == (mode or "all") then
				local parent = ModMenu.State.hiddenLimbParent[limb]
				if parent then limb.Parent = parent end
				ModMenu.State.hiddenLimbOwner[limb] = nil
				ModMenu.State.hiddenLimbParent[limb] = nil
			end
		end
	end
end

ModMenu.Features.Character.invisible = function(enabled: boolean)
	local c = char()
	if not c then return end
	if enabled then
		for _, part in c:GetDescendants() do
			if part:IsA("BasePart") or part:IsA("Decal") then
				if ModMenu.State.invisibleOriginal[part] == nil then
					ModMenu.State.invisibleOriginal[part] = part.Transparency
				end
				part.Transparency = 1
			end
		end
	else
		for part, value in ModMenu.State.invisibleOriginal do
			if part and part.Parent then
				part.Transparency = value
			end
		end
		for k in ModMenu.State.invisibleOriginal do
			ModMenu.State.invisibleOriginal[k] = nil
		end
	end
end

ModMenu.Features.Character.blockHats = function(enabled: boolean)
	local c = char()
	if not c then return end
	if enabled then
		for _, accessory in c:GetChildren() do
			if accessory:IsA("Accessory") or accessory:IsA("Hat") then
				for _, descendant in accessory:GetDescendants() do
					if descendant:IsA("SpecialMesh") or descendant:IsA("SurfaceAppearance") then
						if ModMenu.State.blockedHatMeshes[descendant] == nil then
							ModMenu.State.blockedHatMeshes[descendant] = descendant.Parent
						end
						descendant.Parent = nil
					end
				end
			end
		end
	else
		for mesh, parent in ModMenu.State.blockedHatMeshes do
			if mesh and parent then
				mesh.Parent = parent
			end
		end
		for k in ModMenu.State.blockedHatMeshes do
			ModMenu.State.blockedHatMeshes[k] = nil
		end
	end
end

-- ===== src\features\utility.lua =====
--!strict
-- features/utility.luau
local S = ModMenu.Services

ModMenu.Features = ModMenu.Features or {}
ModMenu.Features.Utility = {}
ModMenu.State.hiddenParts = ModMenu.State.hiddenParts or {}
ModMenu.State.workspaceVisibilityOriginal = ModMenu.State.workspaceVisibilityOriginal or {}
ModMenu.State.lockedPartsOriginal = ModMenu.State.lockedPartsOriginal or {}

-- Click TP / Delete / tool grabber connections handled via movement clickTeleport id and utility ids.

ModMenu.Features.Utility.clickDelete = function(enabled: boolean)
	local id = "utility.clickDelete"
	ModMenu.State.clearConnections(id)
	if not enabled then
		-- restore hidden parts to their original parent
		for part, originalParent in ModMenu.State.hiddenParts do
			if part and part.Parent == nil then
				if typeof(originalParent) == "Instance" then
					part.Parent = originalParent
				else
					part.Parent = S.Workspace
				end
			end
		end
		table.clear(ModMenu.State.hiddenParts)
		return
	end
	local mouse = S.Players.LocalPlayer:GetMouse()
	local conn = mouse.Button1Down:Connect(function()
		local target = mouse.Target
		if target and target:IsA("BasePart") then
			ModMenu.State.hiddenParts[target] = target.Parent
			target.Parent = nil
		end
	end)
	table.insert(ModMenu.State.getConnections(id), conn)
end

ModMenu.Features.Utility.toolGrabber = function(enabled: boolean)
	local id = "utility.toolGrabber"
	ModMenu.State.clearConnections(id)
	if not enabled then return end
	local function grab()
		local bp = S.Players.LocalPlayer:FindFirstChild("Backpack")
		if not bp then return end
		for _, obj in S.Workspace:GetChildren() do
			if obj:IsA("Tool") or obj:IsA("HopperBin") then
				pcall(function() obj.Parent = bp end)
			end
		end
	end
	grab()
	local conn = S.Workspace.ChildAdded:Connect(function(child)
		if enabled and (child:IsA("Tool") or child:IsA("HopperBin")) then
			task.wait()
			local bp = S.Players.LocalPlayer:FindFirstChild("Backpack")
			if bp then pcall(function() child.Parent = bp end) end
		end
	end)
	table.insert(ModMenu.State.getConnections(id), conn)
end

ModMenu.Features.Utility.workspaceVisibility = function(value: number)
	value = math.clamp(value, 0, 1)
	if next(ModMenu.State.workspaceVisibilityOriginal) == nil then
		for _, part in S.Workspace:GetDescendants() do
			if part:IsA("BasePart") then
				ModMenu.State.workspaceVisibilityOriginal[part] = part.Transparency
			end
		end
	end
	for part, original in ModMenu.State.workspaceVisibilityOriginal do
		if part and part.Parent then
			part.Transparency = original + (1 - original) * (1 - value)
		end
	end
end

ModMenu.Features.Utility.restoreWorkspaceVisibility = function()
	for part, original in ModMenu.State.workspaceVisibilityOriginal do
		if part and part.Parent then
			part.Transparency = original
		end
	end
	table.clear(ModMenu.State.workspaceVisibilityOriginal)
end

ModMenu.Features.Utility.lockWorkspace = function(enabled: boolean)
	if enabled then
		if next(ModMenu.State.lockedPartsOriginal) == nil then
			for _, part in S.Workspace:GetDescendants() do
				if part:IsA("BasePart") then
					ModMenu.State.lockedPartsOriginal[part] = part.Anchored
					part.Anchored = true
				end
			end
		end
	else
		for part, original in ModMenu.State.lockedPartsOriginal do
			if part and part.Parent then
				part.Anchored = original
			end
		end
		table.clear(ModMenu.State.lockedPartsOriginal)
	end
end

ModMenu.Features.Utility.reach = function(enabled: boolean)
	local id = "utility.reach"
	ModMenu.State.clearConnections(id)
	if ModMenu.State.reachOriginal == nil then ModMenu.State.reachOriginal = {} end
	if not enabled then
		for handle, size in ModMenu.State.reachOriginal do
			if handle and handle.Parent then
				handle.Size = size
			end
		end
		table.clear(ModMenu.State.reachOriginal)
		return
	end
	local function applyReach()
		local lp = S.Players.LocalPlayer
		local char = lp.Character
		if not char then return end
		local tool = char:FindFirstChildOfClass("Tool")
		local backpack = lp:FindFirstChild("Backpack")
		if not tool and backpack then tool = backpack:FindFirstChildOfClass("Tool") end
		if not tool then return end
		for _, part in tool:GetDescendants() do
			if part:IsA("BasePart") and part.Name:lower():find("handle") then
				if ModMenu.State.reachOriginal[part] == nil then
					ModMenu.State.reachOriginal[part] = part.Size
				end
				part.Size = ModMenu.State.reachOriginal[part] * Vector3.new(4, 4, 8)
			end
		end
	end
	applyReach()
	local conn = S.RunService.Heartbeat:Connect(applyReach)
	table.insert(ModMenu.State.getConnections(id), conn)
end

ModMenu.Features.Utility.feCheck = function()
	local filtering = false
	pcall(function()
		filtering = S.Workspace.FilteringEnabled
	end)
	ModMenu.Notify("FilteringEnabled", filtering and "Filtering enabled (FE)" or "Filtering disabled/unknown")
end

ModMenu.Features.Utility.playerInfo = function(targetName: string?)
	local target = targetName and S.Players:FindFirstChild(targetName) or S.Players.LocalPlayer
	if not target then
		ModMenu.Notify("Info", "Player not found")
		return
	end
	ModMenu.Notify("Player Info", string.format("%s | Age: %d | Id: %d", target.Name, target.AccountAge, target.UserId))
end

-- ===== src\features\teleport.lua =====
--!strict
-- features/teleport.luau
local S = ModMenu.Services
local TeleportService = S.TeleportService
local Players = S.Players

ModMenu.Features = ModMenu.Features or {}
ModMenu.Features.Teleport = {}

-- Open the protection bypass window (when the Protection module is loaded)
-- so the menu's own teleports are never reverted by anti-teleport.
local function tpBypass(seconds: number?)
	local prot = ModMenu.Features and ModMenu.Features.Protection
	if prot and prot.bypass then
		pcall(prot.bypass, seconds)
	end
end

ModMenu.Features.Teleport.toSpawn = function()
	local r = (ModMenu.Services.Players.LocalPlayer.Character or {}).HumanoidRootPart
	if S.Workspace:FindFirstChild("SpawnLocation") then
		local sp = S.Workspace:FindFirstChild("SpawnLocation")
		if sp and r then
			tpBypass(1)
			r.CFrame = sp.CFrame + Vector3.new(0, 3, 0)
		end
	end
end

ModMenu.Features.Teleport.copyPosition = function()
	local r = ModMenu.Services.Players.LocalPlayer.Character and ModMenu.Services.Players.LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
	if r then
		local pos = r.Position
		local text = string.format("%.2f, %.2f, %.2f", pos.X, pos.Y, pos.Z)
		if everyClipboard then everyClipboard(text) end
		ModMenu.Notify("Position", "Copied: " .. text)
	end
end

local REJOIN_LOADSTRING = 'loadstring(game:HttpGet("https://raw.githubusercontent.com/scr1ptyureishirayukimikotofujiwarasayo/robloxsakuramodmenu/main/loader.lua"))()'
local rejoinQueued = false

ModMenu.Features.Teleport.rejoin = function()
	-- Teleports create a fresh DataModel: queue the loader so the menu
	-- rebuilds itself in the new session (needs executor teleport-queue support).
	local queue = queue_on_teleport or (syn and syn.queue_on_teleport)
	if queue and not rejoinQueued then
		pcall(queue, REJOIN_LOADSTRING)
		rejoinQueued = true
	elseif not queue then
		ModMenu.Notify("Rejoin", "This executor can't auto-run after rejoin. Enable auto-execute or rerun the script.")
	end
	pcall(function()
		if game.JobId ~= "" then
			TeleportService:TeleportToPlaceInstance(game.PlaceId, game.JobId, S.Players.LocalPlayer)
		else
			TeleportService:Teleport(game.PlaceId, S.Players.LocalPlayer)
		end
	end)
end

-- ===== src\features\world.lua =====
--!strict
-- features/world.luau
local S = ModMenu.Services
local Lighting = S.Lighting

ModMenu.Features = ModMenu.Features or {}
ModMenu.Features.World = {}

ModMenu.Features.World.antiLag = function(enabled: boolean)
	if enabled then
		pcall(function() Lighting.GlobalShadows = false end)
		pcall(function() Lighting.FogEnd = 1e4 end)
		pcall(function() settings().Rendering.QualityLevel = Enum.QualityLevel.Level01 end)
	else
		pcall(function() Lighting.GlobalShadows = true end)
		pcall(function() settings().Rendering.QualityLevel = Enum.QualityLevel.Automatic end)
	end
end

-- ===== src\features\protection.lua =====
--!strict
-- features/protection.luau
local S = ModMenu.Services
local RunService = S.RunService
local Players = S.Players

ModMenu.Features = ModMenu.Features or {}
ModMenu.Features.Protection = {}

-- Bypass window shared by both protections. The menu's own teleports
-- (click TP, waypoints, saved positions) open it so they are never reverted.
local bypassUntil = 0

ModMenu.Features.Protection.bypass = function(seconds: number?)
	bypassUntil = os.clock() + (seconds or 1)
end

local function isBypassed(): boolean
	return os.clock() < bypassUntil
end

local function root(): BasePart?
	local c = Players.LocalPlayer.Character
	return if c then c:FindFirstChild("HumanoidRootPart") :: BasePart? else nil
end

local function hum(): Humanoid?
	local c = Players.LocalPlayer.Character
	return if c then c:FindFirstChildOfClass("Humanoid") else nil
end

-- Legit movement never spins the root anywhere near this fast; flings do.
local ANGULAR_SPIN_LIMIT = 50

ModMenu.Features.Protection.antiFling = function(enabled: boolean)
	local id = "protection.antiFling"
	ModMenu.State.clearConnections(id)
	if not enabled then return end

	local lastSafe: CFrame? = nil
	local lastRoot: BasePart? = nil

	local conn = RunService.Heartbeat:Connect(function()
		local r = root()
		if not r then return end

		-- Respawn / first frame: re-baseline instead of snapping back.
		if r ~= lastRoot then
			lastRoot = r
			lastSafe = r.CFrame
			return
		end

		if isBypassed() then
			lastSafe = r.CFrame
			return
		end

		local linear = r.AssemblyLinearVelocity.Magnitude
		local angular = r.AssemblyAngularVelocity.Magnitude
		local threshold = ModMenu.State.numbers["protection.flingThreshold"] or 400

		if linear <= threshold and angular <= ANGULAR_SPIN_LIMIT then
			lastSafe = r.CFrame
			return
		end

		-- Fling detected: kill the momentum and restore the last safe pose.
		local h = hum()
		local safe = lastSafe
		pcall(function()
			r.AssemblyLinearVelocity = Vector3.zero
			r.AssemblyAngularVelocity = Vector3.zero
			if h then
				h.Sit = false -- pops us out of fling seats
				h.PlatformStand = false
			end
		end)
		if safe and (r.Position - safe.Position).Magnitude > 5 then
			pcall(function() r.CFrame = safe end)
		end
	end)
	table.insert(ModMenu.State.getConnections(id), conn)
end

ModMenu.Features.Protection.antiTeleport = function(enabled: boolean)
	local id = "protection.antiTeleport"
	ModMenu.State.clearConnections(id)
	if not enabled then return end

	local lastRoot: BasePart? = nil
	local lastCFrame: CFrame? = nil
	local lastNotify = 0

	local conn = RunService.Heartbeat:Connect(function()
		if isBypassed() then
			lastRoot = nil
			lastCFrame = nil
			return
		end
		local r = root()
		if not r then
			lastRoot = nil
			lastCFrame = nil
			return
		end
		-- Respawn / character refresh: re-baseline, never revert.
		if r ~= lastRoot then
			lastRoot = r
			lastCFrame = r.CFrame
			return
		end
		local prev = lastCFrame
		if not prev then
			lastCFrame = r.CFrame
			return
		end
		local maxStuds = ModMenu.State.numbers["protection.tpMaxStuds"] or 50
		local moved = (r.Position - prev.Position).Magnitude
		if moved > maxStuds then
			pcall(function()
				r.CFrame = prev
				r.AssemblyLinearVelocity = Vector3.zero
				r.AssemblyAngularVelocity = Vector3.zero
			end)
			lastCFrame = prev
			if os.clock() - lastNotify > 3 then
				lastNotify = os.clock()
				ModMenu.Notify("Anti-Teleport", string.format("Blocked a %.0f stud teleport", moved))
			end
		else
			lastCFrame = r.CFrame
		end
	end)
	table.insert(ModMenu.State.getConnections(id), conn)
end

-- ===== src\features\interaction.lua =====
--!strict
-- features/interaction.luau
local S = ModMenu.Services
local RunService = S.RunService
local Workspace = S.Workspace
local Players = S.Players

ModMenu.Features = ModMenu.Features or {}
ModMenu.Features.Interaction = {}

local function root(): BasePart?
	local c = Players.LocalPlayer.Character
	return if c then c:FindFirstChild("HumanoidRootPart") :: BasePart? else nil
end

local function interval(): number
	return math.max(0.05, ModMenu.State.numbers["interaction.interval"] or 1)
end

-- Executor global is missing: turn the toggle back off (UI included) and say so.
local function disableToggle(id: string, what: string)
	ModMenu.State.toggles[id] = false
	local syncers = (ModMenu.UI and ModMenu.UI.toggleSync and ModMenu.UI.toggleSync[id]) or {}
	for _, sync in syncers do
		pcall(sync, false)
	end
	pcall(ModMenu.Config.save)
	ModMenu.Notify("Interaction", what .. " is not supported by this executor")
end

ModMenu.Features.Interaction.clickDetectorLoop = function(enabled: boolean)
	local id = "interaction.clickDetectors"
	ModMenu.State.clearConnections(id)
	if not enabled then return end
	if type(fireclickdetector) ~= "function" then
		disableToggle(id, "fireclickdetector")
		return
	end
	local fire = fireclickdetector :: any
	local acc = 0
	local announced = false
	local conn = RunService.Heartbeat:Connect(function(dt: number)
		acc += dt
		if acc < interval() then return end
		acc = 0
		local fired = 0
		for _, d in Workspace:GetDescendants() do
			if d:IsA("ClickDetector") then
				local part = d.Parent
				local pos = if part and part:IsA("BasePart") then part.Position else nil
				pcall(fire, d, pos)
				fired += 1
			end
		end
		if not announced then
			announced = true
			ModMenu.Notify("Interaction", string.format("Fired %d click detector(s)", fired))
		end
	end)
	table.insert(ModMenu.State.getConnections(id), conn)
end

ModMenu.Features.Interaction.touchInterestLoop = function(enabled: boolean)
	local id = "interaction.touch"
	ModMenu.State.clearConnections(id)
	if not enabled then return end
	if type(firetouchinterest) ~= "function" then
		disableToggle(id, "firetouchinterest")
		return
	end
	local fire = firetouchinterest :: any
	local acc = 0
	local announced = false
	local conn = RunService.Heartbeat:Connect(function(dt: number)
		acc += dt
		if acc < interval() then return end
		acc = 0
		local r = root()
		local char = Players.LocalPlayer.Character
		local fired = 0
		for _, d in Workspace:GetDescendants() do
			if d:IsA("TouchTransmitter") then
				local part = d.Parent
				if not (part and part:IsA("BasePart")) then continue end
				-- Never fire touch events on our own character.
				if char and (part == char or part:IsDescendantOf(char)) then continue end
				local toucher = if r and r.Parent then r else part
				pcall(function()
					fire(toucher, part, 0) -- touch begin
					fire(toucher, part, 1) -- touch end
				end)
				fired += 1
			end
		end
		if not announced then
			announced = true
			ModMenu.Notify("Interaction", string.format("Touched %d part(s)", fired))
		end
	end)
	table.insert(ModMenu.State.getConnections(id), conn)
end

-- ===== src\features\misc.lua =====
--!strict
-- features/misc.luau
local S = ModMenu.Services
local StarterGui = S.StarterGui

ModMenu.Features = ModMenu.Features or {}
ModMenu.Features.Misc = {}

ModMenu.Features.Misc.toggleCoreGui = function(guiType: string, enabled: boolean)
	local ok, core = pcall(function()
		return Enum.CoreGuiType[guiType]
	end)
	if ok and core then
		StarterGui:SetCoreGuiEnabled(core, enabled)
	end
end

ModMenu.Features.Misc.hideAllGuis = function(enabled: boolean)
	-- Hides non-essential PlayerGui children (best-effort, reversible).
	local pg = S.Players.LocalPlayer:FindFirstChild("PlayerGui")
	if not pg then return end
	for _, child in pg:GetChildren() do
		if child ~= ModMenu.Menu.ScreenGui and child:IsA("ScreenGui") then
			child.Enabled = not enabled
		end
	end
end

-- ===== src\features\dex.lua =====
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
	for _, gui in findDexGuis() do
		pcall(function() gui:Destroy() end)
	end
	dexLoaded = false
end

ModMenu.Features.Dex.open = function()
	if dexLoaded and ModMenu.Features.Dex.isOpen() then
		return -- already running; avoid stacking a second copy
	end
	ModMenu.Features.Dex.close()
	task.spawn(function()
		local ok, err = pcall(function()
			local source = game:HttpGet(DEX_URL, true)
			local chunk = loadstring(source)
			if not chunk then
				error("failed to compile dex.lua")
			end
			chunk()
		end)
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

-- ===== src\features\reviz.lua =====
--!strict
-- features/reviz.luau
-- Toggleable SakuraVibes999's Reviz Admin: fetches the script from the repo on enable and runs
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
	ModMenu.Notify("SakuraVibes999's Reviz Admin", "Closed.")
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
				ModMenu.Notify("SakuraVibes999's Reviz Admin", "Loaded. Press ; for the command bar.")
			else
				warn("[ModMenu] reviz.lua ran but no RevizAdmin GUI was found")
				ModMenu.Notify("SakuraVibes999's Reviz Admin", "Ran, but no command bar appeared (see console).")
			end
		else
			revizLoaded = false
			warn("[ModMenu] Reviz load failed: " .. tostring(err))
			ModMenu.Notify("SakuraVibes999's Reviz Admin", "Failed to load: " .. tostring(err))
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

-- A re-executed menu may leave a previous SakuraVibes999's Reviz running; clean it up on load.
-- init.luau re-activates it afterwards if the saved toggle is on.
unloadExisting()

-- ===== src\features\shattervast.lua =====
--!strict
-- features/shattervast.luau
-- Toggleable Grac3Haz3Lion's ShatterVast Admin: fetches the improved script from the repo on
-- enable and runs it through loadstring, then calls the unload hook the script
-- exposes (getgenv().ShatterVastUnload) on disable. The script unloads any
-- previous run before loading, so activating it never stacks command bars.
local S = ModMenu.Services
local Players = S.Players

local SHATTERVAST_URL = "https://raw.githubusercontent.com/scr1ptyureishirayukimikotofujiwarasayo/robloxsakuramodmenu/main/shattervast.lua"
local SHATTERVAST_GUI_NAMES = { "CommandBar", "CMDS_GUI_V2", "ChatLogsv2", "Notification", "Intro", "InfoGUIv2" }

ModMenu.Features = ModMenu.Features or {}
ModMenu.Features.Shattervast = {}

local shattervastLoaded = false

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
	unloadExisting()
	task.spawn(function()
		local ok, err = pcall(function()
			local source = game:HttpGet(SHATTERVAST_URL, true)
			local chunk = loadstring(source)
			if not chunk then
				error("failed to compile shattervast.lua")
			end
			chunk()
		end)
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

-- ===== src\init.lua =====
--!strict
-- init.luau
local C = ModMenu.UI.Components
local Panels = ModMenu.Menu.Panels
local T = ModMenu.Theme

-- Ids starting with "settings." are preferences (auto-save, remember-toggles,
-- background), not feature toggles. Reset and restore must leave them alone.
local function isPreference(id: string): boolean
	return string.sub(id, 1, 9) == "settings."
end

-- Home
do
	local p = Panels.home
	C.section(p, "About")
	local info = Instance.new("TextLabel")
	info.Size = UDim2.new(1, -8, 0, 46)
	info.BackgroundTransparency = 1
	info.TextWrapped = true
	info.TextColor3 = T.text
	info.Font = T.font
	info.TextSize = 13
	info.Text = "Executor client mod menu. Features are local to your client unless the game exposes server remotes. Use responsibly."
	info.Parent = p
	T.textStroke(info, 0.65)
	C.section(p, "Quick Actions")
	C.button(p, "Copy Position", function() ModMenu.Features.Teleport.copyPosition() end)
	C.toggle(p, "visual.fullbright", "Fullbright", false, function(v) ModMenu.Features.Visual.fullbright(v) end)
end

-- Player
do
	local p = Panels.player
	C.section(p, "Movement Stats")
	C.slider(p, "player.walkspeed", "WalkSpeed", 0, 200, 16, function(v) ModMenu.Features.Movement.setWalkSpeed(v) end)
	C.slider(p, "player.jumppower", "JumpPower", 0, 200, 50, function(v) ModMenu.Features.Movement.setJumpPower(v) end)
	C.slider(p, "player.gravity", "Gravity", 0, 300, 196.2, function(v) ModMenu.Features.Movement.setGravity(v) end)
	C.section(p, "Waypoints")
	C.button(p, "Save Waypoint", function() ModMenu.Features.Movement.saveWaypoint() end)
	C.button(p, "Teleport to Last", function()
		local wps = ModMenu.Features.Movement.getWaypoints()
		if #wps > 0 then ModMenu.Features.Movement.teleportWaypoint(#wps) end
	end)
end

-- Movement
do
	local p = Panels.movement
	C.toggle(p, "movement.fly", "Fly", false, function(v) ModMenu.Features.Movement.fly(v) end)
	C.slider(p, "movement.flySpeed", "Fly Speed", 10, 250, 60, function(v) ModMenu.State.numbers["movement.flySpeed"] = v end)
	C.toggle(p, "movement.noclip", "Noclip", false, function(v) ModMenu.Features.Movement.noclip(v) end)
	C.toggle(p, "movement.float", "Float Platform", false, function(v) ModMenu.Features.Movement.float(v) end)
end

-- Visual
do
	local p = Panels.visual
	C.toggle(p, "visual.esp", "Player ESP (Highlight)", false, function(v) ModMenu.Features.Visual.esp(v) end)
	C.toggle(p, "visual.fullbright", "Fullbright", false, function(v) ModMenu.Features.Visual.fullbright(v) end)
	C.toggle(p, "visual.removeFog", "Remove Fog", false, function(v) ModMenu.Features.Visual.removeFog(v) end)
	C.slider(p, "visual.fov", "Field of View", 40, 120, 70, function(v) ModMenu.Features.Visual.setFOV(v) end)
	C.slider(p, "visual.clock", "Clock Time", 0, 24, 14, function(v) ModMenu.Features.Visual.setClockTime(v) end)
end

-- World
do
	local p = Panels.world
	C.toggle(p, "world.antiLag", "Anti-Lag / Low Graphics", false, function(v) ModMenu.Features.World.antiLag(v) end)
	C.button(p, "Rejoin", function() ModMenu.Features.Teleport.rejoin() end)
end

-- Teleport
do
	local p = Panels.teleport
	C.button(p, "Teleport to Spawn", function() ModMenu.Features.Teleport.toSpawn() end)
	C.button(p, "Copy Position", function() ModMenu.Features.Teleport.copyPosition() end)
	C.button(p, "Rejoin Server", function() ModMenu.Features.Teleport.rejoin() end)
end

-- Character
do
	local p = Panels.character
	C.section(p, "Body")
	C.slider(p, "character.hipHeight", "Hip Height", 0, 10, 2, function(v) ModMenu.Features.Movement.setHipHeight(v) end)
	C.toggle(p, "character.platformStand", "Platform Stand", false, function(v) ModMenu.Features.Character.platformStand(v) end)
	C.toggle(p, "character.invisible", "Invisible", false, function(v) ModMenu.Features.Character.invisible(v) end)
	C.toggle(p, "character.nolimbs", "No Limbs", false, function(v) ModMenu.Features.Character.setLimbs("all", v) end)
	C.toggle(p, "character.noarms", "No Arms", false, function(v) ModMenu.Features.Character.setLimbs("arms", v) end)
	C.toggle(p, "character.nolegs", "No Legs", false, function(v) ModMenu.Features.Character.setLimbs("legs", v) end)
	C.toggle(p, "character.blockHats", "Block Hats", false, function(v) ModMenu.Features.Character.blockHats(v) end)
	C.section(p, "Camera")
	local players = {}
	for _, plr in ModMenu.Services.Players:GetPlayers() do
		table.insert(players, plr.Name)
	end
	C.dropdown(p, "character.viewTarget", "View Player", players, players[1], function(v)
		ModMenu.Features.Character.view(v)
	end)
	C.button(p, "Unview", function() ModMenu.Features.Character.view(nil) end)
	C.button(p, "Reset Movement", function() ModMenu.Features.Movement.resetMovement() end)
end

-- Protection
do
	local p = Panels.protection
	C.section(p, "Anti-Fling")
	C.toggle(p, "protection.antiFling", "Anti-Fling", false, function(v) ModMenu.Features.Protection.antiFling(v) end)
	C.slider(p, "protection.flingThreshold", "Fling Velocity", 50, 5000, 400)
	C.section(p, "Anti-Teleport")
	C.toggle(p, "protection.antiTeleport", "Anti-Teleport", false, function(v) ModMenu.Features.Protection.antiTeleport(v) end)
	C.slider(p, "protection.tpMaxStuds", "Max Studs Per Frame", 5, 500, 50)
end

-- Utility
do
	local p = Panels.utility
	C.section(p, "Scripts & Explorer")
	C.toggle(p, "utility.dex", "Dex Explorer", false, function(v) ModMenu.Features.Dex.toggle(v) end)
	C.toggle(p, "utility.reviz", "SakuraVibes999's Reviz Admin", false, function(v) ModMenu.Features.Reviz.toggle(v) end)
	C.toggle(p, "utility.shattervast", "Grac3Haz3Lion's ShatterVast Admin", false, function(v) ModMenu.Features.Shattervast.toggle(v) end)
	C.section(p, "Movement Tools")
	C.toggle(p, "utility.clickTP", "Click Teleport", false, function(v) ModMenu.Features.Movement.clickTeleport(v) end)
	C.button(p, "Save Position", function() ModMenu.Features.Movement.savePosition() end)
	C.button(p, "Load Position", function() ModMenu.Features.Movement.loadPosition() end)
	C.section(p, "World Tools")
	C.slider(p, "utility.workspaceVisibility", "Workspace Visibility", 0, 1, 1, function(v) ModMenu.Features.Utility.workspaceVisibility(v) end)
	C.button(p, "Restore Workspace", function() ModMenu.Features.Utility.restoreWorkspaceVisibility() end)
	C.toggle(p, "utility.clickDelete", "Click Delete (Reversible)", false, function(v) ModMenu.Features.Utility.clickDelete(v) end)
	C.toggle(p, "utility.lockWorkspace", "Lock Workspace", false, function(v) ModMenu.Features.Utility.lockWorkspace(v) end)
	C.toggle(p, "utility.toolGrabber", "Tool Grabber", false, function(v) ModMenu.Features.Utility.toolGrabber(v) end)
	C.toggle(p, "utility.reach", "Tool Reach", false, function(v) ModMenu.Features.Utility.reach(v) end)
	C.section(p, "Interactions")
	C.toggle(p, "interaction.clickDetectors", "Auto Click Detectors", false, function(v) ModMenu.Features.Interaction.clickDetectorLoop(v) end)
	C.toggle(p, "interaction.touch", "Auto Touch Parts", false, function(v) ModMenu.Features.Interaction.touchInterestLoop(v) end)
	C.slider(p, "interaction.interval", "Fire Interval (s)", 0.05, 10, 1)
	C.section(p, "Diagnostics")
	C.button(p, "FE Check", function() ModMenu.Features.Utility.feCheck() end)
	local players = {}
	for _, plr in ModMenu.Services.Players:GetPlayers() do
		table.insert(players, plr.Name)
	end
	C.dropdown(p, "utility.playerInfoTarget", "Player Info Target", players, players[1], function(v)
		ModMenu.Features.Utility.playerInfo(v)
	end)
end

-- Settings
do
	local p = Panels.settings
	C.section(p, "Menu")
	local keys = {}
	for _, k in Enum.KeyCode:GetEnumItems() do
		table.insert(keys, k.Name)
	end
	C.dropdown(p, "settings.openKey", "Open Key", keys, ModMenu.State.settings.openKey.Name, function(v)
		local k = Enum.KeyCode[v]
		if k then
			ModMenu.State.settings.openKey = k
			pcall(ModMenu.Config.save)
			ModMenu.Notify("Settings", "Open key set to " .. v)
		end
	end)
	C.toggle(p, "misc.hideGuis", "Hide Other GUIs", false, function(v) ModMenu.Features.Misc.hideAllGuis(v) end)
	C.section(p, "Background")
	C.toggle(p, "settings.backgroundImage", "Background Image", true, function()
		ModMenu.Menu.applyBackground()
	end)
	C.slider(p, "settings.bgBrightness", "Background Brightness", 0, 255, 80, function()
		ModMenu.Menu.applyBackground()
	end)
	C.section(p, "Persistence")
	C.toggle(p, "settings.autoSave", "Auto-Save", ModMenu.State.settings.autoSave, function(v)
		ModMenu.State.settings.autoSave = v
		pcall(ModMenu.Config.save, true) -- the flag itself must persist
	end)
	C.toggle(p, "settings.rememberToggles", "Remember Toggles on Load", ModMenu.State.settings.rememberToggles, function(v)
		ModMenu.State.settings.rememberToggles = v
		pcall(ModMenu.Config.save, true)
	end)
	C.button(p, "Save Now", function()
		pcall(ModMenu.Config.save, true)
		ModMenu.Notify("Settings", "Saved")
	end)
	C.button(p, "Reset Toggles Now", function()
		for id, callbacks in ModMenu.UI.toggleApply do
			if not isPreference(id) and ModMenu.State.toggles[id] then
				ModMenu.State.toggles[id] = false
				for _, apply in callbacks do
					pcall(apply, false)
				end
			end
		end
		for id, syncers in ModMenu.UI.toggleSync do
			if not isPreference(id) then
				for _, sync in syncers do
					pcall(sync, false)
				end
			end
		end
		pcall(ModMenu.Config.save)
		ModMenu.Notify("Settings", "All feature toggles turned off")
	end)
	C.button(p, "Wipe Saved Config", function()
		pcall(ModMenu.Config.wipe)
		ModMenu.Notify("Settings", "Config wiped. Reload to reset the UI.")
	end)
end

-- Single explicit restore point. Widgets no longer run their feature while
-- being built, so re-apply the toggles loaded from config once, after the whole
-- UI exists -- and only when the user opted in. Preferences ("settings.") are
-- skipped: they are read live, never "enabled".
if ModMenu.State.settings.rememberToggles then
	for id, callbacks in ModMenu.UI.toggleApply do
		if not isPreference(id) and ModMenu.State.toggles[id] == true then
			for _, apply in callbacks do
				pcall(apply, true)
			end
		end
	end
end

ModMenu.Menu.applyZOrder()
ModMenu.Notify("Mod Menu", "Loaded. Press " .. ModMenu.State.settings.openKey.Name .. " to open.")
-- init complete
