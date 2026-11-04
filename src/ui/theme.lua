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
	text = Color3.fromRGB(235, 235, 240),
	muted = Color3.fromRGB(150, 150, 165),
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
ModMenu.Theme.accent = function()
	return ModMenu.State.settings.accent
end
