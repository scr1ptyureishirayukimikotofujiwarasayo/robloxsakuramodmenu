-- features/reviz.luau
-- SakuraVibes999's Reviz Admin command engine, integrated into ModMenu.
-- The command bodies are the verified revival's; the GUI shell, command bar
-- and chat-bar plumbing are replaced by ModMenu's Console panel.
ModMenu.Features = ModMenu.Features or {}
ModMenu.Features.Reviz = (function()
    local Reviz = {}

    -- The Console panel overrides log/onCommands so command feedback appears
    -- in the panel instead of only in the F9 console.
    Reviz.log = function() end
    Reviz.onCommands = nil
    Reviz.chatEnabled = true
    Reviz.commands = {}
    local showCommandList

    local prefix = ":"
    local lplayer
    local plr
    local mouse

    local change, GetPlayer, plrchat, apply
    local Char, Local, added, adminversion, annoying, annplr, attplr, b, banpl, binds, box, bplrr, brplr, cbring, cbringall, cbringing, changingstate, chatlogs, clickdel, clickgoto, droppinghats, droppingtools, flwplr, flying, followed, gettingtools, handleSize, hdwplr, hwalk, loc, no, noclip, objtodel, pmspammed, remotes, removingmeshhats, removingmeshtool, saved, spamdelay, spamming, spammingpm, spamtext, speedfly, speedget, spin, spinplr, stareplr, staring, statechosen, stopsitting, touched, tpdback, traill, trlplr, vis

local function on(signal, handler)
    local connection = signal:Connect(handler)
    table.insert(ModMenu.State.getConnections("reviz"), connection)
    return connection
end

-- Keeps the long lived loops alive and stops them spamming the console after a death.
local revizLoopErrors = {}
local function guarded(handler)
    return function(...)
        local ok, err = pcall(handler, ...)
        if not ok then
            local key = tostring(err)
            if not revizLoopErrors[key] then
                revizLoopErrors[key] = true
                warn("[reviz] loop error (further repeats suppressed): " .. key)
            end
        end
    end
end

-- 'remotes' used to add another set of listeners every time it was run.
local revizRemoteConnections = {}
local function onRemotes(signal, handler)
    local connection = signal:Connect(handler)
    table.insert(revizRemoteConnections, connection)
    return connection
end

local function clearRemotes()
    for _, connection in ipairs(revizRemoteConnections) do
        pcall(function() connection:Disconnect() end)
    end
    revizRemoteConnections = {}
end

local function onGuarded(signal, handler)
    return on(signal, guarded(handler))
end

local StarterGuiService = game:GetService("StarterGui")
local TextChatService = game:GetService("TextChatService")
local WorkspaceService = game:GetService("Workspace")

local function safeSetCore(name, data)
    local ok, err = pcall(function()
        return StarterGuiService:SetCore(name, data)
    end)
    if not ok then
        warn("[reviz] SetCore " .. tostring(name) .. " failed: " .. tostring(err))
    end
    if name == "SendNotification" and type(data) == "table" then
        pcall(Reviz.log, "[" .. tostring(data.Title) .. "] " .. tostring(data.Text))
    end
end

local function sendChat(text)
    local legacy = pcall(function()
        local chatEvents = game:GetService("ReplicatedStorage"):FindFirstChild("DefaultChatSystemChatEvents")
        local request = chatEvents and chatEvents:FindFirstChild("SayMessageRequest")
        if not request then error("legacy chat system not present") end
        request:FireServer(text, "All")
    end)
    if legacy then return true end
    local modern = pcall(function()
        local channels = TextChatService:FindFirstChild("TextChannels")
        local channel = channels and (channels:FindFirstChild("RBXGeneral") or channels:FindFirstChild("General"))
        if not channel then error("no TextChatService channel") end
        channel:SendAsync(text)
    end)
    if not modern then
        warn("[reviz] chat send failed: " .. tostring(text))
    end
    return modern
end

local function loadAnim(humanoid, animation)
    if not humanoid then return nil end
    local animator = humanoid:FindFirstChildOfClass("Animator")
    if not animator then
        animator = Instance.new("Animator")
        animator.Parent = humanoid
    end
    return animator:LoadAnimation(animation)
end

-- R6 name -> R15 fallbacks, so the R6-era commands do not throw in R15 games.
local LIMB_ALIASES = {
    ["Torso"] = { "Torso", "UpperTorso", "LowerTorso", "HumanoidRootPart" },
    ["Left Leg"] = { "Left Leg", "LeftUpperLeg", "LeftLowerLeg", "LeftFoot" },
    ["Right Leg"] = { "Right Leg", "RightUpperLeg", "RightLowerLeg", "RightFoot" },
    ["Left Arm"] = { "Left Arm", "LeftUpperArm", "LeftLowerArm", "LeftHand" },
    ["Right Arm"] = { "Right Arm", "RightUpperArm", "RightLowerArm", "RightHand" },
}

local function limb(character, name)
    if not character then return nil end
    local candidates = LIMB_ALIASES[name] or { name }
    for _, candidate in ipairs(candidates) do
        local part = character:FindFirstChild(candidate)
        if part then return part end
    end
    return character:FindFirstChild("HumanoidRootPart") or character:FindFirstChild("Head")
end

local function anchorCharacter(character, anchored)
    if not character then return end
    for _, name in ipairs({ "Left Leg", "Left Arm", "Right Leg", "Right Arm", "Torso" }) do
        local part = limb(character, name)
        if part then part.Anchored = anchored end
    end
    local head = character:FindFirstChild("Head")
    if head then head.Anchored = anchored end
end

local function removeMesh(handle)
    if not handle then return end
    local mesh = handle:FindFirstChild("Mesh") or handle:FindFirstChildOfClass("SpecialMesh")
    if mesh then mesh:Destroy() end
end

local function loadAsset(assetId, label)
    local ok, err = pcall(function()
        local objects = game:GetObjects(assetId)
        local source = objects and objects[1] and objects[1].Source
        if not source then error("asset source unavailable") end
        local chunk = loadstring(source)
        if not chunk then error("asset did not compile") end
        chunk()
    end)
    if not ok then
        warn("[reviz] " .. tostring(label or assetId) .. " unavailable: " .. tostring(err))
    end
    return ok
end

local function loadDex()
    if loadAsset("rbxassetid://492005721", "Dex asset") then return true end
    if type(readfile) == "function" then
        for _, path in ipairs({ "Dex Explorer (Embedded).lua", "Dex Explorer.lua", "dex.lua" }) do
            local ok, data = pcall(readfile, path)
            if ok and type(data) == "string" then
                local chunk = loadstring(data)
                if chunk and pcall(chunk) then return true end
            end
        end
    end
    safeSetCore("SendNotification", {
        Title = "Dex unavailable",
        Text = "The old asset is gone. Put Dex Explorer (Embedded).lua in your executor workspace.",
    })
    return false
end

local function pgsEnabled()
    local ok, result = pcall(function() return WorkspaceService:PGSIsEnabled() end)
    if ok and result ~= nil then return result end
    local ok2, result2 = pcall(function() return WorkspaceService.PGSPhysicsSolverEnabled end)
    if ok2 then return result2 end
    return true
end

    -- Original command list, shown by the Console panel's List Commands button.
    local Commands = {
        '[-] cmdbar is shown when ; is pressed.',
        '[1] kill [plr] -- You need a tool! Will kill the player, use rkill to kill you and player',
        '[2] bring [plr] -- You need a tool! Will bring player to you',
        '[3] spin [plr] -- You need a tool! Makes you and the player spin crazy',
        '[4] unspin -- Use after using spin cmd and dying, so you stop loop teleporting',
        '[5] attach [plr] -- You need a tool! Attaches you to player',
        '[6] unattach [plr] -- Attempts to unattach you from a player',
        '[7] follow [plr] -- Makes you follow behind the player',
        '[8] unfollow',
        '[9] freefall [plr] -- You need a tool! Teleports you and the player up into the air',
        '[10] trail [plr] -- The opposite of follow, you stay infront of player',
        '[11] untrail',
        '[12] orbit [plr] -- Makes you orbit the player',
        '[13] unorbit',
        '[14] fling [plr] -- Makes you fling the player',
        '[15] unfling',
        '[16] fecheck -- Checks if the game is FE or not',
        '[17] void [plr] -- Teleports player to the void',
        '[18] noclip -- Gives you noclip to walk through walls',
        '[19] clip -- Removes noclip',
        '[20] speed [num]/ws [num] -- Changes how fast you walk 16 is default',
        '[21] jumppower [num]/jp [num] -- Changes how high you jump 50 is default',
        '[22] hipheight [num]/hh [num] -- Changes how high you float 0 is default',
        '[23] default -- Changes your speed, jumppower and hipheight to default values',
        '[24] annoy [plr] -- Loop teleports you to the player',
        '[25] unannoy',
        '[26] headwalk [plr] -- Loop teleports you to the player head',
        '[27] unheadwalk',
        '[28] nolimbs -- Removes your arms and legs',
        '[29] god -- Gives you FE Godmode',
        '[30] drophats -- Drops your accessories',
        '[31] droptool -- Drops any tool you have equipped',
        '[32] loopdhats -- Loop drops your accessories',
        '[33] unloopdhats',
        '[34] loopdtool -- Loop drops any tools you have equipped',
        '[35] unloopdtool',
        '[36] invisible -- Gives you invisibility CREDIT TO TIMELESS',
        '[37] view [plr] -- Changes your camera to the player character',
        '[38] unview',
        '[39] goto [plr] -- Teleports you to player',
        '[40] fly -- Allows you to fly, credit to Infinite Yield',
        '[41] unfly',
        '[42] chat [msg] -- Makes you chat a message',
        '[43] spam [msg] -- Spams a message',
        '[44] unspam',
        '[45] spamwait [num] -- Changes delay of chatting a message for the spam command in seconds default is 1 second',
        '[46] pmspam [plr] -- Spams a player in private message',
        '[47] unpmspam',
        '[48] cfreeze [plr] -- Freezes a player on your client, they will only be frozen for you',
        '[49] uncfreeze [plr]',
        '[50] unlockws -- Unlocks the workspace',
        '[51] lockws -- Locks the workspace',
        '[52] btools -- Gives you btools that will only show to you useful for deleting certain blocks only for you',
        '[53] pstand -- Enables platform stand',
        '[54] unpstand -- Disables platform stand',
        '[55] blockhead -- Removes your head mesh',
        '[56] sit',
        '[57] bringobj [obj] -- Only shows on client, brings an object/part to you constantly, can be used to bring healing parts, weapons, money etc, type in exact name',
        '[58] wsvis [num] -- Changes visibility of workspace parts, num should be between 0 and 1, only shows client sided',
        '[59] hypertotal -- Loads in my FE GUI Hypertotal',
        '[60] cmds -- Prints all commands',
        '[61] rmeshhats/blockhats -- Removes the meshes of all your accessories aka block hats',
        '[62] rmeshtool/blocktool -- Removes the mesh of the tool you have equipped aka block tool',
        '[63] spinner -- Makes you spin',
        '[64] nospinner',
        '[65] reach [num] -- Gives you reach, mostly used for swords, say ;reachd for default and enter number after for custom',
        '[66] noreach -- Removes reach, must have tool equipped',
        '[67] rkill [plr] -- Kills you and the player, use kill to just kill the player without dying',
        '[68] tp me [plr] -- Alternative to goto',
        '[69] cbring [plr] -- Brings player infront of you, shows only on client, allows you to do damage to player',
        '[70] uncbring',
        '[71] swap [plr] -- You need a tool! Swaps players position with yours and your position with players',
        '[72] givetool [plr] -- Gives the tool you have equipped to the player',
        '[73] glitch [plr] -- Glitches you and the player, looks very cool',
        '[74] unglitch -- Unglitches you',
        '[75] grespawn -- Alternative to normal respawn and usually works best for when you want to reset with FE Godmode',
        '[76] explorer -- Loads up DEX',
        '[77] reset -- Resets your character.',
        '[78] anim [id] -- Applies an animation on you, must be created by ROBLOX',
        '[79] animgui -- Loads up Energize animations GUI',
        '[80] savepos -- Saves your current position',
        '[81] loadpos -- Teleports you to your saved position',
        '[82] bang [plr] -- 18+ will not work if you have FE Godmode on',
        '[83] unbang',
        '[84] delcmdbar -- Removes the command bar completely',
        '[85] bringmod [obj] -- Brings all the parts in a model, client only, comes from ;bringobj enter exact name of model',
        '[86] shutdown -- Uses harkinians script to shutdown server',
        '[87] respawn -- If grespawn doesnt work you can use respawn',
        '[88] delobj [obj] -- Deletes a certain brick in workspace, client sided',
        '[89] getplrs -- Prints all players in game',
        '[90] deldecal -- Deletes all decals client sided',
        '[91] opfinality -- Loads in my FE GUI Opfinality',
        '[92] remotes -- Prints all remotes in the game in the console when added',
        '[93] noremotes -- Stops printing remotes',
        '[94] tpdefault -- Stops all loop teleports to a player',
        '[95] stopsit -- Will not allow you to sit',
        '[96] gosit -- Allows you to sit',
        '[97] clicktp -- Enables click tp',
        '[98] noclicktp -- Disables click tp',
        '[99] toolson -- If any tools are dropped in the workspace you will automatically get them',
        '[100] toolsoff -- Stops ;toolson',
        '[101] version -- Gets the admin version',
        '[102] state [num] -- Changes your humanoid state, ;unstate to stop.',
        '[103] gravity [num] -- Changes workspace gravity default is 196.2',
        '[104] pgs -- Checks if the game has PGSPhysicsSolverEnabled enabled',
        '[105] clickdel -- Delete any block you press q on, client sided',
        '[106] noclickdel -- Stops clickdel',
        '[107] looprhats -- Loop removes mesh of your hats/loop block hats',
        '[108] unlooprhats -- Stops loop removing mesh',
        '[109] looprtool -- Loop removes mesh of your tool/loop block tools',
        '[110] unlooprtool -- Stops loop removing mesh',
        '[111] givealltools [plr] -- Gives all the tools you have in your backpack to the player',
        '[112] age [plr] -- Makes you chat the account age of the player',
        '[113] id [plr] -- Makes you chat the account ID of the player',
        '[114] .age [plr] -- Privately shows you the account age of the player',
        '[115] .id [plr] -- Privately shows you the account ID of the player',
        '[116] gameid -- Shows the game ID',
        '[117] removeinvis -- Removes all invisible walls/parts, client sided',
        '[118] removefog -- Removes fog, client sided',
        '[119] disable -- Disables your character by removing humanoid',
        '[120] enable -- Enables your character by adding humanoid',
        '[121] prefix [key] -- Changes the prefix used, default is ;',
        '[122] ;resetprefix -- Resets the prefix to ; incase you change it to an unusable prefix. Say exactly ";resetprefix" to do this command, no matter what your prefix is set to.',
        '[123] flyspeed [num] -- Change your fly speed, default is 1',
        '[124] carpet [plr] -- Makes you a carpet for a player, will not work if FE Godmode is on',
        '[125] uncarpet -- Stops carpet player',
        '[126] stare [plr] -- Turns your character to stare at another player',
        '[127] unstare -- Stops stare player',
        '[128] logchat -- Logs all chat (including /e and whispers) of all players',
        '[129] unlogchat -- Disables logchat',
        '[130] fixcam -- Fixes/resets your camera',
        '[131] unstate -- Stops changing state',
    }

speedget = 1
 
lplayer = game:GetService("Players").LocalPlayer
 
on(lplayer.CharacterAdded, function(character)
    spin = false
    flying = false
    staring = false
    banpl = false
end)
 
function change()
    prefix = prefix
    speedfly = speedfly
end
 
function GetPlayer(String) -- Credit to Timeless/xFunnieuss
    local Found = {}
    local strl = String:lower()
    if strl == "all" then
        for i,v in pairs(game:GetService("Players"):GetPlayers()) do
            table.insert(Found,v)
        end
    elseif strl == "others" then
        for i,v in pairs(game:GetService("Players"):GetPlayers()) do
            if v.Name ~= lplayer.Name then
                table.insert(Found,v)
            end
        end  
    elseif strl == "me" then
        for i,v in pairs(game:GetService("Players"):GetPlayers()) do
            if v.Name == lplayer.Name then
                table.insert(Found,v)
            end
        end  
    else
        for i,v in pairs(game:GetService("Players"):GetPlayers()) do
            if v.Name:lower():sub(1, #String) == String:lower() then
                table.insert(Found,v)
            end
        end    
    end
    return Found    
end
 
spin = false
followed = false
traill = false
noclip = false
annoying = false
hwalk = false
droppinghats = false
droppingtools = false
flying = false
spamdelay = 1
spamming = false
spammingpm = false
cbringing = false
remotes = true
added = true
binds = false
stopsitting = false
clickgoto = false
gettingtools = false
removingmeshhats = false
removingmeshtool = false
clickdel = false
staring = false
chatlogs = false
banpl = false
changingstate = false
statechosen = 0
 
adminversion = "SakuraVibes999's Reviz Admin by sakuravibes999, Version 2.0"
 
flying = false
speedfly = 1
 
function plrchat(plr, chat)
print(plr.Name..": "..tick().."\n"..chat)
end
 
for i,v in pairs(game:GetService("Players"):GetPlayers()) do
on(v.Chatted, function(chat)
if chatlogs then
plrchat(v, chat)
end
end)
end
on(game:GetService("Players").PlayerAdded, function(plr)
on(plr.Chatted, function(chat)
if chatlogs then
plrchat(plr, chat)
end
end)
end)
 
 

onGuarded(game:GetService('RunService').Stepped, function()
    if spin then
        lplayer.Character.HumanoidRootPart.CFrame = game:GetService("Players")[spinplr.Name].Character.HumanoidRootPart.CFrame
    end
    if followed then
        lplayer.Character.HumanoidRootPart.CFrame = game:GetService("Players")[flwplr.Name].Character.HumanoidRootPart.CFrame + game:GetService("Players")[flwplr.Name].Character.HumanoidRootPart.CFrame.lookVector * -5
    end
    if traill then
        lplayer.Character.HumanoidRootPart.CFrame = game:GetService("Players")[trlplr.Name].Character.HumanoidRootPart.CFrame + game:GetService("Players")[trlplr.Name].Character.HumanoidRootPart.CFrame.lookVector * 5
    end
    if annoying then
        lplayer.Character.HumanoidRootPart.CFrame = game:GetService("Players")[annplr.Name].Character.HumanoidRootPart.CFrame
    end
    if hwalk then
        lplayer.Character.HumanoidRootPart.CFrame = game:GetService("Players")[hdwplr.Name].Character.HumanoidRootPart.CFrame + Vector3.new(0, 4, 0)
    end
    if staring then
        lplayer.Character.HumanoidRootPart.CFrame = CFrame.new(limb(lplayer.Character, "Torso").Position, game:GetService("Players")[stareplr.Name].Character.Torso.Position)
    end
end)
onGuarded(game:GetService('RunService').Stepped, function()
    if noclip then
        if lplayer.Character.Humanoid.RigType == Enum.HumanoidRigType.R6 then
            lplayer.Character.Head.CanCollide = false
            limb(lplayer.Character, "Torso").CanCollide = false
            limb(lplayer.Character, "Left Leg").CanCollide = false
            limb(lplayer.Character, "Right Leg").CanCollide = false
        else
            lplayer.Character.Humanoid:ChangeState(11)
        end
    end
    if changingstate then
        lplayer.Character.Humanoid:ChangeState(statechosen)
    end
end)
onGuarded(game:GetService('RunService').Stepped, function()
    if droppinghats then
        for i,v in pairs(lplayer.Character:GetChildren()) do
            if (v:IsA("Accessory")) or (v:IsA("Hat")) then
                v.Parent = workspace
            end
        end
    end
    if droppingtools then
        for i,v in pairs(lplayer.Character:GetChildren()) do
            if (v:IsA("Tool")) then
                v.Parent = workspace
            end
        end
    end
    if removingmeshhats then
        for i,v in pairs(lplayer.Character:GetChildren()) do
            if (v:IsA("Accessory")) or (v:IsA("Hat")) then
                removeMesh(v.Handle)
            end
        end
    end
    if removingmeshtool then
        for i,v in pairs(lplayer.Character:GetChildren()) do
            if (v:IsA("Tool")) then
                removeMesh(v.Handle)
            end
        end
    end
end)
onGuarded(game:GetService('RunService').Stepped, function()
    if banpl then
        lplayer.Character.HumanoidRootPart.CFrame = game:GetService("Players")[bplrr].Character.HumanoidRootPart.CFrame
    end
end)
onGuarded(game:GetService('RunService').Stepped, function()
    if stopsitting then
        lplayer.Character.Humanoid.Sit = false
    end
end)
 
plr = lplayer
mouse = plr:GetMouse()
on(mouse.KeyDown, function(key)
    if key == "e" then
        local character = lplayer.Character
        local root = character and character:FindFirstChild("HumanoidRootPart")
        if mouse.Target and root then
            if clickgoto then
                root.CFrame = CFrame.new(mouse.Hit.x, mouse.Hit.y + 5, mouse.Hit.z)
            elseif clickdel then
                mouse.Target:Destroy()
            end
        end
    end
end)
 
on(game:GetService("Workspace").ChildAdded, function(part)
    if gettingtools then
        if part:IsA("Tool") then
            part.Handle.CFrame = lplayer.Character.HumanoidRootPart.CFrame
        end
    end
end)
 

local function Execute(msg)
    if string.sub(msg, 1, 6) == (prefix.."kill ") then
        if string.sub(msg, 7) == "me" then
            lplayer.Character.HumanoidRootPart.CFrame = CFrame.new(100000,0,100000)
        else
            for i,v in pairs(GetPlayer(string.sub(msg, 7)))do
                local NOW = lplayer.Character.HumanoidRootPart.CFrame
                lplayer.Character.Humanoid.Name = "1"
                local l = lplayer.Character["1"]:Clone()
                l.Parent = lplayer.Character
                l.Name = "Humanoid"
                task.wait(0.1)
                lplayer.Character["1"]:Destroy()
                game:GetService("Workspace").CurrentCamera.CameraSubject = lplayer.Character
                lplayer.Character.Animate.Disabled = true
                task.wait(0.1)
                lplayer.Character.Animate.Disabled = false
                lplayer.Character.Humanoid.DisplayDistanceType = "None"
                for i,v in pairs(game:GetService'Players'.LocalPlayer.Backpack:GetChildren())do
                lplayer.Character.Humanoid:EquipTool(v)
                end
                local function tp(player,player2)
                local char1,char2=player.Character,player2.Character
                if char1 and char2 then
                char1:MoveTo(char2.Head.Position)
                end
                end
                task.wait(0.1)
                lplayer.Character.HumanoidRootPart.CFrame = game:GetService("Players")[v.Name].Character.HumanoidRootPart.CFrame
                task.wait(0.2)
                lplayer.Character.HumanoidRootPart.CFrame = game:GetService("Players")[v.Name].Character.HumanoidRootPart.CFrame
                task.wait(0.5)
                lplayer.Character.HumanoidRootPart.CFrame = CFrame.new(Vector3.new(-100000,10,-100000))
                task.wait(0.7)
                tp(lplayer,game:GetService("Players")[v.Name])
                task.wait(0.7)
                lplayer.Character.HumanoidRootPart.CFrame = NOW
                safeSetCore("SendNotification", {
                Title = "Tools needed!";
                Text = "You need a tool in your backpack for this command!";
                })
            end
        end
    end
    if string.sub(msg, 1, 7) == (prefix.."bring ") then
        for i,v in pairs(GetPlayer(string.sub(msg, 8)))do
            local NOW = lplayer.Character.HumanoidRootPart.CFrame
            lplayer.Character.Humanoid.Name = "1"
            local l = lplayer.Character["1"]:Clone()
            l.Parent = lplayer.Character
            l.Name = "Humanoid"
            task.wait(0.1)
            lplayer.Character["1"]:Destroy()
            game:GetService("Workspace").CurrentCamera.CameraSubject = lplayer.Character
            lplayer.Character.Animate.Disabled = true
            task.wait(0.1)
            lplayer.Character.Animate.Disabled = false
            lplayer.Character.Humanoid.DisplayDistanceType = "None"
            for i,v in pairs(game:GetService'Players'.LocalPlayer.Backpack:GetChildren())do
            lplayer.Character.Humanoid:EquipTool(v)
            end
            local function tp(player,player2)
            local char1,char2=player.Character,player2.Character
            if char1 and char2 then
            char1.HumanoidRootPart.CFrame = char2.HumanoidRootPart.CFrame
            end
            end
            local function getout(player,player2)
            local char1,char2=player.Character,player2.Character
            if char1 and char2 then
            char1:MoveTo(char2.Head.Position)
            end
            end
            tp(game:GetService("Players")[v.Name], lplayer)
            task.wait(0.2)
            tp(game:GetService("Players")[v.Name], lplayer)
            task.wait(0.5)
            lplayer.Character.HumanoidRootPart.CFrame = NOW
            task.wait(0.5)
            getout(lplayer, game:GetService("Players")[v.Name])
            task.wait(0.3)
            lplayer.Character.HumanoidRootPart.CFrame = NOW
            safeSetCore("SendNotification", {
            Title = "Tools needed!";
            Text = "You need a tool in your backpack for this command!";
            })
        end
    end
    if string.sub(msg, 1, 6) == (prefix.."spin ") then
        for i,v in pairs(GetPlayer(string.sub(msg, 7))) do
            lplayer.Character.Humanoid.Name = "1"
            local l = lplayer.Character["1"]:Clone()
            l.Parent = lplayer.Character
            l.Name = "Humanoid"
            task.wait(0.1)
            lplayer.Character["1"]:Destroy()
            game:GetService("Workspace").CurrentCamera.CameraSubject = lplayer.Character
            lplayer.Character.Animate.Disabled = true
            task.wait(0.1)
            lplayer.Character.Animate.Disabled = false
            lplayer.Character.Humanoid.DisplayDistanceType = "None"
            lplayer.Character.Animate.Disabled = false
            for i,v in pairs(game:GetService'Players'.LocalPlayer.Backpack:GetChildren())do
            lplayer.Character.Humanoid:EquipTool(v)
            end
            lplayer.Character.HumanoidRootPart.CFrame = limb(game:GetService("Players")[v.Name].Character, "Left Arm").CFrame
            spinplr = v
            task.wait(0.5)
            spin = true
            safeSetCore("SendNotification", {
            Title = "Tools needed!";
            Text = "You need a tool in your backpack for this command!";
            })
        end
    end
    if string.sub(msg, 1, 7) == (prefix.."unspin") then
        spin = false
    end
    if string.sub(msg, 1, 8) == (prefix.."attach ") then
        for i,v in pairs(GetPlayer(string.sub(msg, 9))) do
            lplayer.Character.Humanoid.Name = "1"
            local l = lplayer.Character["1"]:Clone()
            l.Parent = lplayer.Character
            l.Name = "Humanoid"
            task.wait(0.1)
            lplayer.Character["1"]:Destroy()
            game:GetService("Workspace").CurrentCamera.CameraSubject = lplayer.Character
            lplayer.Character.Animate.Disabled = true
            task.wait(0.1)
            lplayer.Character.Animate.Disabled = false
            lplayer.Character.Humanoid.DisplayDistanceType = "None"
            for i,v in pairs(game:GetService'Players'.LocalPlayer.Backpack:GetChildren())do
            lplayer.Character.Humanoid:EquipTool(v)
            end
            lplayer.Character.HumanoidRootPart.CFrame = limb(game:GetService("Players")[v.Name].Character, "Left Arm").CFrame
            task.wait(0.3)
            lplayer.Character.HumanoidRootPart.CFrame = limb(game:GetService("Players")[v.Name].Character, "Left Arm").CFrame
            attplr = v
            safeSetCore("SendNotification", {
            Title = "Tools needed!";
            Text = "You need a tool in your backpack for this command!";
            })
        end
    end
    if string.sub(msg, 1, 10) == (prefix.."unattach ") then
        for i,v in pairs(GetPlayer(string.sub(msg, 11))) do
            local function getout(player,player2)
            local char1,char2=player.Character,player2.Character
            if char1 and char2 then
            char1:MoveTo(char2.Head.Position)
            end
            end
            getout(lplayer, game:GetService("Players")[v.Name])
        end
    end
    if string.sub(msg, 1, 8) == (prefix.."follow ") then
        for i,v in pairs(GetPlayer(string.sub(msg, 9))) do
            followed = true
            flwplr = v
        end
    end
    if string.sub(msg, 1, 9) == (prefix.."unfollow") then
        followed = false
    end
    if string.sub(msg, 1, 10) == (prefix.."freefall ") then
        for i,v in pairs(GetPlayer(string.sub(msg, 11))) do
            local NOW = lplayer.Character.HumanoidRootPart.CFrame
            lplayer.Character.Humanoid.Name = "1"
            local l = lplayer.Character["1"]:Clone()
            l.Parent = lplayer.Character
            l.Name = "Humanoid"
            task.wait(0.1)
            lplayer.Character["1"]:Destroy()
            game:GetService("Workspace").CurrentCamera.CameraSubject = lplayer.Character
            lplayer.Character.Animate.Disabled = true
            task.wait(0.1)
            lplayer.Character.Animate.Disabled = false
            lplayer.Character.Humanoid.DisplayDistanceType = "None"
            for i,v in pairs(game:GetService'Players'.LocalPlayer.Backpack:GetChildren())do
            lplayer.Character.Humanoid:EquipTool(v)
            end
            lplayer.Character.HumanoidRootPart.CFrame = game:GetService("Players")[v.Name].Character.HumanoidRootPart.CFrame
            task.wait(0.2)
            lplayer.Character.HumanoidRootPart.CFrame = game:GetService("Players")[v.Name].Character.HumanoidRootPart.CFrame
            task.wait(0.6)
            lplayer.Character.HumanoidRootPart.CFrame = NOW
            task.wait(0.6)
            lplayer.Character.HumanoidRootPart.CFrame = CFrame.new(0,50000,0)
            safeSetCore("SendNotification", {
            Title = "Tools needed!";
            Text = "You need a tool in your backpack for this command!";
            })
        end
    end
    if string.sub(msg, 1, 7) == (prefix.."trail ") then
        for i,v in pairs(GetPlayer(string.sub(msg, 8))) do
            traill = true
            trlplr = v
        end
    end
    if string.sub(msg, 1, 8) == (prefix.."untrail") then
        traill = false
    end
    if string.sub(msg, 1, 7) == (prefix.."orbit ") then
        if string.sub(msg, 8) == "all" or string.sub(msg, 8) == "others" or string.sub(msg, 8) == "me" then
            lplayer.Character.HumanoidRootPart.CFrame = lplayer.Character.HumanoidRootPart.CFrame
        else
            for i,v in pairs(GetPlayer(string.sub(msg, 8))) do
                local o = Instance.new("RocketPropulsion")
                o.Parent = lplayer.Character.HumanoidRootPart
                o.Name = "Orbit"
                o.Target = game:GetService("Players")[v.Name].Character.HumanoidRootPart
                o:Fire()
                noclip = true
            end
        end
    end
    if string.sub(msg, 1, 8) == (prefix.."unorbit") then
        lplayer.Character.HumanoidRootPart.Orbit:Destroy()
        noclip = false
    end
    if string.sub(msg, 1, 7) == (prefix.."fling ") then
        if string.sub(msg, 8) == "all" or string.sub(msg, 8) == "others" or string.sub(msg, 8) == "me" then
            lplayer.Character.HumanoidRootPart.CFrame = lplayer.Character.HumanoidRootPart.CFrame
        else
            for i,v in pairs(GetPlayer(string.sub(msg, 8))) do
                local y = Instance.new("RocketPropulsion")
                y.Parent = lplayer.Character.HumanoidRootPart
                y.CartoonFactor = 1
                y.MaxThrust = 800000
                y.MaxSpeed = 1000
                y.ThrustP = 200000
                y.Name = "Fling"
                game:GetService("Workspace").CurrentCamera.CameraSubject = game:GetService("Players")[v.Name].Character.Head
                y.Target = game:GetService("Players")[v.Name].Character.HumanoidRootPart
                y:Fire()
                noclip = true
            end
        end
    end
    if string.sub(msg, 1, 8) == (prefix.."unfling") then
        noclip = false
        lplayer.Character.HumanoidRootPart.Fling:Destroy()
        game:GetService("Workspace").CurrentCamera.CameraSubject = lplayer.Character.Head
        task.wait(0.4)
        lplayer.Character.HumanoidRootPart.Fling:Destroy()
    end
    if string.sub(msg, 1, 8) == (prefix.."fecheck") then
        if true then
            warn("FE is Enabled (Filtering Enabled)")
            safeSetCore("SendNotification", {
                Title = "FE is Enabled";
                Text = "Filtering Enabled. Enjoy using SakuraVibes999's Reviz Admin!";
            })
        else
            warn("FE is Disabled (Filtering Disabled) Consider using a different admin script.")
            safeSetCore("SendNotification", {
                Title = "FE is Disabled";
                Text = "Filtering Disabled. Consider using a different admin script.";
            })
        end
    end
    if string.sub(msg, 1, 6) == (prefix.."void ") then
        for i,v in pairs(GetPlayer(string.sub(msg, 7))) do
            lplayer.Character.Humanoid.Name = "1"
            local l = lplayer.Character["1"]:Clone()
            l.Parent = lplayer.Character
            l.Name = "Humanoid"
            task.wait(0.1)
            lplayer.Character["1"]:Destroy()
            game:GetService("Workspace").CurrentCamera.CameraSubject = lplayer.Character
            lplayer.Character.Animate.Disabled = true
            task.wait(0.1)
            lplayer.Character.Animate.Disabled = false
            lplayer.Character.Humanoid.DisplayDistanceType = "None"
            for i,v in pairs(game:GetService'Players'.LocalPlayer.Backpack:GetChildren())do
            lplayer.Character.Humanoid:EquipTool(v)
            end
            lplayer.Character.HumanoidRootPart.CFrame = game:GetService("Players")[v.Name].Character.HumanoidRootPart.CFrame
            task.wait(0.2)
            lplayer.Character.HumanoidRootPart.CFrame = game:GetService("Players")[v.Name].Character.HumanoidRootPart.CFrame
            task.wait(0.6)
            lplayer.Character.HumanoidRootPart.CFrame = CFrame.new(999999999999999,0,999999999999999)
            safeSetCore("SendNotification", {
            Title = "Tools needed!";
            Text = "You need a tool in your backpack for this command!";
            })
        end
    end
    if string.sub(msg, 1, 7) == (prefix.."noclip") then
        noclip = true
        safeSetCore("SendNotification", {
        Title = "Noclip enabled";
        Text = "Type ;clip to disable";
        })
    end
    if string.sub(msg, 1, 5) == (prefix.."clip") then
        noclip = false
        safeSetCore("SendNotification", {
        Title = "Noclip disabled";
        Text = "Type ;noclip to enable";
        })
    end
    if string.sub(msg, 1, 7) == (prefix.."speed ") then
        lplayer.Character.Humanoid.WalkSpeed = (string.sub(msg, 8))
    end
    if string.sub(msg, 1, 4) == (prefix.."ws ") then
        lplayer.Character.Humanoid.WalkSpeed = (string.sub(msg, 5))
    end
    if string.sub(msg, 1, 11) == (prefix.."hipheight ") then
        lplayer.Character.Humanoid.HipHeight = (string.sub(msg, 12))
    end
    if string.sub(msg, 1, 4) == (prefix.."hh ") then
        lplayer.Character.Humanoid.HipHeight = (string.sub(msg, 5))
    end
    if string.sub(msg, 1, 11) == (prefix.."jumppower ") then
        lplayer.Character.Humanoid.JumpPower = (string.sub(msg, 12))
    end
    if string.sub(msg, 1, 4) == (prefix.."jp ") then
        lplayer.Character.Humanoid.JumpPower = (string.sub(msg, 5))
    end
    if string.sub(msg, 1, 8) == (prefix.."default") then
        lplayer.Character.Humanoid.JumpPower = 50
        lplayer.Character.Humanoid.WalkSpeed = 16
        lplayer.Character.Humanoid.HipHeight = 0
    end
    if string.sub(msg, 1, 7) == (prefix.."annoy ") then
        for i,v in pairs(GetPlayer(string.sub(msg, 8))) do
            annoying = true
            annplr = v
        end
    end
    if string.sub(msg, 1, 8) == (prefix.."unannoy") then
        annoying = false
    end
    if string.sub(msg, 1, 10) == (prefix.."headwalk ") then
        for i,v in pairs(GetPlayer(string.sub(msg, 11))) do
            hwalk = true
            hdwplr = v
        end
    end
    if string.sub(msg, 1, 11) == (prefix.."unheadwalk") then
        hwalk = false
    end
    if string.sub(msg, 1, 8) == (prefix.."nolimbs") then
        limb(lplayer.Character, "Left Leg"):Destroy()
        limb(lplayer.Character, "Left Arm"):Destroy()
        limb(lplayer.Character, "Right Leg"):Destroy()
        limb(lplayer.Character, "Right Arm"):Destroy()
    end
    if string.sub(msg, 1, 4) == (prefix.."god") then
        lplayer.Character.Humanoid.Name = "1"
        local l = lplayer.Character["1"]:Clone()
        l.Parent = lplayer.Character
        l.Name = "Humanoid"
        task.wait(0.1)
        lplayer.Character["1"]:Destroy()
        game:GetService("Workspace").CurrentCamera.CameraSubject = lplayer.Character
        lplayer.Character.Animate.Disabled = true
        task.wait(0.1)
        lplayer.Character.Animate.Disabled = false
        lplayer.Character.Humanoid.DisplayDistanceType = "None"
        safeSetCore("SendNotification", {
        Title = "FE Godmode enabled";
        Text = "Use ;grespawn or ;respawn to remove";
        })
    end
    if string.sub(msg, 1, 9) == (prefix.."drophats") then
        for i,v in pairs(lplayer.Character:GetChildren()) do
            if (v:IsA("Accessory")) or (v:IsA("Hat")) then
                v.Parent = workspace
            end
        end
    end
    if string.sub(msg, 1, 9) == (prefix.."droptool") then
        for i,v in pairs(lplayer.Character:GetChildren()) do
            if (v:IsA("Tool")) then
                v.Parent = workspace
            end
        end
    end
    if string.sub(msg, 1, 10) == (prefix.."loopdhats") then
        droppinghats = true
        safeSetCore("SendNotification", {
        Title = "Loop Drop Enabled";
        Text = "Type ;unloopdhats to disable";
        })
    end
    if string.sub(msg, 1, 12) == (prefix.."unloopdhats") then
        droppinghats = false
        safeSetCore("SendNotification", {
        Title = "Loop Drop Disabled";
        Text = "Type ;loopdhats to enable.";
        })
    end
    if string.sub(msg, 1, 10) == (prefix.."loopdtool") then
        droppingtools = true
        safeSetCore("SendNotification", {
        Title = "Loop Drop Enabled";
        Text = "Type ;unloopdtool to disable";
        })
    end
    if string.sub(msg, 1, 12) == (prefix.."unloopdtool") then
        droppingtools = false
        safeSetCore("SendNotification", {
        Title = "Loop Drop Disabled";
        Text = "Type ;loopdtool to enable.";
        })
    end
    if string.sub(msg, 1, 10) == (prefix.."invisible") then -- Credit to Timeless
        Local = game:GetService('Players').LocalPlayer
        Char  = Local.Character
        touched,tpdback = false, false
        box = Instance.new('Part',workspace)
        box.Anchored = true
        box.CanCollide = true
        box.Size = Vector3.new(10,1,10)
        box.Position = Vector3.new(0,10000,0)
        box.Touched:Connect(function(part)
            if (part.Parent.Name == Local.Name) then
                if touched == false then
                    touched = true
                    function apply()
                        if true then
                            no = Char.HumanoidRootPart:Clone()
                            task.wait(.25)
                            Char.HumanoidRootPart:Destroy()
                            no.Parent = Char
                            Char:MoveTo(loc)
                            touched = false
                        end end
                    if Char then
                        apply()
                    end
                end
            end
        end)
        repeat task.wait() until Char
        loc = Char.HumanoidRootPart.Position
        Char:MoveTo(box.Position + Vector3.new(0,.5,0))
        safeSetCore("SendNotification", {
        Title = "Invisibility enabled!";
        Text = "Reset or use ;respawn to remove.";
        })
    end
    if string.sub(msg, 1, 6) == (prefix.."view ") then
        for i,v in pairs(GetPlayer(string.sub(msg, 7))) do
            if game:GetService("Players")[v.Name].Character.Humanoid then
                game:GetService("Workspace").CurrentCamera.CameraSubject = game:GetService("Players")[v.Name].Character.Humanoid
            else
                game:GetService("Workspace").CurrentCamera.CameraSubject = game:GetService("Players")[v.Name].Character.Head
            end
        end
    end
    if string.sub(msg, 1, 7) == (prefix.."unview") then
        if lplayer.Character.Humanoid then
            game:GetService("Workspace").CurrentCamera.CameraSubject = lplayer.Character.Humanoid
        else
            game:GetService("Workspace").CurrentCamera.CameraSubject = lplayer.Character.Head
        end
    end
    if string.sub(msg, 1, 6) == (prefix.."goto ") then
        for i,v in pairs(GetPlayer(string.sub(msg, 7))) do
            lplayer.Character.HumanoidRootPart.CFrame = game:GetService("Players")[v.Name].Character.HumanoidRootPart.CFrame
        end
    end
    if string.sub(msg, 1, 4) == (prefix.."fly") then
    repeat task.wait() until lplayer and lplayer.Character and lplayer.Character:FindFirstChild('HumanoidRootPart') and lplayer.Character:FindFirstChild('Humanoid')
    repeat task.wait() until mouse
   
    local T = lplayer.Character.HumanoidRootPart
    local CONTROL = {F = 0, B = 0, L = 0, R = 0}
    local lCONTROL = {F = 0, B = 0, L = 0, R = 0}
    local SPEED = speedget
   
    local function fly()
        flying = true
        local BG = Instance.new('BodyGyro', T)
        local BV = Instance.new('BodyVelocity', T)
        BG.P = 9e4
        BG.MaxTorque = Vector3.new(9e9, 9e9, 9e9)
        BG.CFrame = T.CFrame
        BV.Velocity = Vector3.new(0, 0.1, 0)
        BV.MaxForce = Vector3.new(9e9, 9e9, 9e9)
        task.spawn(function()
        repeat task.wait()
        lplayer.Character.Humanoid.PlatformStand = true
        if CONTROL.L + CONTROL.R ~= 0 or CONTROL.F + CONTROL.B ~= 0 then
        SPEED = 50
        elseif not (CONTROL.L + CONTROL.R ~= 0 or CONTROL.F + CONTROL.B ~= 0) and SPEED ~= 0 then
        SPEED = 0
        end
        if (CONTROL.L + CONTROL.R) ~= 0 or (CONTROL.F + CONTROL.B) ~= 0 then
        BV.Velocity = ((workspace.CurrentCamera.CFrame.lookVector * (CONTROL.F + CONTROL.B)) + ((workspace.CurrentCamera.CFrame * CFrame.new(CONTROL.L + CONTROL.R, (CONTROL.F + CONTROL.B) * 0.2, 0).p) - workspace.CurrentCamera.CFrame.p)) * SPEED
        lCONTROL = {F = CONTROL.F, B = CONTROL.B, L = CONTROL.L, R = CONTROL.R}
        elseif (CONTROL.L + CONTROL.R) == 0 and (CONTROL.F + CONTROL.B) == 0 and SPEED ~= 0 then
        BV.Velocity = ((workspace.CurrentCamera.CFrame.lookVector * (lCONTROL.F + lCONTROL.B)) + ((workspace.CurrentCamera.CFrame * CFrame.new(lCONTROL.L + lCONTROL.R, (lCONTROL.F + lCONTROL.B) * 0.2, 0).p) - workspace.CurrentCamera.CFrame.p)) * SPEED
        else
        BV.Velocity = Vector3.new(0, 0.1, 0)
        end
        BG.CFrame = workspace.CurrentCamera.CFrame
                until not flying
                CONTROL = {F = 0, B = 0, L = 0, R = 0}
                lCONTROL = {F = 0, B = 0, L = 0, R = 0}
                SPEED = 0
                BG:Destroy()
                BV:Destroy()
                lplayer.Character.Humanoid.PlatformStand = false
            end)
        end
    mouse.KeyDown:Connect(function(KEY)
        if KEY:lower() == 'w' then
            CONTROL.F = speedfly
        elseif KEY:lower() == 's' then
            CONTROL.B = -speedfly
        elseif KEY:lower() == 'a' then
            CONTROL.L = -speedfly
        elseif KEY:lower() == 'd' then
            CONTROL.R = speedfly
        end
    end)
    mouse.KeyUp:Connect(function(KEY)
        if KEY:lower() == 'w' then
            CONTROL.F = 0
        elseif KEY:lower() == 's' then
            CONTROL.B = 0
        elseif KEY:lower() == 'a' then
            CONTROL.L = 0
        elseif KEY:lower() == 'd' then
            CONTROL.R = 0
        end
    end)
    fly()
    end
    if string.sub(msg, 1, 6) == (prefix.."unfly") then
        flying = false
        lplayer.Character.Humanoid.PlatformStand = false
    end
    if string.sub(msg, 1, 6) == (prefix.."chat ") then
        sendChat((string.sub(msg, 7)))
    end
    if string.sub(msg, 1, 6) == (prefix.."spam ") then
        spamtext = (string.sub(msg, 7))
        spamming = true
    end
    if string.sub(msg, 1, 7) == (prefix.."unspam") then
        spamming = false
    end
    if string.sub(msg, 1, 10) == (prefix.."spamwait ") then
        spamdelay = tonumber(string.sub(msg, 11)) or 1
    end
    if string.sub(msg, 1, 8) == (prefix.."pmspam ") then
        for i,v in pairs(GetPlayer(string.sub(msg, 9))) do
            pmspammed = v.Name
            spammingpm = true
        end
    end
    if string.sub(msg, 1, 9) == (prefix.."unpmspam") then
        spammingpm = false
    end
    if string.sub(msg, 1, 9) == (prefix.."cfreeze ") then
        for i,v in pairs(GetPlayer(string.sub(msg, 10))) do
            anchorCharacter(v.Character, true)
        end
    end
    if string.sub(msg, 1, 11) == (prefix.."uncfreeze ") then
        for i,v in pairs(GetPlayer(string.sub(msg, 12))) do
            anchorCharacter(v.Character, false)
        end
    end
    if string.sub(msg, 1, 9) == (prefix.."unlockws") then
        local a = game:GetService("Workspace"):GetChildren()
        for i = 1, #a do
            if a[i].ClassName == "Part" then
                a[i].Locked = false
            elseif a[i].ClassName == "Model" then
                local r = a[i]:GetChildren()
                for i = 1, #r do
                    if r[i].ClassName == "Part" then
                    r[i].Locked = false
                    end
                end
            end
        end
        safeSetCore("SendNotification", {
        Title = "Success!";
        Text = "Workspace unlocked. Use ;lockws to lock.";
        })
    end
    if string.sub(msg, 1, 7) == (prefix.."lockws") then
        local a = game:GetService("Workspace"):GetChildren()
        for i = 1, #a do
            if a[i].ClassName == "Part" then
                a[i].Locked = true
            elseif a[i].ClassName == "Model" then
                local r = a[i]:GetChildren()
                for i = 1, #r do
                    if r[i].ClassName == "Part" then
                    r[i].Locked = true
                    end
                end
            end
        end
    end
    if string.sub(msg, 1, 7) == (prefix.."btools") then
        local Clone_T = Instance.new("HopperBin",lplayer.Backpack)
        Clone_T.BinType = "Clone"
        local Destruct = Instance.new("HopperBin",lplayer.Backpack)
        Destruct.BinType = "Hammer"
        local Hold_T = Instance.new("HopperBin",lplayer.Backpack)
        Hold_T.BinType = "Grab"
    end
    if string.sub(msg, 1, 7) == (prefix.."pstand") then
        lplayer.Character.Humanoid.PlatformStand = true
    end
    if string.sub(msg, 1, 9) == (prefix.."unpstand") then
        lplayer.Character.Humanoid.PlatformStand = false
    end
    if string.sub(msg, 1, 10) == (prefix.."blockhead") then
        removeMesh(lplayer.Character.Head)
    end
    if string.sub(msg, 1, 4) == (prefix.."sit") then
        lplayer.Character.Humanoid.Sit = true
    end
    if string.sub(msg, 1, 10) == (prefix.."bringobj ") then
        local function bringobjw()
        for i,obj in ipairs(game:GetService("Workspace"):GetDescendants()) do
        if obj.Name == (string.sub(msg, 11)) and obj:IsA("BasePart") then
        obj.CFrame = lplayer.Character.HumanoidRootPart.CFrame
        obj.CanCollide = false
        obj.Transparency = 0.7
        task.wait()
        obj.CFrame = limb(lplayer.Character, "Left Leg").CFrame
        task.wait()
        obj.CFrame = limb(lplayer.Character, "Right Leg").CFrame
        task.wait()
        obj.CFrame = lplayer.Character["Head"].CFrame
        end
        end
        end
        while task.wait() do
            bringobjw()
        end
        safeSetCore("SendNotification", {
        Title = "BringObj";
        Text = "BringObj enabled.";
        })
    end
    if string.sub(msg, 1, 7) == (prefix.."wsvis ") then
        vis = (string.sub(msg, 8))
        local a = game:GetService("Workspace"):GetDescendants()
        for i = 1, #a do
            if a[i].ClassName == "Part" then
                a[i].Transparency = vis
            elseif a[i].ClassName == "Model" then
                local r = a[i]:GetChildren()
                for i = 1, #r do
                    if r[i].ClassName == "Part" then
                    r[i].Transparency = vis
                    end
                end
            end
        end
    end
    if string.sub(msg, 1, 11) == (prefix.."hypertotal") then
        loadAsset("rbxassetid://1255063809")
        safeSetCore("SendNotification", {
        Title = "Success!";
        Text = "HyperTotal GUI Loaded!";
        })
    end
    if string.sub(msg, 1, 5) == (prefix.."cmds") then
        showCommandList()
    end
    if string.sub(msg, 1, 10) == (prefix.."rmeshhats") then
        for i,v in pairs(lplayer.Character:GetChildren()) do
            if (v:IsA("Accessory")) or (v:IsA("Hat")) then
                removeMesh(v.Handle)
            end
        end
    end
    if string.sub(msg, 1, 10) == (prefix.."blockhats") then
        for i,v in pairs(lplayer.Character:GetChildren()) do
            if (v:IsA("Accessory")) or (v:IsA("Hat")) then
                removeMesh(v.Handle)
            end
        end
    end
    if string.sub(msg, 1, 10) == (prefix.."rmeshtool") then
        for i,v in pairs(lplayer.Character:GetChildren()) do
            if (v:IsA("Tool")) then
                removeMesh(v.Handle)
            end
        end
    end
    if string.sub(msg, 1, 10) == (prefix.."blocktool") then
        for i,v in pairs(lplayer.Character:GetChildren()) do
            if (v:IsA("Tool")) then
                removeMesh(v.Handle)
            end
        end
    end
    if string.sub(msg, 1, 8) == (prefix.."spinner") then
        local p = Instance.new("RocketPropulsion")
        p.Parent = lplayer.Character.HumanoidRootPart
        p.Name = "Spinner"
        p.Target = limb(lplayer.Character, "Left Arm")
        p:Fire()
        safeSetCore("SendNotification", {
        Title = "Spinner enabled";
        Text = "Type ;nospinner to disable.";
        })
    end
    if string.sub(msg, 1, 10) == (prefix.."nospinner") then
        lplayer.Character.HumanoidRootPart.Spinner:Destroy()
    end
    if string.sub(msg, 1, 7) == (prefix.."reachd") then
        for i,v in pairs(game:GetService'Players'.LocalPlayer.Character:GetChildren())do
            if v:IsA("Tool") then
                local a = Instance.new("SelectionBox",v.Handle)
                a.Adornee = v.Handle
                v.Handle.Size = Vector3.new(0.5,0.5,60)
                v.GripPos = Vector3.new(0,0,0)
                lplayer.Character.Humanoid:UnequipTools()
            end
        end
        safeSetCore("SendNotification", {
        Title = "Reach applied!";
        Text = "Applied to equipped sword. Use ;noreach to disable.";
        })
    end
    if string.sub(msg, 1, 7) == (prefix.."reach ") then
        for i,v in pairs(game:GetService'Players'.LocalPlayer.Character:GetChildren())do
            if v:IsA("Tool") then
                handleSize = v.Handle.Size
                task.wait()
                local a = Instance.new("SelectionBox",v.Handle)
                a.Name = "a"
                a.Adornee = v.Handle
                v.Handle.Size = Vector3.new(0.5,0.5,(string.sub(msg, 8)))
                v.GripPos = Vector3.new(0,0,0)
                lplayer.Character.Humanoid:UnequipTools()
            end
        end
        safeSetCore("SendNotification", {
        Title = "Reach applied!";
        Text = "Applied to equipped sword. Use ;noreach to disable.";
        })
    end
    if string.sub(msg, 1, 8) == (prefix.."noreach") then
        for i,v in pairs(game:GetService'Players'.LocalPlayer.Character:GetChildren())do
            if v:IsA("Tool") and v.Handle then
                local marker = v.Handle:FindFirstChild("a")
                if marker then marker:Destroy() end
                if handleSize then v.Handle.Size = handleSize end
            end
        end
        safeSetCore("SendNotification", {
        Title = "Reach removed!";
        Text = "Removed reach from equipped sword.";
        })
    end
    if string.sub(msg, 1, 7) == (prefix.."rkill ") then
        for i,v in pairs(GetPlayer(string.sub(msg, 8)))do
            lplayer.Character.Humanoid.Name = "1"
            local l = lplayer.Character["1"]:Clone()
            l.Parent = lplayer.Character
            l.Name = "Humanoid"
            task.wait(0.1)
            lplayer.Character["1"]:Destroy()
            game:GetService("Workspace").CurrentCamera.CameraSubject = lplayer.Character
            lplayer.Character.Animate.Disabled = true
            task.wait(0.1)
            lplayer.Character.Animate.Disabled = false
            lplayer.Character.Humanoid.DisplayDistanceType = "None"
            for i,v in pairs(game:GetService'Players'.LocalPlayer.Backpack:GetChildren())do
            lplayer.Character.Humanoid:EquipTool(v)
            end
            task.wait(0.1)
            lplayer.Character.HumanoidRootPart.CFrame = game:GetService("Players")[v.Name].Character.HumanoidRootPart.CFrame
            task.wait(0.2)
            lplayer.Character.HumanoidRootPart.CFrame = game:GetService("Players")[v.Name].Character.HumanoidRootPart.CFrame
            task.wait(0.5)
            lplayer.Character.HumanoidRootPart.CFrame = CFrame.new(Vector3.new(-100000,10,-100000))
            safeSetCore("SendNotification", {
            Title = "Tools needed!";
            Text = "You need a tool in your backpack for this command!";
            })
        end
    end
    if string.sub(msg, 1, 7) == (prefix.."tp me ") then
        for i,v in pairs(GetPlayer(string.sub(msg, 8))) do
            lplayer.Character.HumanoidRootPart.CFrame = game:GetService("Players")[v.Name].Character.HumanoidRootPart.CFrame
        end
    end
    if string.sub(msg, 1, 8) == (prefix.."cbring ") then
        if (string.sub(msg, 9)) == "all" or (string.sub(msg, 9)) == "All" or (string.sub(msg, 9)) == "ALL" then
            cbringall = true
        else
            for i,v in pairs(GetPlayer(string.sub(msg, 9))) do
                brplr = v.Name
            end
        end
        cbring = true
    end
    if string.sub(msg, 1, 9) == (prefix.."uncbring") then
        cbring = false
        cbringall = false
    end
    if string.sub(msg, 1, 6) == (prefix.."swap ") then
        for i,v in pairs(GetPlayer(string.sub(msg, 7))) do
            local NOWPLR = game:GetService("Players")[v.Name].Character.HumanoidRootPart.CFrame
            local NOW = lplayer.Character.HumanoidRootPart.CFrame
            lplayer.Character.Humanoid.Name = "1"
            local l = lplayer.Character["1"]:Clone()
            l.Parent = lplayer.Character
            l.Name = "Humanoid"
            task.wait(0.1)
            lplayer.Character["1"]:Destroy()
            game:GetService("Workspace").CurrentCamera.CameraSubject = lplayer.Character
            lplayer.Character.Animate.Disabled = true
            task.wait(0.1)
            lplayer.Character.Animate.Disabled = false
            lplayer.Character.Humanoid.DisplayDistanceType = "None"
            for i,v in pairs(game:GetService'Players'.LocalPlayer.Backpack:GetChildren())do
            lplayer.Character.Humanoid:EquipTool(v)
            end
            local function tp(player,player2)
            local char1,char2=player.Character,player2.Character
            if char1 and char2 then
            char1:MoveTo(char2.Head.Position)
            end
            end
            task.wait(0.1)
            lplayer.Character.HumanoidRootPart.CFrame = game:GetService("Players")[v.Name].Character.HumanoidRootPart.CFrame
            task.wait(0.2)
            lplayer.Character.HumanoidRootPart.CFrame = game:GetService("Players")[v.Name].Character.HumanoidRootPart.CFrame
            task.wait(0.5)
            lplayer.Character.HumanoidRootPart.CFrame = NOW
            task.wait(0.6)
            tp(lplayer, game:GetService("Players")[v.Name])
            task.wait(0.4)
            lplayer.Character.HumanoidRootPart.CFrame = NOWPLR
            safeSetCore("SendNotification", {
            Title = "Tools needed!";
            Text = "You need a tool in your backpack for this command!";
            })
        end
    end
    if string.sub(msg, 1, 8) == (prefix.."glitch ") then
        for i,v in pairs(GetPlayer(string.sub(msg, 9))) do
            lplayer.Character.Humanoid.Name = "1"
            local l = lplayer.Character["1"]:Clone()
            l.Parent = lplayer.Character
            l.Name = "Humanoid"
            task.wait(0.1)
            lplayer.Character["1"]:Destroy()
            game:GetService("Workspace").CurrentCamera.CameraSubject = lplayer.Character
            lplayer.Character.Animate.Disabled = true
            task.wait(0.1)
            lplayer.Character.Animate.Disabled = false
            lplayer.Character.Humanoid.DisplayDistanceType = "None"
            for i,v in pairs(game:GetService'Players'.LocalPlayer.Backpack:GetChildren())do
            lplayer.Character.Humanoid:EquipTool(v)
            end
            lplayer.Character.HumanoidRootPart.CFrame = limb(game:GetService("Players")[v.Name].Character, "Left Arm").CFrame
            task.wait(0.3)
            lplayer.Character.HumanoidRootPart.CFrame = limb(game:GetService("Players")[v.Name].Character, "Left Arm").CFrame
            task.wait(0.4)
            b = Instance.new("BodyForce")
            b.Parent = lplayer.Character.HumanoidRootPart
            b.Name = "Glitch"
            b.Force = Vector3.new(100000000,5000,0)
            safeSetCore("SendNotification", {
            Title = "Tools needed!";
            Text = "You need a tool in your backpack for this command!";
            })
        end
    end
    if string.sub(msg, 1, 9) == (prefix.."unglitch") then
        lplayer.Character.HumanoidRootPart.Glitch:Destroy()
        lplayer.Character.HumanoidRootPart.CFrame = CFrame.new(10000,0,10000)
        b = Instance.new("BodyForce")
        b.Parent = lplayer.Character.HumanoidRootPart
        b.Name = "unGlitch"
        b.Force = Vector3.new(0,-5000000,0)
        task.wait(2)
        lplayer.Character.HumanoidRootPart.unGlitch:Destroy()
    end
    if string.sub(msg, 1, 9) == (prefix.."grespawn") then
        lplayer.Character.Humanoid.Health = 0
        task.wait(1)
        lplayer.Character.Head.CFrame = CFrame.new(1000000,0,1000000)
        limb(lplayer.Character, "Torso").CFrame = CFrame.new(1000000,0,1000000)
    end
    if string.sub(msg, 1, 9) == (prefix.."explorer") then
        loadDex()
        safeSetCore("SendNotification", {
        Title = "Success!";
        Text = "DEX Explorer has loaded.";
        })
    end
    if string.sub(msg, 1, 6) == (prefix.."anim ") then
        local Anim = Instance.new("Animation")
        Anim.AnimationId = "rbxassetid://"..(string.sub(msg, 7))
        local track = loadAnim(lplayer.Character.Humanoid, Anim)
        track:Play(.1, 1, 1)
    end
    if string.sub(msg, 1, 8) == (prefix.."animgui") then
        loadAsset("rbxassetid://1202558084")
        safeSetCore("SendNotification", {
        Title = "Success!";
        Text = "Energize Animations GUI has loaded.";
        })
    end
    if string.sub(msg, 1, 8) == (prefix.."savepos") then
        saved = lplayer.Character.HumanoidRootPart.CFrame
        safeSetCore("SendNotification", {
        Title = "Position Saved";
        Text = "Use ;loadpos to return to saved position.";
        })
    end
    if string.sub(msg, 1, 8) == (prefix.."loadpos") then
        lplayer.Character.HumanoidRootPart.CFrame = saved
    end
    if string.sub(msg, 1, 6) == (prefix.."bang ") then
        for i,v in pairs(GetPlayer(string.sub(msg, 7))) do
            local Anim2 = Instance.new("Animation")
            Anim2.AnimationId = "rbxassetid://148840371"
            local track2 = loadAnim(lplayer.Character.Humanoid, Anim2)
            track2:Play(.1, 1, 1)
            bplrr = v.Name
            banpl = true
        end
    end
    if string.sub(msg, 1, 7) == (prefix.."unbang") then
        banpl = false
    end
    if string.sub(msg, 1, 10) == (prefix.."bringmod ") then
        local function bringmodw()
        for i,obj in ipairs(game:GetService("Workspace"):GetDescendants()) do
        if obj.Name == (string.sub(msg, 11)) then
        for i,ch in pairs(obj:GetDescendants()) do
        if (ch:IsA("BasePart")) then
        ch.CFrame = lplayer.Character.HumanoidRootPart.CFrame
        ch.CanCollide = false
        ch.Transparency = 0.7
        task.wait()
        ch.CFrame = limb(lplayer.Character, "Left Leg").CFrame
        task.wait()
        ch.CFrame = limb(lplayer.Character, "Right Leg").CFrame
        task.wait()
        ch.CFrame = lplayer.Character["Head"].CFrame
        end
        end
        end
        end
        end
        while task.wait() do
            bringmodw()
        end
        safeSetCore("SendNotification", {
        Title = "BringMod";
        Text = "BringMod enabled.";
        })
    end
    if string.sub(msg, 1, 8) == (prefix.."respawn") then
        local mod = Instance.new('Model', workspace) mod.Name = 're '..lplayer.Name
        local hum = Instance.new('Humanoid', mod)
        local ins = Instance.new('Part', mod) ins.Name = 'Torso' ins.CanCollide = false ins.Transparency = 1
        lplayer.Character = mod
    end
    if string.sub(msg, 1, 9) == (prefix.."shutdown") then
        game:GetService'RunService'.Stepped:Connect(function()
        pcall(function()
            for i,v in pairs(game:GetService'Players':GetPlayers()) do
                if v.Character ~= nil and v.Character:FindFirstChild'Head' then
                    for _,x in pairs(v.Character.Head:GetChildren()) do
                        if x:IsA'Sound' then x.Playing = true x.CharacterSoundEvent:FireServer(true, true) end
                    end
                end
            end
        end)
        end)
        safeSetCore("SendNotification", {
        Title = "Attempting Shutdown";
        Text = "Shutdown Attempt has begun.";
        })
    end
    if string.sub(msg, 1, 8) == (prefix.."delobj ") then
        objtodel = (string.sub(msg, 9))
        for i,v in pairs(game:GetService("Workspace"):GetDescendants()) do
            if v.Name == objtodel then
                v:Destroy()
            end
        end
    end
    if string.sub(msg, 1, 8) == (prefix.."getplrs") then
        for i,v in pairs(game:GetService("Players"):GetPlayers())do
            print(v)
        end
        safeSetCore("SendNotification", {
        Title = "Printed";
        Text = "Players have been printed to console. (F9)";
        })
    end
    if string.sub(msg, 1, 9) == (prefix.."deldecal") then
        for i,v in pairs(game:GetService("Workspace"):GetDescendants())do
            if (v:IsA("Decal")) then
                v:Destroy()
            end
        end
    end
    if string.sub(msg, 1, 11) == (prefix.."opfinality") then
        loadAsset("rbxassetid://1294358929")
        safeSetCore("SendNotification", {
        Title = "Success!";
        Text = "OpFinality GUI has loaded.";
        })
    end
    if string.sub(msg, 1, 8) == (prefix.."remotes") then
        remotes = true
        added = true
        clearRemotes()
        onRemotes(game.DescendantAdded, function(rmt)
        if added == true then
        if remotes == true then
        if rmt:IsA("RemoteEvent") then
        print("A RemoteEvent was added!")
        print(" game." .. rmt:GetFullName() .. " | RemoteEvent")
        print(" game." .. rmt:GetFullName() .. " | RemoteEvent", 247, 0, 0, true)
        end end end
        end)
        onRemotes(game.DescendantAdded, function(rmtfnctn)
        if added == true then
        if remotes == true then
        if rmtfnctn:IsA("RemoteFunction") then
        warn("A RemoteFunction was added!")
        warn(" game." .. rmtfnctn:GetFullName() .. " | RemoteFunction")
        print(" game." .. rmtfnctn:GetFullName() .. " | RemoteFunction", 5, 102, 198, true)
        end end end
        end)
       
        onRemotes(game.DescendantAdded, function(bndfnctn)
        if added == true then
        if binds == true then
        if bndfnctn:IsA("BindableFunction") then
        print("A BindableFunction was added!")
        print(" game." .. bndfnctn:GetFullName() .. " | BindableFunction")
        print(" game." .. bndfnctn:GetFullName() .. " | BindableFunction", 239, 247, 4, true)
        end end end
        end)
       
        onRemotes(game.DescendantAdded, function(bnd)
        if added == true then
        if binds == true then
        if bnd:IsA("BindableEvent") then
        warn("A BindableEvent was added!")
        warn(" game." .. bnd:GetFullName() .. " | BindableEvent")
        print(" game." .. bnd:GetFullName() .. " | BindableEvent", 13, 193, 22, true)
        end end end
        end)
       
       
        if binds == true then
        for i,v in pairs(game:GetDescendants()) do
        if v:IsA("BindableFunction") then
        print(" game." .. v:GetFullName() .. " | BindableFunction")
        print(" game." .. v:GetFullName() .. " | BindableFunction", 239, 247, 4, true)
        end end
        for i,v in pairs(game:GetDescendants()) do
        if v:IsA("BindableEvent") then
        warn(" game." .. v:GetFullName() .. " | BindableEvent")
        print(" game." .. v:GetFullName() .. " | BindableEvent", 13, 193, 22, true)
        end end
        else
        print("Off")
        end
        if remotes == true then
        for i,v in pairs(game:GetDescendants()) do
        if v:IsA("RemoteFunction") then
        warn(" game." .. v:GetFullName() .. " | RemoteFunction")
        print(" game." .. v:GetFullName() .. " | RemoteFunction", 5, 102, 198, true)
        end end
        task.wait()
        for i,v in pairs(game:GetDescendants()) do
        if v:IsA("RemoteEvent") then
        print(" game." .. v:GetFullName() .. " | RemoteEvent")
        print(" game." .. v:GetFullName() .. " | RemoteEvent", 247, 0, 0, true)
        end end
        else
        print("Off")
        end
        safeSetCore("SendNotification", {
        Title = "Printing Remotes";
        Text = "Type ;noremotes to disable.";
        })
    end
    if string.sub(msg, 1, 10) == (prefix.."noremotes") then
        remotes = false
        added = false
        safeSetCore("SendNotification", {
        Title = "Printing Remotes Disabled";
        Text = "Type ;remotes to enable.";
        })
    end
    if string.sub(msg, 1, 10) == (prefix.."tpdefault") then
        spin = false
        followed = false
        traill = false
        noclip = false
        annoying = false
        hwalk = false
        cbringing = false
    end
    if string.sub(msg, 1, 8) == (prefix.."stopsit") then
        stopsitting = true
    end
    if string.sub(msg, 1, 6) == (prefix.."gosit") then
        stopsitting = false
    end
    if string.sub(msg, 1, 8) == (prefix.."version") then
        print(adminversion)
        safeSetCore("SendNotification", {
        Title = "Version";
        Text = adminversion;
        })
    end
    if string.sub(msg, 1, 8) == (prefix.."clicktp") then
        clickgoto = true
        safeSetCore("SendNotification", {
        Title = "Click TP";
        Text = "Press E to teleport to mouse position, ;noclicktp to stop";
        })
    end
    if string.sub(msg, 1, 9) == (prefix.."clickdel") then
        clickdel = true
        safeSetCore("SendNotification", {
        Title = "Click Delete";
        Text = "Press E to delete part at mouse, ;noclickdel to stop";
        })
    end
    if string.sub(msg, 1, 11) == (prefix.."noclickdel") then
        clickdel = false
        safeSetCore("SendNotification", {
        Title = "Click Delete";
        Text = "Click delete has been disabled.";
        })
    end
    if string.sub(msg, 1, 10) == (prefix.."noclicktp") then
        clickgoto = false
        safeSetCore("SendNotification", {
        Title = "Click TP";
        Text = "Click TP has been disabled.";
        })
    end
    if string.sub(msg, 1, 8) == (prefix.."toolson") then
        gettingtools = true
        safeSetCore("SendNotification", {
        Title = "Tools Enabled";
        Text = "Automatically colleting tools dropped.";
        })
    end
    if string.sub(msg, 1, 9) == (prefix.."toolsoff") then
        gettingtools = false
        safeSetCore("SendNotification", {
        Title = "Tools Disabled";
        Text = "Click TP has been disabled.";
        })
    end
    if string.sub(msg, 1, 10) == (prefix.."delcmdbar") then
        if ModMenu.Menu and ModMenu.Menu.setOpen then ModMenu.Menu.setOpen(false) end
    end
    if string.sub(msg, 1, 6) == (prefix.."reset") then
        lplayer.Character.Head:Destroy()
    end
    if string.sub(msg, 1, 7) == (prefix.."state ") then
        statechosen = string.sub(msg, 8)
        changingstate = true
    end
    if string.sub(msg, 1, 9) == (prefix.."gravity ") then
        game:GetService("Workspace").Gravity = string.sub(msg, 10)
    end
    if string.sub(msg, 1, 10) == (prefix.."looprhats") then
        removingmeshhats = true
    end
    if string.sub(msg, 1, 12) == (prefix.."unlooprhats") then
        removingmeshhats = false
    end
    if string.sub(msg, 1, 10) == (prefix.."looprtool") then
        removingmeshtool = true
    end
    if string.sub(msg, 1, 12) == (prefix.."unlooprtool") then
        removingmeshtool = false
    end
    if string.sub(msg, 1, 10) == (prefix.."givetool ") then
        for i,v in pairs(game:GetService("Players").LocalPlayer.Character:GetDescendants()) do
            if v:IsA("Tool") then
                for i,player in pairs(GetPlayer(string.sub(msg, 11))) do
                    v.Parent = player.Character
                end
            end
        end
    end
    if string.sub(msg, 1, 14) == (prefix.."givealltools ") then
        for i,v in pairs(game:GetService("Players").LocalPlayer.Backpack:GetDescendants()) do
            if v:IsA("Tool") then
                v.Parent = lplayer.Character
                task.wait()
                for i,player in pairs(GetPlayer(string.sub(msg, 15))) do
                    v.Parent = player.Character
                end
            end
        end
    end
    if string.sub(msg, 1, 5) == (prefix.."age ") then
        for i,player in pairs(GetPlayer(string.sub(msg, 6))) do
            sendChat(player.Name.." Account Age: "..player.AccountAge.." days!")
        end
    end
    if string.sub(msg, 1, 4) == (prefix.."id ") then
        for i,player in pairs(GetPlayer(string.sub(msg, 5))) do
            sendChat(player.Name.." Account ID: "..player.UserId)
        end
    end
    if string.sub(msg, 1, 6) == (prefix..".age ") then
        for i,player in pairs(GetPlayer(string.sub(msg, 7))) do
            safeSetCore("SendNotification", {
            Title = player.AccountAge.." Days";
            Text = "Account age of "..player.Name;
            })
        end
    end
    if string.sub(msg, 1, 5) == (prefix..".id ") then
        for i,player in pairs(GetPlayer(string.sub(msg, 6))) do
            safeSetCore("SendNotification", {
            Title = player.UserId.." ID";
            Text = "Account ID of "..player.Name;
            })
        end
    end
    if string.sub(msg, 1, 7) == (prefix.."gameid") then
        safeSetCore("SendNotification", {
        Title = "Game ID";
        Text = "Game ID: ".. game.GameId;
        })
    end
    if string.sub(msg, 1, 4) == (prefix.."pgs") then
        local pgscheck = pgsEnabled()
        if pgscheck == true then
            safeSetCore("SendNotification", {
            Title = "PGSPhysicsSolverEnabled";
            Text = "PGS is Enabled!";
            })
        else
            safeSetCore("SendNotification", {
            Title = "PGSPhysicsSolverEnabled";
            Text = "PGS is Disabled!";
            })
        end
    end
    if string.sub(msg, 1, 12) == (prefix.."removeinvis") then
        for i,v in pairs(game:GetService("Workspace"):GetDescendants()) do
            if v:IsA("Part") then
                if v.Transparency == 1 then
                    if v.Name ~= "HumanoidRootPart" then
                        v:Destroy()
                    end
                end
            end
        end
    end
    if string.sub(msg, 1, 10) == (prefix.."removefog") then
        game:GetService("Lighting").FogStart = 0
        game:GetService("Lighting").FogEnd = 9999999999999
    end
    if string.sub(msg, 1, 8) == (prefix.."disable") then
        lplayer.Character.Humanoid.Parent = lplayer
    end
    if string.sub(msg, 1, 7) == (prefix.."enable") then
        lplayer.Humanoid.Parent = lplayer.Character
    end
    if string.sub(msg, 1, 8) == (prefix.."prefix ") then
        prefix = (string.sub(msg, 9, 9))
        task.wait(0.1)
        change()
        task.wait(0.1)
        safeSetCore("SendNotification", {
        Title = "Prefix changed!";
        Text = "Prefix is now "..prefix..". Use ;resetprefix to reset to ;";
        })
    end
    if string.sub(msg, 1, 12) == (";resetprefix") then
        prefix = ";"
        task.wait(0.1)
        change()
        task.wait(0.1)
        safeSetCore("SendNotification", {
        Title = "Prefix changed!";
        Text = "Prefix is now "..prefix..". Make sure it's one key!";
        })
    end
    if string.sub(msg, 1, 10) == (prefix.."flyspeed ") then
        speedfly = string.sub(msg, 11)
        task.wait()
        change()
    end
    if string.sub(msg, 1, 8) == (prefix.."carpet ") then
        for i,v in pairs(GetPlayer(string.sub(msg, 9))) do
            local Anim3 = Instance.new("Animation")
            Anim3.AnimationId = "rbxassetid://282574440"
            local track3 = loadAnim(lplayer.Character.Humanoid, Anim3)
            track3:Play(.1, 1, 1)
            bplrr = v.Name
            banpl = true
        end
    end
    if string.sub(msg, 1, 9) == (prefix.."uncarpet") then
        banpl = false
    end
    if string.sub(msg, 1, 7) == (prefix.."stare ") then
        for i,v in pairs(GetPlayer(string.sub(msg, 8))) do
            staring = true
            stareplr = v
        end
    end
    if string.sub(msg, 1, 8) == (prefix.."unstare") then
        staring = false
    end
    if string.sub(msg, 1, 8) == (prefix.."logchat") then
        chatlogs = true
        safeSetCore("SendNotification", {
        Title = "LogChat enabled";
        Text = "Now logging all player chat.";
        })
    end
    if string.sub(msg, 1, 10) == (prefix.."unlogchat") then
        chatlogs = false
        safeSetCore("SendNotification", {
        Title = "LogChat disabled";
        Text = "Stopped logging all player chat.";
        })
    end
    if string.sub(msg, 1, 7) == (prefix.."fixcam") then
        -- camera reset (destroying CurrentCamera breaks the client)
        game:GetService("Workspace").CurrentCamera.CameraSubject = lplayer.Character.Humanoid
        game:GetService("Workspace").CurrentCamera.CameraType = "Custom"
        lplayer.CameraMinZoomDistance = 0.5
        lplayer.CameraMaxZoomDistance = 400
        lplayer.CameraMode = "Classic"
    end
    if string.sub(msg, 1, 8) == (prefix.."unstate") then
        changingstate = false
    end
end

local function tp()
    for i, player in ipairs(game:GetService("Players"):GetPlayers()) do
        if player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
            if player.Name == brplr then
                player.Character.HumanoidRootPart.CFrame = lplayer.Character.HumanoidRootPart.CFrame + lplayer.Character.HumanoidRootPart.CFrame.lookVector * 2
            end
        end
    end
end
local function tpall()
    for i, player in ipairs(game:GetService("Players"):GetPlayers()) do
        if player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
            player.Character.HumanoidRootPart.CFrame = lplayer.Character.HumanoidRootPart.CFrame + lplayer.Character.HumanoidRootPart.CFrame.lookVector * 3
        end
    end
end
task.spawn(function()
    while task.wait(spamdelay) do
        if spamming == true then
            sendChat(spamtext)
        end
    end
end)
task.spawn(function()
    while task.wait(spamdelay) do
        if spammingpm == true then
            sendChat("/w "..pmspammed.." @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@")
        end
    end
end)
task.spawn(function()
    while task.wait() do
        if cbring == true then
            tp()
        end
    end
end)
task.spawn(function()
    while task.wait() do
        if cbringall == true then
            tpall()
        end
    end
end)

    showCommandList = function()
        if Reviz.onCommands then
            pcall(Reviz.onCommands)
            return
        end
        for _, entry in ipairs(Reviz.commands) do
            pcall(Reviz.log, entry)
        end
    end

    Reviz.commands = Commands

    function Reviz.getPrefix()
        return prefix
    end

    function Reviz.setPrefix(value)
        if type(value) == "string" and #value == 1 then
            prefix = value
        end
        return prefix
    end

    -- Accepts text with or without the prefix.
    Reviz.execute = function(text)
        if type(text) ~= "string" or text == "" then return end
        local full = text
        if string.sub(full, 1, #prefix) ~= prefix then
            full = prefix .. full
        end
        local ok, err = pcall(Execute, full)
        if not ok then
            warn("[reviz] " .. tostring(full) .. " failed: " .. tostring(err))
            pcall(Reviz.log, "[error] " .. tostring(err))
        end
    end

    Reviz.showCommands = function()
        showCommandList()
    end

    on(lplayer.Chatted, function(msg)
        if not Reviz.chatEnabled then return end
        if string.sub(msg, 1, #prefix) == prefix then
            Reviz.execute(msg)
        end
    end)

    if STATE and STATE.onCleanup then
        STATE.onCleanup(function()
            ModMenu.State.clearConnections("reviz")
            clearRemotes()
        end)
    end

    return Reviz
end)()
