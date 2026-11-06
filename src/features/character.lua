--!strict
-- features/character.luau
local S = ModMenu.Services

ModMenu.Features = ModMenu.Features or {}
ModMenu.Features.Character = {}

ModMenu.State.originalPlatformStand = ModMenu.State.originalPlatformStand or {}
ModMenu.State.invisibleOriginal = ModMenu.State.invisibleOriginal or {}
ModMenu.State.hiddenLimbOwner = ModMenu.State.hiddenLimbOwner or {}
ModMenu.State.hiddenLimbState = ModMenu.State.hiddenLimbState or {}
ModMenu.State.blockedHatMeshes = ModMenu.State.blockedHatMeshes or {}

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

local limbNames = {
	all = {"Left Arm", "Right Arm", "Left Leg", "Right Leg"},
	arms = {"Left Arm", "Right Arm"},
	legs = {"Left Leg", "Right Leg"},
}

-- Hide limbs with Transparency/CanCollide rather than unparenting them: removing
-- a limb from the model breaks its Motor6D and can leave the character tumbling.
ModMenu.Features.Character.setLimbs = function(mode: string?, enabled: boolean)
	local c = char()
	if not c then return end
	local key = mode or "all"
	local selected = limbNames[key] or limbNames.all
	for _, limbName in selected do
		local limb = c:FindFirstChild(limbName)
		if not limb or not limb:IsA("BasePart") then continue end
		local owner = ModMenu.State.hiddenLimbOwner[limb]
		if enabled then
			if not owner then
				ModMenu.State.hiddenLimbState[limb] = {
					transparency = limb.Transparency,
					collide = limb.CanCollide,
				}
				limb.Transparency = 1
				limb.CanCollide = false
				ModMenu.State.hiddenLimbOwner[limb] = key
			end
		else
			if owner == key then
				local saved = ModMenu.State.hiddenLimbState[limb]
				if saved then
					limb.Transparency = saved.transparency
					limb.CanCollide = saved.collide
				end
				ModMenu.State.hiddenLimbOwner[limb] = nil
				ModMenu.State.hiddenLimbState[limb] = nil
			end
		end
	end
end

ModMenu.Features.Character.invisible = function(enabled: boolean)
	local c = char()
	if not c then return end
	if enabled then
		for _, part in c:GetDescendants() do
			if part:IsA("BasePart") or part:IsA("Decal") then
				if ModMenu.State.invisibleOriginal[part] == nil then
					ModMenu.State.invisibleOriginal[part] = part.Transparency
				end
				part.Transparency = 1
			end
		end
	else
		for part, value in ModMenu.State.invisibleOriginal do
			if part and part.Parent then
				part.Transparency = value
			end
		end
		table.clear(ModMenu.State.invisibleOriginal)
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
	end
end

-- Re-apply character toggles on a fresh character. The obvious alternative --
-- leaving them to the user -- is what made them silently revert after dying.
table.insert(ModMenu.State.getConnections("character.respawn"), S.Players.LocalPlayer.CharacterAdded:Connect(function(character: Model)
	local h = character:WaitForChild("Humanoid", 5)
	if not h or not h:IsA("Humanoid") then return end

	-- Drop state keyed on the previous (destroyed) character to avoid leaks.
	table.clear(ModMenu.State.invisibleOriginal)
	table.clear(ModMenu.State.hiddenLimbOwner)
	table.clear(ModMenu.State.hiddenLimbState)
	table.clear(ModMenu.State.blockedHatMeshes)

	if ModMenu.State.toggles["character.platformStand"] then
		h.PlatformStand = true
	end
	-- Wait a frame so the character's body parts are fully parented first.
	task.defer(function()
		if not character.Parent then return end
		if ModMenu.State.toggles["character.invisible"] then
			ModMenu.Features.Character.invisible(true)
		end
		if ModMenu.State.toggles["character.nolimbs"] then
			ModMenu.Features.Character.setLimbs("all", true)
		end
		if ModMenu.State.toggles["character.noarms"] then
			ModMenu.Features.Character.setLimbs("arms", true)
		end
		if ModMenu.State.toggles["character.nolegs"] then
			ModMenu.Features.Character.setLimbs("legs", true)
		end
		if ModMenu.State.toggles["character.blockHats"] then
			ModMenu.Features.Character.blockHats(true)
		end
	end)
end))
