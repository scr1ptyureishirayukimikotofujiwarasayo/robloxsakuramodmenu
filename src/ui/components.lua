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
		local list = ModMenu.UI.toggleApply[id]
		if not list then
			list = {}
			ModMenu.UI.toggleApply[id] = list
		end
		-- The same id can appear on two panels (Home + Visual "Fullbright").
		-- Registering the identical callback twice would apply the feature
		-- twice on every reset/restore, so keep only one copy of it.
		local already = false
		for _, existing in list do
			if existing == apply then
				already = true
				break
			end
		end
		if not already then
			table.insert(list, apply)
		end
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
		ModMenu.State.touched[id] = true
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
	-- Register the callback so init.luau can re-apply sliders the user has
	-- previously touched (respawn / restore), without firing on load otherwise.
	if apply then
		ModMenu.UI.numberApply[id] = ModMenu.UI.numberApply[id] or {}
		table.insert(ModMenu.UI.numberApply[id], apply)
	end
	-- Let callers update the UI value without marking it "touched" or firing apply.
	ModMenu.UI.sliderSet[id] = function(v: number)
		render(v)
	end
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
	list.BackgroundColor3 = Theme.panel
	list.BorderSizePixel = 0
	list.Visible = false
	list.ZIndex = 200
	list.ScrollBarThickness = 6
	list.AutomaticCanvasSize = Enum.AutomaticSize.Y
	list.CanvasSize = UDim2.new(0, 0, 0, #items * 22)
	Theme.corner(list, 6)
	local listLayout = Instance.new("UIListLayout")
	listLayout.Padding = UDim.new(0, 1)
	listLayout.SortOrder = Enum.SortOrder.LayoutOrder
	listLayout.Parent = list
	-- Host the options in the ScreenGui, not the scrolling row/panel: a panel's
	-- ClipsDescendants would otherwise slice a dropdown near the bottom in half.
	local host = (ModMenu.Menu and ModMenu.Menu.ScreenGui) or row
	list.Parent = host

	local function placeList()
		local maxHeight = math.min(#items * 22, 160)
		local inset = 0
		local okInset, guiInset = pcall(function()
			return game:GetService("GuiService"):GetGuiInset()
		end)
		if okInset and typeof(guiInset) == "Vector2" then
			inset = guiInset.Y
		end
		list.Size = UDim2.fromOffset(btn.AbsoluteSize.X, maxHeight)
		list.Position = UDim2.fromOffset(btn.AbsolutePosition.X, btn.AbsolutePosition.Y + btn.AbsoluteSize.Y - inset)
		list.CanvasSize = UDim2.new(0, 0, 0, #items * 22)
	end

	local function setOpen(value: boolean)
		open = value
		if value then placeList() end
		list.Visible = value
	end

	local function buildItems(newItems: { string })
		items = newItems
		for _, child in list:GetChildren() do
			if child:IsA("TextButton") then
				child:Destroy()
			end
		end
		list.CanvasSize = UDim2.new(0, 0, 0, #items * 22)
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
				setOpen(false)
				ModMenu.State.strings[id] = selected
				if apply then pcall(apply, selected) end
				pcall(ModMenu.Config.save)
			end)
		end
		if open then placeList() end
	end
	buildItems(items)
	-- Let callers repopulate the options (e.g. as players join/leave).
	ModMenu.UI.dropdowns[id] = { refresh = buildItems }
	-- Let callers update the shown selection without firing apply (config wipe).
	ModMenu.UI.dropdownSet[id] = function(v: string)
		selected = v
		btn.Text = v
	end

	btn.MouseButton1Click:Connect(function()
		if not open and ModMenu.UI.hideDropdowns then
			ModMenu.UI.hideDropdowns() -- only one dropdown open at a time
		end
		setOpen(not open)
	end)
	table.insert(ModMenu.UI.dropdownLists, function() setOpen(false) end)

	ModMenu.State.strings[id] = selected
	-- Do not run apply() at construction: a dropdown's default item was switching
	-- the camera to the first player and firing a player-info notification on load.
	return row
end

ModMenu.UI = ModMenu.UI or {}
-- Reset per-run registries. Do NOT `or`-keep these: on a re-execute the old
-- closures would otherwise linger and fire against destroyed widgets/features.
ModMenu.UI.toggleSync = {}
ModMenu.UI.toggleApply = {}
ModMenu.UI.numberApply = {}
ModMenu.UI.dropdowns = {}
ModMenu.UI.dropdownLists = {}
-- Live widget setters, so callers can push values back into the UI (e.g. Reset
-- Movement / Wipe Config) without re-triggering the feature callbacks.
ModMenu.UI.sliderSet = {}
ModMenu.UI.dropdownSet = {}
-- Close every open dropdown option list (called when the menu closes or the
-- tab switches, since the lists now live in the ScreenGui rather than a panel).
ModMenu.UI.hideDropdowns = function()
	for _, hide in ModMenu.UI.dropdownLists do
		pcall(hide)
	end
end
ModMenu.UI.Components = {
	button = button,
	toggle = toggle,
	slider = slider,
	section = section,
	dropdown = dropdown,
}
