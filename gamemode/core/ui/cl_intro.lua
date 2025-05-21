
local gradientBottom = Material("vgui/gradient-d")
local gradientTop = Material("vgui/gradient-u")

-- Config
local FADE_IN_TIME = 1.5
local FADE_OUT_TIME = 0.5
local DISCLAIMER_ALPHA_PULSE = 0.8
local PULSE_SPEED = 1.5
local FRAME_RATE = 0.06 -- 0.1s per frame

-- Intro sequence configs
local WARNING_FADE_IN_TIME = 1.5
local WARNING_DISPLAY_TIME = 5
local NARRATION_FADE_IN_TIME = 1.5
local NARRATION_FADE_OUT_TIME = 1.5
local NARRATION_DISPLAY_TIME = 3
local BUTTON_FADE_IN_TIME = 0.5
local FINAL_TRANSITION_TIME = 5

-- Dynamic frame loading with proper directory structure
local frames = {}

-- Frame pattern structure - defines each folder and frame count
local framePatterns = {
    -- First pattern: frame1/frame_000_delay-0.1s.png to frame_299_delay-0.1s.png
    {
        folder = "frame1",
        pattern = "frame_%03d_delay-0.1s.png", 
        start = 0,
        count = 300
    },
    -- Second pattern: frame2/frame_000_delay-0.1s.png to frame_299_delay-0.1s.png
    {
        folder = "frame2",
        pattern = "frame_%03d_delay-0.1s.png",
        start = 0,
        count = 300
    },
    -- Third pattern: frame3/frame_000_delay-0.1s.png to frame_299_delay-0.1s.png
    {
        folder = "frame3",
        pattern = "frame_%03d_delay-0.1s.png",
        start = 0,
        count = 300
    },
    -- Fourth pattern: frame4/frame_000_delay-0.1s.png to frame_299_delay-0.1s.png
    {
        folder = "frame4",
        pattern = "frame_%03d_delay-0.1s.png",
        start = 0,
        count = 300
    },
    -- Fifth pattern: frame5/frame_000_delay-0.1s.png to frame_299_delay-0.1s.png
    {
        folder = "frame5",
        pattern = "frame_%03d_delay-0.1s.png",
        start = 0,
        count = 300
    },
    -- Sixth pattern: frame6/frame_000_delay-0.1s.png to frame_299_delay-0.1s.png
    {
        folder = "frame6",
        pattern = "frame_%03d_delay-0.1s.png",
        start = 0,
        count = 300
    },
    -- Seventh pattern: frame7/frame_000_delay-0.1s.png to frame_205_delay-0.1s.png
    {
        folder = "frame7",
        pattern = "frame_%03d_delay-0.1s.png",
        start = 0,
        count = 206  -- 0 to 205 inclusive = 206 frames
    }
}



-- Track loading progress
local totalExpectedFrames = 0
local loadedFrames = 0
local failedFrames = 0

-- Calculate total expected frames
for _, patternInfo in ipairs(framePatterns) do
    totalExpectedFrames = totalExpectedFrames + patternInfo.count
end

-- Load all frames based on patterns
for patternIndex, patternInfo in ipairs(framePatterns) do
    
    for i = patternInfo.start, patternInfo.start + patternInfo.count - 1 do
        -- Format filename
        local fileName = string.format(patternInfo.pattern, i)
        
        -- Construct full path with folder
        local fullPath = "materials/back/" .. patternInfo.folder .. "/" .. fileName
        
        local mat = Material(fullPath)
        if not mat:IsError() then
            table.insert(frames, mat)
            loadedFrames = loadedFrames + 1
            
            -- Print progress every 100 frames
            if loadedFrames % 100 == 0 then
                print("Progress: " .. loadedFrames .. "/" .. totalExpectedFrames .. 
                      " frames loaded (" .. math.floor((loadedFrames/totalExpectedFrames)*100) .. "%)")
            end
        else
            failedFrames = failedFrames + 1
            print("Failed to load frame: " .. fullPath)
        end
    end
end

-- New Intro Panel with Warning and Narration
local PANEL = {}

function PANEL:Init()
    if IsValid(ax.gui.intro) then
        ax.gui.intro:Remove()
    end

    ax.gui.intro = self
    self:SetSize(ScrW(), ScrH())
    self:SetPos(0, 0)
    self:MakePopup()
    self:InitWarningScreenEffects()
    self.narrationIndex = 1
    
    -- Initialize narration effects
    self:InitNarrationEffects()

    self.alpha = 0
    self.startTime = CurTime()
    self.pulseValue = 0
    self.inputDelay = CurTime() + FADE_IN_TIME
    self.frameIndex = 1
    self.lastFrameChange = CurTime()
    
    -- Intro sequence states
    self.introState = "warning" -- States: "warning", "button", "narration", "final"
    self.warningAlpha = 0
    self.buttonAlpha = 0
    self.narrationAlpha = 0
    self.narrationIndex = 0
    self.mainIntroAlpha = 0
    
    -- Start with warning fade in
    timer.Simple(1.5, function()
        if IsValid(self) then
            self:FadeInWarning()
        end
    end)
    
    -- Cancel any existing frame timers
    if timer.Exists("IntroFrameAdvance") then
        timer.Remove("IntroFrameAdvance")
    end
    
    print("Intro panel initialized with " .. #frames .. " animation frames")
end

function PANEL:FadeInWarning()
    self.introState = "warning"
    self.warningStartTime = CurTime()
    
    timer.Create("WarningFadeIn", 0.01, 0, function()
        if not IsValid(self) then timer.Remove("WarningFadeIn") return end
        
        local elapsed = CurTime() - self.warningStartTime
        local progress = math.Clamp(elapsed / WARNING_FADE_IN_TIME, 0, 1)
        self.warningAlpha = Lerp(progress, 0, 255)
        
        if progress >= 1 then
            timer.Remove("WarningFadeIn")
            
            -- After full display time, show the continue button
            timer.Simple(WARNING_DISPLAY_TIME + 8, function()
                if IsValid(self) then
                    self:FadeInContinueButton()
                end
            end)
        end
    end)
end

function PANEL:FadeInContinueButton()
    self.introState = "button"
    self.buttonStartTime = CurTime()
    
    timer.Create("ButtonFadeIn", 0.01, 0, function()
        if not IsValid(self) then timer.Remove("ButtonFadeIn") return end
        
        local elapsed = CurTime() - self.buttonStartTime
        local progress = math.Clamp(elapsed / BUTTON_FADE_IN_TIME, 0, 1)
        self.buttonAlpha = Lerp(progress, 0, 255)
        
        if progress >= 1 then
            timer.Remove("ButtonFadeIn")
        end
    end)
end

-- Intro narration text segments
local narrationSegments = {
    "Breathing. Your breathing.\nHeavy... erratic... unfamiliar.\nYour eyes open.. not to a sky, not to light.. but to a cold, flickering glow on the inside of a visor.\nEverything is wrong.\nYou don't know what year it is.\nThe suit's chronolog is corrupted.\nNo signals. No stars to track. Nothing.\nOnly instinct... and the cold hum of your suit keeping you alive.",
    "You don't remember where you are.\nYou don't remember how you got here.\nYou don't remember anything... Except your name. And even that... feels foreign.",
    "You don't remember where you are.\nYou don't remember how you got here.\nYou don't remember anything... Except your name. And even that... feels foreign.",
    "You're awake now.\nBut the world you woke into is silent.\nDead.\nYou're alone... or so you think.\nA biological leak... something unspeakable... something that was... not expected happened.\nThose... are now crawling with mutations of what once were people.\nYou begin to walk.\nDo what you can to survive and understand what's going on.\nYour story starts here.",
    "You're awake now.\nBut the world you woke into is silent.\nDead.\nYou're alone... or so you think.\nA biological leak... something unspeakable... something that was... not expected happened.\nThose... are now crawling with mutations of what once were people.\nYou begin to walk.\nDo what you can to survive and understand what's going on.\nYour story starts here.",
    "You don't know what year it is.\nThe suit's chronolog is corrupted.\nNo signals. No stars to track. Nothing.\nOnly instinct... and the cold hum of your suit keeping you alive.",
    "You're awake now.\nBut the world you woke into is silent.\nDead.\nYou're alone... or so you think.\nA biological leak... something unspeakable... something that was... not expected happened.\nThose... are now crawling with mutations of what once were people.\nYou begin to walk.\nDo what you can to survive and understand what's going on.\nYour story starts here.",
}


function PANEL:StartNarration()
    -- Fade out warning and button
    timer.Create("WarningFadeOut", 0.01, 0, function()
        if not IsValid(self) then timer.Remove("WarningFadeOut") return end
        
        local progress = math.Clamp((CurTime() - self.narrationStartTime) / FADE_OUT_TIME, 0, 1)
        self.warningAlpha = Lerp(progress, 255, 0)
        self.buttonAlpha = Lerp(progress, 255, 0)
        
        if progress >= 1 then
            timer.Remove("WarningFadeOut")
            self:NextNarrationSegment()
        end
    end)
    
    self.introState = "narration"
    self.narrationStartTime = CurTime()
    self.narrationIndex = 0
    self.narrationAlpha = 0
    
    -- Only run on client
    if CLIENT then
        -- Store the sound for control
        self.introSound = CreateSound(LocalPlayer(), "intro1.mp3")
        self.introSound:SetSoundLevel(75)
        self.introSound:Play()
        
        -- Create a timer to fade out the sound after 5 seconds
        timer.Simple(72, function()
            if not IsValid(self) then return end
            if self.introSound then
                self.introSound:FadeOut(2) -- Fade out over 2 seconds
            end
        end)
    end
end

function PANEL:NextNarrationSegment()
    if self.narrationIndex >= #narrationSegments then
        -- All narration segments shown, don't immediately move to final phase
        -- Instead, let AdvanceNarration handle it with the fade out
        self:AdvanceNarration()
        return
    end
    
    self.narrationIndex = self.narrationIndex + 1
    self.narrationSegmentStartTime = CurTime()
    
    -- Fade in this segment
    timer.Create("NarrationFadeIn", 0.01, 0, function()
        if not IsValid(self) then timer.Remove("NarrationFadeIn") return end
        
        local elapsed = CurTime() - self.narrationSegmentStartTime
        local progress = math.Clamp(elapsed / NARRATION_FADE_IN_TIME, 0, 1)
        
        if progress >= 1 then
            timer.Remove("NarrationFadeIn")
            
            -- Display time for this segment
            timer.Simple(NARRATION_DISPLAY_TIME, function()
                if IsValid(self) then
                    -- Fade out this segment
                    local fadeOutStartTime = CurTime()
                    
                    timer.Create("NarrationFadeOut", 0.01, 0, function()
                        if not IsValid(self) then timer.Remove("NarrationFadeOut") return end
                        
                        local elapsed = CurTime() - fadeOutStartTime
                        local fadeProgress = math.Clamp(elapsed / NARRATION_FADE_OUT_TIME, 0, 1)
                        
                        if fadeProgress >= 1 then
                            timer.Remove("NarrationFadeOut")
                            
                            -- Small pause before next segment
                            timer.Simple(0.5, function()
                                if IsValid(self) then
                                    self:NextNarrationSegment()
                                end
                            end)
                        end
                    end)
                end
            end)
        end
    end)
end

function PANEL:StartFinalTransition()
    self.introState = "final"
    self.finalStartTime = CurTime()
    
    -- Play the background music
    LocalPlayer():EmitSound("aurora1.mp3")
    
    -- We're already starting with a black background from the narration phase,
    -- so we can start fading in the main intro content
    timer.Create("FinalTransition", 0.01, 0, function()
        if not IsValid(self) then timer.Remove("FinalTransition") return end
        
        local elapsed = CurTime() - self.finalStartTime
        local progress = math.Clamp(elapsed / FINAL_TRANSITION_TIME, 0, 1)
        self.mainIntroAlpha = Lerp(progress, 0, 255)
        
        if progress >= 1 then
            timer.Remove("FinalTransition")
            self.alpha = 255 -- Set the main alpha for the original content
        end
    end)
end


function PANEL:InitWarningScreenEffects()
    -- Initialize warning screen specific effects and variables
    self.warningGlitchTimer = 0
    self.warningGlitchInterval = math.random(2, 5)
    self.warningGlitchActive = false
    self.warningGlitchDuration = 0.2
    self.warningGlitchLastTime = 0
    
    -- Text animation values
    self.charRevealIndex = 0
    self.charRevealDelay = 0.03
    self.charRevealLastTime = 0
    self.revealedText = ""
    self.fullWarningText = "This game contains disturbing imagery, loud noises, and psychological themes.\nIt is not recommended for players who may be sensitive to graphic content,\nmental distress, or sudden audio/visual stimuli.\n\nPlayer discretion is strongly advised.\n\nThe events depicted are fictional. Any resemblance to real people,\nevents, or entities is purely coincidental.\n\nBy continuing, you agree to experience the consequences of your actions,\nyour choices, and your sanity.\n\nThere is no comfort here. There is only survival."
    

    self.currentNoiseFrame = 1
    self.noiseUpdateTime = 0
    
    -- VHS scanline effect
    self.scanlineOffset = 0
    
    -- Warning title animation
    self.warningTitleScale = 1
    self.warningTitleRotation = 0
    
end

function PANEL:UpdateWarningEffects()
    -- Update text reveal animation
    if self.warningAlpha > 200 and CurTime() - self.charRevealLastTime > self.charRevealDelay and self.charRevealIndex < string.len(self.fullWarningText) then
        self.charRevealIndex = self.charRevealIndex + 1.5
        self.revealedText = string.sub(self.fullWarningText, 1, self.charRevealIndex)
        self.charRevealLastTime = CurTime()
        
        --[[ Play subtle typing sounds with variation
        if self.charRevealIndex % 3 == 0 then
            local typeSounds = {
                "ambient/machines/keyboard" .. math.random(1, 7) .. "_clicks.wav",
            }
            surface.PlaySound(typeSounds[math.random(1)])
        end]]
    end
    
    -- Random glitch effect timing
    if CurTime() - self.warningGlitchLastTime > self.warningGlitchInterval then
        self.warningGlitchActive = true
        self.warningGlitchTimer = CurTime()
        self.warningGlitchLastTime = CurTime()
        self.warningGlitchInterval = math.random(2, 28)
    end
    
    -- Turn off glitch effect after duration
    if self.warningGlitchActive and CurTime() - self.warningGlitchTimer > self.warningGlitchDuration then
        self.warningGlitchActive = false
    end
    

    
    -- Update scanline animation
    self.scanlineOffset = (self.scanlineOffset + 0.5) % 20
end

function PANEL:DrawWarningScreen(w, h)
    -- Call update function for animations
    self:UpdateWarningEffects()
    
    -- Dark base background
    surface.SetDrawColor(0, 0, 0, 255)
    surface.DrawRect(0, 0, w, h)
    
    -- Apply random glitch effects
    local glitchOffsetX, glitchOffsetY = 0, 0
    if self.warningGlitchActive then
        glitchOffsetX = math.random(-10, 10)
        glitchOffsetY = math.random(-5, 5)
        
        -- Create random colored bars during glitch
        for i = 1, math.random(3, 7) do
            local barY = math.random(0, h)
            local barHeight = math.random(5, 20)
            local barColor = {
                math.random(150, 255),
                math.random(150, 255),
                math.random(150, 255),
                math.random(30, 70)
            }
            
            surface.SetDrawColor(barColor[1], barColor[2], barColor[3], barColor[4])
            surface.DrawRect(0, barY, w, barHeight)
        end
        
        -- Create RGB split effect during glitch
        local splitOffset = math.random(1, 5)
        
        -- Temporarily store original alpha to restore it
        local originalAlpha = self.warningAlpha
        
        -- Red channel offset
        self.warningAlpha = originalAlpha * 0.5
        surface.SetTextColor(255, 0, 0, self.warningAlpha)
        surface.SetFont("AmmoThing")
        local titleText = "WARNING!"
        local tw, th = surface.GetTextSize(titleText)
        surface.SetTextPos((w - tw) / 2 + splitOffset, h * 0.25 - splitOffset)
        surface.DrawText(titleText)
        
        -- Blue channel offset
        surface.SetTextColor(0, 0, 255, self.warningAlpha)
        surface.SetTextPos((w - tw) / 2 - splitOffset, h * 0.25 + splitOffset)
        surface.DrawText(titleText)
        
        -- Restore original alpha
        self.warningAlpha = originalAlpha
    end
    
    -- Warning title with more dramatic styling
    surface.SetFont("AmmoThing")
    local titleText = "WARNING!"
    local tw, th = surface.GetTextSize(titleText)
    
    -- Draw shadow/glow for title
    for i = 1, 5 do
        local shadowDist = i * 1.5
        surface.SetTextColor(200, 0, 0, math.max(0, self.warningAlpha * 0.15 - (i * 10)))
        surface.SetTextPos((w - tw * self.warningTitleScale) / 2 + shadowDist + glitchOffsetX, 
                         h * 0.25 + shadowDist + glitchOffsetY)
        
        -- Apply matrix for rotation and scaling
        local matrixRotScale = Matrix()
        matrixRotScale:Translate(Vector((w) / 2, h * 0.25 + th/2, 0))
        matrixRotScale:Rotate(Angle(0, 0, self.warningTitleRotation))
        matrixRotScale:Scale(Vector(self.warningTitleScale, self.warningTitleScale, 1))
        matrixRotScale:Translate(Vector(-(w) / 2, -(h * 0.25 + th/2), 0))
        
        cam.PushModelMatrix(matrixRotScale)
        surface.DrawText(titleText)
        cam.PopModelMatrix()
    end
    
    -- Main title with pulsing effect
    local pulseValue = math.abs(math.sin(CurTime() * 2))
    local titleColorR = Lerp(pulseValue, 200, 255)
    
    -- Apply matrix for rotation and scaling to main title
    local matrixRotScale = Matrix()
    matrixRotScale:Translate(Vector((w) / 2, h * 0.25 + th/2, 0))
    matrixRotScale:Rotate(Angle(0, 0, self.warningTitleRotation))
    matrixRotScale:Scale(Vector(self.warningTitleScale, self.warningTitleScale, 1))
    matrixRotScale:Translate(Vector(-(w) / 2, -(h * 0.25 + th/2), 0))
    
    cam.PushModelMatrix(matrixRotScale)
    surface.SetTextColor(titleColorR, 30, 30, self.warningAlpha)
    surface.SetTextPos((w - tw) / 2 + glitchOffsetX, h * 0.25 + glitchOffsetY)
    surface.DrawText(titleText)
    cam.PopModelMatrix()
    
    -- Warning content with typewriter effect
    surface.SetFont("DisclaimerFont")
    local _, lineHeight = surface.GetTextSize("A")
    
    -- Only show the text that has been revealed through the typing effect
    -- If warningAlpha isn't high enough yet, don't show any text
    local textToShow = self.warningAlpha > 200 and self.revealedText or ""
    local lines = string.Explode("\n", textToShow)
    local yPos = h * 0.32 + glitchOffsetY
    
    for _, line in ipairs(lines) do
        local lineWidth = surface.GetTextSize(line)
        
        -- Draw text shadow for better readability
        surface.SetTextColor(50, 50, 50, self.warningAlpha * 0.5)
        surface.SetTextPos((w - lineWidth) / 2 + 2 + glitchOffsetX, yPos + 2)
        surface.DrawText(line)
        
        -- Draw glitched version occasionally
        if self.warningGlitchActive and math.random() > 0.7 then
            local glitchedLine = ""
            for i = 1, #line do
                if math.random() > 0.8 then
                    glitchedLine = glitchedLine .. string.char(math.random(33, 126))
                else
                    glitchedLine = glitchedLine .. line:sub(i, i)
                end
            end
            
            surface.SetTextColor(200, 200, 200, self.warningAlpha)
            surface.SetTextPos((w - lineWidth) / 2 + glitchOffsetX, yPos)
            surface.DrawText(glitchedLine)
        else
            -- Draw normal text
            surface.SetTextColor(200, 200, 200, self.warningAlpha)
            surface.SetTextPos((w - lineWidth) / 2 + glitchOffsetX, yPos)
            surface.DrawText(line)
        end
        
        yPos = yPos + lineHeight * 1.5
    end
    

    
    -- Continue button with enhanced styling
    if self.buttonAlpha > 0 then
        surface.SetFont("DisclaimerSubtitleFont")
        local buttonText = "Continue"
        local btnW, btnH = surface.GetTextSize(buttonText)
        
        local btnX, btnY = (w - btnW - 60) / 2, h * 0.75
        local btnWidth, btnHeight = btnW + 60, btnH + 20
        
        -- Button pulse/hover effects
        local pulseValue = math.abs(math.sin(CurTime() * 1.5))
        local btnAlpha = Lerp(pulseValue, self.buttonAlpha * 0.7, self.buttonAlpha)
        
        local mouseX, mouseY = gui.MousePos()
        local isHovering = mouseX >= btnX and mouseX <= btnX + btnWidth and
                         mouseY >= btnY and mouseY <= btnY + btnHeight
        
        local hoverScale = isHovering and 1.1 or 1.0
        local hoverColor = isHovering and 255 or 200
        
        -- Apply hover animation
        if isHovering and not self.buttonHovered then
            self.buttonHovered = true
        elseif not isHovering and self.buttonHovered then
            self.buttonHovered = false
        end
        
        -- Button glow effect
        if isHovering then
            for i = 1, 5 do
                local glowSize = i * 2
                surface.SetDrawColor(100, 100, 100, btnAlpha * 0.1 * (6-i)/5)
                surface.DrawOutlinedRect(btnX - glowSize, btnY - glowSize, 
                                      btnWidth + glowSize*2, btnHeight + glowSize*2, 1)
            end
        end
        
        -- Button background with gradient
        draw.RoundedBox(4, btnX, btnY, btnWidth, btnHeight, Color(30, 30, 30, btnAlpha * 0.7))
        
        -- Button top highlight
        surface.SetDrawColor(150, 150, 150, btnAlpha * 0.2)
        surface.DrawRect(btnX + 2, btnY + 2, btnWidth - 4, 2)
        
        -- Button border with animation
        local borderColor = isHovering and 150 or 100
        local borderPulse = Lerp(pulseValue, borderColor * 0.7, borderColor)
        
        surface.SetDrawColor(borderPulse, borderPulse, borderPulse, btnAlpha)
        surface.DrawOutlinedRect(btnX, btnY, btnWidth, btnHeight, 2)
        
        -- Inner border
        if isHovering then
            surface.SetDrawColor(200, 200, 200, btnAlpha * 0.3)
            surface.DrawOutlinedRect(btnX + 3, btnY + 3, btnWidth - 6, btnHeight - 6, 1)
        end
        
        -- Button text shadow
        surface.SetTextColor(0, 0, 0, btnAlpha * 0.7)
        surface.SetTextPos(btnX + 30 + 1, btnY + 10 + 1)
        surface.DrawText(buttonText)
        
        -- Button text with hover effect
        surface.SetTextColor(hoverColor, hoverColor, hoverColor, btnAlpha)
        surface.SetTextPos(btnX + 30, btnY + 10)
        surface.DrawText(buttonText)
        
        -- Store button bounds for click detection
        self.continueButtonBounds = {
            x = btnX,
            y = btnY,
            w = btnWidth,
            h = btnHeight
        }
        
        -- Add button indicator arrows with animation
        if isHovering then
            local arrowPulse = math.abs(math.sin(CurTime() * 3))
            local arrowOffset = Lerp(arrowPulse, 0, 5)
            
            -- Left arrow
            surface.SetTextColor(hoverColor, hoverColor, hoverColor, btnAlpha)
            surface.SetFont("DisclaimerSubtitleFont")
            surface.SetTextPos(btnX - 15 - arrowOffset, btnY + 8)
            surface.DrawText(">")
            
            -- Right arrow
            surface.SetTextPos(btnX + btnWidth + 5 + arrowOffset, btnY + 8)
            surface.DrawText("<")
        end
    end
    
    -- Add occasional screen tears during glitch
    if self.warningGlitchActive then
        for i = 1, math.random(2, 5) do
            local tearY = math.random(0, h)
            local tearHeight = math.random(5, 20)
            local tearOffset = math.random(-10, 10)
            
            -- Save the portion of screen to shift
            local screenData = render.Capture({
                x = 0,
                y = tearY,
                width = w,
                height = tearHeight,
                format = "png"
            })
            
            local tearMaterial = Material("___tearCapture" .. i)
            if not tearMaterial or tearMaterial:IsError() then
                -- Create material or update existing
                tearMaterial = CreateMaterial("___tearCapture" .. i, "UnlitGeneric", {
                    ["$basetexture"] = "__tearCapture" .. i,
                    ["$translucent"] = 1
                })
            end
            
            -- Draw the captured portion with offset
            surface.SetMaterial(tearMaterial)
            surface.SetDrawColor(255, 255, 255, 255)
            surface.DrawTexturedRect(tearOffset, tearY, w, tearHeight)
        end
    end
end


function PANEL:InitNarrationEffects()
    -- Narration typing effect variables
    self.typingData = {
        displayedText = {},      -- Currently displayed text for each line
        targetText = {},         -- Final text for each line
        charIndex = 1,           -- Current character index
        lineIndex = 1,           -- Current line index
        lastTypeTime = 0,        -- Last time a character was typed
        typeDelay = 0.05,        -- Base delay between typing characters
        initialized = false,     -- Whether typing has been initialized
        typingStarted = false,   -- Whether typing has started
        narrationCompleted = false, -- Whether current narration segment is complete
        pauseUntil = 0,          -- Time until typing should resume after pause
        
        cursor = {
            visible = true,
            lastBlinkTime = 0,
            blinkInterval = 0.5
        }
    }
    
    -- Start typing effect after a short delay
    timer.Simple(0.8, function()
        if IsValid(self) then
            self.typingData.typingStarted = true
        end
    end)
    
    -- FIXED: Ensure narration alpha is properly initialized and locked at full opacity
    self.narrationAlpha = 255
    self.fadeState = "STABLE" -- New state tracking: STABLE, FADE_IN, FADE_OUT
    self.fadeStartTime = 0
    self.fadeDuration = 0
    self.preventAutoFade = true -- Add this flag to prevent automatic fading
end

-- Add a controlled fade function that won't run unless explicitly called
function PANEL:FadeNarration(targetAlpha, duration)
    if self.preventAutoFade then return end -- Skip if we're preventing auto fades
    
    self.fadeStartTime = CurTime()
    self.fadeStartAlpha = self.narrationAlpha
    self.fadeTargetAlpha = targetAlpha
    self.fadeDuration = duration
    
    if targetAlpha > self.narrationAlpha then
        self.fadeState = "FADE_IN"
    elseif targetAlpha < self.narrationAlpha then
        self.fadeState = "FADE_OUT"
    else
        self.fadeState = "STABLE"
    end
end

-- Add a function to update fade effects
function PANEL:UpdateFadeEffects()
    -- If we're in a stable state or preventing auto fades, do nothing
    if self.fadeState == "STABLE" or self.preventAutoFade then return end
    
    local currentTime = CurTime()
    local elapsed = currentTime - self.fadeStartTime
    
    if elapsed >= self.fadeDuration then
        -- Fade complete
        self.narrationAlpha = self.fadeTargetAlpha
        self.fadeState = "STABLE"
        return
    end
    
    -- Calculate current alpha based on progress
    local progress = elapsed / self.fadeDuration
    self.narrationAlpha = Lerp(progress, self.fadeStartAlpha, self.fadeTargetAlpha)
end

function PANEL:UpdateTypingEffect()
    local data = self.typingData
    local currentTime = CurTime()
    
    -- Skip if no narration yet
    if self.narrationIndex <= 0 then return end
    
    -- Get current narration target text
    local narrationText = narrationSegments[self.narrationIndex] 
    if not narrationText then return end
    
    local lines = string.Explode("\n", narrationText)
    
    -- Initialize target text if needed
    if not data.initialized then
        data.targetText = {}
        data.displayedText = {}
        
        for _, line in ipairs(lines) do
            -- Add ">" prefix to each line if it doesn't already have one
            if not string.match(line, "^>") then
                line = "> " .. line
            end
            table.insert(data.targetText, line)
            table.insert(data.displayedText, "")
        end
        
        data.initialized = true
        data.lineIndex = 1
        data.charIndex = 1
        data.narrationCompleted = false
        data.pauseUntil = 0
        
        -- FIXED: Ensure narration is fully visible when initialized
        self.narrationAlpha = 255
        self.fadeState = "STABLE"
    end
    
    -- Update cursor blinking
    if currentTime - data.cursor.lastBlinkTime > data.cursor.blinkInterval then
        data.cursor.visible = not data.cursor.visible
        data.cursor.lastBlinkTime = currentTime
    end
    
    -- Don't start typing until the signal is given
    if not data.typingStarted then
        return
    end
    
    -- If we're in a pause state, check if it's time to resume
    if data.pauseUntil > currentTime then
        return
    end
    
    -- Calculate typing delay (constant speed now)
    local typeDelay = data.typeDelay
    
    -- Only proceed if enough time has passed for next character
    if currentTime - data.lastTypeTime < typeDelay then return end
    
    -- Normal typing mode
    if data.lineIndex <= #data.targetText then
        -- Check if current line is complete
        if data.charIndex <= #data.targetText[data.lineIndex] then
            -- Type next character
            local nextChar = string.sub(data.targetText[data.lineIndex], data.charIndex, data.charIndex)
            data.displayedText[data.lineIndex] = data.displayedText[data.lineIndex] .. nextChar
            data.charIndex = data.charIndex + 1
            data.lastTypeTime = currentTime
            
            -- Add pause after punctuation marks
            if string.match(nextChar, "[%.%,%:%-%?%!]") then
                data.pauseUntil = currentTime + math.Rand(0.2, 0.4)
            end
            
        else
            -- Line complete, move to next line
            data.lineIndex = data.lineIndex + 1
            data.charIndex = 1
            
            -- Add slightly longer pause between lines
            data.pauseUntil = currentTime + math.Rand(0.4, 0.6)
        end
    else
        -- All lines have been typed, narration segment is complete
        if not data.narrationCompleted then
            data.narrationCompleted = true
            
            -- FIXED: Do not trigger fade out automatically
            -- Instead, just wait for 3 seconds before advancing
            timer.Simple(3, function()
                if IsValid(self) then
                    self:AdvanceNarration()
                end
            end)
        end
    end
end

-- New function to advance to the next narration segment
function PANEL:AdvanceNarration()
    -- Check if this is the last narration segment
    if self.narrationIndex == #narrationSegments then
        -- For the last segment, we need to wait until the typing is fully complete
        -- before starting the fade out
        
        -- Check if typing animation is complete
        if self.typingData.narrationCompleted then
            -- Start fading out only if typing has finished and we haven't started fading yet
            if not self.lastSegmentFadeStarted then
                self.lastSegmentFadeStarted = true
                self.lastSegmentFadeOutStartTime = CurTime()
                
                -- Add a delay after typing finishes before starting fade
                timer.Simple(5, function() -- Add a 2-second pause before fading out
                    if not IsValid(self) then return end
                    
                    -- Create a fade-out effect for the last segment
                    timer.Create("LastNarrationFadeOut", 0.01, 0, function()
                        if not IsValid(self) then timer.Remove("LastNarrationFadeOut") return end
                        
                        local elapsed = CurTime() - (self.lastSegmentFadeOutStartTime + 2.0)
                        local fadeOutDuration = 2.0 -- 2 seconds fade out
                        local progress = math.Clamp(elapsed / fadeOutDuration, 0, 1)
                        
                        -- Update the narration alpha directly
                        self.narrationAlpha = Lerp(progress, 255, 0)
                        
                        if progress >= 1 then
                            timer.Remove("LastNarrationFadeOut")
                            
                            -- After fade out is complete, start the final transition
                            timer.Simple(0.5, function()
                                if IsValid(self) then
                                    self:StartFinalTransition()
                                end
                            end)
                        end
                    end)
                end)
            end
        end
        
        return -- Exit the function early to avoid advancing to the next segment
    end
    
    -- Reset typing effect for next segment
    self.typingData.initialized = false
    self.typingData.typingStarted = true
    self.typingData.narrationCompleted = false
    self.typingData.pauseUntil = 0
    
    -- Advance to next narration segment
    self.narrationIndex = self.narrationIndex + 1
    
    -- FIXED: Ensure narration is fully visible and stable
    self.narrationAlpha = 255
    self.fadeState = "STABLE"
    
    -- If we've reached the end of narration segments, handle accordingly
    if self.narrationIndex > #narrationSegments then
        -- Either reset to first segment or end narration
        self.narrationIndex = 1 -- or set to 0 and call self:EndNarration() if needed
    end
end

-- Ensure this function exists if it doesn't already
function PANEL:SetNarrationIndex(index)
    if index >= 0 and index <= #narrationSegments then
        self.narrationIndex = index
        self.typingData.initialized = false
        self.typingData.typingStarted = true
        self.typingData.narrationCompleted = false
        self.typingData.pauseUntil = 0
        
        -- FIXED: Ensure narration is fully visible and stable
        self.narrationAlpha = 255
        self.fadeState = "STABLE"
    end
end

function PANEL:DrawNarration(w, h)
    -- Black background with slight vignette effect
    surface.SetDrawColor(0, 0, 0, 255)
    surface.DrawRect(0, 0, w, h)
    
    -- Skip if no narration yet or if narration index is invalid
    if self.narrationIndex <= 0 or self.narrationIndex > #narrationSegments then return end
    
    -- FIXED: Update fade effects before updating typing
    self:UpdateFadeEffects()
    
    -- Update typing effects
    self:UpdateTypingEffect()
    
    -- Current narration text and typing data
    local data = self.typingData
    
    -- Calculate layout
    surface.SetFont("DisclaimerFont")
    local _, lineHeight = surface.GetTextSize("A")
    
    -- Calculate the total height of text
    local totalHeight = (#data.displayedText > 0 and #data.displayedText or 1) * lineHeight * 1.5
    local yPos = (h - totalHeight) / 2
    
    -- Draw each line with typing effect
    for i, displayText in ipairs(data.displayedText) do
        -- Only show lines up to current typing position
        if i <= data.lineIndex then
            -- Calculate text width for centering
            local lineWidth = surface.GetTextSize(displayText)
            
            -- Center text horizontally
            local xPos = (w - lineWidth) / 2
            
            -- Determine text color based on content
            local textColor = {200, 200, 200, self.narrationAlpha}
            
            -- Check if line is a system message (has brackets or starts with >)
            if string.match(displayText, "%[") or string.match(displayText, "^>") then
                textColor = {130, 220, 130, self.narrationAlpha} -- Green for system text
            -- Check if line has warnings or errors
            elseif string.match(displayText, "ERROR") or string.match(displayText, "FAILED") then
                textColor = {220, 130, 130, self.narrationAlpha} -- Red for errors
            -- Check if all uppercase for emphasis
            elseif string.upper(displayText) == displayText and #displayText > 3 then
                textColor = {220, 210, 150, self.narrationAlpha} -- Gold for emphasis
            end
            
            -- Text shadow for better readability (slightly offset from center)
            surface.SetTextColor(30, 30, 30, textColor[4] * 0.7)
            surface.SetTextPos(xPos + 1, yPos + 1)
            surface.DrawText(displayText)
            
            -- Main text (centered)
            surface.SetTextColor(textColor[1], textColor[2], textColor[3], textColor[4])
            surface.SetTextPos(xPos, yPos)
            surface.DrawText(displayText)
            
            -- Always draw blinking cursor at end of current line
            if i == data.lineIndex and data.cursor.visible and self.narrationAlpha > 200 then
                local cursorX = xPos + lineWidth
                surface.SetTextColor(220, 220, 220, self.narrationAlpha)
                surface.SetTextPos(cursorX, yPos)
                surface.DrawText("_")
            end
        end
        
        yPos = yPos + lineHeight * 1.5
    end
    
    -- Add subtle static/noise effect for terminal feel (adjusted for centered aesthetic)
    for i = 1, 8 do
        if math.random(1, 1000) <= 3 then
            -- More centered noise distribution for cinematic effect
            local noiseX = math.random(w * 0.3, w * 0.7)
            local noiseY = math.random(h * 0.2, h * 0.8)
            local noiseW = math.random(1, 3)
            local noiseH = math.random(1, 5)
            
            surface.SetDrawColor(255, 255, 255, math.random(5, 20))
            surface.DrawRect(noiseX, noiseY, noiseW, noiseH)
        end
    end
    
    -- Optional: Add subtle vignette effect for more cinematic look
    local vignetteStrength = 180 -- Adjust as needed
    for i = 0, 10 do
        local alpha = (i / 10) * vignetteStrength
        surface.SetDrawColor(0, 0, 0, alpha)
        surface.DrawOutlinedRect(i, i, w - i * 2, h - i * 2)
    end
    
    -- FIXED: Debug info - uncomment if needed to troubleshoot
    -- surface.SetFont("Default")
    -- surface.SetTextColor(255, 255, 255, 255)
    -- surface.SetTextPos(10, 10)
    -- surface.DrawText("Alpha: " .. self.narrationAlpha .. " State: " .. self.fadeState)
end

--[[function PANEL:DrawFinalIntro(w, h)
    -- Draw current frame if valid
    local frame = frames[self.frameIndex]
    if frame then
        surface.SetDrawColor(255, 255, 255, self.mainIntroAlpha)
        surface.SetMaterial(frame)
        surface.DrawTexturedRect(0, 0, w, h)
    end

    -- Top and bottom gradients
    surface.SetDrawColor(0, 0, 0, self.mainIntroAlpha)
    surface.SetMaterial(gradientTop)
    surface.DrawTexturedRect(0, 0, w, h/3)

    surface.SetDrawColor(0, 0, 0, self.mainIntroAlpha)
    surface.SetMaterial(gradientBottom)
    surface.DrawTexturedRect(0, h - h/3, w, h/3)

    -- Disclaimer text
    surface.SetFont("MainThing")
    local titleText = "> B E T A   S T A S I S _   |   P R E - A L P H A"
    local tw, th = surface.GetTextSize(titleText)

    surface.SetTextColor(0, 0, 0, self.mainIntroAlpha * 0.5)
    surface.SetTextPos((w - tw) / 2 + 2, (h / 2) - th + 2)
    surface.DrawText(titleText)

    surface.SetTextColor(220, 220, 220, self.mainIntroAlpha)
    surface.SetTextPos((w - tw) / 2, (h / 2) - th)
    surface.DrawText(titleText)

    surface.SetFont("DisclaimerSubtitleFont")
    local subtitleText = "This game is in pre-alpha stage. Expect bugs and frequent changes."
    local stw, sth = surface.GetTextSize(subtitleText)

    surface.SetTextColor(0, 0, 0, self.mainIntroAlpha * 0.5)
    surface.SetTextPos((w - stw) / 2 + 2, (h / 2) + 2)
    surface.DrawText(subtitleText)

    surface.SetTextColor(180, 180, 180, self.mainIntroAlpha)
    surface.SetTextPos((w - stw) / 2, (h / 2))
    surface.DrawText(subtitleText)

    local promptText = "PRESS SPACE TO START"
    local ptw, pth = surface.GetTextSize(promptText)
    local pulseAlpha = math.Remap(self.pulseValue, 0, 1, self.mainIntroAlpha * DISCLAIMER_ALPHA_PULSE, self.mainIntroAlpha)

    surface.SetTextColor(0, 0, 0, pulseAlpha * 0.5)
    surface.SetTextPos((w - ptw) / 2 + 2, (h * 0.75) + 2)
    surface.DrawText(promptText)

    surface.SetTextColor(200, 200, 200, pulseAlpha)
    surface.SetTextPos((w - ptw) / 2, (h * 0.75))
    surface.DrawText(promptText)
end

function PANEL:Think()
    -- Handle pulse effect
    self.pulseValue = math.abs(math.sin(CurTime() * PULSE_SPEED))
    
    -- Frame switching logic with controlled timing
    if self.introState == "final" and CurTime() - self.lastFrameChange >= FRAME_RATE then
        self.lastFrameChange = CurTime()
        
        -- Advance frame
        self.frameIndex = self.frameIndex + 1
        if self.frameIndex > #frames then
            self.frameIndex = 1
        end
    end
end

function PANEL:Paint(w, h)
    -- Draw the appropriate state
    if self.introState == "warning" or self.introState == "button" then
        self:DrawWarningScreen(w, h)
    elseif self.introState == "narration" then
        self:DrawNarration(w, h)
    elseif self.introState == "final" then
        -- Black background transition
        surface.SetDrawColor(0, 0, 0, 255)
        surface.DrawRect(0, 0, w, h)
        
        -- Draw the original intro content with fade-in
        self:DrawFinalIntro(w, h)
    end
end

function PANEL:OnMousePressed(mouseCode)
    if mouseCode == MOUSE_LEFT and self.introState == "button" and self.continueButtonBounds then
        local mouseX, mouseY = gui.MousePos()
        local btn = self.continueButtonBounds
        
        if mouseX >= btn.x and mouseX <= btn.x + btn.w and
           mouseY >= btn.y and mouseY <= btn.y + btn.h then

            self.narrationStartTime = CurTime()
            self:StartNarration()
        end
    end
end

function PANEL:OnKeyCodePressed(key)
    if self.introState == "final" and key == KEY_SPACE and self.mainIntroAlpha >= 250 then

        self:AlphaTo(0, FADE_OUT_TIME, 0, function()
            self:Remove()
            vgui.Create("ax.mainmenu")
        end)
    end
end

function PANEL:AlphaTo(target, duration, delay, callback)
    local startTime = CurTime() + (delay or 0)
    local startAlpha = self.alpha

    timer.Create("IntroFade", 0.01, 0, function()
        local elapsed = CurTime() - startTime
        if elapsed >= 0 then
            local progress = math.Clamp(elapsed / duration, 0, 1)
            self.alpha = Lerp(progress, startAlpha, target)

            if progress >= 1 then
                timer.Remove("IntroFade")
                if callback then callback() end
            end
        end
    end)
end

function PANEL:OnRemove()
    if timer.Exists("IntroFade") then
        timer.Remove("IntroFade")
    end
    if timer.Exists("WarningFadeIn") then
        timer.Remove("WarningFadeIn")
    end
    if timer.Exists("ButtonFadeIn") then
        timer.Remove("ButtonFadeIn")
    end
    if timer.Exists("WarningFadeOut") then
        timer.Remove("WarningFadeOut")
    end
    if timer.Exists("NarrationFadeIn") then
        timer.Remove("NarrationFadeIn")
    end
    if timer.Exists("NarrationFadeOut") then
        timer.Remove("NarrationFadeOut")
    end
    if timer.Exists("FinalTransition") then
        timer.Remove("FinalTransition")
    end
    ax.gui.intro = nil
    print("Intro panel removed, all timers cleaned up")
end

vgui.Register("ax.intro", PANEL, "EditablePanel")

timer.Simple(0.1, function()
    if IsValid(ax.gui.intro) then
        ax.gui.intro:Remove()
    end
    vgui.Create("ax.intro")
end)

hook.Add("OnCharacterSelected", "RemoveIntroIfOpen", function()
    if IsValid(ax.gui.intro) then
        ax.gui.intro:Remove()
    end
end)]]