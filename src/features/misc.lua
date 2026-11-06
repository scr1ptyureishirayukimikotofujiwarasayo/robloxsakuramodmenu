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

ModMenu.State.hiddenGuis = ModMenu.State.hiddenGuis or {}

ModMenu.Features.Misc.hideAllGuis = function(enabled: boolean)
	-- Hides other PlayerGui children (best-effort, reversible). Only GUIs we
	-- actually disabled are re-enabled, so a GUI that started disabled stays off.
	local pg = S.Players.LocalPlayer:FindFirstChild("PlayerGui")
	if not pg then return end
	if enabled then
		for _, child in pg:GetChildren() do
			if child:IsA("ScreenGui") and child ~= ModMenu.Menu.ScreenGui and child.Enabled then
				ModMenu.State.hiddenGuis[child] = true
				child.Enabled = false
			end
		end
	else
		for gui in ModMenu.State.hiddenGuis do
			if gui and gui.Parent then
				gui.Enabled = true
			end
		end
		table.clear(ModMenu.State.hiddenGuis)
	end
end
