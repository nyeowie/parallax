local MODULE = MODULE

MODULE.Name = "View Bob and Sway System"
MODULE.Author = "setsunaok"
MODULE.Description = "Adds realistic view bobbing and sway effects while walking and looking around"
MODULE.license = [[ MIT License
Copyright (c) 2024 setsunaok
Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:
The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.
THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT or OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
]]

if SERVER then return end

local CAMERA_CONFIG = {
    HEAD_BOB_INTENSITY = 0.5,
    WALK_INTENSITY = 0.6,
    WALK_FREQUENCY = 0.4,
    STEP_ANGLE_LEFT = Angle(2, -3, 1),
    STEP_ANGLE_RIGHT = Angle(2, 3, -1),
    SMOOTH_SPEED = 2,
    SWAY_INTENSITY = 0.5,      -- Increased sway intensity
    SWAY_SMOOTH = 0.15,        -- Adjusted smoothing for more natural feel
    SWAY_MAX_ANGLE = 15,        -- Maximum sway angle
    SWAY_RETURN_SPEED = 3,     -- How quickly sway returns to center
    SWAY_MOMENTUM = 0.8        -- How much momentum the sway maintains
}

local state = {
    stepTimer = 0,
    currentStep = 0,
    isLeftStep = true,
    currentAngle = Angle(0, 0, 0),
    targetAngle = Angle(0, 0, 0),
    lastYaw = 0,
    swayAngle = 0,
    swayVelocity = 0,          -- Track sway momentum
    lastMouseX = 0,            -- Track mouse movement
    mouseDelta = 0             -- Store mouse movement delta
}

CAMERA_CONFIG.BREATHING_ENABLED = true
CAMERA_CONFIG.BREATHING_INTENSITY = 1        -- Reduced base intensity for subtlety
CAMERA_CONFIG.BREATHING_FREQUENCY = 0.7       -- Slowed down breathing cycle for realism
CAMERA_CONFIG.BREATHING_VARIANCE = 0.05        -- Reduced variance for smoother transitions
CAMERA_CONFIG.EXERTION_MULTIPLIER = 1.75       -- Slightly reduced exertion effect
CAMERA_CONFIG.EXERTION_RECOVERY = 0.3          -- Slower recovery for smoother transitions
CAMERA_CONFIG.BREATHING_PITCH_RATIO = 0.8      -- Slight reduction in pitch movement
CAMERA_CONFIG.BREATHING_ROLL_RATIO = 0.15      -- Reduced roll for subtlety
-- New parameters for enhanced breathing
CAMERA_CONFIG.BREATHING_SMOOTH_FACTOR = 8.0    -- Higher value = smoother transitions
CAMERA_CONFIG.BREATHING_SECONDARY_CYCLE = 0.1  -- Secondary micro-movements for realism
CAMERA_CONFIG.BREATHING_VARIANCE_BLEND = 0.03  -- How quickly variance changes blend in

-- Add these to your state table
state.breathCycle = 0                      -- Current position in breathing cycle
state.breathIntensity = 1.0                -- Current intensity multiplier based on exertion
state.lastBreathTime = 0                   -- Track time for random variations
state.breathVariance = 0                   -- Start with neutral variance
state.targetBreathVariance = 0             -- Target variance for smooth blending
state.secondaryCycle = 0                   -- Secondary micro-movement cycle
state.lastBreathAngle = Angle(0, 0, 0)     -- Previous frame's breath angle for smoothing

local function AngleDifference(a, b)
    local diff = a - b
    return math.NormalizeAngle(diff)
end

local function LerpAngleFull(start, target, fraction)
    local result = Angle(0, 0, 0)
    
    local pitchDiff = AngleDifference(target.p, start.p)
    local yawDiff = AngleDifference(target.y, start.y)
    local rollDiff = AngleDifference(target.r, start.r)
    
    result.p = start.p + pitchDiff * fraction
    result.y = start.y + yawDiff * fraction
    result.r = start.r + rollDiff * fraction
    
    return result
end

local function CalculateHeadBob(ply, deltaTime)
    local velocity = ply:GetVelocity():Length2D()
    local bobAmount = math.min(velocity / 100, 1) * CAMERA_CONFIG.HEAD_BOB_INTENSITY
    
    state.stepTimer = (state.stepTimer + deltaTime * velocity * 0.01) % (math.pi * 2)
    
    local bobX = math.sin(state.stepTimer * 2) * bobAmount
    local bobY = math.cos(state.stepTimer * 4) * bobAmount * 0.5
    
    return Vector(bobX, bobY, 0)
end

local function CalculateStepMovement(ply, deltaTime)
    local velocity = ply:GetVelocity():Length2D()
    
    if velocity < 50 then 
        state.currentStep = 0
        state.targetAngle = Angle(0, 0, 0)
    else
        state.currentStep = (state.currentStep + deltaTime * CAMERA_CONFIG.WALK_FREQUENCY * velocity * 0.05) % math.pi
        
        local moveDir = ply:GetVelocity():Angle().y
        local viewDir = ply:EyeAngles().y
        local relativeDir = AngleDifference(moveDir, viewDir)
        
        local stepAngle = state.isLeftStep and 
            CAMERA_CONFIG.STEP_ANGLE_LEFT or 
            CAMERA_CONFIG.STEP_ANGLE_RIGHT
            
        if math.abs(relativeDir) > 90 then
            stepAngle = Angle(-stepAngle.p, -stepAngle.y, -stepAngle.r)
        end
        
        local stepProgress = math.sin(state.currentStep * 2)
        
        if state.currentStep >= math.pi / 2 then
            state.isLeftStep = not state.isLeftStep
            state.currentStep = 0
        end
        
        state.targetAngle = stepAngle * math.abs(stepProgress) * CAMERA_CONFIG.WALK_INTENSITY
    end
    
    local smoothFraction = math.min(deltaTime * CAMERA_CONFIG.SMOOTH_SPEED, 1)
    state.currentAngle = LerpAngleFull(state.currentAngle, state.targetAngle, smoothFraction)
    
    return state.currentAngle
end

-- Calculate view sway from mouse/look movement
local function CalculateViewSway(ply, deltaTime, currentYaw)
    -- Get current mouse position
    local mouseX = input.GetCursorPos()
    
    -- Calculate mouse movement delta
    state.mouseDelta = mouseX - state.lastMouseX
    state.lastMouseX = mouseX
    
    -- Calculate yaw difference
    local yawDiff = AngleDifference(currentYaw, state.lastYaw)
    
    -- Add mouse movement influence to sway with better scaling
    local mouseInfluence = state.mouseDelta * 0.01
    
    -- Calculate target sway with both yaw and mouse movement
    local targetSway = (-yawDiff * CAMERA_CONFIG.SWAY_INTENSITY) + (mouseInfluence * CAMERA_CONFIG.SWAY_INTENSITY)
    
    -- Apply momentum to sway velocity
    state.swayVelocity = state.swayVelocity * CAMERA_CONFIG.SWAY_MOMENTUM + targetSway * (1 - CAMERA_CONFIG.SWAY_MOMENTUM)
    
    -- Update sway angle with velocity and clamping
    state.swayAngle = state.swayAngle + state.swayVelocity
    state.swayAngle = math.Clamp(state.swayAngle, -CAMERA_CONFIG.SWAY_MAX_ANGLE, CAMERA_CONFIG.SWAY_MAX_ANGLE)
    
    -- Apply return-to-center force
    local returnForce = -state.swayAngle * CAMERA_CONFIG.SWAY_RETURN_SPEED * deltaTime
    state.swayAngle = state.swayAngle + returnForce
    
    -- Smooth the final sway
    state.swayAngle = Lerp(CAMERA_CONFIG.SWAY_SMOOTH, state.swayAngle, state.swayAngle + state.swayVelocity)
    
    -- Update last yaw for next frame
    state.lastYaw = currentYaw
    
    -- Create full sway angle including pitch and roll effects
    local swayPitch = state.swayVelocity * 0.2  -- Add slight pitch when swaying
    local swayRoll = state.swayAngle * 0.3      -- Add roll proportional to sway
    
    return Angle(swayPitch, state.swayAngle * 0.15, swayRoll)
end

local function CalculateBreathing(ply, deltaTime)
    if not CAMERA_CONFIG.BREATHING_ENABLED then
        return Angle(0, 0, 0)
    end
    
    local velocity = ply:GetVelocity():Length2D()
    
    -- Update breath intensity based on player exertion - smoother transitions
    local targetIntensity = 1.0
    if velocity > 200 then
        -- Player is running - increase breath intensity
        targetIntensity = CAMERA_CONFIG.EXERTION_MULTIPLIER
    end
    
    -- Smoother intensity change with proper acceleration/deceleration
    state.breathIntensity = Lerp(deltaTime * CAMERA_CONFIG.EXERTION_RECOVERY, 
                                state.breathIntensity, 
                                targetIntensity)
    
    -- Update primary breath cycle with adjusted frequency based on intensity
    local cycleSpeed = CAMERA_CONFIG.BREATHING_FREQUENCY * state.breathIntensity
    state.breathCycle = (state.breathCycle + deltaTime * cycleSpeed) % (math.pi * 2)
    
    -- Update secondary micro-movement cycle for added realism
    state.secondaryCycle = (state.secondaryCycle + deltaTime * 1.7) % (math.pi * 2)
    
    -- Smoother variance transitions - update target occasionally
    if CurTime() - state.lastBreathTime > 3 + math.random() * 2 then
        state.targetBreathVariance = math.Rand(-CAMERA_CONFIG.BREATHING_VARIANCE, CAMERA_CONFIG.BREATHING_VARIANCE)
        state.lastBreathTime = CurTime()
    end
    
    -- Blend current variance smoothly toward target
    state.breathVariance = Lerp(deltaTime * CAMERA_CONFIG.BREATHING_VARIANCE_BLEND, 
                               state.breathVariance, 
                               state.targetBreathVariance)
    
    -- Calculate breathing motion with smoother sine wave
    -- Use primary sine wave for main breathing movement
    local mainBreath = math.sin(state.breathCycle) * CAMERA_CONFIG.BREATHING_INTENSITY
    
    -- Add subtle secondary micro-movements
    local microMovement = math.sin(state.secondaryCycle) * CAMERA_CONFIG.BREATHING_SECONDARY_CYCLE
    
    -- Combine movements with variance
    local breathAmount = (mainBreath + microMovement) * (1.0 + state.breathVariance)
    
    -- Create a subtle angle change for breathing
    local targetBreathAngle = Angle(
        breathAmount * CAMERA_CONFIG.BREATHING_PITCH_RATIO,
        0, 
        breathAmount * 0.5 * CAMERA_CONFIG.BREATHING_ROLL_RATIO -- Reduced roll effect
    )
    
    -- Apply smoothing between frames for ultra-smooth transitions
    local smoothFactor = math.min(deltaTime * CAMERA_CONFIG.BREATHING_SMOOTH_FACTOR, 1)
    local smoothedAngle = LerpAngleFull(state.lastBreathAngle, targetBreathAngle, smoothFactor)
    
    -- Save current angle for next frame's smoothing
    state.lastBreathAngle = smoothedAngle
    
    return smoothedAngle
end

hook.Add("CalcView", "ViewBobAndSway", function(ply, pos, ang, fov)
    if not IsValid(ply) or ply:InVehicle() then return end
    
    local deltaTime = FrameTime()
    local headBob = CalculateHeadBob(ply, deltaTime)
    local stepAngle = CalculateStepMovement(ply, deltaTime)
    local swayAngle = CalculateViewSway(ply, deltaTime, ang.y)
    local breathAngle = CalculateBreathing(ply, deltaTime)
    
    -- Combine all effects including breathing
    return {
        origin = pos + headBob,
        angles = ang + stepAngle + swayAngle + breathAngle,
        fov = fov
    }
end)

function MODULE:ConfigureMovement(settings)
    for k, v in pairs(settings or {}) do
        if CAMERA_CONFIG[k] ~= nil then
            CAMERA_CONFIG[k] = v
        end
    end
end