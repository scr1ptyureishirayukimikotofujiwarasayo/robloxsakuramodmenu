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
	ModMenu.State.noclipOriginal = ModMenu.State.noclipOriginal or {}
	if not enabled then
		-- Restore the original CanCollide of every part we changed (not a blanket
		-- `true`, which would wrongly collide HumanoidRootPart/accessories).
		for part, original in ModMenu.State.noclipOriginal do
			if part and part.Parent then
				part.CanCollide = original
			end
		end
		table.clear(ModMenu.State.noclipOriginal)
		return
	end
	local function applyNoclip()
		local c = char()
		if not c then return end
		for _, part in c:GetDescendants() do
			if part:IsA("BasePart") then
				if ModMenu.State.noclipOriginal[part] == nil then
					ModMenu.State.noclipOriginal[part] = part.CanCollide
				end
				part.CanCollide = false
			end
		end
	end
	applyNoclip()
	local conn = RunService.Stepped:Connect(applyNoclip)
	table.insert(ModMenu.State.getConnections(id), conn)
end

ModMenu.Features.Movement.float = function(enabled: boolean)
	local id = "movement.float"
	ModMenu.State.clearConnections(id)
	if not enabled then
		local r = root()
		local bp = r and r:FindFirstChild("ModMenuFloat")
		if bp then bp:Destroy() end
		return
	end
	local r = root()
	if not r then return end
	local bodyPosition = Instance.new("BodyPosition")
	bodyPosition.Name = "ModMenuFloat"
	bodyPosition.MaxForce = Vector3.new(0, 1e5, 0)
	bodyPosition.Position = r.Position
	bodyPosition.Parent = r
	local conn = RunService.RenderStepped:Connect(function()
		local r2 = root()
		if not r2 then return end
		-- Re-attach after respawn: the old root (and the parented BodyPosition)
		-- was destroyed, so `bodyPosition.Parent` is nil on the new character.
		if bodyPosition.Parent ~= r2 then bodyPosition.Parent = r2 end
		bodyPosition.Position = Vector3.new(r2.Position.X, bodyPosition.Position.Y, r2.Position.Z)
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
	-- Forget custom slider values so a respawn does not re-apply them.
	ModMenu.State.touched["player.walkspeed"] = nil
	ModMenu.State.touched["player.jumppower"] = nil
	ModMenu.State.touched["character.hipHeight"] = nil
	ModMenu.Features.Movement.setGravity(196.2)
end

-- Re-apply the movement-stat sliders the user actually changed after a respawn.
-- The game resets WalkSpeed/JumpPower/HipHeight on the new Humanoid, so without
-- this the sliders would show their value while the stats silently reverted.
table.insert(ModMenu.State.getConnections("movement.respawn"), S.Players.LocalPlayer.CharacterAdded:Connect(function(character: Model)
	local h = character:WaitForChild("Humanoid", 5)
	if not h or not h:IsA("Humanoid") then return end
	if ModMenu.State.touched["player.walkspeed"] then
		h.WalkSpeed = ModMenu.State.numbers["player.walkspeed"]
	end
	if ModMenu.State.touched["player.jumppower"] then
		h.JumpPower = ModMenu.State.numbers["player.jumppower"]
	end
	if ModMenu.State.touched["character.hipHeight"] then
		h.HipHeight = ModMenu.State.numbers["character.hipHeight"]
	end
end))
