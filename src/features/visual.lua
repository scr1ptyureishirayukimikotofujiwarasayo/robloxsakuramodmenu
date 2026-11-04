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
		p.CharacterAdded:Connect(function(c) if ModMenu.State.toggles["visual.esp"] then applyTo(c) end end)
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
