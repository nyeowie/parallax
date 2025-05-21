local MODULE = MODULE or {}

MODULE.name = "Rolling System"
MODULE.author = "Claude"
MODULE.description = "Enables players to roll in different directions when pressing ALT + W/A/S/D"

-- Configuration
local ROLL_CONFIG = {
    cooldown = 3, -- Time in seconds before a player can roll again
    distance = 200, -- How far the roll will move the player
    duration = 1, -- How long the roll animation/movement lasts
    animations = {
        forward = "evade_n",
        back = "evade_s",
        left = "evade_w",
        right = "evade_e"
    },
    useCustomAnimSystem = true, -- Set to true if using WOS or other custom animation system
    particleEffect = "generic_smoke", -- Particle effect to use during roll
    particleFrequency = 0.05 -- How often to emit particles during roll (in seconds)
}

-- Keep track of player rolling states
local playerRollData = {}

-- Initialize a player's roll data
local function InitPlayerRollData(ply)
    if !IsValid(ply) then return end
    
    playerRollData[ply:SteamID()] = {
        isRolling = false,
        lastRollTime = 0,
        rollDirection = Vector(0, 0, 0),
        rollEndTime = 0,
        lastParticleTime = 0,
        rollProgress = 0 -- For smooth movement (0 to 1)
    }
end

-- Check if the player can roll based on cooldown and movement
local function CanPlayerRoll(ply)
    local steamID = ply:SteamID()
    if !playerRollData[steamID] then
        InitPlayerRollData(ply)
    end
    
    local data = playerRollData[steamID]
    
    -- Can't roll if already rolling
    if data.isRolling then return false end
    
    -- Check if cooldown has passed
    if CurTime() - data.lastRollTime < ROLL_CONFIG.cooldown then return false end
    
    -- NEW: Prevent rolling if player is moving
    if ply:GetVelocity():Length() > 10 then return false end
    
    return true
end

-- Play animation using various methods for compatibility
local function PlayRollAnimation(ply, animName)
    if not IsValid(ply) or not animName or animName == "" then return false end

    local seq = ply:LookupSequence(animName)
    if seq and seq > 0 then
        ply:AddVCDSequenceToGestureSlot(GESTURE_SLOT_CUSTOM, seq, 0, true)

        -- Lock the sequence
        ply:ForceSequence(animName)
        ply:SetCycle(0)
        ply:SetPlaybackRate(1) -- Prevent speed fluctuations

        local startTime = CurTime()

        -- Use a Think hook to manually update cycle
        local uniqueHook = "RollAnimUpdate_" .. ply:EntIndex()
        hook.Add("Think", uniqueHook, function()
            if not IsValid(ply) or not playerRollData[ply:SteamID()] or not playerRollData[ply:SteamID()].isRolling then
                hook.Remove("Think", uniqueHook)
                return
            end

            local elapsed = CurTime() - startTime
            local progress = math.Clamp(elapsed / ROLL_CONFIG.duration, 0, 1)

            -- Apply animation cycle smoothly
            ply:SetCycle(progress)
        end)

        -- Freeze movement if needed
        local oldMoveType = ply:GetMoveType()
        ply:SetMoveType(MOVETYPE_NONE)

        timer.Simple(ROLL_CONFIG.duration, function()
            if IsValid(ply) then
                ply:SetMoveType(oldMoveType)
                ply:LeaveSequence()
                hook.Remove("Think", uniqueHook)
            end
        end)

        return true
    else
        print("[RollAnim] Invalid animation sequence name: " .. animName)
    end

    return false
end


-- Create roll particles
local function CreateRollParticles(ply)
    if !IsValid(ply) then return end
    
    local steamID = ply:SteamID()
    if !playerRollData[steamID] then return end
    
    local data = playerRollData[steamID]
    
    -- Only spawn particles at certain intervals
    if CurTime() - data.lastParticleTime < ROLL_CONFIG.particleFrequency then return end
    data.lastParticleTime = CurTime()

    
    
    -- Create particle effect at player's feet
    local particlePos = ply:GetPos() + Vector(0, 0, 10)

    local particle = EffectData()
    particle:SetOrigin(particlePos)
    particle:SetEntity(ply)
    particle:SetScale(1)
    util.Effect("dust_cloud", particle)
    util.Effect("WheelDust", particle)
end

-- Start rolling in a direction
local function StartRoll(ply, direction, animation)
    if !IsValid(ply) or !CanPlayerRoll(ply) then return end
    
    local steamID = ply:SteamID()
    local data = playerRollData[steamID]
    
    -- Update roll data
    data.isRolling = true
    data.lastRollTime = CurTime()
    data.rollDirection = direction
    data.rollEndTime = CurTime() + ROLL_CONFIG.duration
    data.rollProgress = 0
    data.startPos = ply:GetPos()
    data.endPos = ply:GetPos() + (direction * ROLL_CONFIG.distance)
    
    -- Play the roll animation
    local animPlayed = PlayRollAnimation(ply, animation)
end

-- End rolling
local function EndRoll(ply)
    if !IsValid(ply) then return end
    
    local steamID = ply:SteamID()
    if !playerRollData[steamID] then return end
    
    local data = playerRollData[steamID]
    data.isRolling = false
    
    -- Notify client the roll has ended
    net.Start("PlayerRolling")
    net.WriteEntity(ply)
    net.WriteString("")
    net.WriteVector(Vector(0, 0, 0))
    net.WriteBool(false) -- Ending roll
    net.WriteBool(false) -- No animation
    net.Broadcast()
end

-- Process rolling movement with smooth easing
local function ProcessRolling()
    for steamID, data in pairs(playerRollData) do
        local ply = player.GetBySteamID(steamID)
        
        if IsValid(ply) and data.isRolling then
            -- Check if roll should end
            if CurTime() > data.rollEndTime then
                EndRoll(ply)
            else
                -- Calculate smooth roll progress (0 to 1)
                data.rollProgress = math.Clamp((CurTime() - data.lastRollTime) / ROLL_CONFIG.duration, 0, 1)
                
                -- Apply smooth easing (ease-in-out)
                local easeProgress = data.rollProgress < 0.5 
                    and 2 * data.rollProgress * data.rollProgress 
                    or 1 - math.pow(-2 * data.rollProgress + 2, 2) / 2
                
                -- Calculate new position with smooth movement
                local newPos = LerpVector(easeProgress, data.startPos, data.endPos)
                
                -- Apply movement if possible (simple collision check)
                local trace = util.TraceHull({
                    start = ply:GetPos(),
                    endpos = newPos,
                    filter = ply,
                    mins = ply:OBBMins(),
                    maxs = ply:OBBMaxs()
                })
                
                if !trace.Hit then
                    ply:SetPos(newPos)
                    
                    -- Create particles during roll
                    CreateRollParticles(ply)
                else
                    -- Hit something, stop the roll
                    EndRoll(ply)
                end
            end
        end
    end
end

-- Key press handling
hook.Add("KeyPress", "RollKeyPress", function(ply, key)
    -- Only server-side
    if CLIENT then return end
    
    -- Check if ALT is held down (IN_WALK is ALT by default)
    if !ply:KeyDown(IN_WALK) then return end
    
    local direction = Vector(0, 0, 0)
    local animation = ""
    
    -- Determine roll direction based on movement keys
    if key == IN_FORWARD then
        -- Roll forward
        direction = ply:GetForward()
        animation = ROLL_CONFIG.animations.forward
    elseif key == IN_BACK then
        -- Roll backward
        direction = -ply:GetForward()
        animation = ROLL_CONFIG.animations.back
    elseif key == IN_MOVELEFT then
        -- Roll left
        direction = -ply:GetRight()
        animation = ROLL_CONFIG.animations.left
    elseif key == IN_MOVERIGHT then
        -- Roll right
        direction = ply:GetRight()
        animation = ROLL_CONFIG.animations.right
    else
        -- Not a movement key
        return
    end
    
    StartRoll(ply, direction, animation)
end)

-- Player initialization
hook.Add("PlayerInitialSpawn", "InitRollData", function(ply)
    InitPlayerRollData(ply)
end)

-- Process rolling movements
hook.Add("Think", "ProcessRolling", ProcessRolling)

-- Player disconnection cleanup
hook.Add("PlayerDisconnected", "CleanupRollData", function(ply)
    if playerRollData[ply:SteamID()] then
        playerRollData[ply:SteamID()] = nil
    end
end)

-- Block normal player movement during rolling
hook.Add("StartCommand", "BlockMovementDuringRoll", function(ply, cmd)
    if !IsValid(ply) then return end
    
    local steamID = ply:SteamID()
    if playerRollData[steamID] and playerRollData[steamID].isRolling then
        -- Prevent normal movement input during roll
        cmd:ClearMovement()
        cmd:ClearButtons()
    end
end)

hook.Add("EntityTakeDamage", "NoKnockbackWhileRolling", function(target, dmginfo)
    if target:IsPlayer() then
        print("Player taking damage: " .. target:Nick())
        local data = playerRollData[target:SteamID()]
        if data and data.isRolling then
            return true
        end
    end
end)


-- Networking
if SERVER then
    util.AddNetworkString("PlayerRolling")
end

if CLIENT then
    -- Client-side visual effects for rolling
    net.Receive("PlayerRolling", function()
        local ply = net.ReadEntity()
        local animation = net.ReadString()
        local direction = net.ReadVector()
        local isStarting = net.ReadBool()
        local animSuccess = net.ReadBool()
        
        if IsValid(ply) then
            -- Client-side animation playback if server reported failure
            if isStarting and animation != "" and !animSuccess then
                -- Try to play animation on client as a fallback
                if ply.SetWOSAnimation then
                    ply:SetWOSAnimation(animation)
                elseif ply.DoAnimation then
                    ply:DoAnimation(animation)
                end
            end
        end
    end)
end