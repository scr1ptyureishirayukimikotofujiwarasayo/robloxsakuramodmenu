--!strict
-- features/misc.luau
local S = ModMenu.Services
local StarterGui = S.StarterGui

ModMenu.Features = ModMenu.Features or {}
ModMenu.Features.Misc = {}

ModMenu.Features.Misc.toggleCoreGui = function(guiType: string, enabled: boolean)
	local ok, core = pcall(function()
		return Enum.CoreGuiType[guiType]
	end)
	if ok and core then
		StarterGui:SetCoreGuiEnabled(core, enabled)
	end
end

ModMenu.Features.Misc.hideAllGuis = function(enabled: boolean)
	-- Hides non-essential PlayerGui children (best-effort, reversible).
	local pg = S.Players.LocalPlayer:FindFirstChild("PlayerGui")
	if not pg then return end
	for _, child in pg:GetChildren() do
		if child ~= ModMenu.Menu.ScreenGui and child:IsA("ScreenGui") then
			child.Enabled = not enabled
		end
	end
end
