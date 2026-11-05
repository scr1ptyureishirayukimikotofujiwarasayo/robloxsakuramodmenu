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