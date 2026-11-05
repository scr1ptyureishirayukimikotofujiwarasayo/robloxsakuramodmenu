--!strict
-- init.luau
local C = ModMenu.UI.Components
local Panels = ModMenu.Menu.Panels
local T = ModMenu.Theme

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
	C.toggle(p, "utility.reviz", "Reviz Admin Remake", false, function(v) ModMenu.Features.Reviz.toggle(v) end)
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

-- Console (SakuraVibes999's Reviz Admin)
do
	local p = Panels.console
	local Reviz = ModMenu.Features.Reviz
	C.section(p, "SakuraVibes999's Reviz Admin")
	C.toggle(p, "utility.reviz", "Reviz Admin Remake GUI", false, function(v) Reviz.toggle(v) end)

	local info = Instance.new("TextLabel")
	info.Size = UDim2.new(1, -8, 0, 34)
	info.BackgroundTransparency = 1
	info.TextWrapped = true
	info.TextXAlignment = Enum.TextXAlignment.Left
	info.TextYAlignment = Enum.TextYAlignment.Top
	info.TextColor3 = T.text
	info.Font = T.font
	info.TextSize = 12
	info.Text = "Type a command and press Enter. The prefix key (" .. Reviz.getPrefix() .. ") opens this tab and focuses the box."
	info.Parent = p
	T.textStroke(info, 0.65)

	local input = Instance.new("TextBox")
	input.Size = UDim2.new(1, -8, 0, 30)
	input.BackgroundColor3 = T.surface
	input.TextColor3 = T.text
	input.PlaceholderText = "command, e.g. god / goto bob / speed 30"
	input.PlaceholderColor3 = T.muted
	input.Font = T.font
	input.TextSize = 13
	input.Text = ""
	input.ClearTextOnFocus = false
	input.BorderSizePixel = 0
	input.Parent = p
	T.corner(input, 6)
	ModMenu.Menu.ConsoleInput = input

	local output = Instance.new("TextLabel")
	output.Size = UDim2.new(1, -8, 0, 0)
	output.AutomaticSize = Enum.AutomaticSize.Y
	output.BackgroundTransparency = 1
	output.TextWrapped = true
	output.TextXAlignment = Enum.TextXAlignment.Left
	output.TextYAlignment = Enum.TextYAlignment.Top
	output.TextColor3 = T.textSecondary
	output.Font = T.font
	output.TextSize = 12
	output.Text = ""
	output.Parent = p
	T.textStroke(output, 0.7)

	local lines = {}
	local function render()
		output.Text = table.concat(lines, "\n")
	end
	Reviz.log = function(text)
		table.insert(lines, tostring(text))
		while #lines > 200 do
			table.remove(lines, 1)
		end
		render()
	end
	Reviz.onCommands = function()
		for _, entry in ipairs(Reviz.commands) do
			Reviz.log(entry)
		end
	end

	local function run(text)
		text = tostring(text or ""):gsub("^%s+", ""):gsub("%s+$", "")
		if text == "" then return end
		Reviz.log("> " .. text)
		Reviz.execute(text)
	end

	input.FocusLost:Connect(function(enterPressed)
		if enterPressed then
			run(input.Text)
			input.Text = ""
		end
	end)

	C.button(p, "Run Command", function()
		run(input.Text)
		input.Text = ""
	end)
	C.button(p, "List Commands", function() Reviz.showCommands() end)
	C.button(p, "Clear Output", function()
		lines = {}
		render()
	end)
	C.toggle(p, "reviz.chat", "Chat Commands", true, function(v) Reviz.chatEnabled = v end)

	C.section(p, "Quick Commands")
	C.button(p, "Godmode", function() run("god") end)
	C.button(p, "Noclip", function() run("noclip") end)
	C.button(p, "Clip", function() run("clip") end)
	C.button(p, "Invisible", function() run("invisible") end)
	C.button(p, "Fly", function() run("fly") end)
	C.button(p, "Unfly", function() run("unfly") end)
	C.button(p, "Dex Explorer", function() run("explorer") end)
	C.button(p, "Save Position", function() run("savepos") end)
	C.button(p, "Load Position", function() run("loadpos") end)
	C.button(p, "Respawn", function() run("respawn") end)
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
	C.button(p, "Save Settings", function()
		pcall(ModMenu.Config.save)
		ModMenu.Notify("Settings", "Saved")
	end)
	C.button(p, "Reset Toggles", function()
		for k in ModMenu.State.toggles do
			ModMenu.State.toggles[k] = false
		end
		pcall(ModMenu.Config.save)
		ModMenu.Notify("Settings", "Toggles reset (reload to apply)")
	end)
end

ModMenu.Menu.applyZOrder()
ModMenu.Notify("Mod Menu", "Loaded. Press " .. ModMenu.State.settings.openKey.Name .. " to open.")
-- init complete
