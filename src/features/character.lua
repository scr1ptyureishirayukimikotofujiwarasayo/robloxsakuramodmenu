--!strict
-- features/character.luau
local S = ModMenu.Services

ModMenu.Features = ModMenu.Features or {}
ModMenu.Features.Character = {}

ModMenu.State.originalPlatformStand = ModMenu.State.originalPlatformStand or {}
ModMenu.State.invisibleOriginal = ModMenu.State.invisibleOriginal or {}
ModMenu.State.hiddenLimbOwner = ModMenu.State.hiddenLimbOwner or {}
ModMenu.State.hiddenLimbParent = ModMenu.State.hiddenLimbParent or {}
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

ModMenu.Features.Character.setLimbs = function(mode: string?, enabled: boolean)
	local c = char()
	if not c then return end
	local selected = limbNames[mode or "all"] or limbNames.all
	for _, limbName in selected do
		local limb = c:FindFirstChild(limbName)
		if not limb or not limb:IsA("BasePart") then continue end
		local owner = ModMenu.State.hiddenLimbOwner[limb]
		if enabled then
			if not owner then
				ModMenu.State.hiddenLimbParent[limb] = limb.Parent
				limb.Parent = nil
				ModMenu.State.hiddenLimbOwner[limb] = mode or "all"
			end
		else
			if owner == (mode or "all") then
				local parent = ModMenu.State.hiddenLimbParent[limb]
				if parent then limb.Parent = parent end
				ModMenu.State.hiddenLimbOwner[limb] = nil
				ModMenu.State.hiddenLimbParent[limb] = nil
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
		for k in ModMenu.State.invisibleOriginal do
			ModMenu.State.invisibleOriginal[k] = nil
		end
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
		for k in ModMenu.State.blockedHatMeshes do
			ModMenu.State.blockedHatMeshes[k] = nil
		end
	end
end
