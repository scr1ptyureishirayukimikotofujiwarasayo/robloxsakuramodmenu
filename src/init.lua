--!strict
-- init.luau
local C = ModMenu.UI.Components
local Panels = ModMenu.Menu.Panels
local T = ModMenu.Theme

-- Ids starting with "settings." are preferences (auto-save, remember-toggles,
-- background), not feature toggles. Reset and restore must leave them alone.
local function isPreference(id: string): boolean
	return string.sub(id, 1, 9) == "settings."
end

-- Home
do
	local p = Panels.home
	C.section(p, "About")
	local info = Instance.new("TextLabel")
	info.Size = UDim2.new(1, -8, 0, 46)
	info.BackgroundTransparency = 1
	info.TextWrapped = true
	info.TextColor3 = T.text
	info.Font = T.font
	info.TextSize = 13
	info.Text = "Executor client mod menu. Features are local to your client unless the game exposes server remotes. Use responsibly."
	info.Parent = p
	T.textStroke(info, 0.65)
	C.section(p, "Quick Actions")
	C.button(p, "Copy Position", function() ModMenu.Features.Teleport.copyPosition() end)
	C.toggle(p, "visual.fullbright", "Fullbright", false, function(v) ModMenu.Features.Visual.fullbright(v) end)
end

-- Player
do
	local p = Panels.player
	C.section(p, "Movement Stats")
	C.slider(p, "player.walkspeed", "WalkSpeed", 0, 200, 16, function(v) ModMenu.Features.Movement.setWalkSpeed(v) end)
	C.slider(p, "player.jumppower", "JumpPower", 0, 200, 50, function(v) ModMenu.Features.Movement.setJumpPower(v) end)
	C.slider(p, "player.gravity", "Gravity", 0, 300, 196.2, function(v) ModMenu.Features.Movement.setGravity(v) end)
	C.section(p, "Waypoints")
	C.button(p, "Save Waypoint", function() ModMenu.Features.Movement.saveWaypoint() end)
	C.button(p, "Teleport to Last", function()
		local wps = ModMenu.Features.Movement.getWaypoints()
		if #wps > 0 then ModMenu.Features.Movement.teleportWaypoint(#wps) end
	end)
end

-- Movement
do
	local p = Panels.movement
	C.toggle(p, "movement.fly", "Fly", false, function(v) ModMenu.Features.Movement.fly(v) end)
	C.slider(p, "movement.flySpeed", "Fly Speed", 10, 250, 60, function(v) ModMenu.State.numbers["movement.flySpeed"] = v end)
	C.toggle(p, "movement.noclip", "Noclip", false, function(v) ModMenu.Features.Movement.noclip(v) end)
	C.toggle(p, "movement.float", "Float Platform", false, function(v) ModMenu.Features.Movement.float(v) end)
end

-- Visual
do
	local p = Panels.visual
	C.toggle(p, "visual.esp", "Player ESP (Highlight)", false, function(v) ModMenu.Features.Visual.esp(v) end)
	C.toggle(p, "visual.fullbright", "Fullbright", false, function(v) ModMenu.Features.Visual.fullbright(v) end)
	C.toggle(p, "visual.removeFog", "Remove Fog", false, function(v) ModMenu.Features.Visual.removeFog(v) end)
	C.slider(p, "visual.fov", "Field of View", 40, 120, 70, function(v) ModMenu.Features.Visual.setFOV(v) end)
	C.slider(p, "visual.clock", "Clock Time", 0, 24, 14, function(v) ModMenu.Features.Visual.setClockTime(v) end)
end

-- World
do
	local p = Panels.world
	C.toggle(p, "world.antiLag", "Anti-Lag / Low Graphics", false, function(v) ModMenu.Features.World.antiLag(v) end)
	C.button(p, "Rejoin", function() ModMenu.Features.Teleport.rejoin() end)
end

-- Teleport
do
	local p = Panels.teleport
	C.button(p, "Teleport to Spawn", function() ModMenu.Features.Teleport.toSpawn() end)
	C.button(p, "Copy Position", function() ModMenu.Features.Teleport.copyPosition() end)
	C.button(p, "Rejoin Server", function() ModMenu.Features.Teleport.rejoin() end)
end

-- Character
do
	local p = Panels.character
	C.section(p, "Body")
	C.slider(p, "character.hipHeight", "Hip Height", 0, 10, 2, function(v) ModMenu.Features.Movement.setHipHeight(v) end)
	C.toggle(p, "character.platformStand", "Platform Stand", false, function(v) ModMenu.Features.Character.platformStand(v) end)
	C.toggle(p, "character.invisible", "Invisible", false, function(v) ModMenu.Features.Character.invisible(v) end)
	C.toggle(p, "character.nolimbs", "No Limbs", false, function(v) ModMenu.Features.Character.setLimbs("all", v) end)
	C.toggle(p, "character.noarms", "No Arms", false, function(v) ModMenu.Features.Character.setLimbs("arms", v) end)
	C.toggle(p, "character.nolegs", "No Legs", false, function(v) ModMenu.Features.Character.setLimbs("legs", v) end)
	C.toggle(p, "character.blockHats", "Block Hats", false, function(v) ModMenu.Features.Character.blockHats(v) end)
	C.section(p, "Camera")
	local players = {}
	for _, plr in ModMenu.Services.Players:GetPlayers() do
		table.insert(players, plr.Name)
	end
	C.dropdown(p, "character.viewTarget", "View Player", players, players[1], function(v)
		ModMenu.Features.Character.view(v)
	end)
	C.button(p, "Unview", function() ModMenu.Features.Character.view(nil) end)
	C.button(p, "Reset Movement", function() ModMenu.Features.Movement.resetMovement() end)
end

-- Protection
do
	local p = Panels.protection
	C.section(p, "Anti-Fling")
	C.toggle(p, "protection.antiFling", "Anti-Fling", false, function(v) ModMenu.Features.Protection.antiFling(v) end)
	C.slider(p, "protection.flingThreshold", "Fling Velocity", 50, 5000, 400)
	C.section(p, "Anti-Teleport")
	C.toggle(p, "protection.antiTeleport", "Anti-Teleport", false, function(v) ModMenu.Features.Protection.antiTeleport(v) end)
	C.slider(p, "protection.tpMaxStuds", "Max Studs Per Frame", 5, 500, 50)
end

-- Utility
do
	local p = Panels.utility
	C.section(p, "Scripts & Explorer")
	C.toggle(p, "utility.dex", "Dex Explorer", false, function(v) ModMenu.Features.Dex.toggle(v) end)
	C.toggle(p, "utility.reviz", "Reviz Admin", false, function(v) ModMenu.Features.Reviz.toggle(v) end)
	C.toggle(p, "utility.shattervast", "Grac3Haz3Lion's ShatterVast Admin", false, function(v) ModMenu.Features.Shattervast.toggle(v) end)
	C.section(p, "Movement Tools")
	C.toggle(p, "utility.clickTP", "Click Teleport", false, function(v) ModMenu.Features.Movement.clickTeleport(v) end)
	C.button(p, "Save Position", function() ModMenu.Features.Movement.savePosition() end)
	C.button(p, "Load Position", function() ModMenu.Features.Movement.loadPosition() end)
	C.section(p, "World Tools")
	C.slider(p, "utility.workspaceVisibility", "Workspace Visibility", 0, 1, 1, function(v) ModMenu.Features.Utility.workspaceVisibility(v) end)
	C.button(p, "Restore Workspace", function() ModMenu.Features.Utility.restoreWorkspaceVisibility() end)
	C.toggle(p, "utility.clickDelete", "Click Delete (Reversible)", false, function(v) ModMenu.Features.Utility.clickDelete(v) end)
	C.toggle(p, "utility.lockWorkspace", "Lock Workspace", false, function(v) ModMenu.Features.Utility.lockWorkspace(v) end)
	C.toggle(p, "utility.toolGrabber", "Tool Grabber", false, function(v) ModMenu.Features.Utility.toolGrabber(v) end)
	C.toggle(p, "utility.reach", "Tool Reach", false, function(v) ModMenu.Features.Utility.reach(v) end)
	C.section(p, "Interactions")
	C.toggle(p, "interaction.clickDetectors", "Auto Click Detectors", false, function(v) ModMenu.Features.Interaction.clickDetectorLoop(v) end)
	C.toggle(p, "interaction.touch", "Auto Touch Parts", false, function(v) ModMenu.Features.Interaction.touchInterestLoop(v) end)
	C.slider(p, "interaction.interval", "Fire Interval (s)", 0.05, 10, 1)
	C.section(p, "Diagnostics")
	C.button(p, "FE Check", function() ModMenu.Features.Utility.feCheck() end)
	local players = {}
	for _, plr in ModMenu.Services.Players:GetPlayers() do
		table.insert(players, plr.Name)
	end
	C.dropdown(p, "utility.playerInfoTarget", "Player Info Target", players, players[1], function(v)
		ModMenu.Features.Utility.playerInfo(v)
	end)
end

-- Settings
do
	local p = Panels.settings
	C.section(p, "Menu")
	local keys = {}
	for _, k in Enum.KeyCode:GetEnumItems() do
		table.insert(keys, k.Name)
	end
	C.dropdown(p, "settings.openKey", "Open Key", keys, ModMenu.State.settings.openKey.Name, function(v)
		local k = Enum.KeyCode[v]
		if k then
			ModMenu.State.settings.openKey = k
			pcall(ModMenu.Config.save)
			ModMenu.Notify("Settings", "Open key set to " .. v)
		end
	end)
	C.toggle(p, "misc.hideGuis", "Hide Other GUIs", false, function(v) ModMenu.Features.Misc.hideAllGuis(v) end)
	C.section(p, "Background")
	C.toggle(p, "settings.backgroundImage", "Background Image", true, function()
		ModMenu.Menu.applyBackground()
	end)
	C.slider(p, "settings.bgBrightness", "Background Brightness", 0, 255, 80, function()
		ModMenu.Menu.applyBackground()
	end)
	C.section(p, "Persistence")
	C.toggle(p, "settings.autoSave", "Auto-Save", ModMenu.State.settings.autoSave, function(v)
		ModMenu.State.settings.autoSave = v
		pcall(ModMenu.Config.save, true) -- the flag itself must persist
	end)
	C.toggle(p, "settings.rememberToggles", "Remember Toggles on Load", ModMenu.State.settings.rememberToggles, function(v)
		ModMenu.State.settings.rememberToggles = v
		pcall(ModMenu.Config.save, true)
	end)
	C.button(p, "Save Now", function()
		pcall(ModMenu.Config.save, true)
		ModMenu.Notify("Settings", "Saved")
	end)
	C.button(p, "Reset Toggles Now", function()
		for id, callbacks in ModMenu.UI.toggleApply do
			if not isPreference(id) and ModMenu.State.toggles[id] then
				ModMenu.State.toggles[id] = false
				for _, apply in callbacks do
					pcall(apply, false)
				end
			end
		end
		for id, syncers in ModMenu.UI.toggleSync do
			if not isPreference(id) then
				for _, sync in syncers do
					pcall(sync, false)
				end
			end
		end
		pcall(ModMenu.Config.save)
		ModMenu.Notify("Settings", "All feature toggles turned off")
	end)
	C.button(p, "Wipe Saved Config", function()
		pcall(ModMenu.Config.wipe)
		ModMenu.Notify("Settings", "Config wiped. Reload to reset the UI.")
	end)
end

-- Single explicit restore point. Widgets no longer run their feature while
-- being built, so re-apply the toggles loaded from config once, after the whole
-- UI exists -- and only when the user opted in. Preferences ("settings.") are
-- skipped: they are read live, never "enabled".
if ModMenu.State.settings.rememberToggles then
	for id, callbacks in ModMenu.UI.toggleApply do
		if not isPreference(id) and ModMenu.State.toggles[id] == true then
			for _, apply in callbacks do
				pcall(apply, true)
			end
		end
	end
end

ModMenu.Menu.applyZOrder()
ModMenu.Notify("Mod Menu", "Loaded. Press " .. ModMenu.State.settings.openKey.Name .. " to open.")
-- init complete
