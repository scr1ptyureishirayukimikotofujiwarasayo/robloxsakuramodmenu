--!strict
-- core/compat.luau
local function missing(expectedType: string, value: any, fallback: any): any
	if type(value) == expectedType then
		return value
	end
	return fallback
end

-- Read a field off an executor object without assuming it is indexable: some
-- executors expose `syn` as userdata, and indexing that can throw.
local function safeGet(object: any, key: string): any
	if object == nil then
		return nil
	end
	local kind = type(object)
	if kind ~= "table" and kind ~= "userdata" then
		return nil
	end
	local ok, value = pcall(function()
		return object[key]
	end)
	if ok then
		return value
	end
	return nil
end

-- getgenv() must hand back the SAME table on every call: the payload scripts
-- store their unload hook in it, and a fresh table per call loses it.
local getgenvStore: { [string]: any } = {}
getgenv = missing("function", getgenv, function(): any return getgenvStore end)

gethui = missing("function", gethui or get_hidden_gui, function(): any
	local ok, core = pcall(function()
		return game:GetService("CoreGui")
	end)
	if ok then
		return core
	end
	return nil
end)

-- Keep the executor's own `syn` object (table OR userdata); replacing it with
-- {} would throw away syn.request / syn.queue_on_teleport / syn.protect_gui.
if syn == nil then
	syn = {}
end
syn_protect_gui = missing("function", safeGet(syn, "protect_gui"), function(): any return nil end)
sethidden = missing("function", sethiddenproperty or set_hidden_property or set_hidden_prop, function(object: any, property: string, hidden: boolean): any
	if type(object) ~= "table" and type(object) ~= "userdata" then
		return nil
	end
	if property == "Transparency" then
		object.Transparency = if hidden then 1 else 0
	end
	return nil
end)
gethidden = missing("function", gethiddenproperty or get_hidden_property or get_hidden_prop, function(object: any, property: string): any
	if type(object) ~= "table" and type(object) ~= "userdata" then
		return nil
	end
	return safeGet(object, property)
end)
queueteleport = missing(
	"function",
	queue_on_teleport or safeGet(syn, "queue_on_teleport") or safeGet(fluxus, "queue_on_teleport")
)
httprequest = missing(
	"function",
	request
		or http_request
		or safeGet(syn, "request")
		or safeGet(http, "request")
		or safeGet(fluxus, "request")
)
everyClipboard = missing("function", setclipboard or toclipboard or set_clipboard or safeGet(Clipboard, "set"))
firetouchinterest = missing("function", firetouchinterest)
-- fireclickdetector has no sensible fallback: interaction.lua checks for it and
-- switches its own toggle back off when the executor does not provide it.
fireclickdetector = missing("function", fireclickdetector)

waxwritefile, waxreadfile = writefile, readfile
if type(waxwritefile) == "function" then
	writefile = function(file: string, data: string, safe: boolean?)
		if safe == true then
			return pcall(waxwritefile, file, data)
		end
		waxwritefile(file, data)
	end
end
if type(waxreadfile) == "function" then
	readfile = function(file: string, safe: boolean?)
		if safe == true then
			return pcall(waxreadfile, file)
		end
		return waxreadfile(file)
	end
end
isfile = missing("function", isfile, readfile and function(file: string): boolean
	local success, result = pcall(function()
		return readfile(file)
	end)
	return success and result ~= nil and result ~= ""
end)
makefolder = missing("function", makefolder, function(): any return nil end)
isfolder = missing("function", isfolder, function(): any return false end)
-- An empty content id makes the caller fall through to its next fallback.
getcustomasset = missing("function", getcustomasset or getsynasset, function(): any return "" end)
hookfunction = missing("function", hookfunction, function(_: any, name: any): any return name end)
hookmetamethod = missing("function", hookmetamethod, function(_: any, index: any): any return index end)
getnamecallmethod = missing("function", getnamecallmethod or get_namecall_method, function(): any return nil end)
checkcaller = missing("function", checkcaller, function(): boolean return false end)
newcclosure = missing("function", newcclosure, function(f: (...any) -> ...any, ...: any): ...any return f(...) end)
getgc = missing("function", getgc or get_gc_objects, function(): any return {} end)
setthreadidentity = missing(
	"function",
	setthreadidentity or safeGet(syn, "set_thread_identity") or syn_context_set or setthreadcontext,
	function(): any return nil end
)
replicatesignal = missing("function", replicatesignal, function(): any return nil end)
getconnections = missing("function", getconnections or get_signal_cons, function(): any return {} end)
delfile = missing("function", delfile)

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
ModMenu.Compat = {
	missing = missing,
	safeGet = safeGet,
	-- Read a field off the executor's `syn` object without assuming it is a
	-- table (some executors expose it as userdata).
	getSyn = function(name: string): any
		return safeGet(syn, name)
	end,
}
