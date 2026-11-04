--!strict
-- features/teleport.luau
local S = ModMenu.Services
local TeleportService = S.TeleportService
local Players = S.Players

ModMenu.Features = ModMenu.Features or {}
ModMenu.Features.Teleport = {}

ModMenu.Features.Teleport.toSpawn = function()
	local r = (ModMenu.Services.Players.LocalPlayer.Character or {}).HumanoidRootPart
	if S.Workspace:FindFirstChild("SpawnLocation") then
		local sp = S.Workspace:FindFirstChild("SpawnLocation")
		if sp and r then r.CFrame = sp.CFrame + Vector3.new(0, 3, 0) end
	end
end

ModMenu.Features.Teleport.copyPosition = function()
	local r = ModMenu.Services.Players.LocalPlayer.Character and ModMenu.Services.Players.LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
	if r then
		local pos = r.Position
		local text = string.format("%.2f, %.2f, %.2f", pos.X, pos.Y, pos.Z)
		if everyClipboard then everyClipboard(text) end
		ModMenu.Notify("Position", "Copied: " .. text)
	end
end

ModMenu.Features.Teleport.rejoin = function()
	pcall(function()
		TeleportService:TeleportToPlaceInstance(game.PlaceId, game.JobId, S.Players.LocalPlayer)
	end)
end
