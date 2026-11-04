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
	btn.Parent = row

	local function refresh()
		btn.Text = state and "ON" or "OFF"
		btn.BackgroundColor3 = state and Theme.success or Theme.surface
		btn.TextColor3 = Theme.text
	end
	refresh()

	btn.MouseButton1Click:Connect(function()
		state = not state
		ModMenu.State.toggles[id] = state
		refresh()
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

	bar.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			dragging = true
		end
	end)
	S.UserInputService.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			dragging = false
			pcall(ModMenu.Config.save)
		end
	end)
	S.UserInputService.InputChanged:Connect(function(input)
		if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
			local pct = math.clamp((input.Position.X - bar.AbsolutePosition.X) / bar.AbsoluteSize.X, 0, 1)
			setValue(min + (max - min) * pct)
		end
	end)

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

	local btn = Instance.new("TextButton")
	btn.Size = UDim2.new(0.6, 0, 1, -4)
	btn.Position = UDim2.new(0.4, 0, 0, 2)
	btn.BackgroundColor3 = Theme.surface
	btn.TextColor3 = Theme.text
	btn.Font = Theme.font
	btn.TextSize = 13
	btn.BorderSizePixel = 0
	Theme.corner(btn, 6)
	btn.Parent = row

	local savedString = ModMenu.State.strings[id]
	local selected = if savedString ~= nil then savedString else (initial or items[1] or "")
	btn.Text = selected
	local open = false
	local list = Instance.new("ScrollingFrame")
	list.Size = UDim2.new(0.6, 0, 0, math.min(#items * 22, 120))
	list.Position = UDim2.new(0.4, 0, 1, 0)
	list.BackgroundColor3 = Theme.panel
	list.BorderSizePixel = 0
	list.Visible = false
	list.ZIndex = 20
	list.ScrollBarThickness = 4
	Theme.corner(list, 6)
	list.Parent = row

	for i, item in items do
		local b = Instance.new("TextButton")
		b.Size = UDim2.new(1, 0, 0, 22)
		b.Position = UDim2.new(0, 0, 0, (i - 1) * 22)
		b.BackgroundColor3 = Theme.surface
		b.TextColor3 = Theme.text
		b.Font = Theme.font
		b.TextSize = 13
		b.Text = item
		b.BorderSizePixel = 0
		b.Parent = list
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
ModMenu.UI.Components = {
	button = button,
	toggle = toggle,
	slider = slider,
	section = section,
	dropdown = dropdown,
}
