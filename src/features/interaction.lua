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