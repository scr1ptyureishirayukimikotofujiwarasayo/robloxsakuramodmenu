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
