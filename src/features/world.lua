--!strict
-- features/world.luau

ModMenu.Features = ModMenu.Features or {}
ModMenu.Features.World = {}

-- Anti-Lag feeds into the shared Lighting state (features/visual.luau
-- refreshLighting) instead of writing GlobalShadows/FogEnd itself. That way it
-- no longer clobbers -- or gets clobbered by -- Fullbright / Remove Fog, and
-- switching it off restores the map's original fog instead of leaving 1e4.
ModMenu.Features.World.antiLag = function(enabled: boolean)
	local Visual = ModMenu.Features.Visual
	pcall(function()
		if enabled then
			if ModMenu.State.antiLagQuality == nil then
				ModMenu.State.antiLagQuality = settings().Rendering.QualityLevel
			end
			settings().Rendering.QualityLevel = Enum.QualityLevel.Level01
		else
			settings().Rendering.QualityLevel = ModMenu.State.antiLagQuality or Enum.QualityLevel.Automatic
			ModMenu.State.antiLagQuality = nil
		end
	end)
	if Visual and Visual.refreshLighting then
		Visual.refreshLighting()
	end
end
