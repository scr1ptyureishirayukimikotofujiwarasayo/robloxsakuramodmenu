--!strict
-- Mod Menu (client) - generated from local sources
-- Version: 0.4.2

-- ===== src\core\compat.luau =====
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

-- ===== src\core\services.luau =====
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

-- ===== src\core\notify.luau =====
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

-- ===== src\core\state.luau =====
--!strict
-- core/state.luau
ModMenu.State = {
	settings = {
		openKey = Enum.KeyCode.RightShift,
		accent = Color3.fromRGB(210, 50, 75),
		menuSize = UDim2.fromOffset(460, 340),
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

-- ===== src\core\config.luau =====
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
	save = function()
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
}

pcall(ModMenu.Config.load)

-- ===== src\ui\theme.luau =====
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

-- ===== src\ui\components.luau =====
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
	if apply then
		pcall(apply, state)
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

	local function setValue(v: number)
		value = math.clamp(v, min, max)
		ModMenu.State.numbers[id] = value
		local pct = (value - min) / (max - min)
		fill.Size = UDim2.new(pct, 0, 1, 0)
		fill.BackgroundColor3 = ModMenu.Theme.accent()
		lbl.Text = label .. ": " .. string.format("%.1f", value)
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

	setValue(value)
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
	if apply then
		pcall(apply, selected)
	end
	return row
end

ModMenu.UI = ModMenu.UI or {}
ModMenu.UI.toggleSync = ModMenu.UI.toggleSync or {}
ModMenu.UI.Components = {
	button = button,
	toggle = toggle,
	slider = slider,
	section = section,
	dropdown = dropdown,
}

-- ===== src\ui\menu.luau =====
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
	{ id = "console", name = "Console" },
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
	-- Reviz prefix key: if the standalone Reviz Admin command bar is open, its
	-- own listener focuses CMDBAR; otherwise open the Console tab and focus its box.
	local reviz = ModMenu.Features and ModMenu.Features.Reviz
	if reviz and reviz.getPrefix then
		if reviz.isOpen and reviz.isOpen() then
			return
		end
		local prefix = reviz.getPrefix()
		local key = nil
		if prefix == ";" or prefix == ":" then
			key = Enum.KeyCode.Semicolon
		elseif type(prefix) == "string" and #prefix == 1 then
			local ok, kc = pcall(function() return Enum.KeyCode[string.upper(prefix)] end)
			if ok then key = kc end
		end
		if key and input.KeyCode == key then
			if not ModMenu.Menu.Open then setOpen(true) end
			switchTab("console")
			local box = ModMenu.Menu.ConsoleInput
			if box then
				task.defer(function() pcall(function() box:CaptureFocus() end) end)
			end
		end
	end
end))

switchTab("home")
setOpen(false)
applyZOrder()
-- UI built

-- ===== src\features\movement.luau =====
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

-- ===== src\features\visual.luau =====
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

-- ===== src\features\character.luau =====
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

-- ===== src\features\utility.luau =====
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

-- ===== src\features\teleport.luau =====
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

-- ===== src\features\world.luau =====
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

-- ===== src\features\protection.luau =====
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

-- ===== src\features\interaction.luau =====
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

-- ===== src\features\misc.luau =====
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

-- ===== src\features\dex.luau =====
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

-- ===== src\features\reviz.luau =====
-- features/reviz.luau
-- SakuraVibes999's Reviz Admin remake, integrated into ModMenu as a toggleable
-- standalone GUI (command bar + CMDS window) and also usable from the Console tab.
ModMenu.Features = ModMenu.Features or {}
ModMenu.Features.Reviz = (function()
    local Reviz = {}

    -- The Console panel overrides log/onCommands so command feedback appears
    -- in the panel instead of only in the F9 console.
    Reviz.log = function() end
    Reviz.onCommands = nil
    Reviz.chatEnabled = true
    Reviz.commands = {}
    local showCommandList

    local prefix = ":"
    local DEFAULT_PREFIX = ":"

    -- Re-executing the bundle used to leave the previous copy's Chatted /
    -- Stepped / InputBegan handlers and its four background loops alive: the
    -- old module kept revizAlive = true, so commands ran several times and old
    -- hotkeys stayed bound. Tear the previous copy down before this one wires
    -- anything up. trackedConnections (below) makes this work even though
    -- core/state.luau replaces ModMenu.State on every run.
    do
        local previous = _G.__revizCleanup
        if type(previous) == "function" then
            pcall(previous)
        end
        pcall(function()
            _G.__revizCleanup = nil
        end)
        pcall(function()
            ModMenu.State.clearConnections("reviz")
        end)
    end

    -- Mouse.KeyDown hands over a lowercase key-name string, never the prefix
    -- character, so the old `Key == prefix` check could never fire. Map the
    -- prefix character to a KeyCode instead.
    local PREFIX_KEYCODES = {
        [";"] = Enum.KeyCode.Semicolon,
        [":"] = Enum.KeyCode.Semicolon,
        [","] = Enum.KeyCode.Comma,
        ["."] = Enum.KeyCode.Period,
        ["/"] = Enum.KeyCode.Slash,
        ["-"] = Enum.KeyCode.Minus,
        ["="] = Enum.KeyCode.Equals,
        ["'"] = Enum.KeyCode.Quote,
        ["`"] = Enum.KeyCode.Backquote,
        ["["] = Enum.KeyCode.LeftBracket,
        ["]"] = Enum.KeyCode.RightBracket,
    }
    local DIGIT_KEYCODES = {
        ["0"] = "Zero", ["1"] = "One", ["2"] = "Two", ["3"] = "Three", ["4"] = "Four",
        ["5"] = "Five", ["6"] = "Six", ["7"] = "Seven", ["8"] = "Eight", ["9"] = "Nine",
    }

    local function prefixKeyCode(): Enum.KeyCode?
        if type(prefix) ~= "string" or #prefix ~= 1 then return nil end
        local mapped = PREFIX_KEYCODES[prefix]
        if mapped then return mapped end
        local name = DIGIT_KEYCODES[prefix] or string.upper(prefix)
        local ok, keycode = pcall(function() return Enum.KeyCode[name] end)
        if ok then return keycode end
        return nil
    end
    local lplayer
    local plr
    local mouse

    local change, GetPlayer, plrchat, apply
    local Char, Local, added, adminversion, annoying, annplr, attplr, b, banpl, binds, box, bplrr, brplr, cbring, cbringall, cbringing, changingstate, chatlogs, clickdel, clickgoto, droppinghats, droppingtools, flwplr, flying, followed, gettingtools, handleSize, hdwplr, hwalk, loc, no, noclip, objtodel, pmspammed, remotes, removingmeshhats, removingmeshtool, saved, spamdelay, spamming, spammingpm, spamtext, speedfly, speedget, spin, spinplr, stareplr, staring, statechosen, stopsitting, touched, tpdback, traill, trlplr, vis
    local bringingmod = false
    local bringingobj = false
    local revizGuiOpen = false
    local flyKeyConnections = {}
    local statusLabel: TextLabel? = nil
    local hintLabel: TextLabel? = nil
    local executing = false
    local executingToken = nil
    local EXECUTE_TIMEOUT = 10
    local ScreenGui: ScreenGui? = nil
    local CMDBAR: TextBox? = nil
    local CMDS: ScreenGui? = nil
    local CMDSFRAME: Frame? = nil

local function tpBypass(seconds: number?)
    local prot = ModMenu.Features and ModMenu.Features.Protection
    if prot and prot.bypass then
        pcall(prot.bypass, seconds or 1)
    end
end

-- Every container a Reviz GUI may live in, best first. CoreGui is listed but
-- assigning to it throws on Studio / low identity, so callers must pcall.
local function guiParents(): { Instance }
    local parents = {}
    if type(gethui) == "function" then
        local ok, parent = pcall(gethui)
        if ok and typeof(parent) == "Instance" then
            table.insert(parents, parent)
        end
    end
    local okCore, coreGui = pcall(function() return game:GetService("CoreGui") end)
    if okCore and typeof(coreGui) == "Instance" then
        table.insert(parents, coreGui)
    end
    local lp = game:GetService("Players").LocalPlayer
    local pg = lp and lp:FindFirstChild("PlayerGui")
    if pg then table.insert(parents, pg) end
    return parents
end

-- Parents a ScreenGui to the first container that actually accepts it. Doing
-- this unguarded is why toggling Reviz on could silently do nothing: the
-- ScreenGui failed to parent to CoreGui and the error was swallowed by pcall.
local function parentGui(gui: ScreenGui): boolean
    for _, parent in ipairs(guiParents()) do
        local ok = pcall(function()
            gui.Parent = parent
        end)
        if ok and gui.Parent ~= nil then
            return true
        end
    end
    return false
end

local function destroyRevizGuis()
    local parents = guiParents()
    for _, parent in ipairs(parents) do
        for _, name in ipairs({ "RevizAdmin", "RevizAdminCMDS", "RevizAdminIntro" }) do
            local ok, g = pcall(function() return parent:FindFirstChild(name) end)
            if ok and g then
                pcall(function() g:Destroy() end)
            end
        end
    end
    ScreenGui = nil
    CMDBAR = nil
    CMDS = nil
    CMDSFRAME = nil
    statusLabel = nil
    hintLabel = nil
end

local function syncRevizToggle(state: boolean)
    ModMenu.State.toggles["utility.reviz"] = state
    local syncers = ModMenu.UI and ModMenu.UI.toggleSync and ModMenu.UI.toggleSync["utility.reviz"]
    if syncers then
        for _, sync in syncers do
            pcall(sync, state)
        end
    end
    if ModMenu.Config and ModMenu.Config.save then
        pcall(ModMenu.Config.save)
    end
end

-- Connections are tracked locally as well as in ModMenu.State, because
-- core/state.luau rebuilds ModMenu.State on every execution and a cleanup
-- running from the previous copy would otherwise look at the new (empty) list.
local trackedConnections = {}
local function on(signal, handler)
    local connection = signal:Connect(handler)
    table.insert(trackedConnections, connection)
    table.insert(ModMenu.State.getConnections("reviz"), connection)
    return connection
end

-- Keeps the long lived loops alive and stops them spamming the console after a death.
local revizLoopErrors = {}
local function guarded(handler)
    return function(...)
        local ok, err = pcall(handler, ...)
        if not ok then
            local key = tostring(err)
            if not revizLoopErrors[key] then
                revizLoopErrors[key] = true
                warn("[reviz] loop error (further repeats suppressed): " .. key)
            end
        end
    end
end

-- 'remotes' used to add another set of listeners every time it was run.
local revizRemoteConnections = {}
local function onRemotes(signal, handler)
    local connection = signal:Connect(handler)
    table.insert(revizRemoteConnections, connection)
    return connection
end

local function clearRemotes()
    for _, connection in ipairs(revizRemoteConnections) do
        pcall(function() connection:Disconnect() end)
    end
    revizRemoteConnections = {}
end

local function onGuarded(signal, handler)
    return on(signal, guarded(handler))
end

local StarterGuiService = game:GetService("StarterGui")
local TextChatService = game:GetService("TextChatService")
local WorkspaceService = game:GetService("Workspace")

local function safeSetCore(name, data)
    local ok, err = pcall(function()
        return StarterGuiService:SetCore(name, data)
    end)
    if not ok then
        warn("[reviz] SetCore " .. tostring(name) .. " failed: " .. tostring(err))
    end
    if name == "SendNotification" and type(data) == "table" then
        pcall(Reviz.log, "[" .. tostring(data.Title) .. "] " .. tostring(data.Text))
    end
end

-- Messages sent by the script itself must not be re-executed by the Chatted
-- listener (e.g. ;spam with a prefix, or ;chat).
local sentChat = {}

local function sendChat(text)
    sentChat[text] = os.clock() + 5
    local legacy = pcall(function()
        local chatEvents = game:GetService("ReplicatedStorage"):FindFirstChild("DefaultChatSystemChatEvents")
        local request = chatEvents and chatEvents:FindFirstChild("SayMessageRequest")
        if not request then error("legacy chat system not present") end
        request:FireServer(text, "All")
    end)
    if legacy then return true end
    local modern = pcall(function()
        local channels = TextChatService:FindFirstChild("TextChannels")
        local channel = channels and (channels:FindFirstChild("RBXGeneral") or channels:FindFirstChild("General"))
        if not channel then error("no TextChatService channel") end
        channel:SendAsync(text)
    end)
    if not modern then
        warn("[reviz] chat send failed: " .. tostring(text))
    end
    return modern
end

local function loadAnim(humanoid, animation)
    if not humanoid then return nil end
    local animator = humanoid:FindFirstChildOfClass("Animator")
    if not animator then
        animator = Instance.new("Animator")
        animator.Parent = humanoid
    end
    return animator:LoadAnimation(animation)
end

-- R6 name -> R15 fallbacks, so the R6-era commands do not throw in R15 games.
local LIMB_ALIASES = {
    ["Torso"] = { "Torso", "UpperTorso", "LowerTorso", "HumanoidRootPart" },
    ["Left Leg"] = { "Left Leg", "LeftUpperLeg", "LeftLowerLeg", "LeftFoot" },
    ["Right Leg"] = { "Right Leg", "RightUpperLeg", "RightLowerLeg", "RightFoot" },
    ["Left Arm"] = { "Left Arm", "LeftUpperArm", "LeftLowerArm", "LeftHand" },
    ["Right Arm"] = { "Right Arm", "RightUpperArm", "RightLowerArm", "RightHand" },
}

local function limb(character, name)
    if not character then return nil end
    local candidates = LIMB_ALIASES[name] or { name }
    for _, candidate in ipairs(candidates) do
        local part = character:FindFirstChild(candidate)
        if part then return part end
    end
    return character:FindFirstChild("HumanoidRootPart") or character:FindFirstChild("Head")
end

local function anchorCharacter(character, anchored)
    if not character then return end
    for _, name in ipairs({ "Left Leg", "Left Arm", "Right Leg", "Right Arm", "Torso" }) do
        local part = limb(character, name)
        if part then part.Anchored = anchored end
    end
    local head = character:FindFirstChild("Head")
    if head then head.Anchored = anchored end
end

local function removeMesh(handle)
    if not handle then return end
    local mesh = handle:FindFirstChild("Mesh") or handle:FindFirstChildOfClass("SpecialMesh")
    if mesh then mesh:Destroy() end
end

local function loadAsset(assetId, label)
    local ok, err = pcall(function()
        local objects = game:GetObjects(assetId)
        local source = objects and objects[1] and objects[1].Source
        if not source then error("asset source unavailable") end
        local chunk = loadstring(source)
        if not chunk then error("asset did not compile") end
        chunk()
    end)
    if not ok then
        warn("[reviz] " .. tostring(label or assetId) .. " unavailable: " .. tostring(err))
    end
    return ok
end

local function loadDex()
    if loadAsset("rbxassetid://492005721", "Dex asset") then return true end
    if type(readfile) == "function" then
        for _, path in ipairs({ "Dex Explorer (Embedded).lua", "Dex Explorer.lua", "dex.lua" }) do
            local ok, data = pcall(readfile, path)
            if ok and type(data) == "string" then
                local chunk = loadstring(data)
                if chunk and pcall(chunk) then return true end
            end
        end
    end
    safeSetCore("SendNotification", {
        Title = "Dex unavailable",
        Text = "The old asset is gone. Put Dex Explorer (Embedded).lua in your executor workspace.",
    })
    return false
end

local function pgsEnabled()
    local ok, result = pcall(function() return WorkspaceService:PGSIsEnabled() end)
    if ok and result ~= nil then return result end
    local ok2, result2 = pcall(function() return WorkspaceService.PGSPhysicsSolverEnabled end)
    if ok2 then return result2 end
    return true
end

-- Roblox properties are typed: assigning a string to WalkSpeed/JumpPower/
-- HipHeight used to throw "number expected, got string" on every use.
local function toNumber(text, fallback: number): number
    local value = tonumber(text)
    if value == nil then
        return fallback
    end
    return value
end

local function destroyNamed(parent: Instance?, name: string)
    if not parent then return end
    local child = parent:FindFirstChild(name)
    if child then child:Destroy() end
end

local function setStatus(text: string)
    if statusLabel and statusLabel.Parent then
        statusLabel.Text = text
    end
end

    -- Original command list, shown by the Console panel's List Commands button.
    local Commands = {
        '[-] cmdbar is shown when ; is pressed.',
        '[1] kill [plr] -- You need a tool! Will kill the player, use rkill to kill you and player',
        '[2] bring [plr] -- You need a tool! Will bring player to you',
        '[3] spin [plr] -- You need a tool! Makes you and the player spin crazy',
        '[4] unspin -- Use after using spin cmd and dying, so you stop loop teleporting',
        '[5] attach [plr] -- You need a tool! Attaches you to player',
        '[6] unattach [plr] -- Attempts to unattach you from a player',
        '[7] follow [plr] -- Makes you follow behind the player',
        '[8] unfollow',
        '[9] freefall [plr] -- You need a tool! Teleports you and the player up into the air',
        '[10] trail [plr] -- The opposite of follow, you stay infront of player',
        '[11] untrail',
        '[12] orbit [plr] -- Makes you orbit the player',
        '[13] unorbit',
        '[14] fling [plr] -- Makes you fling the player',
        '[15] unfling',
        '[16] fecheck -- Checks if the game is FE or not',
        '[17] void [plr] -- Teleports player to the void',
        '[18] noclip -- Gives you noclip to walk through walls',
        '[19] clip -- Removes noclip',
        '[20] speed [num]/ws [num] -- Changes how fast you walk 16 is default',
        '[21] jumppower [num]/jp [num] -- Changes how high you jump 50 is default',
        '[22] hipheight [num]/hh [num] -- Changes how high you float 0 is default',
        '[23] default -- Changes your speed, jumppower and hipheight to default values',
        '[24] annoy [plr] -- Loop teleports you to the player',
        '[25] unannoy',
        '[26] headwalk [plr] -- Loop teleports you to the player head',
        '[27] unheadwalk',
        '[28] nolimbs -- Removes your arms and legs',
        '[29] god -- Gives you FE Godmode',
        '[30] drophats -- Drops your accessories',
        '[31] droptool -- Drops any tool you have equipped',
        '[32] loopdhats -- Loop drops your accessories',
        '[33] unloopdhats',
        '[34] loopdtool -- Loop drops any tools you have equipped',
        '[35] unloopdtool',
        '[36] invisible -- Gives you invisibility CREDIT TO TIMELESS',
        '[37] view [plr] -- Changes your camera to the player character',
        '[38] unview',
        '[39] goto [plr] -- Teleports you to player',
        '[40] fly -- Allows you to fly, credit to Infinite Yield',
        '[41] unfly',
        '[42] chat [msg] -- Makes you chat a message',
        '[43] spam [msg] -- Spams a message',
        '[44] unspam',
        '[45] spamwait [num] -- Changes delay of chatting a message for the spam command in seconds default is 1 second',
        '[46] pmspam [plr] -- Spams a player in private message',
        '[47] unpmspam',
        '[48] cfreeze [plr] -- Freezes a player on your client, they will only be frozen for you',
        '[49] uncfreeze [plr]',
        '[50] unlockws -- Unlocks the workspace',
        '[51] lockws -- Locks the workspace',
        '[52] btools -- Gives you btools that will only show to you useful for deleting certain blocks only for you',
        '[53] pstand -- Enables platform stand',
        '[54] unpstand -- Disables platform stand',
        '[55] blockhead -- Removes your head mesh',
        '[56] sit',
        '[57] bringobj [obj] -- Only shows on client, brings an object/part to you constantly, can be used to bring healing parts, weapons, money etc, type in exact name',
        '[58] wsvis [num] -- Changes visibility of workspace parts, num should be between 0 and 1, only shows client sided',
        '[59] hypertotal -- Loads in my FE GUI Hypertotal',
        '[60] cmds -- Prints all commands',
        '[61] rmeshhats/blockhats -- Removes the meshes of all your accessories aka block hats',
        '[62] rmeshtool/blocktool -- Removes the mesh of the tool you have equipped aka block tool',
        '[63] spinner -- Makes you spin',
        '[64] nospinner',
        '[65] reach [num] -- Gives you reach, mostly used for swords, say ;reachd for default and enter number after for custom',
        '[66] noreach -- Removes reach, must have tool equipped',
        '[67] rkill [plr] -- Kills you and the player, use kill to just kill the player without dying',
        '[68] tp me [plr] -- Alternative to goto',
        '[69] cbring [plr] -- Brings player infront of you, shows only on client, allows you to do damage to player',
        '[70] uncbring',
        '[71] swap [plr] -- You need a tool! Swaps players position with yours and your position with players',
        '[72] givetool [plr] -- Gives the tool you have equipped to the player',
        '[73] glitch [plr] -- Glitches you and the player, looks very cool',
        '[74] unglitch -- Unglitches you',
        '[75] grespawn -- Alternative to normal respawn and usually works best for when you want to reset with FE Godmode',
        '[76] explorer -- Loads up DEX',
        '[77] reset -- Resets your character.',
        '[78] anim [id] -- Applies an animation on you, must be created by ROBLOX',
        '[79] animgui -- Loads up Energize animations GUI',
        '[80] savepos -- Saves your current position',
        '[81] loadpos -- Teleports you to your saved position',
        '[82] bang [plr] -- 18+ will not work if you have FE Godmode on',
        '[83] unbang',
        '[84] delcmdbar -- Removes the command bar completely',
        '[85] bringmod [obj] -- Brings all the parts in a model, client only, comes from ;bringobj enter exact name of model',
        '[86] shutdown -- Uses harkinians script to shutdown server',
        '[87] respawn -- If grespawn doesnt work you can use respawn',
        '[88] delobj [obj] -- Deletes a certain brick in workspace, client sided',
        '[89] getplrs -- Prints all players in game',
        '[90] deldecal -- Deletes all decals client sided',
        '[91] opfinality -- Loads in my FE GUI Opfinality',
        '[92] remotes -- Prints all remotes in the game in the console when added',
        '[93] noremotes -- Stops printing remotes',
        '[94] tpdefault -- Stops all loop teleports to a player',
        '[95] stopsit -- Will not allow you to sit',
        '[96] gosit -- Allows you to sit',
        '[97] clicktp -- Enables click tp',
        '[98] noclicktp -- Disables click tp',
        '[99] toolson -- If any tools are dropped in the workspace you will automatically get them',
        '[100] toolsoff -- Stops ;toolson',
        '[101] version -- Gets the admin version',
        '[102] state [num] -- Changes your humanoid state, ;unstate to stop.',
        '[103] gravity [num] -- Changes workspace gravity default is 196.2',
        '[104] pgs -- Checks if the game has PGSPhysicsSolverEnabled enabled',
        '[105] clickdel -- Delete any block you press q on, client sided',
        '[106] noclickdel -- Stops clickdel',
        '[107] looprhats -- Loop removes mesh of your hats/loop block hats',
        '[108] unlooprhats -- Stops loop removing mesh',
        '[109] looprtool -- Loop removes mesh of your tool/loop block tools',
        '[110] unlooprtool -- Stops loop removing mesh',
        '[111] givealltools [plr] -- Gives all the tools you have in your backpack to the player',
        '[112] age [plr] -- Makes you chat the account age of the player',
        '[113] id [plr] -- Makes you chat the account ID of the player',
        '[114] .age [plr] -- Privately shows you the account age of the player',
        '[115] .id [plr] -- Privately shows you the account ID of the player',
        '[116] gameid -- Shows the game ID',
        '[117] removeinvis -- Removes all invisible walls/parts, client sided',
        '[118] removefog -- Removes fog, client sided',
        '[119] disable -- Disables your character by removing humanoid',
        '[120] enable -- Enables your character by adding humanoid',
        '[121] prefix [key] -- Changes the prefix used, default is :',
        '[122] resetprefix -- Resets the prefix to : if you change it to an unusable one. Works no matter what the prefix is set to.',
        '[123] flyspeed [num] -- Change your fly speed, default is 1',
        '[124] carpet [plr] -- Makes you a carpet for a player, will not work if FE Godmode is on',
        '[125] uncarpet -- Stops carpet player',
        '[126] stare [plr] -- Turns your character to stare at another player',
        '[127] unstare -- Stops stare player',
        '[128] logchat -- Logs all chat (including /e and whispers) of all players',
        '[129] unlogchat -- Disables logchat',
        '[130] fixcam -- Fixes/resets your camera',
        '[131] unstate -- Stops changing state',
        '[132] unbringobj -- Stops ;bringobj',
        '[133] unbringmod -- Stops ;bringmod',
    }

    -- Names parsed out of the command list above. Used only to tell the user
    -- that a command was not recognised - previously every typo reported "ok"
    -- and did nothing. Dispatch itself is unchanged.
    local knownCommands
    do
        local set = {}
        for _, entry in ipairs(Commands) do
            local body = string.match(entry, "^%[%d+%]%s*(.-)%s*%-%-")
                or string.match(entry, "^%[%d+%]%s*(.+)$")
            if body then
                body = string.gsub(body, "%[.-%]", "")
                for variant in string.gmatch(body, "[^/]+") do
                    variant = string.gsub(variant, "^%s+", "")
                    variant = string.gsub(variant, "%s+$", "")
                    variant = string.gsub(variant, "%s+", " ")
                    if variant ~= "" then
                        set[variant] = true
                    end
                end
            end
        end
        -- Implemented but missing from the list.
        set["reachd"] = true
        knownCommands = set
    end

    local function isKnownCommand(full: string): boolean
        local count = 0
        for _ in pairs(knownCommands) do count += 1 end
        if count < 50 then
            -- Parsing failed; never block a command because of it.
            return true
        end
        local bare = string.sub(full, #prefix + 1)
        for name in pairs(knownCommands) do
            if bare == name or string.sub(bare, 1, #name + 1) == name .. " " then
                return true
            end
        end
        return false
    end

speedget = 1
 
lplayer = game:GetService("Players").LocalPlayer
 
on(lplayer.CharacterAdded, function(character)
    -- Every transient loop must stop on respawn, otherwise the Stepped handlers
    -- keep dereferencing a character that no longer exists.
    spin = false
    flying = false
    staring = false
    banpl = false
    followed = false
    traill = false
    annoying = false
    hwalk = false
    droppinghats = false
    droppingtools = false
    removingmeshhats = false
    removingmeshtool = false
    stopsitting = false
    changingstate = false
    bringingobj = false
    bringingmod = false
end)
 
-- Kept for compatibility with the original script; it used to be a no-op
-- self-assignment (prefix = prefix).
function change()
    if hintLabel and hintLabel.Parent then
        hintLabel.Text = prefix .. " focuses  |  delcmdbar closes"
    end
end
 
function GetPlayer(String) -- Credit to Timeless/xFunnieuss
    local Found = {}
    local strl = String:lower()
    if strl == "all" then
        for i,v in pairs(game:GetService("Players"):GetPlayers()) do
            table.insert(Found,v)
        end
    elseif strl == "others" then
        for i,v in pairs(game:GetService("Players"):GetPlayers()) do
            if v.Name ~= lplayer.Name then
                table.insert(Found,v)
            end
        end  
    elseif strl == "me" then
        for i,v in pairs(game:GetService("Players"):GetPlayers()) do
            if v.Name == lplayer.Name then
                table.insert(Found,v)
            end
        end  
    else
        for i,v in pairs(game:GetService("Players"):GetPlayers()) do
            if v.Name:lower():sub(1, #String) == String:lower() then
                table.insert(Found,v)
            end
        end    
    end
    return Found    
end
 
spin = false
followed = false
traill = false
noclip = false
annoying = false
hwalk = false
droppinghats = false
droppingtools = false
flying = false
spamdelay = 1
spamming = false
spammingpm = false
cbringing = false
remotes = true
added = true
binds = false
stopsitting = false
clickgoto = false
gettingtools = false
removingmeshhats = false
removingmeshtool = false
clickdel = false
staring = false
chatlogs = false
banpl = false
changingstate = false
statechosen = 0
 
adminversion = "SakuraVibes999's Reviz Admin by sakuravibes999, Version 2.0"
 
flying = false
speedfly = 1
 
function plrchat(plr, chat)
print(plr.Name..": "..tick().."\n"..chat)
end
 
for i,v in pairs(game:GetService("Players"):GetPlayers()) do
on(v.Chatted, function(chat)
if chatlogs then
plrchat(v, chat)
end
end)
end
on(game:GetService("Players").PlayerAdded, function(plr)
on(plr.Chatted, function(chat)
if chatlogs then
plrchat(plr, chat)
end
end)
end)
 
 

onGuarded(game:GetService('RunService').Stepped, function()
    if spin then
        lplayer.Character.HumanoidRootPart.CFrame = game:GetService("Players")[spinplr.Name].Character.HumanoidRootPart.CFrame
    end
    if followed then
        lplayer.Character.HumanoidRootPart.CFrame = game:GetService("Players")[flwplr.Name].Character.HumanoidRootPart.CFrame + game:GetService("Players")[flwplr.Name].Character.HumanoidRootPart.CFrame.lookVector * -5
    end
    if traill then
        lplayer.Character.HumanoidRootPart.CFrame = game:GetService("Players")[trlplr.Name].Character.HumanoidRootPart.CFrame + game:GetService("Players")[trlplr.Name].Character.HumanoidRootPart.CFrame.lookVector * 5
    end
    if annoying then
        lplayer.Character.HumanoidRootPart.CFrame = game:GetService("Players")[annplr.Name].Character.HumanoidRootPart.CFrame
    end
    if hwalk then
        lplayer.Character.HumanoidRootPart.CFrame = game:GetService("Players")[hdwplr.Name].Character.HumanoidRootPart.CFrame + Vector3.new(0, 4, 0)
    end
    if staring then
        lplayer.Character.HumanoidRootPart.CFrame = CFrame.new(limb(lplayer.Character, "Torso").Position, game:GetService("Players")[stareplr.Name].Character.Torso.Position)
    end
end)
onGuarded(game:GetService('RunService').Stepped, function()
    if noclip then
        if lplayer.Character.Humanoid.RigType == Enum.HumanoidRigType.R6 then
            lplayer.Character.Head.CanCollide = false
            limb(lplayer.Character, "Torso").CanCollide = false
            limb(lplayer.Character, "Left Leg").CanCollide = false
            limb(lplayer.Character, "Right Leg").CanCollide = false
        else
            lplayer.Character.Humanoid:ChangeState(11)
        end
    end
    if changingstate then
        local humanoid = lplayer.Character and lplayer.Character:FindFirstChildOfClass("Humanoid")
        if humanoid then
            local ok = pcall(function() humanoid:ChangeState(statechosen) end)
            if not ok then changingstate = false end
        end
    end
end)
onGuarded(game:GetService('RunService').Stepped, function()
    if droppinghats then
        for i,v in pairs(lplayer.Character:GetChildren()) do
            if (v:IsA("Accessory")) or (v:IsA("Hat")) then
                v.Parent = workspace
            end
        end
    end
    if droppingtools then
        for i,v in pairs(lplayer.Character:GetChildren()) do
            if (v:IsA("Tool")) then
                v.Parent = workspace
            end
        end
    end
    if removingmeshhats then
        for i,v in pairs(lplayer.Character:GetChildren()) do
            if (v:IsA("Accessory")) or (v:IsA("Hat")) then
                removeMesh(v.Handle)
            end
        end
    end
    if removingmeshtool then
        for i,v in pairs(lplayer.Character:GetChildren()) do
            if (v:IsA("Tool")) then
                removeMesh(v.Handle)
            end
        end
    end
end)
onGuarded(game:GetService('RunService').Stepped, function()
    if banpl then
        lplayer.Character.HumanoidRootPart.CFrame = game:GetService("Players")[bplrr].Character.HumanoidRootPart.CFrame
    end
end)
onGuarded(game:GetService('RunService').Stepped, function()
    if stopsitting then
        lplayer.Character.Humanoid.Sit = false
    end
end)
 
plr = lplayer
mouse = plr:GetMouse()
on(mouse.KeyDown, function(key)
    if key == "e" then
        local character = lplayer.Character
        local root = character and character:FindFirstChild("HumanoidRootPart")
        if mouse.Target and root then
            if clickgoto then
                tpBypass(0.5)
                root.CFrame = CFrame.new(mouse.Hit.x, mouse.Hit.y + 5, mouse.Hit.z)
            elseif clickdel then
                mouse.Target:Destroy()
            end
        end
    end
end)
 
on(game:GetService("Workspace").ChildAdded, function(part)
    if gettingtools then
        if part:IsA("Tool") then
            part.Handle.CFrame = lplayer.Character.HumanoidRootPart.CFrame
        end
    end
end)
 

local function Execute(msg)
    if string.sub(msg, 1, 6) == (prefix.."kill ") then
        if string.sub(msg, 7) == "me" then
            lplayer.Character.HumanoidRootPart.CFrame = CFrame.new(100000,0,100000)
        else
            for i,v in pairs(GetPlayer(string.sub(msg, 7)))do
                local NOW = lplayer.Character.HumanoidRootPart.CFrame
                lplayer.Character.Humanoid.Name = "1"
                local l = lplayer.Character["1"]:Clone()
                l.Parent = lplayer.Character
                l.Name = "Humanoid"
                task.wait(0.1)
                lplayer.Character["1"]:Destroy()
                game:GetService("Workspace").CurrentCamera.CameraSubject = lplayer.Character
                lplayer.Character.Animate.Disabled = true
                task.wait(0.1)
                lplayer.Character.Animate.Disabled = false
                lplayer.Character.Humanoid.DisplayDistanceType = "None"
                for i,v in pairs(game:GetService'Players'.LocalPlayer.Backpack:GetChildren())do
                lplayer.Character.Humanoid:EquipTool(v)
                end
                local function tp(player,player2)
                local char1,char2=player.Character,player2.Character
                if char1 and char2 then
                char1:MoveTo(char2.Head.Position)
                end
                end
                task.wait(0.1)
                lplayer.Character.HumanoidRootPart.CFrame = game:GetService("Players")[v.Name].Character.HumanoidRootPart.CFrame
                task.wait(0.2)
                lplayer.Character.HumanoidRootPart.CFrame = game:GetService("Players")[v.Name].Character.HumanoidRootPart.CFrame
                task.wait(0.5)
                lplayer.Character.HumanoidRootPart.CFrame = CFrame.new(Vector3.new(-100000,10,-100000))
                task.wait(0.7)
                tp(lplayer,game:GetService("Players")[v.Name])
                task.wait(0.7)
                lplayer.Character.HumanoidRootPart.CFrame = NOW
                safeSetCore("SendNotification", {
                Title = "Tools needed!";
                Text = "You need a tool in your backpack for this command!";
                })
            end
        end
    end
    if string.sub(msg, 1, 7) == (prefix.."bring ") then
        for i,v in pairs(GetPlayer(string.sub(msg, 8)))do
            local NOW = lplayer.Character.HumanoidRootPart.CFrame
            lplayer.Character.Humanoid.Name = "1"
            local l = lplayer.Character["1"]:Clone()
            l.Parent = lplayer.Character
            l.Name = "Humanoid"
            task.wait(0.1)
            lplayer.Character["1"]:Destroy()
            game:GetService("Workspace").CurrentCamera.CameraSubject = lplayer.Character
            lplayer.Character.Animate.Disabled = true
            task.wait(0.1)
            lplayer.Character.Animate.Disabled = false
            lplayer.Character.Humanoid.DisplayDistanceType = "None"
            for i,v in pairs(game:GetService'Players'.LocalPlayer.Backpack:GetChildren())do
            lplayer.Character.Humanoid:EquipTool(v)
            end
            local function tp(player,player2)
            local char1,char2=player.Character,player2.Character
            if char1 and char2 then
            char1.HumanoidRootPart.CFrame = char2.HumanoidRootPart.CFrame
            end
            end
            local function getout(player,player2)
            local char1,char2=player.Character,player2.Character
            if char1 and char2 then
            char1:MoveTo(char2.Head.Position)
            end
            end
            tp(game:GetService("Players")[v.Name], lplayer)
            task.wait(0.2)
            tp(game:GetService("Players")[v.Name], lplayer)
            task.wait(0.5)
            lplayer.Character.HumanoidRootPart.CFrame = NOW
            task.wait(0.5)
            getout(lplayer, game:GetService("Players")[v.Name])
            task.wait(0.3)
            lplayer.Character.HumanoidRootPart.CFrame = NOW
            safeSetCore("SendNotification", {
            Title = "Tools needed!";
            Text = "You need a tool in your backpack for this command!";
            })
        end
    end
    if string.sub(msg, 1, 6) == (prefix.."spin ") then
        for i,v in pairs(GetPlayer(string.sub(msg, 7))) do
            lplayer.Character.Humanoid.Name = "1"
            local l = lplayer.Character["1"]:Clone()
            l.Parent = lplayer.Character
            l.Name = "Humanoid"
            task.wait(0.1)
            lplayer.Character["1"]:Destroy()
            game:GetService("Workspace").CurrentCamera.CameraSubject = lplayer.Character
            lplayer.Character.Animate.Disabled = true
            task.wait(0.1)
            lplayer.Character.Animate.Disabled = false
            lplayer.Character.Humanoid.DisplayDistanceType = "None"
            lplayer.Character.Animate.Disabled = false
            for i,v in pairs(game:GetService'Players'.LocalPlayer.Backpack:GetChildren())do
            lplayer.Character.Humanoid:EquipTool(v)
            end
            lplayer.Character.HumanoidRootPart.CFrame = limb(game:GetService("Players")[v.Name].Character, "Left Arm").CFrame
            spinplr = v
            task.wait(0.5)
            spin = true
            safeSetCore("SendNotification", {
            Title = "Tools needed!";
            Text = "You need a tool in your backpack for this command!";
            })
        end
    end
    if string.sub(msg, 1, 7) == (prefix.."unspin") then
        spin = false
    end
    if string.sub(msg, 1, 8) == (prefix.."attach ") then
        for i,v in pairs(GetPlayer(string.sub(msg, 9))) do
            lplayer.Character.Humanoid.Name = "1"
            local l = lplayer.Character["1"]:Clone()
            l.Parent = lplayer.Character
            l.Name = "Humanoid"
            task.wait(0.1)
            lplayer.Character["1"]:Destroy()
            game:GetService("Workspace").CurrentCamera.CameraSubject = lplayer.Character
            lplayer.Character.Animate.Disabled = true
            task.wait(0.1)
            lplayer.Character.Animate.Disabled = false
            lplayer.Character.Humanoid.DisplayDistanceType = "None"
            for i,v in pairs(game:GetService'Players'.LocalPlayer.Backpack:GetChildren())do
            lplayer.Character.Humanoid:EquipTool(v)
            end
            lplayer.Character.HumanoidRootPart.CFrame = limb(game:GetService("Players")[v.Name].Character, "Left Arm").CFrame
            task.wait(0.3)
            lplayer.Character.HumanoidRootPart.CFrame = limb(game:GetService("Players")[v.Name].Character, "Left Arm").CFrame
            attplr = v
            safeSetCore("SendNotification", {
            Title = "Tools needed!";
            Text = "You need a tool in your backpack for this command!";
            })
        end
    end
    if string.sub(msg, 1, 10) == (prefix.."unattach ") then
        for i,v in pairs(GetPlayer(string.sub(msg, 11))) do
            local function getout(player,player2)
            local char1,char2=player.Character,player2.Character
            if char1 and char2 then
            char1:MoveTo(char2.Head.Position)
            end
            end
            getout(lplayer, game:GetService("Players")[v.Name])
        end
    end
    if string.sub(msg, 1, 8) == (prefix.."follow ") then
        for i,v in pairs(GetPlayer(string.sub(msg, 9))) do
            followed = true
            flwplr = v
        end
    end
    if string.sub(msg, 1, 9) == (prefix.."unfollow") then
        followed = false
    end
    if string.sub(msg, 1, 10) == (prefix.."freefall ") then
        for i,v in pairs(GetPlayer(string.sub(msg, 11))) do
            local NOW = lplayer.Character.HumanoidRootPart.CFrame
            lplayer.Character.Humanoid.Name = "1"
            local l = lplayer.Character["1"]:Clone()
            l.Parent = lplayer.Character
            l.Name = "Humanoid"
            task.wait(0.1)
            lplayer.Character["1"]:Destroy()
            game:GetService("Workspace").CurrentCamera.CameraSubject = lplayer.Character
            lplayer.Character.Animate.Disabled = true
            task.wait(0.1)
            lplayer.Character.Animate.Disabled = false
            lplayer.Character.Humanoid.DisplayDistanceType = "None"
            for i,v in pairs(game:GetService'Players'.LocalPlayer.Backpack:GetChildren())do
            lplayer.Character.Humanoid:EquipTool(v)
            end
            lplayer.Character.HumanoidRootPart.CFrame = game:GetService("Players")[v.Name].Character.HumanoidRootPart.CFrame
            task.wait(0.2)
            lplayer.Character.HumanoidRootPart.CFrame = game:GetService("Players")[v.Name].Character.HumanoidRootPart.CFrame
            task.wait(0.6)
            lplayer.Character.HumanoidRootPart.CFrame = NOW
            task.wait(0.6)
            lplayer.Character.HumanoidRootPart.CFrame = CFrame.new(0,50000,0)
            safeSetCore("SendNotification", {
            Title = "Tools needed!";
            Text = "You need a tool in your backpack for this command!";
            })
        end
    end
    if string.sub(msg, 1, 7) == (prefix.."trail ") then
        for i,v in pairs(GetPlayer(string.sub(msg, 8))) do
            traill = true
            trlplr = v
        end
    end
    if string.sub(msg, 1, 8) == (prefix.."untrail") then
        traill = false
    end
    if string.sub(msg, 1, 7) == (prefix.."orbit ") then
        if string.sub(msg, 8) == "all" or string.sub(msg, 8) == "others" or string.sub(msg, 8) == "me" then
            lplayer.Character.HumanoidRootPart.CFrame = lplayer.Character.HumanoidRootPart.CFrame
        else
            for i,v in pairs(GetPlayer(string.sub(msg, 8))) do
                local o = Instance.new("RocketPropulsion")
                o.Parent = lplayer.Character.HumanoidRootPart
                o.Name = "Orbit"
                o.Target = game:GetService("Players")[v.Name].Character.HumanoidRootPart
                o:Fire()
                noclip = true
            end
        end
    end
    if string.sub(msg, 1, 8) == (prefix.."unorbit") then
        local root = lplayer.Character and lplayer.Character:FindFirstChild("HumanoidRootPart")
        destroyNamed(root, "Orbit")
        noclip = false
    end
    if string.sub(msg, 1, 7) == (prefix.."fling ") then
        if string.sub(msg, 8) == "all" or string.sub(msg, 8) == "others" or string.sub(msg, 8) == "me" then
            lplayer.Character.HumanoidRootPart.CFrame = lplayer.Character.HumanoidRootPart.CFrame
        else
            for i,v in pairs(GetPlayer(string.sub(msg, 8))) do
                local y = Instance.new("RocketPropulsion")
                y.Parent = lplayer.Character.HumanoidRootPart
                y.CartoonFactor = 1
                y.MaxThrust = 800000
                y.MaxSpeed = 1000
                y.ThrustP = 200000
                y.Name = "Fling"
                game:GetService("Workspace").CurrentCamera.CameraSubject = game:GetService("Players")[v.Name].Character.Head
                y.Target = game:GetService("Players")[v.Name].Character.HumanoidRootPart
                y:Fire()
                noclip = true
            end
        end
    end
    if string.sub(msg, 1, 8) == (prefix.."unfling") then
        noclip = false
        local root = lplayer.Character and lplayer.Character:FindFirstChild("HumanoidRootPart")
        destroyNamed(root, "Fling")
        game:GetService("Workspace").CurrentCamera.CameraSubject = lplayer.Character.Head
        task.wait(0.4)
        destroyNamed(root, "Fling")
    end
    if string.sub(msg, 1, 8) == (prefix.."fecheck") then
        -- Every live Roblox game is FilteringEnabled; the old branch was dead code.
        warn("FE is Enabled (Filtering Enabled)")
        safeSetCore("SendNotification", {
            Title = "FE is Enabled";
            Text = "Filtering Enabled. Enjoy using SakuraVibes999's Reviz Admin!";
        })
    end
    if string.sub(msg, 1, 6) == (prefix.."void ") then
        for i,v in pairs(GetPlayer(string.sub(msg, 7))) do
            lplayer.Character.Humanoid.Name = "1"
            local l = lplayer.Character["1"]:Clone()
            l.Parent = lplayer.Character
            l.Name = "Humanoid"
            task.wait(0.1)
            lplayer.Character["1"]:Destroy()
            game:GetService("Workspace").CurrentCamera.CameraSubject = lplayer.Character
            lplayer.Character.Animate.Disabled = true
            task.wait(0.1)
            lplayer.Character.Animate.Disabled = false
            lplayer.Character.Humanoid.DisplayDistanceType = "None"
            for i,v in pairs(game:GetService'Players'.LocalPlayer.Backpack:GetChildren())do
            lplayer.Character.Humanoid:EquipTool(v)
            end
            lplayer.Character.HumanoidRootPart.CFrame = game:GetService("Players")[v.Name].Character.HumanoidRootPart.CFrame
            task.wait(0.2)
            lplayer.Character.HumanoidRootPart.CFrame = game:GetService("Players")[v.Name].Character.HumanoidRootPart.CFrame
            task.wait(0.6)
            lplayer.Character.HumanoidRootPart.CFrame = CFrame.new(999999999999999,0,999999999999999)
            safeSetCore("SendNotification", {
            Title = "Tools needed!";
            Text = "You need a tool in your backpack for this command!";
            })
        end
    end
    if string.sub(msg, 1, 7) == (prefix.."noclip") then
        noclip = true
        safeSetCore("SendNotification", {
        Title = "Noclip enabled";
        Text = "Type ;clip to disable";
        })
    end
    if string.sub(msg, 1, 5) == (prefix.."clip") then
        noclip = false
        safeSetCore("SendNotification", {
        Title = "Noclip disabled";
        Text = "Type ;noclip to enable";
        })
    end
    if string.sub(msg, 1, 7) == (prefix.."speed ") then
        local humanoid = lplayer.Character and lplayer.Character:FindFirstChildOfClass("Humanoid")
        if humanoid then
            humanoid.WalkSpeed = toNumber(string.sub(msg, 8), humanoid.WalkSpeed)
        end
    end
    if string.sub(msg, 1, 4) == (prefix.."ws ") then
        local humanoid = lplayer.Character and lplayer.Character:FindFirstChildOfClass("Humanoid")
        if humanoid then
            humanoid.WalkSpeed = toNumber(string.sub(msg, 5), humanoid.WalkSpeed)
        end
    end
    if string.sub(msg, 1, 11) == (prefix.."hipheight ") then
        local humanoid = lplayer.Character and lplayer.Character:FindFirstChildOfClass("Humanoid")
        if humanoid then
            humanoid.HipHeight = toNumber(string.sub(msg, 12), humanoid.HipHeight)
        end
    end
    if string.sub(msg, 1, 4) == (prefix.."hh ") then
        local humanoid = lplayer.Character and lplayer.Character:FindFirstChildOfClass("Humanoid")
        if humanoid then
            humanoid.HipHeight = toNumber(string.sub(msg, 5), humanoid.HipHeight)
        end
    end
    if string.sub(msg, 1, 11) == (prefix.."jumppower ") then
        local humanoid = lplayer.Character and lplayer.Character:FindFirstChildOfClass("Humanoid")
        if humanoid then
            humanoid.JumpPower = toNumber(string.sub(msg, 12), humanoid.JumpPower)
        end
    end
    if string.sub(msg, 1, 4) == (prefix.."jp ") then
        local humanoid = lplayer.Character and lplayer.Character:FindFirstChildOfClass("Humanoid")
        if humanoid then
            humanoid.JumpPower = toNumber(string.sub(msg, 5), humanoid.JumpPower)
        end
    end
    if string.sub(msg, 1, 8) == (prefix.."default") then
        lplayer.Character.Humanoid.JumpPower = 50
        lplayer.Character.Humanoid.WalkSpeed = 16
        lplayer.Character.Humanoid.HipHeight = 0
    end
    if string.sub(msg, 1, 7) == (prefix.."annoy ") then
        for i,v in pairs(GetPlayer(string.sub(msg, 8))) do
            annoying = true
            annplr = v
        end
    end
    if string.sub(msg, 1, 8) == (prefix.."unannoy") then
        annoying = false
    end
    if string.sub(msg, 1, 10) == (prefix.."headwalk ") then
        for i,v in pairs(GetPlayer(string.sub(msg, 11))) do
            hwalk = true
            hdwplr = v
        end
    end
    if string.sub(msg, 1, 11) == (prefix.."unheadwalk") then
        hwalk = false
    end
    if string.sub(msg, 1, 8) == (prefix.."nolimbs") then
        limb(lplayer.Character, "Left Leg"):Destroy()
        limb(lplayer.Character, "Left Arm"):Destroy()
        limb(lplayer.Character, "Right Leg"):Destroy()
        limb(lplayer.Character, "Right Arm"):Destroy()
    end
    if string.sub(msg, 1, 4) == (prefix.."god") then
        lplayer.Character.Humanoid.Name = "1"
        local l = lplayer.Character["1"]:Clone()
        l.Parent = lplayer.Character
        l.Name = "Humanoid"
        task.wait(0.1)
        lplayer.Character["1"]:Destroy()
        game:GetService("Workspace").CurrentCamera.CameraSubject = lplayer.Character
        lplayer.Character.Animate.Disabled = true
        task.wait(0.1)
        lplayer.Character.Animate.Disabled = false
        lplayer.Character.Humanoid.DisplayDistanceType = "None"
        safeSetCore("SendNotification", {
        Title = "FE Godmode enabled";
        Text = "Use ;grespawn or ;respawn to remove";
        })
    end
    if string.sub(msg, 1, 9) == (prefix.."drophats") then
        for i,v in pairs(lplayer.Character:GetChildren()) do
            if (v:IsA("Accessory")) or (v:IsA("Hat")) then
                v.Parent = workspace
            end
        end
    end
    if string.sub(msg, 1, 9) == (prefix.."droptool") then
        for i,v in pairs(lplayer.Character:GetChildren()) do
            if (v:IsA("Tool")) then
                v.Parent = workspace
            end
        end
    end
    if string.sub(msg, 1, 10) == (prefix.."loopdhats") then
        droppinghats = true
        safeSetCore("SendNotification", {
        Title = "Loop Drop Enabled";
        Text = "Type ;unloopdhats to disable";
        })
    end
    if string.sub(msg, 1, 12) == (prefix.."unloopdhats") then
        droppinghats = false
        safeSetCore("SendNotification", {
        Title = "Loop Drop Disabled";
        Text = "Type ;loopdhats to enable.";
        })
    end
    if string.sub(msg, 1, 10) == (prefix.."loopdtool") then
        droppingtools = true
        safeSetCore("SendNotification", {
        Title = "Loop Drop Enabled";
        Text = "Type ;unloopdtool to disable";
        })
    end
    if string.sub(msg, 1, 12) == (prefix.."unloopdtool") then
        droppingtools = false
        safeSetCore("SendNotification", {
        Title = "Loop Drop Disabled";
        Text = "Type ;loopdtool to enable.";
        })
    end
    if string.sub(msg, 1, 10) == (prefix.."invisible") then -- Credit to Timeless
        Local = game:GetService('Players').LocalPlayer
        Char  = Local.Character
        if not (Char and Char:FindFirstChild("HumanoidRootPart")) then
            safeSetCore("SendNotification", {
            Title = "Invisible";
            Text = "No character to hide yet - wait until you respawn.";
            })
            return
        end
        touched,tpdback = false, false
        box = Instance.new('Part',workspace)
        box.Anchored = true
        box.CanCollide = true
        box.Size = Vector3.new(10,1,10)
        box.Position = Vector3.new(0,10000,0)
        box.Touched:Connect(function(part)
            if (part.Parent.Name == Local.Name) then
                if touched == false then
                    touched = true
                    function apply()
                        if true then
                            no = Char.HumanoidRootPart:Clone()
                            task.wait(.25)
                            Char.HumanoidRootPart:Destroy()
                            no.Parent = Char
                            Char:MoveTo(loc)
                            touched = false
                        end end
                    if Char then
                        apply()
                    end
                end
            end
        end)
        loc = Char.HumanoidRootPart.Position
        Char:MoveTo(box.Position + Vector3.new(0,.5,0))
        safeSetCore("SendNotification", {
        Title = "Invisibility enabled!";
        Text = "Reset or use ;respawn to remove.";
        })
    end
    if string.sub(msg, 1, 6) == (prefix.."view ") then
        for i,v in pairs(GetPlayer(string.sub(msg, 7))) do
            if game:GetService("Players")[v.Name].Character.Humanoid then
                game:GetService("Workspace").CurrentCamera.CameraSubject = game:GetService("Players")[v.Name].Character.Humanoid
            else
                game:GetService("Workspace").CurrentCamera.CameraSubject = game:GetService("Players")[v.Name].Character.Head
            end
        end
    end
    if string.sub(msg, 1, 7) == (prefix.."unview") then
        if lplayer.Character.Humanoid then
            game:GetService("Workspace").CurrentCamera.CameraSubject = lplayer.Character.Humanoid
        else
            game:GetService("Workspace").CurrentCamera.CameraSubject = lplayer.Character.Head
        end
    end
    if string.sub(msg, 1, 6) == (prefix.."goto ") then
        for i,v in pairs(GetPlayer(string.sub(msg, 7))) do
            tpBypass(1)
            lplayer.Character.HumanoidRootPart.CFrame = game:GetService("Players")[v.Name].Character.HumanoidRootPart.CFrame
        end
    end
    -- Exact match: the old prefix check also swallowed ":flyspeed".
    if msg == (prefix.."fly") then
    -- Do not block the command engine waiting for a character that may never
    -- exist. This `repeat task.wait()` used to hang :fly and leave `executing`
    -- stuck, which silently discarded every later command.
    local flyChar = lplayer and lplayer.Character
    local flyRoot = flyChar and flyChar:FindFirstChild('HumanoidRootPart')
    if not (flyRoot and flyChar:FindFirstChild('Humanoid') and mouse) then
        safeSetCore("SendNotification", {
        Title = "Fly";
        Text = "No character to fly yet - wait until you respawn.";
        })
        return
    end

    local T = flyRoot
    -- Never stack a second fly: drop the previous movers and key listeners.
    destroyNamed(T, "RevizFlyBG")
    destroyNamed(T, "RevizFlyBV")
    for _, connection in ipairs(flyKeyConnections) do
        pcall(function() connection:Disconnect() end)
    end
    flyKeyConnections = {}

    local CONTROL = {F = 0, B = 0, L = 0, R = 0}
    local lCONTROL = {F = 0, B = 0, L = 0, R = 0}
    local SPEED = speedget
   
    local function fly()
        flying = true
        local BG = Instance.new('BodyGyro', T)
        local BV = Instance.new('BodyVelocity', T)
        BG.Name = "RevizFlyBG"
        BV.Name = "RevizFlyBV"
        BG.P = 9e4
        BG.MaxTorque = Vector3.new(9e9, 9e9, 9e9)
        BG.CFrame = T.CFrame
        BV.Velocity = Vector3.new(0, 0.1, 0)
        BV.MaxForce = Vector3.new(9e9, 9e9, 9e9)
        task.spawn(function()
        repeat task.wait()
        lplayer.Character.Humanoid.PlatformStand = true
        if CONTROL.L + CONTROL.R ~= 0 or CONTROL.F + CONTROL.B ~= 0 then
        SPEED = 50
        elseif not (CONTROL.L + CONTROL.R ~= 0 or CONTROL.F + CONTROL.B ~= 0) and SPEED ~= 0 then
        SPEED = 0
        end
        if (CONTROL.L + CONTROL.R) ~= 0 or (CONTROL.F + CONTROL.B) ~= 0 then
        BV.Velocity = ((workspace.CurrentCamera.CFrame.lookVector * (CONTROL.F + CONTROL.B)) + ((workspace.CurrentCamera.CFrame * CFrame.new(CONTROL.L + CONTROL.R, (CONTROL.F + CONTROL.B) * 0.2, 0).p) - workspace.CurrentCamera.CFrame.p)) * SPEED
        lCONTROL = {F = CONTROL.F, B = CONTROL.B, L = CONTROL.L, R = CONTROL.R}
        elseif (CONTROL.L + CONTROL.R) == 0 and (CONTROL.F + CONTROL.B) == 0 and SPEED ~= 0 then
        BV.Velocity = ((workspace.CurrentCamera.CFrame.lookVector * (lCONTROL.F + lCONTROL.B)) + ((workspace.CurrentCamera.CFrame * CFrame.new(lCONTROL.L + lCONTROL.R, (lCONTROL.F + lCONTROL.B) * 0.2, 0).p) - workspace.CurrentCamera.CFrame.p)) * SPEED
        else
        BV.Velocity = Vector3.new(0, 0.1, 0)
        end
        BG.CFrame = workspace.CurrentCamera.CFrame
                until not flying
                CONTROL = {F = 0, B = 0, L = 0, R = 0}
                lCONTROL = {F = 0, B = 0, L = 0, R = 0}
                SPEED = 0
                BG:Destroy()
                BV:Destroy()
                lplayer.Character.Humanoid.PlatformStand = false
            end)
        end
    table.insert(flyKeyConnections, on(mouse.KeyDown, function(KEY)
        if KEY:lower() == 'w' then
            CONTROL.F = speedfly
        elseif KEY:lower() == 's' then
            CONTROL.B = -speedfly
        elseif KEY:lower() == 'a' then
            CONTROL.L = -speedfly
        elseif KEY:lower() == 'd' then
            CONTROL.R = speedfly
        end
    end))
    table.insert(flyKeyConnections, on(mouse.KeyUp, function(KEY)
        if KEY:lower() == 'w' then
            CONTROL.F = 0
        elseif KEY:lower() == 's' then
            CONTROL.B = 0
        elseif KEY:lower() == 'a' then
            CONTROL.L = 0
        elseif KEY:lower() == 'd' then
            CONTROL.R = 0
        end
    end))
    fly()
    end
    if string.sub(msg, 1, 6) == (prefix.."unfly") then
        flying = false
        local humanoid = lplayer.Character and lplayer.Character:FindFirstChildOfClass("Humanoid")
        if humanoid then humanoid.PlatformStand = false end
        local root = lplayer.Character and lplayer.Character:FindFirstChild("HumanoidRootPart")
        destroyNamed(root, "RevizFlyBG")
        destroyNamed(root, "RevizFlyBV")
        for _, connection in ipairs(flyKeyConnections) do
            pcall(function() connection:Disconnect() end)
        end
        flyKeyConnections = {}
    end
    if string.sub(msg, 1, 6) == (prefix.."chat ") then
        sendChat((string.sub(msg, 7)))
    end
    if string.sub(msg, 1, 6) == (prefix.."spam ") then
        spamtext = (string.sub(msg, 7))
        spamming = true
    end
    if string.sub(msg, 1, 7) == (prefix.."unspam") then
        spamming = false
    end
    if string.sub(msg, 1, 10) == (prefix.."spamwait ") then
        spamdelay = tonumber(string.sub(msg, 11)) or 1
    end
    if string.sub(msg, 1, 8) == (prefix.."pmspam ") then
        for i,v in pairs(GetPlayer(string.sub(msg, 9))) do
            pmspammed = v.Name
            spammingpm = true
        end
    end
    if string.sub(msg, 1, 9) == (prefix.."unpmspam") then
        spammingpm = false
    end
    if string.sub(msg, 1, 9) == (prefix.."cfreeze ") then
        for i,v in pairs(GetPlayer(string.sub(msg, 10))) do
            anchorCharacter(v.Character, true)
        end
    end
    if string.sub(msg, 1, 11) == (prefix.."uncfreeze ") then
        for i,v in pairs(GetPlayer(string.sub(msg, 12))) do
            anchorCharacter(v.Character, false)
        end
    end
    if string.sub(msg, 1, 9) == (prefix.."unlockws") then
        local a = game:GetService("Workspace"):GetChildren()
        for i = 1, #a do
            if a[i].ClassName == "Part" then
                a[i].Locked = false
            elseif a[i].ClassName == "Model" then
                local r = a[i]:GetChildren()
                for i = 1, #r do
                    if r[i].ClassName == "Part" then
                    r[i].Locked = false
                    end
                end
            end
        end
        safeSetCore("SendNotification", {
        Title = "Success!";
        Text = "Workspace unlocked. Use ;lockws to lock.";
        })
    end
    if string.sub(msg, 1, 7) == (prefix.."lockws") then
        local a = game:GetService("Workspace"):GetChildren()
        for i = 1, #a do
            if a[i].ClassName == "Part" then
                a[i].Locked = true
            elseif a[i].ClassName == "Model" then
                local r = a[i]:GetChildren()
                for i = 1, #r do
                    if r[i].ClassName == "Part" then
                    r[i].Locked = true
                    end
                end
            end
        end
    end
    if string.sub(msg, 1, 7) == (prefix.."btools") then
        local Clone_T = Instance.new("HopperBin",lplayer.Backpack)
        Clone_T.BinType = "Clone"
        local Destruct = Instance.new("HopperBin",lplayer.Backpack)
        Destruct.BinType = "Hammer"
        local Hold_T = Instance.new("HopperBin",lplayer.Backpack)
        Hold_T.BinType = "Grab"
    end
    if string.sub(msg, 1, 7) == (prefix.."pstand") then
        lplayer.Character.Humanoid.PlatformStand = true
    end
    if string.sub(msg, 1, 9) == (prefix.."unpstand") then
        lplayer.Character.Humanoid.PlatformStand = false
    end
    if string.sub(msg, 1, 10) == (prefix.."blockhead") then
        removeMesh(lplayer.Character.Head)
    end
    if string.sub(msg, 1, 4) == (prefix.."sit") then
        lplayer.Character.Humanoid.Sit = true
    end
    if string.sub(msg, 1, 10) == (prefix.."bringobj ") then
        local targetObjName = string.sub(msg, 11)
        if targetObjName == "" then
            safeSetCore("SendNotification", {
            Title = "BringObj";
            Text = "Usage: bringobj [object name]";
            })
        else
            bringingobj = true
            local function bringobjw()
            for i,obj in ipairs(game:GetService("Workspace"):GetDescendants()) do
            if not bringingobj then return end
            if obj.Name == targetObjName and obj:IsA("BasePart") then
            obj.CFrame = lplayer.Character.HumanoidRootPart.CFrame
            obj.CanCollide = false
            obj.Transparency = 0.7
            task.wait()
            obj.CFrame = limb(lplayer.Character, "Left Leg").CFrame
            task.wait()
            obj.CFrame = limb(lplayer.Character, "Right Leg").CFrame
            task.wait()
            obj.CFrame = lplayer.Character["Head"].CFrame
            end
            end
            end
            -- Flag-driven, so it can actually be stopped; the old `while
            -- task.wait() do` hung its thread forever and never reached the
            -- notification below it.
            task.spawn(function()
                while bringingobj and task.wait() do
                    local ok, err = pcall(bringobjw)
                    if not ok then
                        bringingobj = false
                        warn("[reviz] bringobj stopped: " .. tostring(err))
                    end
                end
            end)
            safeSetCore("SendNotification", {
            Title = "BringObj";
            Text = "BringObj enabled. Use unbringobj to stop.";
            })
        end
    end
    if string.sub(msg, 1, 11) == (prefix.."unbringobj") then
        bringingobj = false
    end
    if string.sub(msg, 1, 7) == (prefix.."wsvis ") then
        vis = tonumber(string.sub(msg, 8)) or 0
        local a = game:GetService("Workspace"):GetDescendants()
        for i = 1, #a do
            if a[i].ClassName == "Part" then
                a[i].Transparency = vis
            elseif a[i].ClassName == "Model" then
                local r = a[i]:GetChildren()
                for i = 1, #r do
                    if r[i].ClassName == "Part" then
                    r[i].Transparency = vis
                    end
                end
            end
        end
    end
    if string.sub(msg, 1, 11) == (prefix.."hypertotal") then
        if loadAsset("rbxassetid://1255063809") then
            safeSetCore("SendNotification", {
            Title = "Success!";
            Text = "HyperTotal GUI Loaded!";
            })
        end
    end
    if string.sub(msg, 1, 5) == (prefix.."cmds") then
        showCommandList()
    end
    if string.sub(msg, 1, 10) == (prefix.."rmeshhats") then
        for i,v in pairs(lplayer.Character:GetChildren()) do
            if (v:IsA("Accessory")) or (v:IsA("Hat")) then
                removeMesh(v.Handle)
            end
        end
    end
    if string.sub(msg, 1, 10) == (prefix.."blockhats") then
        for i,v in pairs(lplayer.Character:GetChildren()) do
            if (v:IsA("Accessory")) or (v:IsA("Hat")) then
                removeMesh(v.Handle)
            end
        end
    end
    if string.sub(msg, 1, 10) == (prefix.."rmeshtool") then
        for i,v in pairs(lplayer.Character:GetChildren()) do
            if (v:IsA("Tool")) then
                removeMesh(v.Handle)
            end
        end
    end
    if string.sub(msg, 1, 10) == (prefix.."blocktool") then
        for i,v in pairs(lplayer.Character:GetChildren()) do
            if (v:IsA("Tool")) then
                removeMesh(v.Handle)
            end
        end
    end
    if string.sub(msg, 1, 8) == (prefix.."spinner") then
        local p = Instance.new("RocketPropulsion")
        p.Parent = lplayer.Character.HumanoidRootPart
        p.Name = "Spinner"
        p.Target = limb(lplayer.Character, "Left Arm")
        p:Fire()
        safeSetCore("SendNotification", {
        Title = "Spinner enabled";
        Text = "Type ;nospinner to disable.";
        })
    end
    if string.sub(msg, 1, 10) == (prefix.."nospinner") then
        local root = lplayer.Character and lplayer.Character:FindFirstChild("HumanoidRootPart")
        destroyNamed(root, "Spinner")
    end
    if string.sub(msg, 1, 7) == (prefix.."reachd") then
        for i,v in pairs(game:GetService'Players'.LocalPlayer.Character:GetChildren())do
            if v:IsA("Tool") then
                local a = Instance.new("SelectionBox",v.Handle)
                a.Adornee = v.Handle
                v.Handle.Size = Vector3.new(0.5,0.5,60)
                v.GripPos = Vector3.new(0,0,0)
                lplayer.Character.Humanoid:UnequipTools()
            end
        end
        safeSetCore("SendNotification", {
        Title = "Reach applied!";
        Text = "Applied to equipped sword. Use ;noreach to disable.";
        })
    end
    if string.sub(msg, 1, 7) == (prefix.."reach ") then
        for i,v in pairs(game:GetService'Players'.LocalPlayer.Character:GetChildren())do
            if v:IsA("Tool") then
                handleSize = v.Handle.Size
                task.wait()
                local a = Instance.new("SelectionBox",v.Handle)
                a.Name = "a"
                a.Adornee = v.Handle
                v.Handle.Size = Vector3.new(0.5,0.5,tonumber(string.sub(msg, 8)) or 60)
                v.GripPos = Vector3.new(0,0,0)
                lplayer.Character.Humanoid:UnequipTools()
            end
        end
        safeSetCore("SendNotification", {
        Title = "Reach applied!";
        Text = "Applied to equipped sword. Use ;noreach to disable.";
        })
    end
    if string.sub(msg, 1, 8) == (prefix.."noreach") then
        for i,v in pairs(game:GetService'Players'.LocalPlayer.Character:GetChildren())do
            if v:IsA("Tool") and v.Handle then
                local marker = v.Handle:FindFirstChild("a")
                if marker then marker:Destroy() end
                if handleSize then v.Handle.Size = handleSize end
            end
        end
        safeSetCore("SendNotification", {
        Title = "Reach removed!";
        Text = "Removed reach from equipped sword.";
        })
    end
    if string.sub(msg, 1, 7) == (prefix.."rkill ") then
        for i,v in pairs(GetPlayer(string.sub(msg, 8)))do
            lplayer.Character.Humanoid.Name = "1"
            local l = lplayer.Character["1"]:Clone()
            l.Parent = lplayer.Character
            l.Name = "Humanoid"
            task.wait(0.1)
            lplayer.Character["1"]:Destroy()
            game:GetService("Workspace").CurrentCamera.CameraSubject = lplayer.Character
            lplayer.Character.Animate.Disabled = true
            task.wait(0.1)
            lplayer.Character.Animate.Disabled = false
            lplayer.Character.Humanoid.DisplayDistanceType = "None"
            for i,v in pairs(game:GetService'Players'.LocalPlayer.Backpack:GetChildren())do
            lplayer.Character.Humanoid:EquipTool(v)
            end
            task.wait(0.1)
            lplayer.Character.HumanoidRootPart.CFrame = game:GetService("Players")[v.Name].Character.HumanoidRootPart.CFrame
            task.wait(0.2)
            lplayer.Character.HumanoidRootPart.CFrame = game:GetService("Players")[v.Name].Character.HumanoidRootPart.CFrame
            task.wait(0.5)
            lplayer.Character.HumanoidRootPart.CFrame = CFrame.new(Vector3.new(-100000,10,-100000))
            safeSetCore("SendNotification", {
            Title = "Tools needed!";
            Text = "You need a tool in your backpack for this command!";
            })
        end
    end
    if string.sub(msg, 1, 7) == (prefix.."tp me ") then
        for i,v in pairs(GetPlayer(string.sub(msg, 8))) do
            tpBypass(1)
            lplayer.Character.HumanoidRootPart.CFrame = game:GetService("Players")[v.Name].Character.HumanoidRootPart.CFrame
        end
    end
    if string.sub(msg, 1, 8) == (prefix.."cbring ") then
        if (string.sub(msg, 9)) == "all" or (string.sub(msg, 9)) == "All" or (string.sub(msg, 9)) == "ALL" then
            cbringall = true
        else
            for i,v in pairs(GetPlayer(string.sub(msg, 9))) do
                brplr = v.Name
            end
        end
        cbring = true
    end
    if string.sub(msg, 1, 9) == (prefix.."uncbring") then
        cbring = false
        cbringall = false
    end
    if string.sub(msg, 1, 6) == (prefix.."swap ") then
        for i,v in pairs(GetPlayer(string.sub(msg, 7))) do
            local NOWPLR = game:GetService("Players")[v.Name].Character.HumanoidRootPart.CFrame
            local NOW = lplayer.Character.HumanoidRootPart.CFrame
            lplayer.Character.Humanoid.Name = "1"
            local l = lplayer.Character["1"]:Clone()
            l.Parent = lplayer.Character
            l.Name = "Humanoid"
            task.wait(0.1)
            lplayer.Character["1"]:Destroy()
            game:GetService("Workspace").CurrentCamera.CameraSubject = lplayer.Character
            lplayer.Character.Animate.Disabled = true
            task.wait(0.1)
            lplayer.Character.Animate.Disabled = false
            lplayer.Character.Humanoid.DisplayDistanceType = "None"
            for i,v in pairs(game:GetService'Players'.LocalPlayer.Backpack:GetChildren())do
            lplayer.Character.Humanoid:EquipTool(v)
            end
            local function tp(player,player2)
            local char1,char2=player.Character,player2.Character
            if char1 and char2 then
            char1:MoveTo(char2.Head.Position)
            end
            end
            task.wait(0.1)
            lplayer.Character.HumanoidRootPart.CFrame = game:GetService("Players")[v.Name].Character.HumanoidRootPart.CFrame
            task.wait(0.2)
            lplayer.Character.HumanoidRootPart.CFrame = game:GetService("Players")[v.Name].Character.HumanoidRootPart.CFrame
            task.wait(0.5)
            lplayer.Character.HumanoidRootPart.CFrame = NOW
            task.wait(0.6)
            tp(lplayer, game:GetService("Players")[v.Name])
            task.wait(0.4)
            lplayer.Character.HumanoidRootPart.CFrame = NOWPLR
            safeSetCore("SendNotification", {
            Title = "Tools needed!";
            Text = "You need a tool in your backpack for this command!";
            })
        end
    end
    if string.sub(msg, 1, 8) == (prefix.."glitch ") then
        for i,v in pairs(GetPlayer(string.sub(msg, 9))) do
            lplayer.Character.Humanoid.Name = "1"
            local l = lplayer.Character["1"]:Clone()
            l.Parent = lplayer.Character
            l.Name = "Humanoid"
            task.wait(0.1)
            lplayer.Character["1"]:Destroy()
            game:GetService("Workspace").CurrentCamera.CameraSubject = lplayer.Character
            lplayer.Character.Animate.Disabled = true
            task.wait(0.1)
            lplayer.Character.Animate.Disabled = false
            lplayer.Character.Humanoid.DisplayDistanceType = "None"
            for i,v in pairs(game:GetService'Players'.LocalPlayer.Backpack:GetChildren())do
            lplayer.Character.Humanoid:EquipTool(v)
            end
            lplayer.Character.HumanoidRootPart.CFrame = limb(game:GetService("Players")[v.Name].Character, "Left Arm").CFrame
            task.wait(0.3)
            lplayer.Character.HumanoidRootPart.CFrame = limb(game:GetService("Players")[v.Name].Character, "Left Arm").CFrame
            task.wait(0.4)
            b = Instance.new("BodyForce")
            b.Parent = lplayer.Character.HumanoidRootPart
            b.Name = "Glitch"
            b.Force = Vector3.new(100000000,5000,0)
            safeSetCore("SendNotification", {
            Title = "Tools needed!";
            Text = "You need a tool in your backpack for this command!";
            })
        end
    end
    if string.sub(msg, 1, 9) == (prefix.."unglitch") then
        local root = lplayer.Character and lplayer.Character:FindFirstChild("HumanoidRootPart")
        destroyNamed(root, "Glitch")
        lplayer.Character.HumanoidRootPart.CFrame = CFrame.new(10000,0,10000)
        b = Instance.new("BodyForce")
        b.Parent = lplayer.Character.HumanoidRootPart
        b.Name = "unGlitch"
        b.Force = Vector3.new(0,-5000000,0)
        task.wait(2)
        destroyNamed(root, "unGlitch")
    end
    if string.sub(msg, 1, 9) == (prefix.."grespawn") then
        lplayer.Character.Humanoid.Health = 0
        task.wait(1)
        lplayer.Character.Head.CFrame = CFrame.new(1000000,0,1000000)
        limb(lplayer.Character, "Torso").CFrame = CFrame.new(1000000,0,1000000)
    end
    if string.sub(msg, 1, 9) == (prefix.."explorer") then
        if loadDex() then
            safeSetCore("SendNotification", {
            Title = "Success!";
            Text = "DEX Explorer has loaded.";
            })
        end
    end
    if string.sub(msg, 1, 6) == (prefix.."anim ") then
        local Anim = Instance.new("Animation")
        Anim.AnimationId = "rbxassetid://"..(string.sub(msg, 7))
        local track = loadAnim(lplayer.Character.Humanoid, Anim)
        track:Play(.1, 1, 1)
    end
    if string.sub(msg, 1, 8) == (prefix.."animgui") then
        if loadAsset("rbxassetid://1202558084") then
            safeSetCore("SendNotification", {
            Title = "Success!";
            Text = "Energize Animations GUI has loaded.";
            })
        end
    end
    if string.sub(msg, 1, 8) == (prefix.."savepos") then
        saved = lplayer.Character.HumanoidRootPart.CFrame
        safeSetCore("SendNotification", {
        Title = "Position Saved";
        Text = "Use ;loadpos to return to saved position.";
        })
    end
    if string.sub(msg, 1, 8) == (prefix.."loadpos") then
        tpBypass(1)
        lplayer.Character.HumanoidRootPart.CFrame = saved
    end
    if string.sub(msg, 1, 6) == (prefix.."bang ") then
        for i,v in pairs(GetPlayer(string.sub(msg, 7))) do
            local Anim2 = Instance.new("Animation")
            Anim2.AnimationId = "rbxassetid://148840371"
            local track2 = loadAnim(lplayer.Character.Humanoid, Anim2)
            track2:Play(.1, 1, 1)
            bplrr = v.Name
            banpl = true
        end
    end
    if string.sub(msg, 1, 7) == (prefix.."unbang") then
        banpl = false
    end
    if string.sub(msg, 1, 10) == (prefix.."bringmod ") then
        local targetModName = string.sub(msg, 11)
        if targetModName == "" then
            safeSetCore("SendNotification", {
            Title = "BringMod";
            Text = "Usage: bringmod [model name]";
            })
        else
        bringingmod = true
        local function bringmodw()
        for i,obj in ipairs(game:GetService("Workspace"):GetDescendants()) do
        if obj.Name == targetModName then
        for i,ch in pairs(obj:GetDescendants()) do
        if (ch:IsA("BasePart")) then
        ch.CFrame = lplayer.Character.HumanoidRootPart.CFrame
        ch.CanCollide = false
        ch.Transparency = 0.7
        task.wait()
        ch.CFrame = limb(lplayer.Character, "Left Leg").CFrame
        task.wait()
        ch.CFrame = limb(lplayer.Character, "Right Leg").CFrame
        task.wait()
        ch.CFrame = lplayer.Character["Head"].CFrame
        end
        end
        end
        end
        end
        task.spawn(function()
            while bringingmod and task.wait() do
                pcall(bringmodw)
            end
        end)
        safeSetCore("SendNotification", {
        Title = "BringMod";
        Text = "BringMod enabled. Use unbringmod to stop.";
        })
        end
    end
    if string.sub(msg, 1, 11) == (prefix.."unbringmod") then
        bringingmod = false
    end
    if string.sub(msg, 1, 8) == (prefix.."respawn") then
        local mod = Instance.new('Model', workspace) mod.Name = 're '..lplayer.Name
        local hum = Instance.new('Humanoid', mod)
        local ins = Instance.new('Part', mod) ins.Name = 'Torso' ins.CanCollide = false ins.Transparency = 1
        lplayer.Character = mod
    end
    if string.sub(msg, 1, 9) == (prefix.."shutdown") then
        game:GetService'RunService'.Stepped:Connect(function()
        pcall(function()
            for i,v in pairs(game:GetService'Players':GetPlayers()) do
                if v.Character ~= nil and v.Character:FindFirstChild'Head' then
                    for _,x in pairs(v.Character.Head:GetChildren()) do
                        if x:IsA'Sound' then x.Playing = true x.CharacterSoundEvent:FireServer(true, true) end
                    end
                end
            end
        end)
        end)
        safeSetCore("SendNotification", {
        Title = "Attempting Shutdown";
        Text = "Shutdown Attempt has begun.";
        })
    end
    if string.sub(msg, 1, 8) == (prefix.."delobj ") then
        objtodel = (string.sub(msg, 9))
        for i,v in pairs(game:GetService("Workspace"):GetDescendants()) do
            if v.Name == objtodel then
                v:Destroy()
            end
        end
    end
    if string.sub(msg, 1, 8) == (prefix.."getplrs") then
        for i,v in pairs(game:GetService("Players"):GetPlayers())do
            print(v)
        end
        safeSetCore("SendNotification", {
        Title = "Printed";
        Text = "Players have been printed to console. (F9)";
        })
    end
    if string.sub(msg, 1, 9) == (prefix.."deldecal") then
        for i,v in pairs(game:GetService("Workspace"):GetDescendants())do
            if (v:IsA("Decal")) then
                v:Destroy()
            end
        end
    end
    if string.sub(msg, 1, 11) == (prefix.."opfinality") then
        if loadAsset("rbxassetid://1294358929") then
            safeSetCore("SendNotification", {
            Title = "Success!";
            Text = "OpFinality GUI has loaded.";
            })
        end
    end
    if string.sub(msg, 1, 8) == (prefix.."remotes") then
        remotes = true
        added = true
        clearRemotes()
        onRemotes(game.DescendantAdded, function(rmt)
        if added == true then
        if remotes == true then
        if rmt:IsA("RemoteEvent") then
        print("A RemoteEvent was added!")
        print(" game." .. rmt:GetFullName() .. " | RemoteEvent")
        print(" game." .. rmt:GetFullName() .. " | RemoteEvent", 247, 0, 0, true)
        end end end
        end)
        onRemotes(game.DescendantAdded, function(rmtfnctn)
        if added == true then
        if remotes == true then
        if rmtfnctn:IsA("RemoteFunction") then
        warn("A RemoteFunction was added!")
        warn(" game." .. rmtfnctn:GetFullName() .. " | RemoteFunction")
        print(" game." .. rmtfnctn:GetFullName() .. " | RemoteFunction", 5, 102, 198, true)
        end end end
        end)
       
        onRemotes(game.DescendantAdded, function(bndfnctn)
        if added == true then
        if binds == true then
        if bndfnctn:IsA("BindableFunction") then
        print("A BindableFunction was added!")
        print(" game." .. bndfnctn:GetFullName() .. " | BindableFunction")
        print(" game." .. bndfnctn:GetFullName() .. " | BindableFunction", 239, 247, 4, true)
        end end end
        end)
       
        onRemotes(game.DescendantAdded, function(bnd)
        if added == true then
        if binds == true then
        if bnd:IsA("BindableEvent") then
        warn("A BindableEvent was added!")
        warn(" game." .. bnd:GetFullName() .. " | BindableEvent")
        print(" game." .. bnd:GetFullName() .. " | BindableEvent", 13, 193, 22, true)
        end end end
        end)
       
       
        if binds == true then
        for i,v in pairs(game:GetDescendants()) do
        if v:IsA("BindableFunction") then
        print(" game." .. v:GetFullName() .. " | BindableFunction")
        print(" game." .. v:GetFullName() .. " | BindableFunction", 239, 247, 4, true)
        end end
        for i,v in pairs(game:GetDescendants()) do
        if v:IsA("BindableEvent") then
        warn(" game." .. v:GetFullName() .. " | BindableEvent")
        print(" game." .. v:GetFullName() .. " | BindableEvent", 13, 193, 22, true)
        end end
        else
        print("Off")
        end
        if remotes == true then
        for i,v in pairs(game:GetDescendants()) do
        if v:IsA("RemoteFunction") then
        warn(" game." .. v:GetFullName() .. " | RemoteFunction")
        print(" game." .. v:GetFullName() .. " | RemoteFunction", 5, 102, 198, true)
        end end
        task.wait()
        for i,v in pairs(game:GetDescendants()) do
        if v:IsA("RemoteEvent") then
        print(" game." .. v:GetFullName() .. " | RemoteEvent")
        print(" game." .. v:GetFullName() .. " | RemoteEvent", 247, 0, 0, true)
        end end
        else
        print("Off")
        end
        safeSetCore("SendNotification", {
        Title = "Printing Remotes";
        Text = "Type ;noremotes to disable.";
        })
    end
    if string.sub(msg, 1, 10) == (prefix.."noremotes") then
        remotes = false
        added = false
        clearRemotes()
        safeSetCore("SendNotification", {
        Title = "Printing Remotes Disabled";
        Text = "Type ;remotes to enable.";
        })
    end
    if string.sub(msg, 1, 10) == (prefix.."tpdefault") then
        spin = false
        followed = false
        traill = false
        noclip = false
        annoying = false
        hwalk = false
        cbringing = false
    end
    if string.sub(msg, 1, 8) == (prefix.."stopsit") then
        stopsitting = true
    end
    if string.sub(msg, 1, 6) == (prefix.."gosit") then
        stopsitting = false
    end
    if string.sub(msg, 1, 8) == (prefix.."version") then
        print(adminversion)
        safeSetCore("SendNotification", {
        Title = "Version";
        Text = adminversion;
        })
    end
    if string.sub(msg, 1, 8) == (prefix.."clicktp") then
        clickgoto = true
        safeSetCore("SendNotification", {
        Title = "Click TP";
        Text = "Press E to teleport to mouse position, ;noclicktp to stop";
        })
    end
    if string.sub(msg, 1, 9) == (prefix.."clickdel") then
        clickdel = true
        safeSetCore("SendNotification", {
        Title = "Click Delete";
        Text = "Press E to delete part at mouse, ;noclickdel to stop";
        })
    end
    if string.sub(msg, 1, 11) == (prefix.."noclickdel") then
        clickdel = false
        safeSetCore("SendNotification", {
        Title = "Click Delete";
        Text = "Click delete has been disabled.";
        })
    end
    if string.sub(msg, 1, 10) == (prefix.."noclicktp") then
        clickgoto = false
        safeSetCore("SendNotification", {
        Title = "Click TP";
        Text = "Click TP has been disabled.";
        })
    end
    if string.sub(msg, 1, 8) == (prefix.."toolson") then
        gettingtools = true
        safeSetCore("SendNotification", {
        Title = "Tools Enabled";
        Text = "Automatically colleting tools dropped.";
        })
    end
    if string.sub(msg, 1, 9) == (prefix.."toolsoff") then
        gettingtools = false
        safeSetCore("SendNotification", {
        Title = "Tools Disabled";
        Text = "Click TP has been disabled.";
        })
    end
    if string.sub(msg, 1, 10) == (prefix.."delcmdbar") then
        destroyRevizGuis()
        revizGuiOpen = false
        syncRevizToggle(false)
    end
    -- Exact match so this can never swallow ":resetprefix".
    if msg == (prefix.."reset") then
        if lplayer.Character then
            lplayer.Character:BreakJoints()
        end
    end
    if string.sub(msg, 1, 7) == (prefix.."state ") then
        local chosen = tonumber(string.sub(msg, 8))
        if chosen and chosen >= 0 and chosen <= 20 then
            statechosen = chosen
            changingstate = true
        else
            safeSetCore("SendNotification", {
            Title = "State";
            Text = "Usage: state [0-20]";
            })
        end
    end
    if string.sub(msg, 1, 9) == (prefix.."gravity ") then
        game:GetService("Workspace").Gravity = tonumber(string.sub(msg, 10)) or 196.2
    end
    if string.sub(msg, 1, 10) == (prefix.."looprhats") then
        removingmeshhats = true
    end
    if string.sub(msg, 1, 12) == (prefix.."unlooprhats") then
        removingmeshhats = false
    end
    if string.sub(msg, 1, 10) == (prefix.."looprtool") then
        removingmeshtool = true
    end
    if string.sub(msg, 1, 12) == (prefix.."unlooprtool") then
        removingmeshtool = false
    end
    if string.sub(msg, 1, 10) == (prefix.."givetool ") then
        for i,v in pairs(game:GetService("Players").LocalPlayer.Character:GetDescendants()) do
            if v:IsA("Tool") then
                for i,player in pairs(GetPlayer(string.sub(msg, 11))) do
                    v.Parent = player.Character
                end
            end
        end
    end
    if string.sub(msg, 1, 14) == (prefix.."givealltools ") then
        for i,v in pairs(game:GetService("Players").LocalPlayer.Backpack:GetDescendants()) do
            if v:IsA("Tool") then
                v.Parent = lplayer.Character
                task.wait()
                for i,player in pairs(GetPlayer(string.sub(msg, 15))) do
                    v.Parent = player.Character
                end
            end
        end
    end
    if string.sub(msg, 1, 5) == (prefix.."age ") then
        for i,player in pairs(GetPlayer(string.sub(msg, 6))) do
            sendChat(player.Name.." Account Age: "..player.AccountAge.." days!")
        end
    end
    if string.sub(msg, 1, 4) == (prefix.."id ") then
        for i,player in pairs(GetPlayer(string.sub(msg, 5))) do
            sendChat(player.Name.." Account ID: "..player.UserId)
        end
    end
    if string.sub(msg, 1, 6) == (prefix..".age ") then
        for i,player in pairs(GetPlayer(string.sub(msg, 7))) do
            safeSetCore("SendNotification", {
            Title = player.AccountAge.." Days";
            Text = "Account age of "..player.Name;
            })
        end
    end
    if string.sub(msg, 1, 5) == (prefix..".id ") then
        for i,player in pairs(GetPlayer(string.sub(msg, 6))) do
            safeSetCore("SendNotification", {
            Title = player.UserId.." ID";
            Text = "Account ID of "..player.Name;
            })
        end
    end
    if string.sub(msg, 1, 7) == (prefix.."gameid") then
        safeSetCore("SendNotification", {
        Title = "Game ID";
        Text = "Game ID: ".. game.GameId;
        })
    end
    if string.sub(msg, 1, 4) == (prefix.."pgs") then
        local pgscheck = pgsEnabled()
        if pgscheck == true then
            safeSetCore("SendNotification", {
            Title = "PGSPhysicsSolverEnabled";
            Text = "PGS is Enabled!";
            })
        else
            safeSetCore("SendNotification", {
            Title = "PGSPhysicsSolverEnabled";
            Text = "PGS is Disabled!";
            })
        end
    end
    if string.sub(msg, 1, 12) == (prefix.."removeinvis") then
        for i,v in pairs(game:GetService("Workspace"):GetDescendants()) do
            if v:IsA("Part") then
                if v.Transparency == 1 then
                    if v.Name ~= "HumanoidRootPart" then
                        v:Destroy()
                    end
                end
            end
        end
    end
    if string.sub(msg, 1, 10) == (prefix.."removefog") then
        game:GetService("Lighting").FogStart = 0
        game:GetService("Lighting").FogEnd = 9999999999999
    end
    if string.sub(msg, 1, 8) == (prefix.."disable") then
        lplayer.Character.Humanoid.Parent = lplayer
    end
    if string.sub(msg, 1, 7) == (prefix.."enable") then
        lplayer.Humanoid.Parent = lplayer.Character
    end
    if string.sub(msg, 1, 8) == (prefix.."prefix ") then
        local newPrefix = string.sub(msg, 9, 9)
        if newPrefix ~= "" then
            prefix = newPrefix
            change()
            safeSetCore("SendNotification", {
            Title = "Prefix changed!";
            Text = "Prefix is now " .. prefix .. ". Use " .. prefix .. "resetprefix to restore it.";
            })
        end
    end
    -- Prefix-agnostic: Reviz.execute rewrites the documented ";resetprefix"
    -- into <prefix>resetprefix, so this works whatever the prefix is now.
    if msg == (prefix.."resetprefix") then
        prefix = DEFAULT_PREFIX
        change()
        safeSetCore("SendNotification", {
        Title = "Prefix changed!";
        Text = "Prefix reset to " .. prefix;
        })
    end
    if string.sub(msg, 1, 10) == (prefix.."flyspeed ") then
        speedfly = toNumber(string.sub(msg, 11), 1)
    end
    if string.sub(msg, 1, 8) == (prefix.."carpet ") then
        for i,v in pairs(GetPlayer(string.sub(msg, 9))) do
            local Anim3 = Instance.new("Animation")
            Anim3.AnimationId = "rbxassetid://282574440"
            local track3 = loadAnim(lplayer.Character.Humanoid, Anim3)
            track3:Play(.1, 1, 1)
            bplrr = v.Name
            banpl = true
        end
    end
    if string.sub(msg, 1, 9) == (prefix.."uncarpet") then
        banpl = false
    end
    if string.sub(msg, 1, 7) == (prefix.."stare ") then
        for i,v in pairs(GetPlayer(string.sub(msg, 8))) do
            staring = true
            stareplr = v
        end
    end
    if string.sub(msg, 1, 8) == (prefix.."unstare") then
        staring = false
    end
    if string.sub(msg, 1, 8) == (prefix.."logchat") then
        chatlogs = true
        safeSetCore("SendNotification", {
        Title = "LogChat enabled";
        Text = "Now logging all player chat.";
        })
    end
    if string.sub(msg, 1, 10) == (prefix.."unlogchat") then
        chatlogs = false
        safeSetCore("SendNotification", {
        Title = "LogChat disabled";
        Text = "Stopped logging all player chat.";
        })
    end
    if string.sub(msg, 1, 7) == (prefix.."fixcam") then
        -- camera reset (destroying CurrentCamera breaks the client)
        local cam = game:GetService("Workspace").CurrentCamera
        if cam then
            local char = lplayer and lplayer.Character
            local hum = char and char:FindFirstChildOfClass("Humanoid")
            if hum then
                cam.CameraSubject = hum
            end
            cam.CameraType = Enum.CameraType.Custom
        end
        lplayer.CameraMinZoomDistance = 0.5
        lplayer.CameraMaxZoomDistance = 400
        lplayer.CameraMode = Enum.CameraMode.Classic
    end
    if string.sub(msg, 1, 8) == (prefix.."unstate") then
        changingstate = false
    end
end

local revizAlive = true

local function tp()
    for i, player in ipairs(game:GetService("Players"):GetPlayers()) do
        if player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
            if player.Name == brplr then
                player.Character.HumanoidRootPart.CFrame = lplayer.Character.HumanoidRootPart.CFrame + lplayer.Character.HumanoidRootPart.CFrame.lookVector * 2
            end
        end
    end
end
local function tpall()
    for i, player in ipairs(game:GetService("Players"):GetPlayers()) do
        if player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
            player.Character.HumanoidRootPart.CFrame = lplayer.Character.HumanoidRootPart.CFrame + lplayer.Character.HumanoidRootPart.CFrame.lookVector * 3
        end
    end
end
task.spawn(function()
    while revizAlive and task.wait(spamdelay or 1) do
        if spamming == true then
            sendChat(spamtext)
        end
    end
end)
task.spawn(function()
    while revizAlive and task.wait(spamdelay or 1) do
        if spammingpm == true then
            sendChat("/w "..pmspammed.." @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@")
        end
    end
end)
task.spawn(function()
    while revizAlive and task.wait() do
        if cbring == true then
            tp()
        end
    end
end)
task.spawn(function()
    while revizAlive and task.wait() do
        if cbringall == true then
            tpall()
        end
    end
end)

    -- Focus the standalone command bar when the prefix key is pressed while
    -- the Reviz GUI is open. KeyCode based, because Mouse.KeyDown reports a
    -- key *name* string ("semicolon") and never matched the prefix character.
    on(game:GetService("UserInputService").InputBegan, function(input, processed)
        if processed then return end
        if not revizGuiOpen then return end
        if not CMDBAR or not CMDBAR.Parent then return end
        local key = prefixKeyCode()
        if key and input.KeyCode == key then
            task.defer(function() pcall(function() CMDBAR:CaptureFocus() end) end)
        end
    end)

    local function buildRevizGui(): boolean
        destroyRevizGuis()

        local sg = Instance.new("ScreenGui")
        local Frame = Instance.new("Frame")
        local cmdbar = Instance.new("TextBox")
        sg.Name = "RevizAdmin"
        sg.ResetOnSpawn = false
        sg.DisplayOrder = 10
        -- parentGui() tries gethui -> CoreGui -> PlayerGui and returns false
        -- instead of throwing, so the toggle can report a real failure.
        if not parentGui(sg) then
            sg:Destroy()
            return false
        end
        Frame.Name = "RevizBar"
        Frame.Parent = sg
        Frame.BackgroundColor3 = Color3.new(0.3, 0.1, 0.1)
        Frame.BackgroundTransparency = 0.3
        Frame.Position = UDim2.new(0.5, -110, 0, 10)
        Frame.Size = UDim2.new(0, 220, 0, 64)
        Frame.Active = true
        Frame.Draggable = true
        cmdbar.Name = "CMDBAR"
        cmdbar.Parent = Frame
        cmdbar.BackgroundColor3 = Color3.new(0.105882, 0.164706, 0.207843)
        cmdbar.BackgroundTransparency = 0.2
        cmdbar.Size = UDim2.new(1, -12, 0, 22)
        cmdbar.Position = UDim2.new(0, 6, 0, 4)
        cmdbar.Font = Enum.Font.SourceSansLight
        cmdbar.TextSize = 14
        cmdbar.TextColor3 = Color3.new(0.945098, 0.945098, 0.945098)
        cmdbar.PlaceholderColor3 = Color3.new(0.72, 0.72, 0.78)
        cmdbar.PlaceholderText = "type a command, then Enter"
        cmdbar.Text = ""
        -- The hint used to live in .Text, so clicking the box and typing
        -- appended to it and every command was garbage.
        cmdbar.ClearTextOnFocus = true
        cmdbar.TextScaled = false
        cmdbar.TextWrapped = false

        local status = Instance.new("TextLabel")
        status.Name = "Status"
        status.Parent = Frame
        status.BackgroundTransparency = 1
        status.Size = UDim2.new(1, -12, 0, 16)
        status.Position = UDim2.new(0, 6, 0, 28)
        status.Font = Enum.Font.SourceSans
        status.TextSize = 12
        status.TextColor3 = Color3.new(0.901961, 0.901961, 0.94902)
        status.TextXAlignment = Enum.TextXAlignment.Left
        status.Text = "ready"
        statusLabel = status

        local hint = Instance.new("TextLabel")
        hint.Name = "Hint"
        hint.Parent = Frame
        hint.BackgroundTransparency = 1
        hint.Size = UDim2.new(1, -12, 0, 14)
        hint.Position = UDim2.new(0, 6, 0, 46)
        hint.Font = Enum.Font.SourceSans
        hint.TextSize = 11
        hint.TextColor3 = Color3.new(0.72, 0.72, 0.78)
        hint.TextXAlignment = Enum.TextXAlignment.Left
        hint.Text = prefix .. " focuses  |  delcmdbar closes"
        hintLabel = hint

        cmdbar.FocusLost:Connect(function(enterPressed)
            if enterPressed then
                local entry = string.gsub(cmdbar.Text, "^%s+", "")
                entry = string.gsub(entry, "%s+$", "")
                if entry ~= "" then
                    Reviz.execute(entry)
                end
                cmdbar.Text = ""
            end
        end)

        local cmdsGui = Instance.new("ScreenGui")
        local cmdsFrame = Instance.new("Frame")
        local ScrollingFrame = Instance.new("ScrollingFrame")
        local TextLabel = Instance.new("TextLabel")
        local closegui = Instance.new("TextButton")
        cmdsGui.Name = "RevizAdminCMDS"
        cmdsGui.ResetOnSpawn = false
        cmdsGui.DisplayOrder = 10
        parentGui(cmdsGui)
        cmdsFrame.Name = "CMDSFRAME"
        cmdsFrame.Parent = cmdsGui
        cmdsFrame.Active = true
        cmdsFrame.BackgroundColor3 = Color3.new(0.223529, 0.231373, 0.309804)
        cmdsFrame.BorderSizePixel = 0
        cmdsFrame.Draggable = true
        cmdsFrame.Position = UDim2.new(0, 315, 0, 100)
        cmdsFrame.Size = UDim2.new(0, 275, 0, 275)
        cmdsFrame.Visible = false
        ScrollingFrame.Parent = cmdsFrame
        ScrollingFrame.BackgroundColor3 = Color3.new(0.160784, 0.160784, 0.203922)
        ScrollingFrame.BorderSizePixel = 0
        ScrollingFrame.Position = UDim2.new(0, 0, 0.0729999989, 0)
        ScrollingFrame.Size = UDim2.new(1, 0, 0.927, 0)
        ScrollingFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
        ScrollingFrame.AutomaticCanvasSize = Enum.AutomaticSize.Y
        ScrollingFrame.ScrollBarThickness = 6
        TextLabel.Parent = ScrollingFrame
        TextLabel.BackgroundColor3 = Color3.new(1, 1, 1)
        TextLabel.BackgroundTransparency = 1
        TextLabel.Size = UDim2.new(1, -6, 0, 0)
        TextLabel.AutomaticSize = Enum.AutomaticSize.Y
        TextLabel.Font = Enum.Font.SourceSans
        TextLabel.Text = "Current prefix: " .. prefix .. "\n\n" .. table.concat(Commands, ",\n") .. ",\n This list of commands is NOT showing everything, go to my thread in the pastebin link to see ALL commands."
        TextLabel.TextColor3 = Color3.new(1, 1, 1)
        TextLabel.TextSize = 15
        TextLabel.TextWrapped = true
        TextLabel.TextXAlignment = Enum.TextXAlignment.Left
        TextLabel.TextYAlignment = Enum.TextYAlignment.Top
        closegui.Name = "closegui"
        closegui.Parent = cmdsFrame
        closegui.BackgroundColor3 = Color3.new(0.890196, 0.223529, 0.0588235)
        closegui.BorderSizePixel = 0
        closegui.Position = UDim2.new(1, -28, 0, 4)
        closegui.Size = UDim2.new(0, 24, 0, 24)
        closegui.Font = Enum.Font.SourceSansBold
        closegui.Text = "X"
        closegui.TextColor3 = Color3.new(1, 1, 1)
        closegui.TextSize = 20

        closegui.MouseButton1Click:Connect(function()
            cmdsFrame.Visible = false
        end)

        ScreenGui = sg
        CMDBAR = cmdbar
        CMDS = cmdsGui
        CMDSFRAME = cmdsFrame
        revizGuiOpen = true
        return true
    end

    showCommandList = function()
        if revizGuiOpen and CMDSFRAME and CMDSFRAME.Parent then
            CMDSFRAME.Visible = true
        end
        if Reviz.onCommands then
            pcall(Reviz.onCommands)
            return
        end
        for _, entry in ipairs(Reviz.commands) do
            pcall(Reviz.log, entry)
        end
    end

    Reviz.commands = Commands

    function Reviz.getPrefix()
        return prefix
    end

    function Reviz.setPrefix(value)
        if type(value) == "string" and #value == 1 then
            prefix = value
        end
        return prefix
    end

    -- Accepts text with or without the prefix. `fromChat` marks Player.Chatted
    -- input, which is the only source that needs the re-entrancy guard.
    Reviz.execute = function(text, fromChat)
        if type(text) ~= "string" then return end
        text = string.gsub(text, "^%s+", "")
        text = string.gsub(text, "%s+$", "")
        if text == "" then return end
        if fromChat and executing then
            -- Stops ;spam / ;chat re-entering through Player.Chatted.
            return
        end
        local full = text
        -- The documented emergency command must work whatever the prefix is.
        if text == ";resetprefix" or text == "resetprefix" then
            full = prefix .. "resetprefix"
        else
            -- The original admin documents its commands with ';' while the
            -- live prefix is ':'. Accept either and rewrite it to the live
            -- prefix; blindly prepending produced ":;god", which matched no
            -- command but still reported "ok".
            local first = string.sub(text, 1, 1)
            if first == ";" or first == ":" then
                full = prefix .. string.sub(text, 2)
            elseif string.sub(text, 1, #prefix) ~= prefix then
                full = prefix .. text
            end
        end
        if full == prefix then return end
        if not isKnownCommand(full) then
            if not fromChat then
                warn("[reviz] unknown command: " .. tostring(full))
                pcall(Reviz.log, "[unknown] " .. text .. " (type cmds for the list)")
                setStatus("unknown: " .. text)
            end
            return
        end
        executing = true
        local token = {}
        executingToken = token
        -- A command that waits forever (:fly with no character) used to leave
        -- `executing` true, which silently discarded every later command.
        task.delay(EXECUTE_TIMEOUT, function()
            if executingToken == token then
                executing = false
                executingToken = nil
                warn("[reviz] command timed out: " .. tostring(full))
                pcall(Reviz.log, "[timeout] " .. tostring(full))
                setStatus("timeout: " .. tostring(full))
            end
        end)
        local ok, err = pcall(Execute, full)
        if executingToken == token then
            executing = false
            executingToken = nil
        end
        if ok then
            setStatus("ok: " .. full)
        else
            local message = tostring(err)
            warn("[reviz] " .. tostring(full) .. " failed: " .. message)
            pcall(Reviz.log, "[error] " .. message)
            setStatus("error: " .. message)
        end
    end

    Reviz.showCommands = function()
        showCommandList()
    end

    Reviz.isOpen = function(): boolean
        return revizGuiOpen and ScreenGui ~= nil and ScreenGui.Parent ~= nil
    end

    Reviz.open = function(): boolean
        if Reviz.isOpen() then return true end
        local ok, built = pcall(buildRevizGui)
        if not ok or built == false then
            local reason = if ok then "no GUI container available" else tostring(built)
            warn("[reviz] open failed: " .. reason)
            syncRevizToggle(false)
            ModMenu.Notify("Reviz Admin", "Could not open: " .. reason)
            return false
        end
        ModMenu.Notify("Reviz Admin", "Opened (press " .. prefix .. " to focus the bar).")
        return true
    end

    Reviz.close = function()
        local wasFlying = flying
        local hadState = revizGuiOpen or flying or noclip or spin
        revizGuiOpen = false
        destroyRevizGuis()
        statusLabel = nil
        hintLabel = nil
        -- Stop every transient loop the admin can leave running. Closing the
        -- GUI used to keep fly active (PlatformStand still on) together with
        -- its WASD listeners, so the player stayed floating with no bar left
        -- to type "unfly" into.
        spamming = false
        spammingpm = false
        cbring = false
        cbringall = false
        bringingmod = false
        bringingobj = false
        flying = false
        noclip = false
        spin = false
        followed = false
        traill = false
        annoying = false
        hwalk = false
        staring = false
        banpl = false
        changingstate = false
        chatlogs = false
        clickdel = false
        clickgoto = false
        gettingtools = false
        droppinghats = false
        droppingtools = false
        removingmeshhats = false
        removingmeshtool = false
        stopsitting = false

        for _, connection in ipairs(flyKeyConnections) do
            pcall(function() connection:Disconnect() end)
        end
        flyKeyConnections = {}

        -- Only touch the character when an admin state was actually active;
        -- a plain toggle at startup must not delete unrelated parts.
        if hadState then
            local char = lplayer and lplayer.Character
            local root = char and char:FindFirstChild("HumanoidRootPart")
            if root then
                destroyNamed(root, "RevizFlyBG")
                destroyNamed(root, "RevizFlyBV")
                destroyNamed(root, "Orbit")
                destroyNamed(root, "Fling")
                destroyNamed(root, "Spinner")
            end
            -- Only release PlatformStand if Reviz's own fly held it; otherwise a
            -- saved/menu Platform Stand setting would be cleared by a plain toggle.
            local humanoid = char and char:FindFirstChildOfClass("Humanoid")
            if wasFlying and humanoid then
                humanoid.PlatformStand = false
            end
        end
    end

    Reviz.toggle = function(state: boolean)
        if state then
            Reviz.open()
        else
            local wasOpen = revizGuiOpen
            Reviz.close()
            if wasOpen then
                ModMenu.Notify("Reviz Admin", "Closed.")
            end
        end
        -- Make the canonical menu state (and the saved config) match reality
        -- whichever entry point was used: menu toggle, console button or
        -- :delcmdbar. Skip the write when nothing actually changed.
        local actual = Reviz.isOpen()
        if ModMenu.State.toggles["utility.reviz"] ~= actual then
            syncRevizToggle(actual)
        end
    end

    on(lplayer.Chatted, function(msg)
        -- Ignore chat the script sent itself.
        local expiry = sentChat[msg]
        if expiry then
            sentChat[msg] = nil
            if os.clock() <= expiry then return end
        end
        if not Reviz.chatEnabled then return end
        local first = string.sub(msg, 1, 1)
        if first == prefix or first == ";" or first == ":" then
            Reviz.execute(msg, true)
        end
    end)

    -- Clean up any leftover Reviz GUIs from previous runs before toggle initializes
    destroyRevizGuis()

    -- Registered on the executor environment so the *next* execution of this
    -- bundle can tear this copy down (see the top of the module), and with the
    -- live-reload harness when it provides STATE.
    local function revizCleanup()
        revizAlive = false
        bringingmod = false
        bringingobj = false
        pcall(Reviz.close)
        for _, connection in ipairs(trackedConnections) do
            pcall(function() connection:Disconnect() end)
        end
        table.clear(trackedConnections)
        pcall(function() ModMenu.State.clearConnections("reviz") end)
        clearRemotes()
    end

    pcall(function()
        _G.__revizCleanup = revizCleanup
    end)
    if STATE and STATE.onCleanup then
        STATE.onCleanup(revizCleanup)
    end

    return Reviz
end)()

-- ===== src\init.luau =====
--!strict
-- init.luau
local C = ModMenu.UI.Components
local Panels = ModMenu.Menu.Panels
local T = ModMenu.Theme

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
	C.toggle(p, "utility.reviz", "Reviz Admin Remake", false, function(v) ModMenu.Features.Reviz.toggle(v) end)
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

-- Console (SakuraVibes999's Reviz Admin)
do
	local p = Panels.console
	local Reviz = ModMenu.Features.Reviz
	C.section(p, "SakuraVibes999's Reviz Admin")
	-- Deliberately a button, not a second toggle: two widgets sharing the
	-- "utility.reviz" id fought over the state and the saved config.
	C.button(p, "Open / Close Command Bar", function()
		Reviz.toggle(not Reviz.isOpen())
	end)

	local info = Instance.new("TextLabel")
	info.Size = UDim2.new(1, -8, 0, 34)
	info.BackgroundTransparency = 1
	info.TextWrapped = true
	info.TextXAlignment = Enum.TextXAlignment.Left
	info.TextYAlignment = Enum.TextYAlignment.Top
	info.TextColor3 = T.text
	info.Font = T.font
	info.TextSize = 12
	info.Text = "Type a command and press Enter. The prefix key (" .. Reviz.getPrefix() .. ") opens this tab and focuses the box."
	info.Parent = p
	T.textStroke(info, 0.65)

	local input = Instance.new("TextBox")
	input.Size = UDim2.new(1, -8, 0, 30)
	input.BackgroundColor3 = T.surface
	input.TextColor3 = T.text
	input.PlaceholderText = "command, e.g. god / goto bob / speed 30"
	input.PlaceholderColor3 = T.muted
	input.Font = T.font
	input.TextSize = 13
	input.Text = ""
	input.ClearTextOnFocus = false
	input.BorderSizePixel = 0
	input.Parent = p
	T.corner(input, 6)
	ModMenu.Menu.ConsoleInput = input

	local output = Instance.new("TextLabel")
	output.Size = UDim2.new(1, -8, 0, 0)
	output.AutomaticSize = Enum.AutomaticSize.Y
	output.BackgroundTransparency = 1
	output.TextWrapped = true
	output.TextXAlignment = Enum.TextXAlignment.Left
	output.TextYAlignment = Enum.TextYAlignment.Top
	output.TextColor3 = T.textSecondary
	output.Font = T.font
	output.TextSize = 12
	output.Text = ""
	output.Parent = p
	T.textStroke(output, 0.7)

	local lines = {}
	local function render()
		output.Text = table.concat(lines, "\n")
	end
	Reviz.log = function(text)
		table.insert(lines, tostring(text))
		while #lines > 200 do
			table.remove(lines, 1)
		end
		render()
	end
	Reviz.onCommands = function()
		for _, entry in ipairs(Reviz.commands) do
			Reviz.log(entry)
		end
	end

	local function run(text)
		text = tostring(text or ""):gsub("^%s+", ""):gsub("%s+$", "")
		if text == "" then return end
		Reviz.log("> " .. text)
		Reviz.execute(text)
	end

	input.FocusLost:Connect(function(enterPressed)
		if enterPressed then
			run(input.Text)
			input.Text = ""
		end
	end)

	C.button(p, "Run Command", function()
		run(input.Text)
		input.Text = ""
	end)
	C.button(p, "List Commands", function() Reviz.showCommands() end)
	C.button(p, "Clear Output", function()
		lines = {}
		render()
	end)
	C.toggle(p, "reviz.chat", "Chat Commands", true, function(v) Reviz.chatEnabled = v end)

	C.section(p, "Quick Commands")
	C.button(p, "Godmode", function() run("god") end)
	C.button(p, "Noclip", function() run("noclip") end)
	C.button(p, "Clip", function() run("clip") end)
	C.button(p, "Invisible", function() run("invisible") end)
	C.button(p, "Fly", function() run("fly") end)
	C.button(p, "Unfly", function() run("unfly") end)
	C.button(p, "Dex Explorer", function() run("explorer") end)
	C.button(p, "Save Position", function() run("savepos") end)
	C.button(p, "Load Position", function() run("loadpos") end)
	C.button(p, "Respawn", function() run("respawn") end)
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
	C.button(p, "Save Settings", function()
		pcall(ModMenu.Config.save)
		ModMenu.Notify("Settings", "Saved")
	end)
	C.button(p, "Reset Toggles", function()
		for k in ModMenu.State.toggles do
			ModMenu.State.toggles[k] = false
		end
		pcall(ModMenu.Config.save)
		ModMenu.Notify("Settings", "Toggles reset (reload to apply)")
	end)
end

ModMenu.Menu.applyZOrder()
ModMenu.Notify("Mod Menu", "Loaded. Press " .. ModMenu.State.settings.openKey.Name .. " to open.")
-- init complete
