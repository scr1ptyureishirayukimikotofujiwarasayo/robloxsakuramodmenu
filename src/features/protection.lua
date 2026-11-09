--!strict
-- features/protection.luau
local S = ModMenu.Services
local RunService = S.RunService
local Players = S.Players
local UserInputService = S.UserInputService
local Workspace = S.Workspace

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

-- ---------------------------------------------------------------------------
-- Player Guard: AFK proximity protection.
--
-- While AFK (no user input for `protection.guardAfk` seconds) any other player
-- entering `protection.guardRadius` triggers an escape teleport
-- `protection.guardEscape` studs away from that player. Destinations are
-- raycast-validated (mostly clear path + walkable ground) so an escape never
-- lands in the void; when no direction qualifies it recovers to the last spot
-- where solid ground was underfoot, and does nothing if even that is gone.
-- An anti-void watchdog also restores that spot if you start falling while
-- AFK (pushed off a cliff, failed escape, void teleport). "Trigger: Always"
-- keeps the escape guard running even while you are active.
-- ---------------------------------------------------------------------------

local GUARD_SCAN_INTERVAL = 0.25
local GUARD_COOLDOWN = 3
local GUARD_MIN_SAFE_Y_DROP = 60 -- studs below the last grounded spot before the watchdog cares

local function guardRayParams(exclude: { Instance }): RaycastParams
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = exclude
	pcall(function()
		-- Decorative non-colliding parts must never count as ground or walls.
		params.RespectCanCollide = true
	end)
	return params
end

local function playerCharacters(): { Instance }
	local list: { Instance } = {}
	for _, plr in Players:GetPlayers() do
		local c = plr.Character
		if c then
			table.insert(list, c)
		end
	end
	return list
end

-- Fewest studs of a chest-height ray can travel from `from` toward `to`
-- before something blocks it.
local function clearPathLength(from: Vector3, to: Vector3, exclude: { Instance }): number
	local delta = to - from
	local hit = Workspace:Raycast(from, delta, guardRayParams(exclude))
	if hit then
		return (hit.Position - from).Magnitude
	end
	return delta.Magnitude
end

-- Lands `pos` on verified walkable ground, or nil when there is none (void,
-- water, decorative parts, below the part-destroying plane).
local function groundLanding(pos: Vector3, exclude: { Instance }): Vector3?
	local hit = Workspace:Raycast(pos + Vector3.new(0, 80, 0), Vector3.new(0, -320, 0), guardRayParams(exclude))
	if not hit then
		return nil
	end
	if not hit.Instance.CanCollide or hit.Normal.Y < 0.5 then
		return nil
	end
	local landing = hit.Position + Vector3.new(0, 3, 0)
	if landing.Y < Workspace.FallenPartsDestroyHeight + 50 then
		return nil
	end
	return landing
end

-- Nearest alive other player within `radius`, or nil.
local function nearestThreat(myPos: Vector3, radius: number): (string?, Vector3?)
	local bestName: string? = nil
	local bestPos: Vector3? = nil
	local nearest = radius
	for _, plr in Players:GetPlayers() do
		if plr ~= Players.LocalPlayer then
			local c = plr.Character
			local ph = c and c:FindFirstChildOfClass("Humanoid")
			local pr = c and c:FindFirstChild("HumanoidRootPart")
			if ph and pr and ph.Health > 0 and pr:IsA("BasePart") then
				local d = (pr.Position - myPos).Magnitude
				if d < nearest then
					nearest = d
					bestName = plr.Name
					bestPos = pr.Position
				end
			end
		end
	end
	return bestName, bestPos
end

-- "Directly away" from the threat first, then spread out to the sides. A
-- candidate wins when its horizontal path is mostly clear AND it lands on
-- verified ground; the best partial result is kept as a secondary fallback.
local function escapeDestination(originPos: Vector3, threatPos: Vector3, fallbackPos: Vector3?, distance: number): Vector3?
	local exclude = playerCharacters()
	local away = Vector3.new(originPos.X - threatPos.X, 0, originPos.Z - threatPos.Z)
	if away.Magnitude < 0.1 then
		away = Vector3.new(1, 0, 0) -- stacked exactly on top of each other
	end
	local baseAngle = math.atan2(away.Z, away.X)
	local chest = originPos + Vector3.new(0, 2, 0)

	local bestPos: Vector3? = nil
	local bestStop = -1
	for _, offset in { 0, 20, -20, 40, -40, 60, -60, 80, -80 } do
		local angle = baseAngle + math.rad(offset + math.random(-8, 8))
		local dir = Vector3.new(math.cos(angle), 0, math.sin(angle))
		local pathLen = clearPathLength(chest, chest + dir * distance, exclude)
		local stop = if pathLen >= distance then distance else pathLen - 4
		if stop < 8 then
			continue -- blocked almost immediately; try another angle
		end
		local landing = groundLanding(originPos + dir * stop, exclude)
		if landing and stop >= distance * 0.5 then
			return landing -- clear-ish path and safe ground: done
		end
		if landing and stop > bestStop then
			bestPos = landing
			bestStop = stop
		end
	end
	if bestPos then
		return bestPos
	end
	-- Nothing around has ground (ledge/void): recover to where we last stood
	-- on something solid, re-validated against the current world.
	if fallbackPos then
		return groundLanding(fallbackPos, exclude)
	end
	return nil
end

local function guardTeleport(r: BasePart, pos: Vector3)
	ModMenu.Features.Protection.bypass(1) -- never fight our own anti-teleport
	pcall(function()
		r.CFrame = CFrame.new(pos)
		r.AssemblyLinearVelocity = Vector3.zero
		r.AssemblyAngularVelocity = Vector3.zero
	end)
end

ModMenu.Features.Protection.playerGuard = function(enabled: boolean)
	local id = "protection.playerGuard"
	ModMenu.State.clearConnections(id)
	if not enabled then
		return
	end

	local lastActivity = os.clock()
	local nextScan = 0
	local cooldownUntil = 0
	local lastGrounded: Vector3? = nil

	-- Any input counts as presence, including clicks on the menu itself
	-- (gameProcessed is deliberately ignored here).
	local function markActive()
		lastActivity = os.clock()
	end
	table.insert(ModMenu.State.getConnections(id), UserInputService.InputBegan:Connect(markActive))
	table.insert(ModMenu.State.getConnections(id), UserInputService.InputChanged:Connect(markActive))

	local conn = RunService.Heartbeat:Connect(function()
		local r = root()
		local h = hum()
		if r and h and h.FloorMaterial ~= Enum.Material.Air then
			lastGrounded = r.Position -- last spot with solid ground underfoot
		end

		local now = os.clock()
		if now < nextScan then
			return
		end
		nextScan = now + GUARD_SCAN_INTERVAL
		if now < cooldownUntil then
			return
		end

		local afkFor = math.max(ModMenu.State.numbers["protection.guardAfk"] or 60, 5)
		local isAfk = (now - lastActivity) >= afkFor
		local mode = ModMenu.State.strings["protection.guardMode"] or "AFK Only"
		if not isAfk and mode ~= "Always" then
			return
		end
		if not r or not h or h.Health <= 0 then
			return
		end

		-- Anti-void watchdog (AFK only, so normal falls never trip it): once we
		-- are clearly falling below the last grounded spot, or close to the
		-- part-destroying plane, snap back to verified safe ground.
		if isAfk and lastGrounded then
			local killPlane = Workspace.FallenPartsDestroyHeight
			local nearVoid = killPlane > -1e9 and r.Position.Y < killPlane + 60
			local fallingOut = r.Position.Y < lastGrounded.Y - GUARD_MIN_SAFE_Y_DROP
				and h.FloorMaterial == Enum.Material.Air
				and r.AssemblyLinearVelocity.Y < -10
			if nearVoid or fallingOut then
				local safe = groundLanding(lastGrounded, playerCharacters())
				cooldownUntil = now + GUARD_COOLDOWN
				if safe then
					guardTeleport(r, safe)
					ModMenu.Notify("Player Guard", "Anti-void: restored to safe ground")
				else
					lastGrounded = nil -- world changed under the old spot; forget it
				end
				return
			end
		end

		local radius = math.clamp(ModMenu.State.numbers["protection.guardRadius"] or 30, 5, 200)
		local threatName, threatPos = nearestThreat(r.Position, radius)
		if not threatPos then
			return
		end

		local distance = math.clamp(ModMenu.State.numbers["protection.guardEscape"] or 150, 25, 1000)
		local dest = escapeDestination(r.Position, threatPos, lastGrounded, distance)
		if not dest then
			cooldownUntil = now + GUARD_COOLDOWN
			ModMenu.Notify("Player Guard", "No safe ground to escape to - staying put")
			return
		end
		guardTeleport(r, dest)
		cooldownUntil = now + GUARD_COOLDOWN
		ModMenu.Notify("Player Guard", `Escaped from {threatName or "a player"}`)
	end)
	table.insert(ModMenu.State.getConnections(id), conn)
end

-- One-shot escape toward the nearest player inside the detect radius, so the
-- destination logic can be verified in-game without waiting out the AFK timer.
ModMenu.Features.Protection.guardTest = function()
	local r = root()
	if not r then
		ModMenu.Notify("Player Guard", "No character to move")
		return
	end
	local radius = math.clamp(ModMenu.State.numbers["protection.guardRadius"] or 30, 5, 200)
	local threatName, threatPos = nearestThreat(r.Position, radius)
	if not threatPos then
		ModMenu.Notify("Player Guard", "No players within range")
		return
	end
	local distance = math.clamp(ModMenu.State.numbers["protection.guardEscape"] or 150, 25, 1000)
	local dest = escapeDestination(r.Position, threatPos, nil, distance)
	if not dest then
		ModMenu.Notify("Player Guard", "No safe ground found")
		return
	end
	guardTeleport(r, dest)
	ModMenu.Notify("Player Guard", `Test escape from {threatName or "a player"}`)
end