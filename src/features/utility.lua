--!strict
-- features/utility.luau
local S = ModMenu.Services

ModMenu.Features = ModMenu.Features or {}
ModMenu.Features.Utility = {}
ModMenu.State.hiddenParts = ModMenu.State.hiddenParts or {}
ModMenu.State.workspaceVisibilityOriginal = ModMenu.State.workspaceVisibilityOriginal or {}
ModMenu.State.lockedPartsOriginal = ModMenu.State.lockedPartsOriginal or {}

-- Click TP / Delete / tool grabber connections handled via movement clickTeleport id and utility ids.

ModMenu.Features.Utility.clickDelete = function(enabled: boolean)
	local id = "utility.clickDelete"
	ModMenu.State.clearConnections(id)
	if not enabled then
		-- restore hidden parts
		for part in ModMenu.State.hiddenParts do
			if part and part.Parent == nil then
				-- best-effort restore to workspace
				part.Parent = S.Workspace
			end
		end
		table.clear(ModMenu.State.hiddenParts)
		return
	end
	local mouse = S.Players.LocalPlayer:GetMouse()
	local conn = mouse.Button1Down:Connect(function()
		local target = mouse.Target
		if target and target:IsA("BasePart") then
			ModMenu.State.hiddenParts[target] = true
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
			if part:IsA("BasePart") then
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
				if part:IsA("BasePart") then
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
	local char = S.Players.LocalPlayer.Character
	if not char then return end
	local tool = char:FindFirstChildOfClass("Tool") or S.Players.LocalPlayer:FindFirstChild("Backpack") and S.Players.LocalPlayer.Backpack:FindFirstChildOfClass("Tool")
	local handles = {}
	if tool then
		for _, part in tool:GetDescendants() do
			if part:IsA("BasePart") and (part.Name == "Handle" or part.Name:lower():find("handle")) then
				table.insert(handles, part)
			end
		end
	end
	if enabled then
		for _, handle in handles do
			if ModMenu.State.reachOriginal == nil then ModMenu.State.reachOriginal = {} end
			if ModMenu.State.reachOriginal[handle] == nil then
				ModMenu.State.reachOriginal[handle] = handle.Size
			end
			handle.Size = handle.Size * Vector3.new(4, 4, 8)
		end
	else
		if ModMenu.State.reachOriginal then
			for handle, size in ModMenu.State.reachOriginal do
				if handle and handle.Parent then
					handle.Size = size
				end
			end
			table.clear(ModMenu.State.reachOriginal)
		end
	end
end

ModMenu.Features.Utility.feCheck = function()
	local filtering = false
	pcall(function()
		filtering = S.Workspace.FilteringEnabled
	end)
	ModMenu.Notify("FilteringEnabled", filtering and "Filtering enabled (FE)" or "Filtering disabled/unknown")
end

ModMenu.Features.Utility.playerInfo = function(targetName: string?)
	local target = targetName and S.Players:FindFirstChild(targetName) or S.Players.LocalPlayer
	if not target then
		ModMenu.Notify("Info", "Player not found")
		return
	end
	ModMenu.Notify("Player Info", string.format("%s | Age: %d | Id: %d", target.Name, target.AccountAge, target.UserId))
end
