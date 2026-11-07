--!strict
-- features/teleport.luau
local S = ModMenu.Services
local TeleportService = S.TeleportService
local Players = S.Players

ModMenu.Features = ModMenu.Features or {}
ModMenu.Features.Teleport = {}

-- Open the protection bypass window (when the Protection module is loaded)
-- so the menu's own teleports are never reverted by anti-teleport.
local function tpBypass(seconds: number?)
	local prot = ModMenu.Features and ModMenu.Features.Protection
	if prot and prot.bypass then
		pcall(prot.bypass, seconds)
	end
end

ModMenu.Features.Teleport.toSpawn = function()
	local r = ModMenu.Services.Players.LocalPlayer.Character
		and ModMenu.Services.Players.LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
	if not r then return end
	-- Spawns are often nested in a folder or named SP_Waypoint etc., so search
	-- the whole workspace by class rather than only a direct child by name.
	local sp = S.Workspace:FindFirstChildWhichIsA("SpawnLocation", true)
	if sp then
		tpBypass(1)
		r.CFrame = sp.CFrame + Vector3.new(0, 3, 0)
	else
		ModMenu.Notify("Teleport", "No SpawnLocation found in this place")
	end
end

ModMenu.Features.Teleport.copyPosition = function()
	local r = ModMenu.Services.Players.LocalPlayer.Character and ModMenu.Services.Players.LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
	if r then
		local pos = r.Position
		local text = string.format("%.2f, %.2f, %.2f", pos.X, pos.Y, pos.Z)
		if everyClipboard then
			everyClipboard(text)
			ModMenu.Notify("Position", "Copied: " .. text)
		else
			ModMenu.Notify("Position", "Clipboard unavailable. Position: " .. text)
		end
	end
end

local REJOIN_LOADSTRING = 'loadstring(game:HttpGet("https://raw.githubusercontent.com/scr1ptyureishirayukimikotofujiwarasayo/robloxsakuramodmenu/main/loader.lua"))()'
local rejoinQueued = false

ModMenu.Features.Teleport.rejoin = function()
	-- Teleports create a fresh DataModel: queue the loader so the menu
	-- rebuilds itself in the new session (needs executor teleport-queue support).
	-- util compat resolves queue_on_teleport under several executor names.
	local queue = queueteleport or queue_on_teleport or (syn and syn.queue_on_teleport)
	if queue and not rejoinQueued then
		pcall(queue, REJOIN_LOADSTRING)
		rejoinQueued = true
	elseif not queue then
		ModMenu.Notify("Rejoin", "This executor can't auto-run after rejoin. Enable auto-execute or rerun the script.")
	end
	pcall(function()
		if game.JobId ~= "" then
			TeleportService:TeleportToPlaceInstance(game.PlaceId, game.JobId, S.Players.LocalPlayer)
		else
			TeleportService:Teleport(game.PlaceId, S.Players.LocalPlayer)
		end
	end)
end
