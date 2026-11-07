--!strict
-- features/character.luau
local S = ModMenu.Services

ModMenu.Features = ModMenu.Features or {}
ModMenu.Features.Character = {}

ModMenu.State.originalPlatformStand = ModMenu.State.originalPlatformStand or {}
ModMenu.State.invisibleOriginal = ModMenu.State.invisibleOriginal or {}
ModMenu.State.hiddenLimbState = ModMenu.State.hiddenLimbState or {}
ModMenu.State.blockedHatMeshes = ModMenu.State.blockedHatMeshes or {}
ModMenu.State.blockedHatParts = ModMenu.State.blockedHatParts or {}

local function char()
	return S.Players.LocalPlayer.Character
end
local function hum(): Humanoid?
	local c = char()
	if c then return c:FindFirstChildOfClass("Humanoid") end
	return nil
end

ModMenu.Features.Character.platformStand = function(enabled: boolean)
	local h = hum()
	if not h then return end
	if enabled then
		ModMenu.State.originalPlatformStand[h] = h.PlatformStand
		h.PlatformStand = true
	else
		local original = ModMenu.State.originalPlatformStand[h]
		h.PlatformStand = if original ~= nil then original else false
		ModMenu.State.originalPlatformStand[h] = nil
	end
end

ModMenu.Features.Character.view = function(tagetName: string?)
	local camera = S.Workspace.CurrentCamera
	if not camera then return end
	if not tagetName or tagetName == "" then
		if S.Players.LocalPlayer.Character then
			local h = S.Players.LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
			if h then camera.CameraSubject = h end
		end
		return
	end
	local target = S.Players:FindFirstChild(tagetName)
	if target and target.Character then
		local h = target.Character:FindFirstChildOfClass("Humanoid")
		if h then camera.CameraSubject = h end
	end
end

-- Cover both rigs: R6 uses "Left Arm"/"Left Leg", R15 uses the segmented
-- Upper/Lower/Hand (and Foot) names. FindFirstChild picks whichever exists, so
-- listing both is safe and makes the toggles work on default (R15) avatars.
local R6 = {
	arms = { "Left Arm", "Right Arm" },
	legs = { "Left Leg", "Right Leg" },
}
local R15 = {
	arms = { "LeftUpperArm", "LeftLowerArm", "LeftHand", "RightUpperArm", "RightLowerArm", "RightHand" },
	legs = { "LeftUpperLeg", "LeftLowerLeg", "LeftFoot", "RightUpperLeg", "RightLowerLeg", "RightFoot" },
}
local function concat(...: { string }): { string }
	local out = {}
	for _, list in { ... } do
		for _, name in list do
			table.insert(out, name)
		end
	end
	return out
end
local limbNames = {
	all = concat(R6.arms, R6.legs, R15.arms, R15.legs),
	arms = concat(R6.arms, R15.arms),
	legs = concat(R6.legs, R15.legs),
}

-- Hide limbs with Transparency/CanCollide rather than unparenting them: removing
-- a limb from the model breaks its Motor6D and can leave the character tumbling.
-- Originals are stored per-part and the desired visibility is recomputed from
-- the toggles each time, so "No Limbs" and "No Arms"/"No Legs" combine correctly
-- instead of one toggle's off-state restoring the other's limbs.
local function applyLimbGroup(names: { string }, hide: boolean)
	local c = char()
	if not c then return end
	for _, limbName in names do
		local limb = c:FindFirstChild(limbName)
		if not limb or not limb:IsA("BasePart") then continue end
		if hide then
			if ModMenu.State.hiddenLimbState[limb] == nil then
				ModMenu.State.hiddenLimbState[limb] = {
					transparency = limb.Transparency,
					collide = limb.CanCollide,
				}
			end
			limb.Transparency = 1
			limb.CanCollide = false
		else
			local saved = ModMenu.State.hiddenLimbState[limb]
			if saved then
				limb.Transparency = saved.transparency
				limb.CanCollide = saved.collide
				ModMenu.State.hiddenLimbState[limb] = nil
			end
		end
	end
end

local function refreshLimbs()
	local noLimbs = ModMenu.State.toggles["character.nolimbs"] == true
	local noArms = noLimbs or ModMenu.State.toggles["character.noarms"] == true
	local noLegs = noLimbs or ModMenu.State.toggles["character.nolegs"] == true
	applyLimbGroup(limbNames.all, noLimbs)
	applyLimbGroup(limbNames.arms, noArms)
	applyLimbGroup(limbNames.legs, noLegs)
end

-- Public entry point used by the three limb toggles. Recomputes every group from
-- the current toggle state instead of honouring a single per-limb owner.
ModMenu.Features.Character.setLimbs = function(_mode: string?, _enabled: boolean)
	refreshLimbs()
end

ModMenu.Features.Character.refreshLimbs = refreshLimbs

ModMenu.Features.Character.invisible = function(enabled: boolean)
	local c = char()
	if not c then return end
	local h = c:FindFirstChildOfClass("Humanoid")
	if enabled then
		for _, part in c:GetDescendants() do
			if part:IsA("BasePart") or part:IsA("Decal") then
				if ModMenu.State.invisibleOriginal[part] == nil then
					ModMenu.State.invisibleOriginal[part] = part.Transparency
				end
				part.Transparency = 1
			end
		end
		-- Also hide the engine nametag/health bar, otherwise an "invisible" player
		-- still shows a floating name above everyone else's screen.
		if h then
			if ModMenu.State.invisibleDisplay == nil then
				ModMenu.State.invisibleDisplay = {
					name = h.NameDisplayDistance,
					health = h.HealthDisplayDistance,
				}
			end
			h.NameDisplayDistance = 0
			h.HealthDisplayDistance = 0
		end
	else
		for part, value in ModMenu.State.invisibleOriginal do
			if part and part.Parent then
				part.Transparency = value
			end
		end
		table.clear(ModMenu.State.invisibleOriginal)
		if h and ModMenu.State.invisibleDisplay then
			h.NameDisplayDistance = ModMenu.State.invisibleDisplay.name
			h.HealthDisplayDistance = ModMenu.State.invisibleDisplay.health
		end
		ModMenu.State.invisibleDisplay = nil
	end
end

ModMenu.Features.Character.blockHats = function(enabled: boolean)
	local c = char()
	if not c then return end
	if enabled then
		for _, accessory in c:GetChildren() do
			if accessory:IsA("Accessory") or accessory:IsA("Hat") then
				for _, descendant in accessory:GetDescendants() do
					if descendant:IsA("SpecialMesh") or descendant:IsA("SurfaceAppearance") then
						if ModMenu.State.blockedHatMeshes[descendant] == nil then
							ModMenu.State.blockedHatMeshes[descendant] = descendant.Parent
						end
						descendant.Parent = nil
					elseif descendant:IsA("BasePart") or descendant:IsA("Decal") then
						-- Modern hats use a MeshPart handle with no SpecialMesh, so
						-- hide the part itself too or those hats stay visible.
						if ModMenu.State.blockedHatParts[descendant] == nil then
							ModMenu.State.blockedHatParts[descendant] = descendant.Transparency
						end
						descendant.Transparency = 1
					end
				end
			end
		end
	else
		for mesh, parent in ModMenu.State.blockedHatMeshes do
			if mesh and parent then
				mesh.Parent = parent
			end
		end
		table.clear(ModMenu.State.blockedHatMeshes)
		for part, transparency in ModMenu.State.blockedHatParts do
			if part and part.Parent then
				part.Transparency = transparency
			end
		end
		table.clear(ModMenu.State.blockedHatParts)
	end
end

-- Re-apply character toggles on a fresh character. The obvious alternative --
-- leaving them to the user -- is what made them silently revert after dying.
table.insert(ModMenu.State.getConnections("character.respawn"), S.Players.LocalPlayer.CharacterAdded:Connect(function(character: Model)
	local h = character:WaitForChild("Humanoid", 5)
	if not h or not h:IsA("Humanoid") then return end

	-- Drop state keyed on the previous (destroyed) character to avoid leaks.
	table.clear(ModMenu.State.invisibleOriginal)
	table.clear(ModMenu.State.hiddenLimbState)
	table.clear(ModMenu.State.blockedHatMeshes)
	table.clear(ModMenu.State.blockedHatParts)
	ModMenu.State.invisibleDisplay = nil

	if ModMenu.State.toggles["character.platformStand"] then
		h.PlatformStand = true
	end
	-- Wait a frame so the character's body parts are fully parented first.
	task.defer(function()
		if not character.Parent then return end
		if ModMenu.State.toggles["character.invisible"] then
			ModMenu.Features.Character.invisible(true)
		end
		-- Recompute all three limb groups from the toggles in a single pass.
		refreshLimbs()
		if ModMenu.State.toggles["character.blockHats"] then
			ModMenu.Features.Character.blockHats(true)
		end
	end)
end))
