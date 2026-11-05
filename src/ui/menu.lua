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
local BACKGROUND_FILE = "ModMenuBackground.png" -- file in the executor's workspace folder
local BACKGROUND_ASSET_ID = "86915755447721"

-- Returns (content id or nil, source tag "custom" | "rbxassetid" | "none").
local function resolveBackgroundImage(): (string?, string)
	local custom = getcustomasset or getsynasset
	if custom then
		local ok, cid = pcall(custom, BACKGROUND_FILE)
		if ok and type(cid) == "string" and cid ~= "" then
			return cid, "custom"
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

local sidebar = Instance.new("Frame")
sidebar.Size = UDim2.new(0, 120, 1, -30)
sidebar.Position = UDim2.new(0, 0, 0, 30)
sidebar.BackgroundColor3 = Theme.panel
sidebar.BackgroundTransparency = 0.3
sidebar.BorderSizePixel = 0
sidebar.ZIndex = 2
sidebar.Parent = root

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
	btn.Size = UDim2.new(1, -8, 0, 26)
	btn.Position = UDim2.new(0, 4, 0, 4 + (i - 1) * 30)
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
	-- Reviz prefix key opens the Console tab and focuses its command box.
	local reviz = ModMenu.Features and ModMenu.Features.Reviz
	if reviz and reviz.getPrefix then
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
