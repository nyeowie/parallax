local breathingSounds = {
    "test/breath1.mp3",
    "test/breath2.mp3",
    "test/breath3.mp3",
    "test/breath4.mp3",
    "test/breath5.mp3"
}

local extraDelay = 2 -- extra seconds to wait *after* the sound ends
local activeBreathers = {} -- Track which players are currently making breathing sounds

-- Precache all breathing sounds
for _, soundPath in ipairs(breathingSounds) do
    util.PrecacheSound(soundPath)
end

-- Helper function to get a random sound that's different from the last one
local function GetRandomUniqueSound(ply)
    if #breathingSounds <= 1 then return breathingSounds[1] end
    
    local lastSound = ply.lastBreathingSound
    local availableSounds = {}
    
    -- Create a list of sounds excluding the last played one
    for _, sound in ipairs(breathingSounds) do
        if sound ~= lastSound then
            table.insert(availableSounds, sound)
        end
    end
    
    local randomSound = availableSounds[math.random(#availableSounds)]
    ply.lastBreathingSound = randomSound
    return randomSound
end

local function PlayBreathingSound(ply)
    -- Check if player is valid and alive first
    if not IsValid(ply) or not ply:Alive() then 
        return
    end
    
    -- Don't play sounds for players in noclip
    if ply:GetMoveType() == MOVETYPE_NOCLIP then
        return
    end
    
    -- If this player is already in the active breathers list, don't start a new sound
    if activeBreathers[ply:SteamID()] then
        return
    end
    
    -- Get a random sound different from the last one played
    local randomSound = GetRandomUniqueSound(ply)
    
    -- Clean up any previous sound that might still exist
    if IsValid(ply.breathingSound) then
        ply.breathingSound:Stop()
    end
    
    -- Create and play the new sound
    ply.breathingSound = CreateSound(ply, randomSound)
    
    if ply.breathingSound then
        ply.breathingSound:SetSoundLevel(100)
        ply.breathingSound:Play()
        
        -- Mark this player as currently breathing
        activeBreathers[ply:SteamID()] = true
        
        -- Calculate when this player should breathe next
        local duration = SoundDuration(randomSound)
        ply.nextBreathingSound = CurTime() + duration + extraDelay
        
        -- Set a timer to remove the player from active breathers once sound finishes
        timer.Simple(duration, function()
            if IsValid(ply) then
                activeBreathers[ply:SteamID()] = nil
            end
        end)
    end
end

hook.Add("Think", "CitizenBreathingSound", function()
    for _, ply in ipairs(player.GetAll()) do
        -- Only process players who are alive and not in noclip
        if IsValid(ply) and ply:Alive() and ply:GetMoveType() ~= MOVETYPE_NOCLIP then
            -- Check if it's time for another breath sound
            if not ply.nextBreathingSound or CurTime() >= ply.nextBreathingSound then
                PlayBreathingSound(ply)
            end
        else
            -- Player is not alive or in noclip, clean up any sounds
            if IsValid(ply.breathingSound) then
                ply.breathingSound:Stop()
                activeBreathers[ply:SteamID()] = nil
            end
        end
    end
end)

-- Clean up on player disconnect
hook.Add("PlayerDisconnected", "CleanupBreathingSounds", function(ply)
    if IsValid(ply.breathingSound) then
        ply.breathingSound:Stop()
    end
    activeBreathers[ply:SteamID()] = nil
end)