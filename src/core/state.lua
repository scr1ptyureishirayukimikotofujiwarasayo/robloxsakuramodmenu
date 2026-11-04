--!strict
-- core/state.luau
ModMenu.State = {
	settings = {
		openKey = Enum.KeyCode.RightShift,
		accent = Color3.fromRGB(210, 50, 75),
		menuSize = UDim2.fromOffset(460, 340),
	},
	toggles = {} :: { [string]: boolean },
	numbers = {} :: { [string]: number },
	strings = {} :: { [string]: string },
	connections = {} :: { [string]: { RBXScriptConnection } },
	waypoints = {} :: { { name: string, position: Vector3 } },
	savedPosition = nil :: Vector3?,
	savedPositionName = nil :: string?,
	hiddenParts = {},
	workspaceVisibilityOriginal = {},
	lockedPartsOriginal = {},
	reachOriginal = {},
	originalWalkSpeed = nil :: number?,
	originalJumpPower = nil :: number?,
	originalHipHeight = nil :: number?,
}

ModMenu.State.setToggle = function(id: string, value: boolean, apply: ((boolean) -> ())?)
	ModMenu.State.toggles[id] = value
	if apply then
		pcall(apply, value)
	end
end

ModMenu.State.getConnections = function(id: string): { RBXScriptConnection }
	if not ModMenu.State.connections[id] then
		ModMenu.State.connections[id] = {}
	end
	return ModMenu.State.connections[id]
end

ModMenu.State.clearConnections = function(id: string)
	local cons = ModMenu.State.connections[id]
	if cons then
		for _, c in cons do
			pcall(function() c:Disconnect() end)
		end
		table.clear(cons)
	end
end
