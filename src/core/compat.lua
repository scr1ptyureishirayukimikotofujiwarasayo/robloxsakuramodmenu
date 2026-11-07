--!strict
-- core/compat.luau
local function missing(expectedType: string, value: any, fallback: any): any
	if type(value) == expectedType then
		return value
	end
	return fallback
end

getgenv = missing("function", getgenv, function(): any return {} end)
gethui = missing("function", gethui or get_hidden_gui)
syn = missing("table", syn, {}) :: any
syn_protect_gui = missing("function", syn and syn.protect_gui)
sethidden = missing("function", sethiddenproperty or set_hidden_property or set_hidden_prop)
gethidden = missing("function", gethiddenproperty or get_hidden_property or get_hidden_prop)
queueteleport = missing("function", queue_on_teleport or (syn and syn.queue_on_teleport) or (fluxus and fluxus.queue_on_teleport))
httprequest = missing("function", request or http_request or (syn and syn.request) or (http and http.request) or (fluxus and fluxus.request))
everyClipboard = missing("function", setclipboard or toclipboard or set_clipboard or (Clipboard and Clipboard.set))
firetouchinterest = missing("function", firetouchinterest)
waxwritefile, waxreadfile = writefile, readfile
writefile = missing("function", waxwritefile) and function(file: string, data: string, safe: boolean?)
	if safe == true then
		return pcall(waxwritefile, file, data)
	end
	waxwritefile(file, data)
end
readfile = missing("function", waxreadfile) and function(file: string, safe: boolean?)
	if safe == true then
		return pcall(waxreadfile, file)
	end
	return waxreadfile(file)
end
isfile = missing("function", isfile, readfile and function(file: string)
	local success, result = pcall(function()
		return readfile(file)
	end)
	return success and result ~= nil and result ~= ""
end)
makefolder = missing("function", makefolder)
isfolder = missing("function", isfolder)
getcustomasset = missing("function", getcustomasset or getsynasset)
hookfunction = missing("function", hookfunction)
hookmetamethod = missing("function", hookmetamethod)
getnamecallmethod = missing("function", getnamecallmethod or get_namecall_method)
checkcaller = missing("function", checkcaller, function(): boolean return false end)
newcclosure = missing("function", newcclosure, function(f: (...any) -> ...any, ...: any): ...any return f(...) end)
getgc = missing("function", getgc or get_gc_objects)
setthreadidentity = missing("function", setthreadidentity or (syn and syn.set_thread_identity) or syn_context_set or setthreadcontext)
replicatesignal = missing("function", replicatesignal)
getconnections = missing("function", getconnections or get_signal_cons)

ModMenu = (typeof(ModMenu) == "table" and ModMenu) or (_G and _G.ModMenu) or {}

-- Re-execution: the previous run's feature loops/connections are still live,
-- AND every effect it applied (noclip, Lock Workspace, Fullbright, hidden
-- parts, payload GUIs, ...) is still in force. Tear them down AND revert them
-- BEFORE core/state.luau replaces State -- otherwise the "original value"
-- snapshots are lost and the effects become permanent and un-togglable.
local function isPreference(id: any): boolean
	return type(id) == "string" and string.sub(id, 1, 9) == "settings."
end

-- Turning each active toggle off runs its own off-handler, which restores the
-- originals it snapshotted (see the "Reset Toggles Now" button for the pattern).
if
	typeof(ModMenu.UI) == "table"
	and typeof(ModMenu.UI.toggleApply) == "table"
	and typeof(ModMenu.State) == "table"
	and typeof(ModMenu.State.toggles) == "table"
then
	for id, callbacks in ModMenu.UI.toggleApply do
		if not isPreference(id) and ModMenu.State.toggles[id] == true and typeof(callbacks) == "table" then
			-- Clear the flag first so features that re-derive from the toggle
			-- table (Fullbright / Remove Fog / Anti-Lag) actually revert.
			ModMenu.State.toggles[id] = false
			for _, apply in callbacks do
				pcall(apply, false)
			end
		end
	end
end

-- Workspace Visibility is a slider, not a toggle, so revert it explicitly.
if
	typeof(ModMenu.Features) == "table"
	and typeof(ModMenu.Features.Utility) == "table"
	and typeof(ModMenu.Features.Utility.restoreWorkspaceVisibility) == "function"
then
	pcall(ModMenu.Features.Utility.restoreWorkspaceVisibility)
end

if typeof(ModMenu.State) == "table" and typeof(ModMenu.State.connections) == "table" then
	for _, bucket in ModMenu.State.connections do
		for _, conn in bucket do
			pcall(function() conn:Disconnect() end)
		end
	end
end

_G = _G or {}
_G.ModMenu = ModMenu
ModMenu.Compat = { missing = missing }
