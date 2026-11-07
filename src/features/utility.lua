--!strict
-- features/utility.luau
local S = ModMenu.Services

ModMenu.Features = ModMenu.Features or {}
ModMenu.Features.Utility = {}
ModMenu.State.hiddenParts = ModMenu.State.hiddenParts or {}
ModMenu.State.workspaceVisibilityOriginal = ModMenu.State.workspaceVisibilityOriginal or {}
ModMenu.State.lockedPartsOriginal = ModMenu.State.lockedPartsOriginal or {}

-- True for any part in a character/NPC rig (it has a Humanoid model ancestor).
-- World tools must skip these: anchoring a character freezes it, and hiding it
-- makes players invisible.
local function isCharacterPart(part: BasePart): boolean
	local model = part:FindFirstAncestorOfClass("Model")
	return model ~= nil and model:FindFirstChildOfClass("Humanoid") ~= nil
end

-- Click TP / Delete / tool grabber connections handled via movement clickTeleport id and utility ids.

ModMenu.Features.Utility.clickDelete = function(enabled: boolean)
	local id = "utility.clickDelete"
	ModMenu.State.clearConnections(id)
	if not enabled then
		-- restore hidden parts to their original parent
		for part, originalParent in ModMenu.State.hiddenParts do
			if part and part.Parent == nil then
				if typeof(originalParent) == "Instance" then
					part.Parent = originalParent
				else
					part.Parent = S.Workspace
				end
			end
		end
		table.clear(ModMenu.State.hiddenParts)
		return
	end
	local mouse = S.Players.LocalPlayer:GetMouse()
	-- UserInputService instead of mouse.Button1Down so a click already consumed
	-- by the menu/GUI (gameProcessed) does not delete the part behind the window.
	local conn = S.UserInputService.InputBegan:Connect(function(input, gameProcessed)
		if gameProcessed then return end
		if input.UserInputType ~= Enum.UserInputType.MouseButton1 then return end
		local target = mouse.Target
		-- Never delete parts of a character rig (ours or another player's):
		-- hiding a player's limb client-side is not what "click delete" means.
		if target and target:IsA("BasePart") and not isCharacterPart(target) then
			ModMenu.State.hiddenParts[target] = target.Parent
			target.Parent = nil
		end
	end)
	table.insert(ModMenu.State.getConnections(id), conn)
end

ModMenu.Features.Utility.toolGrabber = function(enabled: boolean)
	local id = "utility.toolGrabber"
	ModMenu.State.clearConnections(id)
	if not enabled then return end
	local function grab()
		local bp = S.Players.LocalPlayer:FindFirstChild("Backpack")
		if not bp then return end
		for _, obj in S.Workspace:GetChildren() do
			if obj:IsA("Tool") or obj:IsA("HopperBin") then
				pcall(function() obj.Parent = bp end)
			end
		end
	end
	grab()
	local conn = S.Workspace.ChildAdded:Connect(function(child)
		if enabled and (child:IsA("Tool") or child:IsA("HopperBin")) then
			task.wait()
			local bp = S.Players.LocalPlayer:FindFirstChild("Backpack")
			if bp then pcall(function() child.Parent = bp end) end
		end
	end)
	table.insert(ModMenu.State.getConnections(id), conn)
end

ModMenu.Features.Utility.workspaceVisibility = function(value: number)
	value = math.clamp(value, 0, 1)
	if next(ModMenu.State.workspaceVisibilityOriginal) == nil then
		for _, part in S.Workspace:GetDescendants() do
			if part:IsA("BasePart") and not isCharacterPart(part) then
				ModMenu.State.workspaceVisibilityOriginal[part] = part.Transparency
			end
		end
	end
	for part, original in ModMenu.State.workspaceVisibilityOriginal do
		if part and part.Parent then
			part.Transparency = original + (1 - original) * (1 - value)
		end
	end
end

ModMenu.Features.Utility.restoreWorkspaceVisibility = function()
	for part, original in ModMenu.State.workspaceVisibilityOriginal do
		if part and part.Parent then
			part.Transparency = original
		end
	end
	table.clear(ModMenu.State.workspaceVisibilityOriginal)
end

ModMenu.Features.Utility.lockWorkspace = function(enabled: boolean)
	if enabled then
		if next(ModMenu.State.lockedPartsOriginal) == nil then
			for _, part in S.Workspace:GetDescendants() do
				if part:IsA("BasePart") and not isCharacterPart(part) then
					ModMenu.State.lockedPartsOriginal[part] = part.Anchored
					part.Anchored = true
				end
			end
		end
	else
		for part, original in ModMenu.State.lockedPartsOriginal do
			if part and part.Parent then
				part.Anchored = original
			end
		end
		table.clear(ModMenu.State.lockedPartsOriginal)
	end
end

ModMenu.Features.Utility.reach = function(enabled: boolean)
	local id = "utility.reach"
	ModMenu.State.clearConnections(id)
	if ModMenu.State.reachOriginal == nil then ModMenu.State.reachOriginal = {} end
	if not enabled then
		for handle, size in ModMenu.State.reachOriginal do
			if handle and handle.Parent then
				handle.Size = size
			end
		end
		table.clear(ModMenu.State.reachOriginal)
		return
	end
	local function applyReach()
		local lp = S.Players.LocalPlayer
		local char = lp.Character
		if not char then return end
		local tool = char:FindFirstChildOfClass("Tool")
		local backpack = lp:FindFirstChild("Backpack")
		if not tool and backpack then tool = backpack:FindFirstChildOfClass("Tool") end
		if not tool then return end
		for _, part in tool:GetDescendants() do
			if part:IsA("BasePart") and part.Name:lower():find("handle") then
				if ModMenu.State.reachOriginal[part] == nil then
					ModMenu.State.reachOriginal[part] = part.Size
				end
				part.Size = ModMenu.State.reachOriginal[part] * Vector3.new(4, 4, 8)
			end
		end
	end
	applyReach()
	local conn = S.RunService.Heartbeat:Connect(applyReach)
	table.insert(ModMenu.State.getConnections(id), conn)
end

ModMenu.Features.Utility.feCheck = function()
	-- Client replication is always filtered in modern Roblox; there is no
	-- exploitable "FE off" state, so report that plainly instead of reading a
	-- property that no longer reflects anything useful.
	ModMenu.Notify("Filtering", "FilteringEnabled is always on (client replication is filtered)")
end

ModMenu.Features.Utility.playerInfo = function(targetName: string?)
	local target = targetName and S.Players:FindFirstChild(targetName) or S.Players.LocalPlayer
	if not target then
		ModMenu.Notify("Info", "Player not found")
		return
	end
	ModMenu.Notify("Player Info", string.format("%s | Age: %d | Id: %d", target.Name, target.AccountAge, target.UserId))
end
