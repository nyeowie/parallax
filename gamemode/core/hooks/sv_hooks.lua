local time = CurTime()
function GM:PlayerInitialSpawn(client)
    if ( client:IsBot() ) then return end

    time = CurTime()
    ax.util:Print("Starting to load player " .. client:SteamName() .. " (" .. client:SteamID64() .. ")")

    client:SetTeam(0)
    client:SetModel("models/player/kleiner.mdl")

    client:SetNoDraw(true)
    client:SetNotSolid(true)
    client:SetMoveType(MOVETYPE_NONE)

    client:KillSilent()
end

function GM:PlayerReady(client)
    client:SetPos(Vector(2385.432861, 392.607391, 497.918518))
    timer.Simple(0.01, function()
        if ( !IsValid(client) ) then return end
        
        client:ConCommand("stopsound") -- Uses the stopsound console command
    end)
    
    
    ax.character:CacheAll(client)
    ax.util:SendChatText(nil, Color(25, 75, 150), client:SteamName() .. " has joined the server.")

    vgui.Create("ax_intro", client)
   

    hook.Run("PostPlayerInitialSpawn", client)

    ax.util:Print("Finished loading player " .. client:SteamName() .. " (" .. client:SteamID64() .. ") in " .. math.Round(CurTime() - time, 2) .. " seconds.")
    time = CurTime()
end

function GM:PostPlayerInitialSpawn(client)
    ax.sqlite:LoadRow("ax_players", "steamid", client:SteamID64(), function(data)
        if ( !IsValid(client) ) then return end

        local clientTable = client:GetTable()
        clientTable.axDatabase = data or {}

        client:SetDBVar("name", client:SteamName())
        client:SetDBVar("ip", client:IPAddress())
        client:SetDBVar("last_played", os.time())
        client:SetDBVar("data", data != nil and data.data or "[]")
        client:SaveDB()

        ax.util:Print("Loaded player " .. client:SteamName() .. " (" .. client:SteamID64() .. ") in " .. math.Round(CurTime() - time, 2) .. " seconds.")
        time = CurTime()

        ax.config:Synchronize(client)
    end)
end

function GM:PlayerDisconnected(client)
    if ( !client:IsBot() ) then
        client:SetDBVar("play_time", client:GetDBVar("play_time", 0) + (os.time() - client:GetDBVar("last_played", 0)))
        client:SetDBVar("last_played", os.time())
        client:SaveDB()

        local character = client:GetCharacter()
        if ( character ) then
            character:SetPlayTime(character:GetPlayTime() + (os.time() - character:GetLastPlayed()))
            character:SetLastPlayed(os.time())
        end
    end
end

function GM:PlayerSpawn(client)
    hook.Run("PlayerLoadout", client)
end

function GM:PlayerLoadout(client)
    if ( hook.Run("PlayerGetToolgun", client) ) then client:Give("gmod_tool") end
    if ( hook.Run("PlayerGetPhysgun", client) ) then client:Give("weapon_physgun") end

    client:Give("ax_hands")
    client:SelectWeapon("ax_hands")

    client:SetWalkSpeed(ax.config:Get("speed.walk", 80))
    client:SetRunSpeed(ax.config:Get("speed.run", 180))
    client:SetJumpPower(ax.config:Get("jump.power", 160))

    client:SetupHands()

    hook.Run("PostPlayerLoadout", client)

    return true
end

function GM:PostPlayerLoadout(client)
end

function GM:PlayerDeathThink(client)
    -- TODO: uh, some happy day this should be replaced
    if ( client:KeyPressed(IN_ATTACK) or client:KeyPressed(IN_ATTACK2) or client:KeyPressed(IN_JUMP) or client:IsBot() ) then
        client:Spawn()
    end
end

function GM:PlayerSay(client, text, teamChat)
    if ( string.sub(text, 1, 3) == ".//" ) then
        -- Check if it's a way of using local out of character chat using .// prefix
        local message = string.Explode(" ", string.sub(text, 4))
        table.remove(message, 1)

        ax.command:Run(client, "looc", message)
    elseif ( string.sub(text, 1, 1) == "/" ) then
        -- This is a command, so we need to parse it
        local arguments = string.Explode(" ", string.sub(text, 2))
        local command = arguments[1]
        table.remove(arguments, 1)

        ax.command:Run(client, command, arguments)
    else
        -- Everything else is a normal chat message
        ax.chat:SendSpeaker(client, "ic", text)
    end

    return ""
end

function GM:PlayerUseSpawnSaver(client)
    return false
end

function GM:Initialize()
    ax.module:LoadFolder("parallax/modules")
    ax.item:LoadFolder("parallax/core/items")
    ax.schema:Initialize()

    if ( game.IsDedicated() ) then
        -- Production (dedicated server)
        RunConsoleCommand("sv_allowupload", "0")
        RunConsoleCommand("sv_allowdownload", "0")
        RunConsoleCommand("net_maxfilesize", "64")
        RunConsoleCommand("sv_kickerrornum", "1")
        RunConsoleCommand("sv_maxrate", "30000")
        RunConsoleCommand("sv_minrate", "5000")
        RunConsoleCommand("sv_maxcmdrate", "66")
        RunConsoleCommand("sv_maxupdaterate", "66")
        RunConsoleCommand("sv_mincmdrate", "30")
        RunConsoleCommand("sv_allowcslua", "0")
    else
        -- Development (listen server)
        RunConsoleCommand("sv_allowupload", "0")
        RunConsoleCommand("sv_allowdownload", "0")
        RunConsoleCommand("net_maxfilesize", "128")
        RunConsoleCommand("sv_kickerrornum", "0")
        RunConsoleCommand("sv_maxrate", "60000")
        RunConsoleCommand("sv_minrate", "10000")
        RunConsoleCommand("sv_maxcmdrate", "100")
        RunConsoleCommand("sv_maxupdaterate", "100")
        RunConsoleCommand("sv_mincmdrate", "30")
        RunConsoleCommand("sv_allowcslua", "1")
    end
end

function GM:OnReloaded()
    ax.module:LoadFolder("parallax/modules")
    ax.item:LoadFolder("parallax/core/items")
    ax.schema:Initialize()
    ax.config:Load()
end

function GM:SetupPlayerVisibility(client, viewEntity)
    if ( client:Team() == 0 ) then
        AddOriginToPVS(ax.config:Get("mainmenu.pos", vector_origin))
    end
end

function GM:PlayerSwitchFlashlight(client, bEnabled)
    return true
end

function GM:GetFallDamage(client, speed)
    if ( speed > 100 ) then
        ax.util:Print("I would ragdoll the player... but missing function!")
        -- TODO: Implement this in the future
        -- client:Ragdoll()
    end

    return speed / 8
end

function GM:PostPlayerLoadedCharacter(client, character, previousCharacter)
    -- Restore the bodygroups of the character
    local groups = character:GetData("groups", {})
    for name, value in pairs(groups) do
        local id = client:FindBodygroupByName(name)
        if ( id == -1 ) then continue end

        client:SetBodygroup(id, value)
    end
end

local nextThink = CurTime() + 1
local nextSave = CurTime() + ax.config:Get("save.interval", 300)
local playerVoiceListeners = {}
function GM:Think()
    if ( CurTime() >= nextThink ) then
        nextThink = CurTime() + 1

        for _, client in player.Iterator() do
            if ( !IsValid(client) or !client:Alive() ) then continue end
            if ( client:Team() == 0 ) then continue end

            -- Voice chat listeners
            local voiceListeners = {}

            for _, listener in player.Iterator() do
                if ( listener == client ) then continue end
                if ( listener:EyePos():DistToSqr(client:EyePos()) > ax.config:Get("voice.distance", 384) ^ 2 ) then continue end

                voiceListeners[listener] = true
            end

            -- Overwrite the voice listeners if the config is disabled
            if ( ax.config:Get("voice", true) ) then
                playerVoiceListeners[client] = voiceListeners
            else
                playerVoiceListeners = {}
            end
        end
    end

    if ( CurTime() >= nextSave ) then
        nextSave = CurTime() + ax.config:Get("save.interval", 300)
        hook.Run("SaveData")
    end
end

function GM:InitPostEntity()
    hook.Run("LoadData")
end

function GM:Shutdown()
    hook.Run("SaveData")
end

function GM:PlayerCanHearPlayersVoice(listener, talker)
    if ( !playerVoiceListeners[listener] ) then return false end
    if ( !playerVoiceListeners[listener][talker] ) then return false end

    return true, true
end

function GM:CanPlayerSuicide(client)
    return false
end

function GM:PlayerDeathSound(client)
    return true
end

function GM:PlayerHurt(client, attacker, healthRemaining, damageTaken)
    local painSound = hook.Run("GetPlayerPainSound", client, attacker, healthRemaining, damageTaken)
    if ( painSound and painSound != "" and !client:InObserver() ) then
        if ( !file.Exists("sound/" .. painSound, "GAME") ) then
            ax.util:PrintWarning("PlayerPainSound: Sound file does not exist! " .. painSound)
            return false
        end

        client:EmitSound(painSound, 75, 100, 1, CHAN_VOICE)
    end
end

local painSounds = {
    Sound("vo/npc/male01/pain01.wav"),
    Sound("vo/npc/male01/pain02.wav"),
    Sound("vo/npc/male01/pain03.wav"),
    Sound("vo/npc/male01/pain04.wav"),
    Sound("vo/npc/male01/pain05.wav"),
    Sound("vo/npc/male01/pain06.wav")
}

local drownSounds = {
    Sound("player/pl_drown1.wav"),
    Sound("player/pl_drown2.wav"),
    Sound("player/pl_drown3.wav"),
}

function GM:GetPlayerPainSound(client, attacker, healthRemaining, damageTaken)
    if ( client:Health() <= 0 ) then return end

    if ( client:WaterLevel() >= 3 ) then
        return drownSounds[math.random(#drownSounds)]
    end

    if ( damageTaken > 0 ) then
        return painSounds[math.random(#painSounds)]
    end
end

function GM:DoPlayerDeath(client, attacker, dmgInfo)
    if ( hook.Run("PreSpawnClientRagdoll", client, attacker, dmgInfo ) != false ) then
        local ragdoll = client:CreateRagdoll()

        hook.Run("PostSpawnClientRagdoll", client, ragdoll, attacker, dmgInfo)
    end
end

function GM:PlayerDeath(client, inflictor, attacker)
    local character = client:GetCharacter()
    if ( character ) then
        local clientRagdoll = client:GetRelay("ragdoll")
        if ( IsValid(clientRagdoll) and hook.Run("ShouldRemoveRagdollOnDeath", client) != false ) then
            clientRagdoll:Remove()
        end

        local deathSound = hook.Run("GetPlayerDeathSound", client, inflictor, attacker)
        if ( deathSound and deathSound != "" and !client:InObserver() ) then
            if ( !file.Exists("sound/" .. deathSound, "GAME") ) then
                ax.util:PrintWarning("PlayerDeathSound: Sound file does not exist! " .. deathSound)
                return false
            end

            client:EmitSound(deathSound, 75, 100, 1, CHAN_VOICE)
        end
    end
end

local deathSounds = {
    Sound("vo/npc/male01/pain07.wav"),
    Sound("vo/npc/male01/pain08.wav"),
    Sound("vo/npc/male01/pain09.wav")
}

function GM:GetPlayerDeathSound(client, inflictor, attacker)
    return deathSounds[math.random(#deathSounds)]
end

function GM:PostPlayerDropItem(client, item, entity)
    if ( !item or !IsValid(entity) ) then return end

    entity:EmitSound("physics/body/body_medium_impact_soft" .. math.random(1, 4) .. ".wav", 75, math.random(90, 110), 1, CHAN_ITEM)
end

function GM:PostPlayerTakeItem(client, item, entity)
    if ( !item or !IsValid(entity) ) then return end

    entity:EmitSound("physics/body/body_medium_impact_soft" .. math.random(5, 7) .. ".wav", 75, math.random(90, 110), 1, CHAN_ITEM)
end

local function IsAdmin(_, client)
    return client:IsAdmin()
end

GM.PlayerSpawnEffect = IsAdmin
GM.PlayerSpawnNPC = IsAdmin
GM.PlayerSpawnObject = IsAdmin
GM.PlayerSpawnProp = IsAdmin
GM.PlayerSpawnRagdoll = IsAdmin
GM.PlayerSpawnSENT = IsAdmin
GM.PlayerSpawnSWEP = IsAdmin
GM.PlayerGiveSWEP = IsAdmin
GM.PlayerSpawnVehicle = IsAdmin