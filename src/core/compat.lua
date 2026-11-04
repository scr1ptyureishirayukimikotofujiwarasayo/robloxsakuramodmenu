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
_G = _G or {}
_G.ModMenu = ModMenu
ModMenu.Compat = { missing = missing }
