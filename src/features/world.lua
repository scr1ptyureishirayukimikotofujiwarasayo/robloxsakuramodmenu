--!strict
-- features/world.luau
local S = ModMenu.Services
local Lighting = S.Lighting

ModMenu.Features = ModMenu.Features or {}
ModMenu.Features.World = {}

ModMenu.Features.World.antiLag = function(enabled: boolean)
	if enabled then
		pcall(function() Lighting.GlobalShadows = false end)
		pcall(function() Lighting.FogEnd = 1e4 end)
		pcall(function() settings().Rendering.QualityLevel = Enum.QualityLevel.Level01 end)
	else
		pcall(function() Lighting.GlobalShadows = true end)
		pcall(function() settings().Rendering.QualityLevel = Enum.QualityLevel.Automatic end)
	end
end
