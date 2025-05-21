local MODULE = MODULE

concommand.Add("ax_thirdperson_toggle", function()
    ax.option:Set("thirdperson", !ax.option:Get("thirdperson", false))
end, nil, ax.localization:GetPhrase("options.thirdperson.toggle"))

concommand.Add("ax_thirdperson_reset", function()
    ax.option:Set("thirdperson.position.x", ax.option:GetDefault("thirdperson.position.x"))
    ax.option:Set("thirdperson.position.y", ax.option:GetDefault("thirdperson.position.y"))
    ax.option:Set("thirdperson.position.z", ax.option:GetDefault("thirdperson.position.z"))
end, nil, ax.localization:GetPhrase("options.thirdperson.reset"))

local fakePos
local fakeAngles
local fakeFov
local camAngles -- Camera angles variable
local isAiming = false -- Track aiming state (Mouse2 pressed)
local crosshairDistance = 100 -- Distance at which to draw the crosshair
local crosshairSize = 4 -- Size of the crosshair
local lastShootTime = 0 -- Last time a weapon was fired
local aimProgress = 0 -- Ranges from 0 (invisible) to 1 (fully visible)
local lastAimState = false


-- Initialize camAngles when needed
hook.Add("InitPostEntity", "AX_ThirdPerson_InitCamAngles", function()
    camAngles = Angle(0, 0, 0)
end)

-- Handle mouse input specifically for third person camera
hook.Add("InputMouseApply", "AX_ThirdPerson_MouseInput", function(cmd, x, y, ang)
    local client = LocalPlayer()
    
    if (!ax.option:Get("thirdperson", false)) then
        return
    end
    
    if (!camAngles) then
        camAngles = Angle(0, 0, 0)
    end
    
    -- Update camera angles based on mouse movement
    camAngles.p = math.Clamp(math.NormalizeAngle(camAngles.p + y / 50), -85, 85)
    camAngles.y = math.NormalizeAngle(camAngles.y - x / 50)
    
    if (ax.option:Get("thirdperson", false) and hook.Run("PreRenderThirdpersonView", client, client:GetPos(), client:EyeAngles(), client:GetFOV()) != false) then
        return true -- Block the default mouse movement
    end
end)

-- Track when Mouse2 (right mouse button) is pressed or released
hook.Add("KeyPress", "AX_ThirdPerson_AimToggle", function(ply, key)
    if (key == IN_ATTACK2 and ax.option:Get("thirdperson", false)) then
        isAiming = true
    end
end)

hook.Add("KeyRelease", "AX_ThirdPerson_AimToggle", function(ply, key)
    if (key == IN_ATTACK2 and ax.option:Get("thirdperson", false)) then
        isAiming = false
    end
end)

function MODULE:PreRenderThirdpersonView(client, pos, angles, fov)
    if (IsValid(ax.gui.mainmenu)) then
        return false
    end

    if (IsValid(client:GetVehicle())) then
        return false
    end

    return true
end

local bulletShakeYawDirection = 1
local lastShootTime = 0
local bulletShakeIntensity = 0
local bulletShakeActive = false
local bulletShakeAngles = Angle(0, 0, 0)
local bulletShakeOffset = Vector(0, 0, 0) -- Position offset for actual screen shaking

-- Variables for managing rapid fire shake increase
local rapidFireCount = 0
local rapidFireTimer = 0
local RAPID_FIRE_THRESHOLD = 0.15 -- Time threshold for considering rapid fire (seconds)
local MAX_RAPID_MULTIPLIER = 3.5 -- Maximum multiplier for rapid fire

-- Randomized seed values for more realistic shake
local seedX, seedY, seedZ, seedPitch, seedYaw, seedRoll
local freqX, freqY, freqZ, freqPitch, freqYaw, freqRoll

net.Receive("AX_BulletShake", function()
    local currentTime = CurTime()
    local timeSinceLastShot = currentTime - lastShootTime
    
    -- Check if this is a rapid fire (less than threshold seconds since last shot)
    if timeSinceLastShot < RAPID_FIRE_THRESHOLD then
        -- Increment rapid fire counter for escalating effect
        rapidFireCount = math.min(rapidFireCount + 1, 10) -- Cap at 10 to prevent excessive shake
    else
        -- Reset counter if it's been too long since last shot
        rapidFireCount = 0
    end
    
    lastShootTime = currentTime
    bulletShakeActive = true
    
    -- Base intensity with added intensity for rapid fire
    local baseIntensity = math.Rand(3, 5.5)
    local rapidFireMultiplier = 1 + (rapidFireCount * 0.25) -- Each shot adds 25% more intensity
    rapidFireMultiplier = math.min(rapidFireMultiplier, MAX_RAPID_MULTIPLIER) -- Cap the multiplier
    
    bulletShakeIntensity = baseIntensity * rapidFireMultiplier
    bulletShakeYawDirection = math.random() > 0.5 and 1 or -1
    
    -- Reset rapid fire decay timer
    rapidFireTimer = currentTime + 1.0 -- Decay rapid fire count after 1 second of no shots
    
    -- Randomize seeds for all shake components
    seedX = math.Rand(0, 100)
    seedY = math.Rand(0, 100)
    seedZ = math.Rand(0, 100)
    seedPitch = math.Rand(0, 100)
    seedYaw = math.Rand(0, 100)
    seedRoll = math.Rand(0, 100)
    
    -- Randomize frequencies for more chaotic motion
    freqX = math.Rand(30, 45)
    freqY = math.Rand(35, 50)
    freqZ = math.Rand(40, 55)
    freqPitch = math.Rand(1, 5)
    freqYaw = math.Rand(1, 10)
    freqRoll = math.Rand(1, 15)
end)

-- Red Screen Flash Variables
local redScreenActive = false
local redScreenAlpha = 0
local redScreenMaxAlpha = 0
local redScreenColor = Color(255, 0, 0, 0)  -- Red with 0 initial alpha
local redScreenDecayRate = 1.5  -- How quickly the effect fades out
local lastRedScreenTime = 0
local redScreenDuration = 0

-- Update the existing network receive function to handle screen fade
net.Receive("AX_DamageShake", function()
    local currentTime = CurTime()
    damageAmount = net.ReadFloat()
    
    -- Scale intensity based on damage amount
    local baseIntensity = math.Clamp(damageAmount / 3, 2, 15)
    
    -- Add some randomness to the intensity
    damageShakeIntensity = baseIntensity * math.Rand(0.9, 1.4)
    damageYawDirection = math.random() > 0.5 and 1 or -1
    lastDamageTime = currentTime
    damageShakeActive = true
    
    -- Randomize seeds for all shake components
    dmgSeedX = math.Rand(0, 100)
    dmgSeedY = math.Rand(0, 100)
    dmgSeedZ = math.Rand(0, 100)
    dmgSeedPitch = math.Rand(0, 100)
    dmgSeedYaw = math.Rand(0, 100)
    dmgSeedRoll = math.Rand(0, 100)
    
    -- Randomize frequencies for more directional, less chaotic motion
    dmgFreqX = math.Rand(12, 25)
    dmgFreqY = math.Rand(12, 25)
    dmgFreqZ = math.Rand(15, 30)
    dmgFreqPitch = math.Rand(0.8, 2.0)
    dmgFreqYaw = math.Rand(0.5, 1.5)
    dmgFreqRoll = math.Rand(0.3, 1.0)
    
    -- Handle red screen effect
    redScreenActive = true
    lastRedScreenTime = currentTime
    
    -- Calculate duration based on damage amount
    redScreenDuration = math.Clamp(0.4 + (damageAmount * 0.03), 0.4, 1.5)
    
    -- Calculate maximum alpha based on damage
    -- Use a lower saturation by keeping the maximum alpha relatively low
    local newMaxAlpha = math.Clamp(damageAmount * 3.5, 20, 120)  -- Low max alpha for subtlety
    
    -- If we're already showing a red screen, add to existing alpha without exceeding maximum
    if redScreenAlpha > 0 then
        -- Add to existing alpha, but don't exceed a reasonable maximum
        redScreenMaxAlpha = math.min(redScreenMaxAlpha + newMaxAlpha, 180)
        redScreenAlpha = redScreenMaxAlpha  -- Reset alpha to the new max
    else
        redScreenMaxAlpha = newMaxAlpha
        redScreenAlpha = newMaxAlpha
    end
    
    -- Update the color alpha
    redScreenColor.a = redScreenAlpha
    
    print("Damage Screen Effect: " .. damageAmount .. " damage, Alpha: " .. redScreenAlpha)
end)

-- Replace the Think hook to include both bullet shake, damage shake, and red screen effect
hook.Add("Think", "AX_ThirdPerson_UpdateShake", function()
    local currentTime = CurTime()
    local client = LocalPlayer()
    if not IsValid(client) then return end
    
    -- Check if we need to decay the rapid fire counter (keep this from original code)
    if rapidFireCount > 0 and currentTime > rapidFireTimer then
        rapidFireCount = math.max(0, rapidFireCount - 1)
        rapidFireTimer = currentTime + 0.5 -- Check again in half a second
    end
    
    -- Handle bullet shake (original code)
    if bulletShakeActive then
        -- Calculate time since shot
        local timeSinceShot = currentTime - lastShootTime
        local shakeDuration = 0.2 * (1 + rapidFireCount * 0.1)
        
        if timeSinceShot > shakeDuration then
            -- Reset the shake when done
            bulletShakeActive = false
            bulletShakeAngles = Angle(0, 0, 0)
            bulletShakeOffset = Vector(0, 0, 0)
        else
            -- Create a decay curve for the shake
            local shakeDecay = 1 - (timeSinceShot / shakeDuration)
            local bellCurve = math.sin(shakeDecay * math.pi)
            
            -- Mix multiple sine waves for more complex, natural motion
            local time = CurTime()
            
            -- Calculate shake angles with very little rotation
            local yawShake = (
                math.sin((time + seedYaw) * freqYaw) * 0.6 + 
                math.sin((time + seedYaw * 0.7) * (freqYaw * 1.3)) * 0.4
            ) * (bulletShakeIntensity * 0.3) * bulletShakeYawDirection * bellCurve
            
            local pitchShake = (
                math.cos((time + seedPitch) * freqPitch) * 0.7 + 
                math.cos((time + seedPitch * 0.5) * (freqPitch * 1.5)) * 0.3
            ) * (bulletShakeIntensity * 0.3) * bellCurve
            
            local rollShake = (
                math.sin((time + seedRoll) * freqRoll) * 0.5 + 
                math.sin((time + seedRoll * 0.3) * (freqRoll * 1.7)) * 0.5
            ) * (bulletShakeIntensity * 0.3) * math.Rand(0.8, 1.2) * bellCurve
            
            -- Add small random jitter to angles for extra realism
            pitchShake = pitchShake + math.Rand(-0.2, 1) * bulletShakeIntensity * bellCurve
            yawShake = yawShake + math.Rand(-0.1, 0.6) * bulletShakeIntensity * bellCurve
            rollShake = rollShake + math.Rand(-0.1, 0.3) * bulletShakeIntensity * bellCurve
            
            -- Set the shake angles
            bulletShakeAngles = Angle(pitchShake, yawShake, rollShake)
            
            -- Calculate position offset with complex patterns for screen shaking
            local xShake = (
                math.sin((time + seedX) * freqX) * 0.6 + 
                math.sin((time + seedX * 0.6) * (freqX * 1.4)) * 0.4
            ) * (bulletShakeIntensity * 0.8) * math.Rand(0.9, 1.1) * bellCurve
            
            local yShake = (
                math.cos((time + seedY) * freqY) * 0.7 + 
                math.cos((time + seedY * 0.4) * (freqY * 1.6)) * 0.3
            ) * (bulletShakeIntensity * 0.7) * math.Rand(0.9, 1.1) * bellCurve
            
            local zShake = (
                math.sin((time + seedZ) * freqZ) * 0.8 + 
                math.sin((time + seedZ * 0.5) * (freqZ * 1.5)) * 0.2
            ) * (bulletShakeIntensity * 0.5) * math.Rand(0.9, 1.1) * bellCurve
            
            -- Add small random jitter to position for extra realism
            xShake = xShake + math.Rand(-0.3, 0.3) * bulletShakeIntensity * bellCurve
            yShake = yShake + math.Rand(-0.3, 0.3) * bulletShakeIntensity * bellCurve
            zShake = zShake + math.Rand(-0.2, 0.2) * bulletShakeIntensity * bellCurve
            
            bulletShakeOffset = Vector(xShake, yShake, zShake)
        end
    end
    
    -- Handle damage shake
    if damageShakeActive then
        -- Calculate time since damage
        local timeSinceDamage = currentTime - lastDamageTime
        local damageDuration = 0.6 + (damageAmount * 0.025)
        damageDuration = math.Clamp(damageDuration, 0.5, 1.8)
        
        if timeSinceDamage > damageDuration then
            -- Reset the shake when done
            damageShakeActive = false
            damageShakeAngles = Angle(0, 0, 0)
            damageShakeOffset = Vector(0, 0, 0)
        else
            -- Create a decay curve for the damage shake
            local shakeDecay = 1 - (timeSinceDamage / damageDuration)
            local damageCurve = math.sin(shakeDecay * math.pi) * math.pow(shakeDecay, 0.5)
            
            -- Add initial impact spike for the first 0.15 seconds
            if timeSinceDamage < 0.15 then
                damageCurve = damageCurve * 1.7
            end
            
            local time = CurTime()
            
            -- Calculate damage shake angles
            local yawShake = (
                math.sin((time + dmgSeedYaw) * dmgFreqYaw) * 0.7 + 
                math.sin((time + dmgSeedYaw * 0.6) * (dmgFreqYaw * 1.2)) * 0.3
            ) * (damageShakeIntensity * 2.4) * damageYawDirection * damageCurve
            
            -- Add an even stronger initial yaw kick in the damage direction
            if timeSinceDamage < 0.15 then
                yawShake = yawShake + (damageShakeIntensity * 2.5 * damageYawDirection * (1 - timeSinceDamage/0.15))
            end
            
            local pitchShake = (
                math.cos((time + dmgSeedPitch) * dmgFreqPitch) * 0.6 + 
                math.cos((time + dmgSeedPitch * 0.5) * (dmgFreqPitch * 1.3)) * 0.4
            ) * (damageShakeIntensity * 1.1) * damageCurve
            
            local rollShake = (
                math.sin((time + dmgSeedRoll) * dmgFreqRoll) * 0.5 + 
                math.sin((time + dmgSeedRoll * 0.3) * (dmgFreqRoll * 1.2)) * 0.5
            ) * (damageShakeIntensity * 0.7) * math.Rand(0.8, 1.2) * damageCurve
            
            -- Add stronger random jitter to angles for damage impact realism
            pitchShake = pitchShake + math.Rand(-0.5, 1.5) * damageShakeIntensity * damageCurve
            yawShake = yawShake + math.Rand(-0.5, 1.2) * damageShakeIntensity * damageCurve
            rollShake = rollShake + math.Rand(-0.3, 0.6) * damageShakeIntensity * damageCurve
            
            -- Set the damage shake angles
            damageShakeAngles = Angle(pitchShake, yawShake, rollShake)
            
            -- Calculate position offset with reduced patterns for more focused, less chaotic shaking
            local xShake = (
                math.sin((time + dmgSeedX) * dmgFreqX) * 0.6 + 
                math.sin((time + dmgSeedX * 0.5) * (dmgFreqX * 1.2)) * 0.4
            ) * (damageShakeIntensity * 1.2) * math.Rand(0.9, 1.1) * damageCurve
            
            local yShake = (
                math.cos((time + dmgSeedY) * dmgFreqY) * 0.7 + 
                math.cos((time + dmgSeedY * 0.4) * (dmgFreqY * 1.1)) * 0.3
            ) * (damageShakeIntensity * 1.0) * math.Rand(0.9, 1.1) * damageCurve
            
            local zShake = (
                math.sin((time + dmgSeedZ) * dmgFreqZ) * 0.6 + 
                math.sin((time + dmgSeedZ * 0.5) * (dmgFreqZ * 1.3)) * 0.4
            ) * (damageShakeIntensity * 1.0) * math.Rand(0.9, 1.1) * damageCurve
            
            -- Add reduced random jitter to position for more focused impact feel
            xShake = xShake + math.Rand(-0.5, 0.5) * damageShakeIntensity * damageCurve
            yShake = yShake + math.Rand(-0.5, 0.5) * damageShakeIntensity * damageCurve
            zShake = zShake + math.Rand(-0.4, 0.4) * damageShakeIntensity * damageCurve
            
            -- Add more directional push based on damage direction
            if timeSinceDamage < 0.2 then
                local dirFactor = (1 - timeSinceDamage/0.2) * damageYawDirection
                xShake = xShake + (dirFactor * damageShakeIntensity * 1.2)
            end
            
            damageShakeOffset = Vector(xShake, yShake, zShake)
        end
    end
    
    -- Handle red screen fade effect
    if redScreenActive then
        local timeSinceRedScreen = currentTime - lastRedScreenTime
        
        if timeSinceRedScreen > redScreenDuration or redScreenAlpha <= 0 then
            -- Reset the red screen when done
            redScreenActive = false
            redScreenAlpha = 0
            redScreenColor.a = 0
        else
            -- Calculate a smooth fade out using a custom decay curve
            -- Fade out more quickly at first, then slower
            local progress = timeSinceRedScreen / redScreenDuration
            local decayCurve = 1 - math.pow(progress, 0.7)  -- Adjust power for fade curve
            
            -- Reduce alpha based on the decay curve
            redScreenAlpha = redScreenMaxAlpha * decayCurve
            redScreenColor.a = math.floor(redScreenAlpha)
        end
    end
end)

-- Add a new hook to draw the red screen effect
hook.Add("HUDPaint", "AX_DamageScreenEffect", function()
    if redScreenAlpha <= 0 then return end
    
    -- Draw a full-screen red overlay with the current alpha
    surface.SetDrawColor(redScreenColor)
    surface.DrawRect(0, 0, ScrW(), ScrH())
end)


-- Replace the existing CalcView function in MODULE - this one includes both bullet and damage shake
function MODULE:CalcView(client, pos, angles, fov)
    if (!ax.option:Get("thirdperson", false) or hook.Run("PreRenderThirdpersonView", client, pos, angles, fov) == false) then
        fakePos = nil
        fakeAngles = nil
        fakeFov = nil
        return
    end

    -- If camAngles doesn't exist yet, initialize it
    if (!camAngles) then
        camAngles = angles
    end

    local view = {}

    if (ax.option:Get("thirdperson.follax.head", false)) then
        local head

        for i = 0, client:GetBoneCount() do
            local bone = client:GetBoneName(i)
            if (ax.util:FindString(bone, "head")) then
                head = i
                break
            end
        end

        if (head) then
            local head_pos = select(1, client:GetBonePosition(head))
            pos = head_pos
        end
    end

    pos = pos + client:GetVelocity() / 8

    -- Use camAngles instead of player angles for camera positioning
    local trace = util.TraceHull({
        start = pos,
        endpos = pos - (camAngles:Forward() * ax.option:Get("thirdperson.position.x", 0)) + 
                 (camAngles:Right() * ax.option:Get("thirdperson.position.y", 0)) + 
                 (camAngles:Up() * ax.option:Get("thirdperson.position.z", 0)),
        filter = client,
        mask = MASK_SHOT,
        mins = Vector(-4, -4, -4),
        maxs = Vector(4, 4, 4)
    })

    local traceData = util.TraceHull({
        start = pos,
        endpos = pos + (camAngles:Forward() * 32768),
        filter = client,
        mask = MASK_SHOT,
        mins = Vector(-8, -8, -8),
        maxs = Vector(8, 8, 8)
    })

    local shootPos = traceData.HitPos
    local followHitAngles = ax.option:Get("thirdperson.follax.hit.angles", true)
    local followHitFov = ax.option:Get("thirdperson.follax.hit.fov", true)

    local viewBob = Angle(0, 0, 0)
    local curTime = CurTime()
    local frameTime = FrameTime()

    -- Normal view bob
    viewBob.p = math.sin(curTime / 4) / 2
    viewBob.y = math.cos(curTime) / 2
    
    -- Apply both bullet shake and damage shake angles to viewBob
    if bulletShakeActive then
        viewBob = viewBob + bulletShakeAngles
    end
    
    -- Apply damage shake - this gets added on top of any bullet shake
    if damageShakeActive then
        viewBob = viewBob + damageShakeAngles
    end

    -- Create position offset for shake
    local posOffset = Vector(0, 0, 0)
    if bulletShakeActive then
        posOffset = posOffset + bulletShakeOffset
    end
    
    if damageShakeActive then
        posOffset = posOffset + damageShakeOffset
    end

    -- Use camAngles for camera movement with the modified viewBob
    fakeAngles = LerpAngle(frameTime * 8, fakeAngles or camAngles, 
                          (followHitAngles and (shootPos - trace.HitPos):Angle() or camAngles) + viewBob)
    
    -- Apply position shake to the camera position
    fakePos = LerpVector(frameTime * 8, fakePos or trace.HitPos, trace.HitPos + posOffset)

    local distance = pos:Distance(traceData.HitPos) / 64
    distance = math.Clamp(distance, 0, 50)
    fakeFov = Lerp(frameTime, fakeFov or fov, followHitFov and (fov - distance) or fov)

    view.origin = fakePos or trace.HitPos
    view.angles = fakeAngles or camAngles
    view.fov = fakeFov or fov

    return view
end

-- Create movement adjustments for the third person mode
function MODULE:CreateMove(cmd)
    if (!ax.option:Get("thirdperson", false)) then
        return
    end
    
    local client = LocalPlayer()
    
    if (!camAngles) then
        return
    end
    
    -- Get camera yaw
    local cam_yaw = camAngles.y
    
    -- When aiming (Mouse2 held), make player face where the camera is pointing
    if (isAiming) then
        -- Set player's eye angles to match camera angles completely (both pitch and yaw)
        local newEyeAngles = Angle(camAngles.p, cam_yaw, 0)
        cmd:SetViewAngles(newEyeAngles)
    else
        -- Only adjust movement when player is actually moving (not aiming)
        local fm = cmd:GetForwardMove()
        local sm = cmd:GetSideMove()
        
        -- When moving, make the player's model face the direction of the camera (only horizontal)
        if (math.abs(fm) > 1 or math.abs(sm) > 1) then
            -- Set player's eye angles to face the same direction as the camera (horizontally only)
            local newEyeAngles = Angle(client:EyeAngles().p, cam_yaw, 0)
            cmd:SetViewAngles(newEyeAngles)
        end
    end
    
    -- Calculate movement angle from input
    local fm = cmd:GetForwardMove()
    local sm = cmd:GetSideMove()
    local movement_angle = math.deg(math.atan2(-sm, fm))
    
    -- Get player yaw
    local player_yaw = client:EyeAngles().y
    
    -- Calculate the angle difference between camera and player view
    local yaw_diff = math.NormalizeAngle(cam_yaw - player_yaw)
    
    -- Calculate magnitude of the movement
    local movement_mag = math.sqrt(fm * fm + sm * sm)
    
    -- Calculate new movement direction based on camera angle
    local new_fm = movement_mag * math.cos(math.rad(movement_angle + yaw_diff))
    local new_sm = -movement_mag * math.sin(math.rad(movement_angle + yaw_diff))
    
    -- Set the new movement values
    cmd:SetForwardMove(new_fm)
    cmd:SetSideMove(new_sm)
end

-- Create movement adjustments for the third person mode
function MODULE:CreateMove(cmd)
    if (!ax.option:Get("thirdperson", false)) then
        return
    end
    
    local client = LocalPlayer()
    
    if (!camAngles) then
        return
    end
    
    -- Get camera yaw
    local cam_yaw = camAngles.y
    
    -- When aiming (Mouse2 held), make player face where the camera is pointing
    if (isAiming) then
        -- Set player's eye angles to match camera angles completely (both pitch and yaw)
        local newEyeAngles = Angle(camAngles.p, cam_yaw, 0)
        cmd:SetViewAngles(newEyeAngles)
    else
        -- Only adjust movement when player is actually moving (not aiming)
        local fm = cmd:GetForwardMove()
        local sm = cmd:GetSideMove()
        
        -- When moving, make the player's model face the direction of the camera (only horizontal)
        if (math.abs(fm) > 1 or math.abs(sm) > 1) then
            -- Set player's eye angles to face the same direction as the camera (horizontally only)
            local newEyeAngles = Angle(client:EyeAngles().p, cam_yaw, 0)
            cmd:SetViewAngles(newEyeAngles)
        end
    end
    
    -- Calculate movement angle from input
    local fm = cmd:GetForwardMove()
    local sm = cmd:GetSideMove()
    local movement_angle = math.deg(math.atan2(-sm, fm))
    
    -- Get player yaw
    local player_yaw = client:EyeAngles().y
    
    -- Calculate the angle difference between camera and player view
    local yaw_diff = math.NormalizeAngle(cam_yaw - player_yaw)
    
    -- Calculate magnitude of the movement
    local movement_mag = math.sqrt(fm * fm + sm * sm)
    
    -- Calculate new movement direction based on camera angle
    local new_fm = movement_mag * math.cos(math.rad(movement_angle + yaw_diff))
    local new_sm = -movement_mag * math.sin(math.rad(movement_angle + yaw_diff))
    
    -- Set the new movement values
    cmd:SetForwardMove(new_fm)
    cmd:SetSideMove(new_sm)
end

-- Create movement adjustments for the third person mode
function MODULE:CreateMove(cmd)
    if (!ax.option:Get("thirdperson", false)) then
        return
    end
    
    local client = LocalPlayer()
    
    if (!camAngles) then
        return
    end
    
    -- Get camera yaw
    local cam_yaw = camAngles.y
    
    -- When aiming (Mouse2 held), make player face where the camera is pointing
    if (isAiming) then
        -- Set player's eye angles to match camera angles completely (both pitch and yaw)
        local newEyeAngles = Angle(camAngles.p, cam_yaw, 0)
        cmd:SetViewAngles(newEyeAngles)
    else
        -- Only adjust movement when player is actually moving (not aiming)
        local fm = cmd:GetForwardMove()
        local sm = cmd:GetSideMove()
        
        -- When moving, make the player's model face the direction of the camera (only horizontal)
        if (math.abs(fm) > 1 or math.abs(sm) > 1) then
            -- Set player's eye angles to face the same direction as the camera (horizontally only)
            local newEyeAngles = Angle(client:EyeAngles().p, cam_yaw, 0)
            cmd:SetViewAngles(newEyeAngles)
        end
    end
    
    -- Calculate movement angle from input
    local fm = cmd:GetForwardMove()
    local sm = cmd:GetSideMove()
    local movement_angle = math.deg(math.atan2(-sm, fm))
    
    -- Get player yaw
    local player_yaw = client:EyeAngles().y
    
    -- Calculate the angle difference between camera and player view
    local yaw_diff = math.NormalizeAngle(cam_yaw - player_yaw)
    
    -- Calculate magnitude of the movement
    local movement_mag = math.sqrt(fm * fm + sm * sm)
    
    -- Calculate new movement direction based on camera angle
    local new_fm = movement_mag * math.cos(math.rad(movement_angle + yaw_diff))
    local new_sm = -movement_mag * math.sin(math.rad(movement_angle + yaw_diff))
    
    -- Set the new movement values
    cmd:SetForwardMove(new_fm)
    cmd:SetSideMove(new_sm)
end

function MODULE:ShouldDrawLocalPlayer(client)
    return ax.option:Get("thirdperson", false)
end

function MODULE:PrePlayerDraw(client, flags)
    if (ax.config:Get("thirdperson.tracecheck") and ax.client != client) then
        local traceLine = util.TraceLine({
            start = ax.client:GetShootPos(),
            endpos = client:GetShootPos(),
            filter = ax.client
        })

        if (!traceLine.Hit) then
            return true
        end
    end
end

hook.Add("PostDrawTranslucentRenderables", "AX_ThirdPerson_Crosshair", function()
    local client = LocalPlayer()
    if (!IsValid(client) or !ax.option:Get("thirdperson", false)) then return end
    if aimProgress == nil then aimProgress = 0 end
    if lastAimState == nil then lastAimState = false end
    if crosshairSize == nil then crosshairSize = 2 end 
    if crosshairDistance == nil then crosshairDistance = 1000 end 
    if duckTransition == nil then duckTransition = 0 end
    if playerDuckLast == nil then playerDuckLast = false end
    if smoothedDistance == nil then smoothedDistance = crosshairDistance end

    local isAiming = client:KeyDown(IN_ATTACK2)

    local target = isAiming and 1 or 0
    aimProgress = Lerp(FrameTime() * 8, aimProgress, target) 

    if aimProgress < 0.01 then return end

    local aimStateChanged = lastAimState ~= isAiming
    if aimStateChanged then
        lastAimState = isAiming
    end

    local startPos = client:EyePos()
    local camAngles = client:EyeAngles() 
    local aimDir = camAngles:Forward()
    
    local trace = util.TraceLine({
        start = startPos,
        endpos = startPos + (aimDir * crosshairDistance),
        filter = client,
        mask = MASK_SHOT 
    })
    
    local idealDistance = crosshairDistance
    if trace.Hit then
        idealDistance = trace.Fraction * crosshairDistance
        
        local bufferDistance = 5 -- Adjust as needed
        idealDistance = math.max(idealDistance - bufferDistance, 50) 
    end
    
    smoothedDistance = Lerp(FrameTime() * 7, smoothedDistance, idealDistance) 
    
    local crosshairPos = startPos + (aimDir * smoothedDistance)
    
    local aimDistance = startPos:Distance(crosshairPos)
    local scaleFactor = math.Clamp(aimDistance / 100, 0.5, 2) 
    
    local viewPos = EyePos() 
    local viewAngles = EyeAngles()
    local viewRight = viewAngles:Right()
    local viewUp = viewAngles:Up()
    
    local exactAimPos = Vector(crosshairPos)
    
    local offsetRight = 23 * aimProgress
    local offsetDown = -2 * aimProgress
    crosshairPos = crosshairPos + (viewRight * offsetRight) + (viewUp * offsetDown)

    local playerVelocity = client:GetVelocity():Length()
    local moveAmount = math.Clamp(playerVelocity / 200, 0, 1) * 1.5 
    
    if moveAmount > 0.1 then
        local swayX = math.sin(CurTime() * 2.5) * moveAmount
        local swayY = math.cos(CurTime() * 1.8) * moveAmount * 0.7
        
        crosshairPos = crosshairPos + viewRight * swayX + viewUp * swayY
    end
    
    local playerDuck = client:Crouching()
    if playerDuckLast ~= playerDuck then
        duckTransition = 0
        playerDuckLast = playerDuck
    end
    
    duckTransition = math.min(duckTransition + FrameTime() * 5, 1)
    
    if duckTransition < 1 then
        local bounceAmount = math.sin(duckTransition * math.pi) * 1.5
        crosshairPos = crosshairPos + viewUp * bounceAmount
    end

    cam.Start3D()
        local crosshairAngles = (viewPos - crosshairPos):Angle()
        local right = crosshairAngles:Right()
        local up = crosshairAngles:Up()
        
        render.SetColorMaterial()

        local beamLength = crosshairSize * scaleFactor 
        local gapSize = crosshairSize * 5 * aimProgress
        local alpha = math.Clamp(aimProgress * 255, 0, 255)
        
        local animationProgress = aimProgress^2 -- Non-linear progression for more dynamic feel
        local slideDistance = 25 * scaleFactor -- How far the brackets slide from, scaled with distance
        
        -- Create brackets that sandwich the exact aim point
        local halfGap = gapSize * 0.5
        
        local leftSlideOffset = slideDistance * (1 - animationProgress)
        local leftCenter = crosshairPos - (right * (halfGap + leftSlideOffset))
        
        local rightSlideOffset = slideDistance * (1 - animationProgress)
        local rightCenter = crosshairPos + (right * (halfGap + rightSlideOffset))

        local hue = 5 * math.sin(CurTime() * 3)
        local baseColor = Color(255, 40 + hue, 40 + hue, alpha)
        
        local glowSize = (0.8 + (0.2 * math.sin(CurTime() * 5))) * scaleFactor
        
        render.DrawBeam(leftCenter + (up * beamLength), leftCenter, 1 * glowSize, 0, 1, baseColor)
        render.DrawBeam(leftCenter - (up * beamLength), leftCenter, 1 * glowSize, 0, 1, baseColor)

        render.DrawBeam(rightCenter + (up * beamLength), rightCenter, 1 * glowSize, 0, 1, baseColor)
        render.DrawBeam(rightCenter - (up * beamLength), rightCenter, 1 * glowSize, 0, 1, baseColor)
        
        --[[ Optional: raw a small dot at exact aim point for precision
        local dotSize = 0.5 * glowSize
        render.DrawBeam(crosshairPos + Vector(0,0,dotSize/2), crosshairPos - Vector(0,0,dotSize/2), dotSize, 0, 1, Color(255, 40, 40, alpha * 0.7))]]
        
        if aimProgress > 0.05 and aimProgress < 0.95 then
            local particleCount = 3
            for i = 1, particleCount do
                local particleProgress = (CurTime() * 2 + i/particleCount) % 1
                local particleAlpha = math.sin(particleProgress * math.pi) * 100 * aimProgress
                
                if particleAlpha > 5 then
                    local particleColor = Color(255, 80, 80, particleAlpha)
                    if isAiming then
                        -- Opening animation
                        local leftParticlePos = crosshairPos - (right * (halfGap * particleProgress))
                        local rightParticlePos = crosshairPos + (right * (halfGap * particleProgress))
                        
                        render.DrawBeam(leftParticlePos, leftParticlePos - (right * 1 * scaleFactor), 0.8 * scaleFactor, 0, 1, particleColor)
                        render.DrawBeam(rightParticlePos, rightParticlePos + (right * 1 * scaleFactor), 0.8 * scaleFactor, 0, 1, particleColor)
                    else
                        -- Closing animation
                        local leftParticlePos = leftCenter + (right * (halfGap * 2 * particleProgress))
                        local rightParticlePos = rightCenter - (right * (halfGap * 2 * particleProgress))
                        
                        render.DrawBeam(leftParticlePos, leftParticlePos + (right * 1 * scaleFactor), 0.8 * scaleFactor, 0, 1, particleColor)
                        render.DrawBeam(rightParticlePos, rightParticlePos - (right * 1 * scaleFactor), 0.8 * scaleFactor, 0, 1, particleColor)
                    end
                end
            end
        end

        local normalDistance = 1000 -- A "normal" distance for color reference
        local proximityFactor = math.Clamp(smoothedDistance / normalDistance, 0, 1)
        
        if proximityFactor < 0.3 then
            local proximityColor = Color(
                255, 
                40 + (180 * (1 - proximityFactor)), 
                40 + (40 * (1 - proximityFactor)), 
                alpha
            )
        end

    cam.End3D()
end)


--[[
function MODULE:AddToolMenuCategories()
    spawnmenu.AddToolCategory("Parallax", "User", "User")
end

function MODULE:AddToolMenuTabs()
    spawnmenu.AddToolTab("Parallax", "Parallax", "icon16/computer.png")

    spawnmenu.AddToolMenuOption("Parallax", "User", "ax_thirdperson", "Third Person", "", "", function(panel)
        panel:ClearControls()

        panel:AddControl("Header", { Text = ax.localization:GetPhrase("options.thirdperson.title"), Description = ax.localization:GetPhrase("options.thirdperson.description") })
        panel:CheckBox(ax.localization:GetPhrase("options.thirdperson.enable"), "ax_thirdperson_enable")
        panel:NumSlider(ax.localization:GetPhrase("options.thirdperson.position.x"), "ax_thirdperson_position_x", -1000, 1000, 0)
        panel:NumSlider(ax.localization:GetPhrase("options.thirdperson.position.y"), "ax_thirdperson_position_y", -1000, 1000, 0)
        panel:NumSlider(ax.localization:GetPhrase("options.thirdperson.position.z"), "ax_thirdperson_position_z", -1000, 1000, 0)
    end)
end
]]