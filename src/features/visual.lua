--!strict
-- features/visual.luau
local S = ModMenu.Services
local Lighting = S.Lighting
local RunService = S.RunService

ModMenu.Features = ModMenu.Features or {}
ModMenu.Features.Visual = {}

-- Snapshot the Lighting properties we may change once, so disabling restores
-- the game's own values instead of hard-coded guesses.
local function lightingOriginal()
	if not ModMenu.State.lightingOriginal then
		ModMenu.State.lightingOriginal = {
			Brightness = Lighting.Brightness,
			ClockTime = Lighting.ClockTime,
			GlobalShadows = Lighting.GlobalShadows,
			FogEnd = Lighting.FogEnd,
			FogStart = Lighting.FogStart,
		}
	end
	return ModMenu.State.lightingOriginal
end

-- Fullbright and Remove Fog both touch fog, so recompute the whole Lighting
-- state from the current toggles rather than each one blindly overwriting.
-- Anti-Lag (world.luau) also writes into this state so the three do not fight.
local function refreshLighting()
	local o = lightingOriginal()
	local fullbright = ModMenu.State.toggles["visual.fullbright"] == true
	local removeFog = ModMenu.State.toggles["visual.removeFog"] == true
	local antiLag = ModMenu.State.toggles["world.antiLag"] == true

	Lighting.Brightness = if fullbright then 2 else o.Brightness
	Lighting.GlobalShadows = if (fullbright or antiLag) then false else o.GlobalShadows

	if fullbright then
		Lighting.ClockTime = 14
	elseif ModMenu.State.touched["visual.clock"] then
		Lighting.ClockTime = ModMenu.State.numbers["visual.clock"]
	else
		Lighting.ClockTime = o.ClockTime
	end

	if fullbright or removeFog or antiLag then
		Lighting.FogEnd = 1e5
		Lighting.FogStart = 0
	else
		Lighting.FogEnd = o.FogEnd
		Lighting.FogStart = o.FogStart
	end
end

-- Shared so the World tab's Anti-Lag can re-derive the same state instead of
-- clobbering it, and so restoring snapshots the map's real values. Re-applying
-- the lighting on load/respawn is not needed (toggles drive it).
ModMenu.Features.Visual.refreshLighting = refreshLighting

ModMenu.Features.Visual.fullbright = function(_enabled: boolean)
	refreshLighting()
end

ModMenu.Features.Visual.removeFog = function(_enabled: boolean)
	refreshLighting()
end

ModMenu.Features.Visual.setFOV = function(value: number)
	local cam = S.Workspace.CurrentCamera
	if cam then cam.FieldOfView = value end
end

ModMenu.Features.Visual.setClockTime = function(value: number)
	-- The slider already stored `value`; just re-derive the Lighting state.
	refreshLighting()
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
		local existing = char:FindFirstChild("ModMenuESP")
		if existing then return end
		local hl = Instance.new("Highlight")
		hl.Name = "ModMenuESP"
		hl.FillTransparency = 0.5
		hl.OutlineTransparency = 0
		hl.FillColor = ModMenu.Theme.accent()
		hl.Parent = char
	end
	for _, p in S.Players:GetPlayers() do
		if p ~= S.Players.LocalPlayer and p.Character then applyTo(p.Character) end
	end
	-- The Heartbeat pass already adds/removes highlights for every player,
	-- including respawns and joins, so no per-player CharacterAdded tracking is
	-- needed (that would leak a connection for every player who left).
	-- It is throttled to a few checks per second: a per-frame sweep over every
	-- player is pure overhead for a purely visual effect.
	local nextScan = 0
	local conn = RunService.Heartbeat:Connect(function()
		local now = os.clock()
		if now < nextScan then
			return
		end
		nextScan = now + 0.25
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
	table.insert(ModMenu.State.getConnections(id), conn)
end
