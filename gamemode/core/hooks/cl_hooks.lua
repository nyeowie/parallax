function GM:PlayerStartVoice(client)
    if ( IsValid(g_VoicePanelList) ) then
        g_VoicePanelList:Remove()
    end
end

function GM:PlayerEndVoice(client)
    if ( IsValid(g_VoicePanelList) ) then
        g_VoicePanelList:Remove()
    end
end

function GM:ScoreboardShow()
    if ( IsValid(ax.gui.mainmenu) ) then return false end

    if ( !IsValid(ax.gui.tab) ) then
        vgui.Create("ax.tab")
    else
        ax.gui.tab:Remove()
    end

    return false
end

function GM:ScoreboardHide()
    return false
end

function GM:Initialize()
    ax.module:LoadFolder("parallax/modules")
    ax.item:LoadFolder("parallax/core/items")
    ax.schema:Initialize()

    hook.Run("LoadFonts")
end

function GM:OnReloaded()
    ax.module:LoadFolder("parallax/modules")
    ax.item:LoadFolder("parallax/core/items")
    ax.schema:Initialize()
    ax.option:Load()

    hook.Run("LoadFonts")
end

function GM:InitPostEntity()
    ax.client = LocalPlayer()
    ax.option:Load()

    if ( !IsValid(ax.gui.chatbox) ) then
        vgui.Create("ax.chatbox")
    end

    ax.net:Start("client.ready")
end

function GM:OnCloseCaptionEmit()
    return true
end

local eyeTraceHullMin = Vector(-2, -2, -2)
local eyeTraceHullMax = Vector(2, 2, 2)
function GM:CalcView(client, pos, angles, fov)
    if ( IsValid(ax.gui.mainmenu) ) then
        local mainmenuPos = ax.config:Get("mainmenu.pos", vector_origin)
        local mainmenuAng = ax.config:Get("mainmenu.ang", angle_zero)
        local mainmenuFov = ax.config:Get("mainmenu.fov", 90)

        return {
            origin = mainmenuPos,
            angles = mainmenuAng,
            fov = mainmenuFov,
            drawviewer = true
        }
    end

    local ragdoll = ax.client:GetDataVariable("ragdoll", nil)
    if ( IsValid(ragdoll) ) then
        local eyePos
        local eyeAng

        if ( ragdoll:LookupAttachment("eyes") ) then
            local attachment = ragdoll:GetAttachment(ragdoll:LookupAttachment("eyes"))
            if ( attachment ) then
                eyePos = attachment.Pos
                eyeAng = attachment.Ang
            end
        else
            local bone = ragdoll:LookupBone("ValveBiped.Bip01_Head1")
            if ( !bone ) then return end

            eyePos, eyeAng = ragdoll:GetBonePosition(bone)
        end

        if ( !eyePos or !eyeAng ) then return end

        local traceHull = util.TraceHull({
            start = eyePos,
            endpos = eyePos + eyeAng:Forward() * 2,
            filter = ragdoll,
            mask = MASK_PLAYERSOLID,
            mins = eyeTraceHullMin,
            maxs = eyeTraceHullMax
        })

        return {
            origin = traceHull.HitPos,
            angles = eyeAng,
            fov = fov,
            drawviewer = true
        }
    end
end

local LOWERED_POS = Vector(0, 0, 0)
local LOWERED_ANGLES = Angle(10, 10, 0)
local LOWERED_LERP = {pos = Vector(0, 0, 0), angles = Angle(0, 0, 0)}
function GM:CalcViewModelView(weapon, viewModel, oldPos, oldAng, pos, ang)
    local client = ax.client
    if ( !IsValid(client) ) then return end

    local targetPos = LOWERED_POS
    local targetAngles = LOWERED_ANGLES
    if ( IsValid(weapon) and weapon:IsWeapon() ) then
        if ( weapon.LoweredPos ) then
            targetPos = weapon.LoweredPos
        end

        if ( weapon.LoweredAngles ) then
            targetAngles = weapon.LoweredAngles
        end
    end

    if ( IsValid(weapon) and !client:IsWeaponRaised() ) then
        LOWERED_LERP.pos = Lerp(FrameTime() * 4, LOWERED_LERP.pos, targetPos)
        LOWERED_LERP.angles = LerpAngle(FrameTime() * 4, LOWERED_LERP.angles, targetAngles)
    else
        LOWERED_LERP.pos = Lerp(FrameTime() * 4, LOWERED_LERP.pos, vector_origin)
        LOWERED_LERP.angles = LerpAngle(FrameTime() * 4, LOWERED_LERP.angles, angle_zero)
    end

    pos = pos + LOWERED_LERP.pos
    ang = ang + LOWERED_LERP.angles

    return self.BaseClass:CalcViewModelView(weapon, viewModel, oldPos, oldAng, pos, ang)
end

local vignette = ax.util:GetMaterial("parallax/overlay_vignette.png", "noclamp smooth")
local vignetteColor = Color(0, 0, 0, 255)
function GM:HUDPaintBackground()
    if ( tobool(hook.Run("ShouldDrawVignette")) ) then
        local client = ax.client
        if ( !IsValid(client) ) then return end

        local scrW, scrH = ScrW(), ScrH()
        local trace = util.TraceLine({
            start = client:GetShootPos(),
            endpos = client:GetShootPos() + client:GetAimVector() * 96,
            filter = client,
            mask = MASK_SHOT
        })

        if ( trace.Hit and trace.HitPos:DistToSqr(client:GetShootPos()) < 96 ^ 2 ) then
            vignetteColor.a = Lerp(FrameTime(), vignetteColor.a, 255)
        else
            vignetteColor.a = Lerp(FrameTime(), vignetteColor.a, 100)
        end

        if ( hook.Run("ShouldDrawDefaultVignette") != false ) then
            surface.SetDrawColor(vignetteColor)
            surface.SetMaterial(vignette)
            surface.DrawRect(0, 0, scrW, scrH, vignetteColor)
        end

        hook.Run("DrawVignette", 1 - (vignetteColor.a / 255))
    end
end

function GM:DrawVignette(fraction)
end

local padding = 16
local backgroundColor = Color(10, 10, 10, 220)

function GM:HUDPaint()
    local client = ax.client
    if ( !IsValid(client) ) then return end

    local shouldDraw = hook.Run("PreHUDPaint")
    if ( shouldDraw == false ) then return end

    local x, y = 24, 24
    local scrW, scrH = ScrW(), ScrH()
    shouldDraw = hook.Run("ShouldDrawDebugHUD")
    if ( shouldDraw != false ) then
        local green = ax.config:Get("color.framework")
        local width = math.max(ax.util:GetTextWidth("parallax.developer", "Pos: " .. tostring(client:GetPos())), ax.util:GetTextWidth("parallax.developer", "Ang: " .. tostring(client:EyeAngles())))
        local height = 16 * 6

        local character = client:GetCharacter()
        if ( character ) then
            height = height + 16 * 6
        end

        ax.util:DrawBlurRect(x - padding, y - padding, width + padding * 2, height + padding * 2)

        surface.SetDrawColor(backgroundColor)
        surface.DrawRect(x - padding, y - padding, width + padding * 2, height + padding * 2)

        draw.SimpleText("[DEVELOPER HUD]", "parallax.developer", x, y, green, TEXT_ALIGN_LEFT)

        draw.SimpleText("Pos: " .. tostring(client:GetPos()), "parallax.developer", x, y + 16 * 1, green, TEXT_ALIGN_LEFT)
        draw.SimpleText("Ang: " .. tostring(client:EyeAngles()), "parallax.developer", x, y + 16 * 2, green, TEXT_ALIGN_LEFT)
        draw.SimpleText("Health: " .. client:Health(), "parallax.developer", x, y + 16 * 3, green, TEXT_ALIGN_LEFT)
        draw.SimpleText("Ping: " .. client:Ping(), "parallax.developer", x, y + 16 * 4, green, TEXT_ALIGN_LEFT)

        local fps = math.floor(1 / FrameTime())
        draw.SimpleText("FPS: " .. fps, "parallax.developer", x, y + 16 * 5, green, TEXT_ALIGN_LEFT)

        if ( character ) then
            local name = character:GetName()
            local charModel = character:GetModel()
            local inventories = ax.inventory:GetByCharacterID(character:GetID()) or {}
            for k, v in pairs(inventories) do
                inventories[k] = tostring(v)
            end
            local inventoryText = "Inventories: " .. table.concat(inventories, ", ")

            draw.SimpleText("[CHARACTER INFO]", "parallax.developer", x, y + 16 * 7, green, TEXT_ALIGN_LEFT)
            draw.SimpleText("Character: " .. tostring(character), "parallax.developer", x, y + 16 * 8, green, TEXT_ALIGN_LEFT)
            draw.SimpleText("Name: " .. name, "parallax.developer", x, y + 16 * 9, green, TEXT_ALIGN_LEFT)
            draw.SimpleText("Model: " .. charModel, "parallax.developer", x, y + 16 * 10, green, TEXT_ALIGN_LEFT)
            draw.SimpleText(inventoryText, "parallax.developer", x, y + 16 * 11, green, TEXT_ALIGN_LEFT)
        end
    end

    shouldDraw = hook.Run("ShouldDrawPreviewHUD")
    if ( shouldDraw != false ) then
        local orange = ax.color:Get("orange")
        local red = ax.color:Get("red")

        ax.util:DrawBlurRect(x - padding, y - padding, 410 + padding * 2, 45 + padding * 2)

        surface.SetDrawColor(backgroundColor)
        surface.DrawRect(x - padding, y - padding, 410 + padding * 2, 45 + padding * 2)

        draw.SimpleText("[PREVIEW MODE]", "parallax.developer", x, y, orange, TEXT_ALIGN_LEFT)
        draw.SimpleText("Warning! Anything you witness is subject to change.", "parallax.developer", x, y + 16, red, TEXT_ALIGN_LEFT)
        draw.SimpleText("This is not the final product.", "parallax.developer", x, y + 16 * 2, red, TEXT_ALIGN_LEFT)
    end

    shouldDraw = hook.Run("ShouldDrawCrosshair")
    if ( shouldDraw != false ) then
        x, y = ScrW() / 2, ScrH() / 2
        local size = 3

        if ( ax.module:Get("thirdperson") and ax.option:Get("thirdperson", false) ) then
            local trace = util.TraceLine({
                start = client:GetShootPos(),
                endpos = client:GetShootPos() + client:GetAimVector() * 8192,
                filter = client,
                mask = MASK_SHOT
            })

            local screen = trace.HitPos:ToScreen()
            x, y = screen.x, screen.y
        end

        -- TODO: Add crosshair
    end

    local lastScrW, lastScrH = 0, 0
    local ammoRT, ammoMat
    local lastAmmo = -1 -- Track ammo changes
    local shakeAmount = 0 -- For shake effect
    local glowIntensity = 0 -- For glow effect

    -- Grayscale holographic color palette
    local holoBaseColor = Color(180, 180, 180, 210) -- Base text color
    local holoDimColor = Color(120, 120, 120, 150)  -- Secondary elements
    local holoGlowColor = Color(255, 255, 255, 50)  -- Glow effect
    local holoWarnColor = Color(220, 220, 220, 255) -- Warning color when ammo drops
    local holoScanColor = Color(200, 200, 200, 8)   -- Scanline color

    -- Error state colors (low saturation red)
    local holoErrorBaseColor = Color(180, 70, 70, 200) -- Error main text color
    local holoErrorDimColor = Color(120, 50, 50, 150) -- Secondary elements in error state
    local holoErrorGlowColor = Color(255, 100, 100, 50) -- Error glow effect
    local holoErrorScanColor = Color(200, 80, 80, 8) -- Error scanline color

    -- Update render target when screen size changes
    local function UpdateAmmoRT()
        local scrW, scrH = ScrW(), ScrH()
        if (scrW != lastScrW or scrH != lastScrH or !ammoRT) then
            ammoRT = GetRenderTarget("AmmoHUD_RT", scrW, scrH, false)
            ammoMat = CreateMaterial("AmmoHUD_Mat", "UnlitGeneric", {
                ["$basetexture"] = "AmmoHUD_RT",
                ["$translucent"] = "1",
                ["$vertexalpha"] = "1",
                ["$vertexcolor"] = "1",
                ["$ignorez"] = "1",
                ["$additive"] = "1",
                ["$basetexturefiltermode"] = "Point"
            })
            lastScrW, lastScrH = scrW, scrH
        end
    end

    -- Noise function for distortion effects
    local function PerlinNoise(x, y)
        return (math.sin(x * 0.1 + y * 0.1) + math.cos(x * 0.11 + y * 0.13)) * 0.5
    end

    -- Function to draw glitched text
    local function DrawGlitchText(text, font, x, y, color, alignX, alignY, glitchAmount)
        -- Draw main text
        draw.SimpleText(text, font, x, y, color, alignX, alignY)
        
        -- Draw glitch effects
        if glitchAmount > 0 then
            -- Small horizontal offset copies with varying alpha
            local alpha = math.min(255, glitchAmount * 150)
            local glitchColor = Color(color.r, color.g, color.b, alpha)
            
            -- Left ghost
            draw.SimpleText(text, font, x - glitchAmount * 2, y, 
                Color(color.r, color.g, color.b, alpha * 0.3), alignX, alignY)
            
            -- Right ghost
            draw.SimpleText(text, font, x + glitchAmount * 2, y, 
                Color(color.r, color.g, color.b, alpha * 0.3), alignX, alignY)
                
            -- Draw digital artifacts - small broken pieces
            if glitchAmount > 1.5 then
                for i = 1, math.floor(glitchAmount * 3) do
                    local offsetX = math.random(-10, 10) * glitchAmount
                    local offsetY = math.random(-3, 3)
                    local glitchWidth = math.random(4, 20)
                    local glitchHeight = math.random(1, 3)
                    local startPos = math.random(1, #text)
                    local endPos = math.min(startPos + math.random(1, 3), #text)
                    local subText = string.sub(text, startPos, endPos)
                    
                    draw.SimpleText(subText, font, x + offsetX, y + offsetY, 
                        Color(color.r, color.g, color.b, math.random(40, 120)), 
                        alignX, alignY)
                end
            end
        end
    end

    -- Render the ammo display to our render target
    function BakeAmmoHUD(client)
        local activeWeapon = client:GetActiveWeapon()
        if (!IsValid(activeWeapon)) then return end

        local ammo = client:GetAmmoCount(activeWeapon:GetPrimaryAmmoType())
        local clip = activeWeapon:Clip1()
        local ammoText = clip .. " / " .. ammo
        local weaponName = activeWeapon:GetPrintName() or "UNKNOWN"
        
        -- Check for ammo drop
        local ammoChanged = false
        if lastAmmo > ammo or (lastAmmo > clip and clip > 0) then
            -- Ammo dropped, trigger effects
            shakeAmount = math.min(shakeAmount + 2, 5)
            glowIntensity = math.min(glowIntensity + 0.6, 1)
            ammoChanged = true
        end
        lastAmmo = clip
        
        -- Decay effects over time
        if shakeAmount > 0 then
            shakeAmount = math.max(0, shakeAmount - FrameTime() * 3)
        end
        
        if glowIntensity > 0 then
            glowIntensity = math.max(0, glowIntensity - FrameTime() * 1.2)
        end
        
        UpdateAmmoRT()
        render.PushRenderTarget(ammoRT)
            render.Clear(0, 0, 0, 0)
            cam.Start2D()
                local scrW, scrH = ScrW(), ScrH()
                local boxWidth = 280
                local boxHeight = 10
                local x = scrW - boxWidth - 100
                local y = scrH - boxHeight - 80
                local curTime = CurTime()
                
                -- Determine if we're in error state
                local isErrorState = (clip < 0)
                
                -- Select color palette based on state
                local currentBaseColor = isErrorState and holoErrorBaseColor or holoBaseColor
                local currentDimColor = isErrorState and holoErrorDimColor or holoDimColor
                local currentGlowColor = isErrorState and holoErrorGlowColor or holoGlowColor
                local currentScanColor = isErrorState and holoErrorScanColor or holoScanColor
                
                -- Draw background with noise pattern
                surface.SetDrawColor(10, 10, 15, 120)
                surface.DrawRect(x, y, boxWidth, boxHeight)
                
                -- Draw noise-based distortion in background
                for i = 0, boxWidth, 4 do
                    for j = 0, boxHeight, 4 do
                        local noise = PerlinNoise(i + curTime * 2, j + curTime) * 20
                        if math.abs(noise) > 15 then
                            local distortColor = isErrorState and Color(40, 20, 20, 30) or Color(30, 30, 35, 30)
                            surface.SetDrawColor(distortColor)
                            surface.DrawRect(x + i, y + j, 2, 2)
                        end
                    end
                end


                local barColor = isErrorState and Color(30, 15, 15, 180) or Color(20, 20, 25, 180)
                surface.SetDrawColor(barColor)
                surface.DrawRect(x, y, boxWidth, 24)
                surface.DrawRect(x, y + boxHeight - 24, boxWidth, 24)
                
                -- Draw scan lines for holographic effect
                for i = 0, boxHeight, 2 do
                    -- Vary the transparency with noise and time
                    local lineAlpha = currentScanColor.a + math.sin(curTime * 2 + i * 0.1) * 3
                    surface.SetDrawColor(currentScanColor.r, currentScanColor.g, currentScanColor.b, lineAlpha)
                    surface.DrawLine(x, y + i, x + boxWidth, y + i)
                end
                
                -- Holographic horizontal lines with pulse
                local pulse = (math.sin(curTime * 2) + 1) * 0.5
                local lineY1 = y + 32
                local lineY2 = y + boxHeight - 32
                
                surface.SetDrawColor(currentDimColor.r, currentDimColor.g, currentDimColor.b, 120 + pulse * 30)
                surface.DrawLine(x + 10, lineY1, x + boxWidth - 10, lineY1)
                surface.DrawLine(x + 10, lineY2, x + boxWidth - 10, lineY2)
                
                -- Small decorative elements
                surface.SetDrawColor(currentDimColor)
                -- Left brackets
                surface.DrawLine(x + 15, y + 40, x + 25, y + 40)
                surface.DrawLine(x + 15, y + 40, x + 15, y + 60)
                -- Right brackets
                surface.DrawLine(x + boxWidth - 15, y + 40, x + boxWidth - 25, y + 40)
                surface.DrawLine(x + boxWidth - 15, y + 40, x + boxWidth - 15, y + 60)
                -- Bottom decorative marks
                surface.DrawLine(x + 15, y + boxHeight - 40, x + 25, y + boxHeight - 40)
                surface.DrawLine(x + boxWidth - 15, y + boxHeight - 40, x + boxWidth - 25, y + boxHeight - 40)
                
                if not isErrorState then
                    -- Draw weapon name at top
                    draw.SimpleText(weaponName, "AmmoSub", x + boxWidth/2, y + 42, currentDimColor, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
                end
                
                -- Calculate shake offsets
                local shakeX = 0
                local shakeY = 0
                if shakeAmount > 0 then
                    shakeX = math.sin(curTime * 30) * shakeAmount
                    shakeY = math.cos(curTime * 20) * shakeAmount * 0.5
                end
                
                -- Check if ammo is less than 0 - display warning message
                if isErrorState then

                    -- Draw warning message with pulsing fade effect
                    local warningText = "! WARNING !"
                    local subText = "No weapon integration found"
                    
                    -- Create pulsing effect using sine wave
                    local pulseIntensity = (math.sin(curTime * 2) + 1) * 0.5 -- 0 to 1 pulse
                    
                    -- Fade in/out effect for warning text
                    local warningAlpha = 100 + (155 * pulseIntensity) -- Range from 100-255 for visibility
                    local warningColor = Color(currentBaseColor.r, currentBaseColor.g, currentBaseColor.b, warningAlpha)
                    
                    -- Warning text without glitch
                    local warningY = y + boxHeight/2 - 6
                    draw.SimpleText(warningText, "AmmoThing", 
                        x + boxWidth/2, warningY, 
                        warningColor, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
                    
                    -- Sub text with less intense pulse
                    local subTextAlpha = 80 + (100 * pulseIntensity) -- Range from 80-180 for visibility
                    local subTextY = y + boxHeight/2 + 13
                    draw.SimpleText(subText, "AmmoSub", 
                        x + boxWidth/2, subTextY, 
                        Color(currentDimColor.r, currentDimColor.g, currentDimColor.b, subTextAlpha), 
                        TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
                else
                    -- Draw central ammo text with shake
                    local ammoX = x + boxWidth/2 + shakeX
                    local ammoY = y + boxHeight/2 + shakeY
                    
                    -- Draw glow when ammo drops
                    if glowIntensity > 0 then
                        local glowSize = 4 + glowIntensity * 6
                        for i = glowSize, 1, -1 do
                            local alpha = holoGlowColor.a * (i/glowSize) * glowIntensity
                            draw.SimpleText(ammoText, "AmmoThing", 
                                ammoX, ammoY, 
                                Color(holoWarnColor.r, holoWarnColor.g, holoWarnColor.b, alpha), 
                                TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
                        end
                    end
                    
                    -- Determine text color based on ammo status
                    local textColor = holoBaseColor
                    if glowIntensity > 0 then
                        -- Pulse between warning color and base color
                        local pulse = (math.sin(curTime * 15) + 1) * 0.5
                        textColor = Color(
                            holoBaseColor.r + (holoWarnColor.r - holoBaseColor.r) * pulse * glowIntensity,
                            holoBaseColor.g + (holoWarnColor.g - holoBaseColor.g) * pulse * glowIntensity,
                            holoBaseColor.b + (holoWarnColor.b - holoBaseColor.b) * pulse * glowIntensity,
                            holoBaseColor.a
                        )
                    end
                    
                    -- Draw main ammo text
                    draw.SimpleText(ammoText, "CloseCaption_Bold", ammoX, ammoY, textColor, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
                    
                    -- Draw "AMMO" text with glitch effect when ammo drops
                    local ammoTextY = y + boxHeight - 40
                    DrawGlitchText("W.I.S | VERSION ''^(&'ERR)", "SmallAmmo", 
                        x + boxWidth/2 + shakeX * 0.5, 
                        ammoTextY + shakeY * 0.5, 
                        shakeAmount > 0 and holoWarnColor or holoDimColor, 
                        TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER, 
                        shakeAmount)
                        
                    -- Draw ammo status indicator
                    local indicatorWidth = 150
                    local indicatorHeight = 4
                    local indicatorX = x + (boxWidth - indicatorWidth)/2
                    local indicatorY = y + 50
                    
                    -- Background bar
                    surface.SetDrawColor(30, 30, 35, 120)
                    surface.DrawRect(indicatorX, indicatorY, indicatorWidth, indicatorHeight)
                    
                    -- Get ammo ratio for indicator
                    local maxAmmo = activeWeapon:GetMaxClip1()
                    local ammoRatio = maxAmmo > 0 and clip / maxAmmo or 0
                    
                    -- Determine color based on ammo level
                    local barColor = holoBaseColor
                    if ammoRatio < 0.25 then
                        -- Low ammo warning effect
                        local pulse = (math.sin(curTime * 8) + 1) * 0.5
                        barColor = Color(holoBaseColor.r, holoBaseColor.g, holoBaseColor.b, 150 + pulse * 100)
                    end
                    
                    -- Ammo level bar
                    surface.SetDrawColor(barColor)
                    surface.DrawRect(indicatorX, indicatorY, indicatorWidth * ammoRatio, indicatorHeight)

                end
                
                
            cam.End2D()
        render.PopRenderTarget()
    end

    -- Draw the curved ammo HUD
    local function DrawCurvedAmmoHUD()
        local overlaySegments = 48
        local overlayCurveAmount = -120
        
        UpdateAmmoRT()
        render.SetMaterial(ammoMat)
        local scrW, scrH = ScrW(), ScrH()
        
        -- Only curve the bottom right section where the ammo is
        local regionWidth = 200
        local regionHeight = 100
        local startX = scrW - regionWidth
        local startY = scrH - regionHeight
        
        mesh.Begin(MATERIAL_TRIANGLES, overlaySegments * 2)
            for i = 0, overlaySegments - 1 do
                local u1 = i / overlaySegments
                local u2 = (i + 1) / overlaySegments
                local x1 = u1 * scrW
                local x2 = u2 * scrW
                local offset1 = math.sin(u1 * math.pi) * overlayCurveAmount
                local offset2 = math.sin(u2 * math.pi) * overlayCurveAmount
                
                local yTop1 = 0 + offset1
                local yTop2 = 0 + offset2
                local yBot1 = scrH + offset1
                local yBot2 = scrH + offset2
                
                -- First triangle
                mesh.Position(Vector(x1, yTop1, 0))
                mesh.TexCoord(0, u1, 0)
                mesh.Color(255, 255, 255, 255)
                mesh.AdvanceVertex()
                
                mesh.Position(Vector(x2, yTop2, 0))
                mesh.TexCoord(0, u2, 0)
                mesh.Color(255, 255, 255, 255)
                mesh.AdvanceVertex()
                
                mesh.Position(Vector(x2, yBot2, 0))
                mesh.TexCoord(0, u2, 1)
                mesh.Color(255, 255, 255, 255)
                mesh.AdvanceVertex()
                
                -- Second triangle
                mesh.Position(Vector(x1, yTop1, 0))
                mesh.TexCoord(0, u1, 0)
                mesh.Color(255, 255, 255, 255)
                mesh.AdvanceVertex()
                
                mesh.Position(Vector(x2, yBot2, 0))
                mesh.TexCoord(0, u2, 1)
                mesh.Color(255, 255, 255, 255)
                mesh.AdvanceVertex()
                
                mesh.Position(Vector(x1, yBot1, 0))
                mesh.TexCoord(0, u1, 1)
                mesh.Color(255, 255, 255, 255)
                mesh.AdvanceVertex()
            end
        mesh.End()
    end

    -- Replace your ammo display code in GM:HUDPaint with this:
    local function DrawSciFiAmmoHUD(client)
        shouldDraw = hook.Run("ShouldDrawAmmoBox")
        if (shouldDraw != nil and shouldDraw != false) then
            local activeWeapon = client:GetActiveWeapon()
            if (!IsValid(activeWeapon)) then return end

            BakeAmmoHUD(client)
            DrawCurvedAmmoHUD()
        end
    end

    local lastScrW, lastScrH = 0, 0
    local vitalsRT, vitalsMat
    local healthHistory = {}
    local armorHistory = {}
    local historyLength = 100 -- How many data points to keep for line graphs
    local lastHealth = -1
    local lastArmor = -1
    local shakeAmount = 0
    local glowIntensity = 0

    -- Grayscale holographic color palette (matching ammo HUD)
    local holoBaseColor = Color(180, 180, 180, 210)
    local holoDimColor = Color(120, 120, 120, 150)
    local holoGlowColor = Color(255, 255, 255, 50)
    local holoWarnColor = Color(220, 220, 220, 255)
    local holoScanColor = Color(200, 200, 200, 8)

    -- Health specific colors
    local healthColor = Color(80, 220, 120, 200)
    local healthDimColor = Color(60, 160, 80, 150)
    local healthCriticalColor = Color(220, 80, 80, 200)

    -- Armor specific colors
    local armorColor = Color(80, 160, 220, 200)
    local armorDimColor = Color(60, 120, 180, 150)

    -- Error state colors (low saturation red)
    local holoErrorBaseColor = Color(180, 70, 70, 200)
    local holoErrorDimColor = Color(120, 50, 50, 150)
    local holoErrorGlowColor = Color(255, 100, 100, 50)
    local holoErrorScanColor = Color(200, 80, 80, 8)

    -- Update history arrays with new data points
    local function UpdateVitalsHistory(health, armor)
        -- Add new data points
        table.insert(healthHistory, health)
        table.insert(armorHistory, armor)
        
        -- Trim history to keep only the required amount of data points
        while #healthHistory > historyLength do
            table.remove(healthHistory, 1)
        end
        
        while #armorHistory > historyLength do
            table.remove(armorHistory, 1)
        end
    end

    -- Update render target when screen size changes
    local function UpdateVitalsRT()
        local scrW, scrH = ScrW(), ScrH()
        if (scrW != lastScrW or scrH != lastScrH or !vitalsRT) then
            vitalsRT = GetRenderTarget("VitalsHUD_RT", scrW, scrH, false)
            vitalsMat = CreateMaterial("VitalsHUD_Mat", "UnlitGeneric", {
                ["$basetexture"] = "VitalsHUD_RT",
                ["$translucent"] = "1",
                ["$vertexalpha"] = "1",
                ["$vertexcolor"] = "1",
                ["$ignorez"] = "1",
                ["$additive"] = "1",
                ["$basetexturefiltermode"] = "Point"
            })
            lastScrW, lastScrH = scrW, scrH
        end
    end

    -- Noise function for distortion effects
    local function PerlinNoise(x, y)
        return (math.sin(x * 0.1 + y * 0.1) + math.cos(x * 0.11 + y * 0.13)) * 0.5
    end

    local function DrawVitalLine(x, y, width, height, dataHistory, color, dimColor, criticalThreshold)
        if #dataHistory == 0 then return end
        
        -- Draw background (dark medical monitor style)
        surface.SetDrawColor(0, 0, 0, 230)
        surface.DrawRect(x, y, width, height)
        

        
        -- Get current value and determine state
        local currentValue = dataHistory[#dataHistory]
        local isCritical = criticalThreshold and currentValue <= criticalThreshold
        
        -- Determine base wave parameters based on current values
        local waveSpeed = 2  -- Base speed of the wave movement
        local wavePeriod = 0.5  -- Base period of the waveform
        
        -- Adjust parameters based on current value
        if currentValue < 50 then
            -- Lower health/armor means faster, more erratic waves
            waveSpeed = waveSpeed + (50 - currentValue) * 0.04
            wavePeriod = wavePeriod - (50 - currentValue) * 0.005
        end
        
        -- Make critical status more dramatic
        if isCritical then
            waveSpeed = waveSpeed * 1.5
            wavePeriod = wavePeriod * 0.7
        end
        
        -- Time-based offset for animation
        local timeOffset = CurTime() * waveSpeed
        
        -- Generate moving waveform
        local baselineY = y + height * 0.7  -- Baseline position (70% down from top)
        local waveHeight = height * 0.3 * (currentValue / 100)  -- Height scales with health/armor
        local lastX, lastY
        
        -- Draw the animated waveform line
        for i = 0, width, 2 do
            -- Calculate normalized position
            local normalizedX = i / width
            local offsetX = i + timeOffset % (width * 2)  -- Wrap around for continuous movement
            
            -- Calculate waveform Y position
            local waveY
            
            -- Different waveform patterns based on health status
            if isCritical then
                -- Critical health: irregular heartbeat pattern with occasional spikes
                local baseWave = math.sin(offsetX * wavePeriod) * 0.5
                local spike = 0
                
                -- Add occasional spikes (erratic heartbeat)
                if (offsetX % 40) < 10 then
                    spike = math.sin((offsetX % 40) * 0.5) * 3
                end
                
                -- Add some noise/jitter for critical state
                local noise = math.sin(offsetX * 3) * 0.2
                
                waveY = baselineY - ((baseWave + spike + noise) * waveHeight)
            else
                -- Normal health: smooth heartbeat pattern
                local beat = math.sin(offsetX * wavePeriod * 0.3) * 0.3  -- Base sine wave
                
                -- Add periodic heartbeat spike
                if (offsetX % 60) < 10 then
                    -- QRS complex of heartbeat
                    if (offsetX % 60) < 2 then
                        -- Q wave - small dip
                        beat = beat - 0.4
                    elseif (offsetX % 60) < 4 then
                        -- R wave - big spike
                        beat = beat + 2
                    elseif (offsetX % 60) < 6 then
                        -- S wave - another dip
                        beat = beat - 0.8
                    elseif (offsetX % 60) < 10 then
                        -- T wave - small bump
                        beat = beat + 0.5
                    end
                end
                
                waveY = baselineY - (beat * waveHeight)
            end
            
            -- Ensure waveY stays within bounds
            waveY = math.Clamp(waveY, y, y + height)
            
            -- Draw line segment
            if lastX then
                -- Determine color and glow based on state
                local lineColor = color
                if isCritical then
                    -- Pulsing red for critical
                    local pulse = (math.sin(CurTime() * 8) + 1) * 0.5
                    lineColor = Color(
                        healthCriticalColor.r,
                        healthCriticalColor.g,
                        healthCriticalColor.b,
                        healthCriticalColor.a * (0.7 + pulse * 0.3)
                    )
                end
                
                -- Draw glow effect first (for CRT monitor look)
                local glowColor = Color(lineColor.r, lineColor.g, lineColor.b, 40)
                surface.SetDrawColor(glowColor)
                for g = 1, 3 do  -- Multiple passes for glow
                    surface.DrawLine(lastX, lastY - g, x + i, waveY - g)
                    surface.DrawLine(lastX, lastY + g, x + i, waveY + g)
                end
                
                -- Draw main line
                surface.SetDrawColor(lineColor)
                surface.DrawLine(lastX, lastY, x + i, waveY)
            end
            
            lastX = x + i
            lastY = waveY
        end
        
        -- Display current value as a digital readout
        local valueColor = color
        if isCritical then
            local pulse = (math.sin(CurTime() * 8) + 1) * 0.5
            valueColor = Color(
                healthCriticalColor.r,
                healthCriticalColor.g,
                healthCriticalColor.b,
                healthCriticalColor.a * (0.7 + pulse * 0.3)
            )
        end
        
        
        -- Add heartbeat "blip" sound effect for very low health (below 20%)
        if isCritical and (math.floor(CurTime() * 2) % 2 == 0) and (math.floor(CurTime() * 10) % 10 == 0) then
            -- This would ideally trigger a beep sound, but we'll just flash the screen slightly
            surface.SetDrawColor(healthCriticalColor.r, healthCriticalColor.g, healthCriticalColor.b, 10)
            surface.DrawRect(x, y, width, height)
        end
    end

    -- Function to draw glitched text
    local function DrawGlitchText(text, font, x, y, color, alignX, alignY, glitchAmount)
        -- Draw main text
        draw.SimpleText(text, font, x, y, color, alignX, alignY)
        
        -- Draw glitch effects
        if glitchAmount > 0 then
            -- Small horizontal offset copies with varying alpha
            local alpha = math.min(255, glitchAmount * 150)
            local glitchColor = Color(color.r, color.g, color.b, alpha)
            
            -- Left ghost
            draw.SimpleText(text, font, x - glitchAmount * 2, y, 
                Color(color.r, color.g, color.b, alpha * 0.3), alignX, alignY)
            
            -- Right ghost
            draw.SimpleText(text, font, x + glitchAmount * 2, y, 
                Color(color.r, color.g, color.b, alpha * 0.3), alignX, alignY)
                
            -- Draw digital artifacts - small broken pieces
            if glitchAmount > 1.5 then
                for i = 1, math.floor(glitchAmount * 3) do
                    local offsetX = math.random(-10, 10) * glitchAmount
                    local offsetY = math.random(-3, 3)
                    local startPos = math.random(1, #text)
                    local endPos = math.min(startPos + math.random(1, 3), #text)
                    local subText = string.sub(text, startPos, endPos)
                    
                    draw.SimpleText(subText, font, x + offsetX, y + offsetY, 
                        Color(color.r, color.g, color.b, math.random(40, 120)), 
                        alignX, alignY)
                end
            end
        end
    end

    -- Render the vitals display to our render target
    function BakeVitalsHUD(client)
        if (!IsValid(client)) then return end

        local health = client:Health()
        local armor = client:Armor()
        local maxHealth = client:GetMaxHealth()
        
        -- Normalize health and armor to percentages
        local healthPercent = math.Clamp((health / maxHealth) * 100, 0, 100)
        local armorPercent = math.Clamp(armor, 0, 100)
        
        -- Check for health/armor drop
        local statsChanged = false
        if lastHealth > health or lastArmor > armor then
            -- Stats dropped, trigger effects
            shakeAmount = math.min(shakeAmount + 2, 5)
            glowIntensity = math.min(glowIntensity + 0.6, 1)
            statsChanged = true
        end
        lastHealth = health
        lastArmor = armor
        
        -- Update the history
        UpdateVitalsHistory(healthPercent, armorPercent)
        
        -- Decay effects over time
        if shakeAmount > 0 then
            shakeAmount = math.max(0, shakeAmount - FrameTime() * 3)
        end
        
        if glowIntensity > 0 then
            glowIntensity = math.max(0, glowIntensity - FrameTime() * 1.2)
        end
        
        UpdateVitalsRT()
        render.PushRenderTarget(vitalsRT)
            render.Clear(0, 0, 0, 0)
            cam.Start2D()
                local scrW, scrH = ScrW(), ScrH()
                local boxWidth = 280
                local boxHeight = 10
                local x = scrW - boxWidth - 100 -- Right side of screen
                local y = scrH - boxHeight - 230 -- Bottom of screen
                local curTime = CurTime()
                
                -- Determine if we're in error state (health critically low)
                local isErrorState = (healthPercent <= 20)
                
                -- Select color palette based on state
                local currentBaseColor = isErrorState and holoErrorBaseColor or holoBaseColor
                local currentDimColor = isErrorState and holoErrorDimColor or holoDimColor
                local currentGlowColor = isErrorState and holoErrorGlowColor or holoGlowColor
                local currentScanColor = isErrorState and holoErrorScanColor or holoScanColor
                
                -- Draw background with noise pattern
                surface.SetDrawColor(10, 10, 15, 120)
                surface.DrawRect(x, y, boxWidth, boxHeight)
                
                -- Draw noise-based distortion in background
                for i = 0, boxWidth, 4 do
                    for j = 0, boxHeight, 4 do
                        local noise = PerlinNoise(i + curTime * 2, j + curTime) * 20
                        if math.abs(noise) > 15 then
                            local distortColor = isErrorState and Color(40, 20, 20, 30) or Color(30, 30, 35, 30)
                            surface.SetDrawColor(distortColor)
                            surface.DrawRect(x + i, y + j, 2, 2)
                        end
                    end
                end
                

                
                -- Draw top and bottom bars
                local barColor = isErrorState and Color(30, 15, 15, 180) or Color(20, 20, 25, 180)
                surface.SetDrawColor(barColor)
                surface.DrawRect(x, y, boxWidth, 24)
                surface.DrawRect(x, y + boxHeight - 24, boxWidth, 24)
                
                -- Draw scan lines for holographic effect
                for i = 0, boxHeight, 2 do
                    -- Vary the transparency with noise and time
                    local lineAlpha = currentScanColor.a + math.sin(curTime * 2 + i * 0.1) * 3
                    surface.SetDrawColor(currentScanColor.r, currentScanColor.g, currentScanColor.b, lineAlpha)
                    surface.DrawLine(x, y + i, x + boxWidth, y + i)
                end
                
                
                -- Calculate shake offsets
                local shakeX = 0
                local shakeY = 0
                if shakeAmount > 0 then
                    shakeX = math.sin(curTime * 30) * shakeAmount
                    shakeY = math.cos(curTime * 20) * shakeAmount * 0.5
                end
                
                -- Draw health monitor
                local lineWidth = boxWidth - 40
                local lineHeight = 10
                local lineX = x + 20
                local healthY = y + 50
                local armorY = y + 80
                
                -- Draw health vitals line
                DrawVitalLine(lineX, healthY, lineWidth, lineHeight, healthHistory, healthColor, healthDimColor, 25)
                
                -- Draw armor vitals line
                DrawVitalLine(lineX, armorY, lineWidth, lineHeight, armorHistory, armorColor, armorDimColor)
                
                -- Draw health text label with glitch effect when health drops
                local healthTextY = healthY - 7
                DrawGlitchText("VITALS", "AmmoSub", 
                    lineX + shakeX * 0.5, 
                    healthTextY + shakeY * 0.5, 
                    isErrorState and healthCriticalColor or healthColor, 
                    TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER, 
                    isErrorState and 1.51 or 0)
                    
                -- Draw armor text label
                draw.SimpleText("BODYPACK", "AmmoSub", 
                    lineX, armorY - 7, 
                    armorColor, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
                    
                -- Draw current values
                local valueX = lineX + lineWidth + 10
                
                -- Health value with color indication
                local healthTextColor = healthColor
                if healthPercent <= 25 then
                    -- Pulse between normal and critical for low health
                    local pulse = (math.sin(curTime * 8) + 1) * 0.5
                    healthTextColor = Color(
                        healthColor.r + (healthCriticalColor.r - healthColor.r) * pulse,
                        healthColor.g + (healthCriticalColor.g - healthColor.g) * pulse,
                        healthColor.b + (healthCriticalColor.b - healthColor.b) * pulse,
                        healthColor.a
                    )
                end
                
                -- Draw health and armor percentage values
                draw.SimpleText(math.Round(healthPercent) .. "%", "AmmoSub", 
                    lineX + lineWidth/1.05, healthY + lineHeight - 18, 
                    healthTextColor, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
                    
                draw.SimpleText(math.Round(armorPercent) .. "%", "AmmoSub", 
                    lineX + lineWidth/1.05, armorY + lineHeight - 17, 
                    armorColor, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
                    
                -- Draw critical indicator if health is low
                if healthPercent <= 25 then
                    local pulse = (math.sin(curTime * 8) + 1) * 0.5
                    local criticalAlpha = 150 + pulse * 105
                    local criticalColor = Color(healthCriticalColor.r, healthCriticalColor.g, healthCriticalColor.b, criticalAlpha)
                    
                    draw.SimpleText("CRITICAL", "AmmoSub", 
                        x + boxWidth/2, y + boxHeight - 4, 
                        criticalColor, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
                else
                    draw.SimpleText("STATUS", "AmmoSub", 
                        x + boxWidth/2, y + boxHeight - 4, 
                        currentDimColor, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
                end
                
            cam.End2D()
        render.PopRenderTarget()
    end

    -- Draw the curved vitals HUD
    local function DrawCurvedVitalsHUD()
        local overlaySegments = 48
        local overlayCurveAmount = -120
        
        UpdateVitalsRT()
        render.SetMaterial(vitalsMat)
        local scrW, scrH = ScrW(), ScrH()
        
        -- Only curve the bottom left section where the vitals are
        local regionWidth = 200
        local regionHeight = 100
        local startX = 0
        local startY = scrH - regionHeight
        
        mesh.Begin(MATERIAL_TRIANGLES, overlaySegments * 2)
            for i = 0, overlaySegments - 1 do
                local u1 = i / overlaySegments
                local u2 = (i + 1) / overlaySegments
                local x1 = u1 * scrW
                local x2 = u2 * scrW
                local offset1 = math.sin(u1 * math.pi) * overlayCurveAmount
                local offset2 = math.sin(u2 * math.pi) * overlayCurveAmount
                
                local yTop1 = 0 + offset1
                local yTop2 = 0 + offset2
                local yBot1 = scrH + offset1
                local yBot2 = scrH + offset2
                
                -- First triangle
                mesh.Position(Vector(x1, yTop1, 0))
                mesh.TexCoord(0, u1, 0)
                mesh.Color(255, 255, 255, 255)
                mesh.AdvanceVertex()
                
                mesh.Position(Vector(x2, yTop2, 0))
                mesh.TexCoord(0, u2, 0)
                mesh.Color(255, 255, 255, 255)
                mesh.AdvanceVertex()
                
                mesh.Position(Vector(x2, yBot2, 0))
                mesh.TexCoord(0, u2, 1)
                mesh.Color(255, 255, 255, 255)
                mesh.AdvanceVertex()
                
                -- Second triangle
                mesh.Position(Vector(x1, yTop1, 0))
                mesh.TexCoord(0, u1, 0)
                mesh.Color(255, 255, 255, 255)
                mesh.AdvanceVertex()
                
                mesh.Position(Vector(x2, yBot2, 0))
                mesh.TexCoord(0, u2, 1)
                mesh.Color(255, 255, 255, 255)
                mesh.AdvanceVertex()
                
                mesh.Position(Vector(x1, yBot1, 0))
                mesh.TexCoord(0, u1, 1)
                mesh.Color(255, 255, 255, 255)
                mesh.AdvanceVertex()
            end
        mesh.End()
    end

    -- Function to draw the sci-fi vitals HUD
    function DrawSciFiVitalsHUD(client)
        if (!IsValid(client)) then return end

        BakeVitalsHUD(client)
        DrawCurvedVitalsHUD()
    end

    local terminalRT, terminalMat
    local lastScrW, lastScrH = 0, 0
    local glitchAmount = 0
    local scanlineOffset = 0
    local terminalLines = {
        "[ SUIT-NODE-3B :: LIFECORE SYSTEM BOOT // ERR^R# ]",
        "> ERROR 404 – /database/planet.db.missing",
        "> Sleep Cycle Interrupt: FORCED ABORT",
        "> Uplink with HQ... [ FAILED ]",
        "> Logging resumed... [ REDUNDANT MODE ]"
    }


    -- Animation states for each line
    local lineStates = {}
    for i = 1, #terminalLines do
        lineStates[i] = {
            visible = false,        -- Is line currently visible
            charCount = 0,          -- For typewriter effect
            glitchTimer = 0,        -- Individual glitch timer
            glitchFrequency = 0.05 * i, -- Lines glitch at different rates
            revealTime = 0.8 + i * 0.4  -- Timing for when line appears
        }
    end

    -- Initialize animation timer
    local animStartTime = 0
    local isAnimating = false

    -- Colors (matching the holographic style from vitals)
    local baseColor = Color(255, 255, 255, 20)
    local dimColor = Color(120, 120, 120, 10)
    local glowColor = Color(255, 255, 255, 10)
    local warnColor = Color(220, 100, 100, 10)
    local errorColor = Color(255, 80, 80, 10)

    -- Function to get proper color for a line
    local function GetLineColor(lineIndex)
        local text = terminalLines[lineIndex]
        
        -- Error and warning messages in red
        if string.find(text, "ERROR") or string.find(text, "Hostile") then
            return errorColor
        elseif string.find(text, "UNSTABLE") or string.find(text, "ABORTED") or string.find(text, "No comms") then
            return warnColor
        elseif string.find(text, "SUIT") then
            return Color(100, 100, 255, 10) -- Title in slightly blueish
        else
            return baseColor
        end
    end

    -- Update render target when screen size changes
    local function UpdateTerminalRT()
        local scrW, scrH = ScrW(), ScrH()
        if (scrW != lastScrW or scrH != lastScrH or !terminalRT) then
            terminalRT = GetRenderTarget("TerminalHUD_RT", scrW, scrH, false)
            terminalMat = CreateMaterial("TerminalHUD_Mat", "UnlitGeneric", {
                ["$basetexture"] = "TerminalHUD_RT",
                ["$translucent"] = "1",
                ["$vertexalpha"] = "1",
                ["$vertexcolor"] = "1",
                ["$ignorez"] = "1",
                ["$additive"] = "1"
            })
            lastScrW, lastScrH = scrW, scrH
        end
    end

    -- Noise function for glitch effects
    local function Noise(x, y, t)
        return (math.sin(x * 0.1 + t) + math.cos(y * 0.1 + t * 0.3)) * 0.5
    end

    -- Draw glitched text with typewriter effect
    local function DrawGlitchText(text, font, x, y, color, alignX, alignY, glitchIntensity, charLimit)
        -- Character limit for typewriter effect
        local displayText = text
        if charLimit and charLimit < #text then
            displayText = string.sub(text, 1, charLimit)
            
            -- Add blinking cursor at end during typewriter effect
            if math.sin(CurTime() * 5) > 0 then
                displayText = displayText .. "_"
            end
        end
        
        -- Draw main text
        draw.SimpleText(displayText, font, x, y, color, alignX, alignY)
        
        -- Draw glitch effects
        if glitchIntensity > 0 then
            -- Small horizontal offset copies with varying alpha
            local alpha = math.min(100, glitchIntensity * 150)
            
            -- Random glitch artifacts
            if glitchIntensity > 0.5 and math.random() < glitchIntensity * 0.3 then
                -- Left ghost
                local offsetX = math.random(-3, 3) * glitchIntensity
                draw.SimpleText(displayText, font, x + offsetX, y, 
                    Color(color.r, color.g, color.b, alpha * 0.7), alignX, alignY)
            end
            
            -- Random character corruption
            if glitchIntensity > 0.7 and math.random() < glitchIntensity * 0.2 then
                local corruptChars = {"#", "*", "!", "$", "%", "&", "=", "?", "@", "^"}
                local startPos = math.random(1, #displayText)
                local endPos = math.min(startPos + math.random(0, 2), #displayText)
                local beforeText = string.sub(displayText, 1, startPos - 1)
                local corruptChar = corruptChars[math.random(1, #corruptChars)]
                local afterText = string.sub(displayText, endPos + 1)
                
                local corruptText = beforeText .. corruptChar .. afterText
                draw.SimpleText(corruptText, font, x, y, 
                    Color(color.r + 40, color.g - 40, color.b - 40, color.a), alignX, alignY)
            end
        end
    end

    -- Function to start animation sequence
    function StartTerminalAnimation()
        animStartTime = CurTime()
        isAnimating = true
        
        -- Reset line states
        for i = 1, #lineStates do
            lineStates[i].visible = false
            lineStates[i].charCount = 0
        end
        
        -- Add random slight glitch
        glitchAmount = math.random(0.5, 1.2)
    end

    -- Render the terminal text to our render target
    function BakeTerminalHUD()
        UpdateTerminalRT()
        
        render.PushRenderTarget(terminalRT)
            render.Clear(0, 0, 0, 0)
            cam.Start2D()
                local scrW, scrH = ScrW(), ScrH()
                local boxWidth = 360
                local boxHeight = 240
                local x = scrW - boxWidth - 50 -- Right side of screen
                local y = 30              -- Top of screen
                local curTime = CurTime()
                
                -- Background with noise pattern
                surface.SetDrawColor(10, 10, 15, 100)
                surface.DrawRect(x, y, boxWidth, boxHeight)
                
                --[[ Draw scan lines
                for i = 0, boxHeight, 2 do
                    local scanY = y + i + scanlineOffset % 4
                    surface.SetDrawColor(255, 255, 255, 1 + math.sin(curTime + i * 0.05) * 1)
                    surface.DrawLine(x, scanY, x + boxWidth, scanY)
                end]]
                
                -- Update scanline movement
                scanlineOffset = scanlineOffset + FrameTime() * 5
                
                -- Draw noise-based distortion in background
                for i = 0, boxWidth, 8 do
                    for j = 0, boxHeight, 8 do
                        local noise = Noise(i, j, curTime * 2) * 30
                        if math.abs(noise) > 24 then
                            surface.SetDrawColor(30, 30, 40, 20)
                            surface.DrawRect(x + i, y + j, 4, 1)
                        end
                    end
                end
                
                -- Animate lines
                local lineHeight = 22
                local startY = y + 25
                local elapsedTime = 0
                
                if isAnimating then
                    elapsedTime = curTime - animStartTime
                    
                    -- Update lines based on animation time
                    for i = 1, #lineStates do
                        -- Determine if this line should be visible yet
                        if elapsedTime >= lineStates[i].revealTime then
                            lineStates[i].visible = true
                            
                            -- Typewriter effect - increase shown characters over time
                            local charRevealRate = 20 -- characters per second
                            local lineRevealTime = elapsedTime - lineStates[i].revealTime
                            lineStates[i].charCount = math.min(#terminalLines[i], math.floor(lineRevealTime * charRevealRate))
                            
                            -- Random glitches
                            lineStates[i].glitchTimer = lineStates[i].glitchTimer - FrameTime()
                            if lineStates[i].glitchTimer <= 0 then
                                -- Reset glitch timer
                                lineStates[i].glitchTimer = math.random(1, 4)
                            end
                        end
                    end
                    
                    -- Check if animation is complete
                    if elapsedTime > lineStates[#lineStates].revealTime + 3 then
                        isAnimating = false
                    end
                end
                
                -- Draw terminal lines
                for i = 1, #terminalLines do
                    if not isAnimating or lineStates[i].visible then
                        local lineY = startY + (i - 1) * lineHeight
                        local lineColor = GetLineColor(i)
                        local glitchIntense = 0
                        
                        -- Apply glitch effect during animation or randomly after
                        if isAnimating then
                            glitchIntense = math.max(0, 1.5 - lineStates[i].glitchTimer) * 0.3
                        elseif math.random() < 0.01 then
                            -- Random glitches after animation
                            glitchIntense = math.random() * 0.8
                        end
                        
                        -- Handle special lines with more dramatic effects
                        if string.find(terminalLines[i], "ERROR") then
                            -- ERROR messages pulse
                            local pulse = (math.sin(curTime * 3) + 1) * 0.5
                            lineColor = Color(
                                errorColor.r,
                                errorColor.g * (0.7 + pulse * 0.3),
                                errorColor.b * (0.7 + pulse * 0.3),
                                errorColor.a
                            )
                            glitchIntense = glitchIntense + math.abs(math.sin(curTime * 2)) * 0.5
                        end
                        
                        if isAnimating then
                            -- During animation, use typewriter effect
                            DrawGlitchText(terminalLines[i], "Vitals", 
                                x + 15, lineY, lineColor, 
                                TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP, 
                                glitchIntense, lineStates[i].charCount)
                        else
                            -- After animation, show full text with occasional glitches
                            DrawGlitchText(terminalLines[i], "Vitals", 
                                x + 15, lineY, lineColor, 
                                TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP, 
                                glitchIntense)
                        end
                    end
                end
                
                -- System status indicator in top right corner
                local statusX = x + boxWidth - 15
                local statusY = y + 12
                local statusSize = 8
                
                -- Pulsing status light
                local pulse = (math.sin(curTime * 2) + 1) * 0.5
                local statusColor = errorColor
                
                --[[ Outer glow
                surface.SetDrawColor(statusColor.r, statusColor.g, statusColor.b, 30 + pulse * 20)
                surface.DrawRect(statusX - statusSize - 4, statusY - statusSize - 4, 
                                statusSize * 2 + 8, statusSize * 2 + 8)]]
                
                --[[ Inner status light
                surface.SetDrawColor(statusColor.r, statusColor.g, statusColor.b, 150 + pulse * 100)
                surface.DrawRect(statusX - statusSize, statusY - statusSize, 
                                statusSize * 2, statusSize * 2)]]
                
                --[[ Draw system time in corner
                local timeStr = os.date("%H:%M:%S", os.time())
                draw.SimpleText(timeStr, "BudgetLabel", x + boxWidth - 15, y + boxHeight - 20, 
                            dimColor, TEXT_ALIGN_RIGHT, TEXT_ALIGN_TOP)]]
                            
                --[[ Draw frame around the terminal
                surface.SetDrawColor(50, 50, 60, 100)
                surface.DrawOutlinedRect(x, y, boxWidth, boxHeight, 1)]]
                
                --[[ Draw a second inner frame
                surface.SetDrawColor(50, 50, 60, 50)
                surface.DrawOutlinedRect(x + 3, y + 3, boxWidth - 6, boxHeight - 6, 1)]]
                
            cam.End2D()
        render.PopRenderTarget()
    end

    -- Draw the curved terminal HUD
    local function DrawCurvedTerminalHUD()
        local overlaySegments = 48
        local overlayCurveAmount = 100  -- Positive for convex curve
        
        UpdateTerminalRT()
        render.SetMaterial(terminalMat)
        local scrW, scrH = ScrW(), ScrH()
        
        mesh.Begin(MATERIAL_TRIANGLES, overlaySegments * 2)
            for i = 0, overlaySegments - 1 do
                local u1 = i / overlaySegments
                local u2 = (i + 1) / overlaySegments
                local x1 = u1 * scrW
                local x2 = u2 * scrW
                local offset1 = math.sin(u1 * math.pi) * overlayCurveAmount
                local offset2 = math.sin(u2 * math.pi) * overlayCurveAmount
                
                local yTop1 = 0 + offset1
                local yTop2 = 0 + offset2
                local yBot1 = scrH + offset1
                local yBot2 = scrH + offset2
                
                -- First triangle
                mesh.Position(Vector(x1, yTop1, 0))
                mesh.TexCoord(0, u1, 0)
                mesh.Color(255, 255, 255, 255)
                mesh.AdvanceVertex()
                
                mesh.Position(Vector(x2, yTop2, 0))
                mesh.TexCoord(0, u2, 0)
                mesh.Color(255, 255, 255, 255)
                mesh.AdvanceVertex()
                
                mesh.Position(Vector(x2, yBot2, 0))
                mesh.TexCoord(0, u2, 1)
                mesh.Color(255, 255, 255, 255)
                mesh.AdvanceVertex()
                
                -- Second triangle
                mesh.Position(Vector(x1, yTop1, 0))
                mesh.TexCoord(0, u1, 0)
                mesh.Color(255, 255, 255, 255)
                mesh.AdvanceVertex()
                
                mesh.Position(Vector(x2, yBot2, 0))
                mesh.TexCoord(0, u2, 1)
                mesh.Color(255, 255, 255, 255)
                mesh.AdvanceVertex()
                
                mesh.Position(Vector(x1, yBot1, 0))
                mesh.TexCoord(0, u1, 1)
                mesh.Color(255, 255, 255, 255)
                mesh.AdvanceVertex()
            end
        mesh.End()
    end

    -- Main function to draw the sci-fi terminal HUD
    function DrawSciFiTerminalHUD()
        BakeTerminalHUD()
        DrawCurvedTerminalHUD()
    end

    -- Periodically re-trigger animation for dramatic effect during gameplay
    timer.Create("TerminalGlitchTimer", 45, 0, function()
        -- Randomly decide to retrigger animation
        if math.random() < 0.3 then
            StartTerminalAnimation()
        else
            -- Just add some glitch
            glitchAmount = math.random(0.5, 2.0)
        end
    end)

    local stationTreeRT, stationTreeMat
    local lastTreeScrW, lastTreeScrH = 0, 0
    local treeGlitchAmount = 0
    local treeGlitchTimer = 0

    -- Tree view data structure
    local stationTreeData = {
        {
            name = "SUIT-NODE-3B",
            status = "CURRENT",
            color = Color(100, 220, 100, 50), -- Active green
            lastPing = "CONNECTED"
        },
        {
            name = "STATION-1",
            status = "OFFLINE",
            color = Color(80, 80, 80, 50), -- Dim gray for offline
            lastPing = "843 DAYS AGO"
        },
        {
            name = "STATION-2",
            status = "OFFLINE",
            color = Color(80, 80, 80, 50),
            lastPing = "512 DAYS AGO"
        },
        {
            name = "STATION-4",
            status = "UNKNOWN",
            color = Color(180, 180, 80, 50), -- Yellow for unknown
            lastPing = "NO DATA"
        }
    }

    -- Location data
    local locationData = {
        {
            label = "CURRENT LOCATION",
            value = "[UNKNOWN ORBIT DETECTED]",
            color = Color(220, 100, 100, 50) -- Warning red
        },
        {
            label = "STELLAR POSITION",
            value = "CALCULATING...",
            color = Color(180, 180, 80, 50) -- Yellow
        },
        {
            label = "COMMS STATUS",
            value = "CRITICAL FAILURE",
            color = Color(220, 100, 100, 50) -- Warning red
        }
    }

    -- Initialize render target for tree view
    local function UpdateStationTreeRT()
        local scrW, scrH = ScrW(), ScrH()
        if (scrW != lastTreeScrW or scrH != lastTreeScrH or !stationTreeRT) then
            stationTreeRT = GetRenderTarget("StationTreeHUD_RT", scrW, scrH, false)
            stationTreeMat = CreateMaterial("StationTreeHUD_Mat", "UnlitGeneric", {
                ["$basetexture"] = "StationTreeHUD_RT",
                ["$translucent"] = "",
                ["$vertexalpha"] = "1",
                ["$vertexcolor"] = "1",
                ["$ignorez"] = "1",
                ["$additive"] = "1"
            })
            lastTreeScrW, lastTreeScrH = scrW, scrH
        end
    end

    -- Noise function for glitch effects (reused from terminal code)
    local function TreeNoise(x, y, t)
        return (math.sin(x * 0.1 + t) + math.cos(y * 0.1 + t * 0.3)) * 0.5
    end

    -- Draw glitched text for tree view
    local function DrawTreeGlitchText(text, font, x, y, color, alignX, alignY, glitchIntensity)
        -- Draw main text
        draw.SimpleText(text, font, x, y, color, alignX, alignY)
        
        -- Draw glitch effects
        if glitchIntensity > 0 then
            -- Small horizontal offset copies with varying alpha
            local alpha = math.min(100, glitchIntensity * 150)
            
            -- Random glitch artifacts
            if glitchIntensity > 0.5 and math.random() < glitchIntensity * 0.2 then
                -- Left ghost
                local offsetX = math.random(-3, 3) * glitchIntensity
                draw.SimpleText(text, font, x + offsetX, y, 
                    Color(color.r, color.g, color.b, alpha * 0.7), alignX, alignY)
            end
            
            -- Random character corruption
            if glitchIntensity > 0.7 and math.random() < glitchIntensity * 0.1 then
                local corruptChars = {"#", "*", "!", "$", "%", "&", "=", "?", "@", "^"}
                local startPos = math.random(1, #text)
                local endPos = math.min(startPos + math.random(0, 2), #text)
                local beforeText = string.sub(text, 1, startPos - 1)
                local corruptChar = corruptChars[math.random(1, #corruptChars)]
                local afterText = string.sub(text, endPos + 1)
                
                local corruptText = beforeText .. corruptChar .. afterText
                draw.SimpleText(corruptText, font, x, y, 
                    Color(color.r + 40, color.g - 40, color.b - 40, color.a), alignX, alignY)
            end
        end
    end

    -- Function to draw the station tree view to render target
    function BakeStationTreeHUD()
        UpdateStationTreeRT()
        
        render.PushRenderTarget(stationTreeRT)
            render.Clear(0, 0, 0, 0)
            cam.Start2D()
                local scrW, scrH = ScrW(), ScrH()
                local boxWidth = 280  -- Smaller than terminal
                local boxHeight = 280 -- Taller to fit tree
                local x = 80         -- Left side of screen
                local y = scrH / 2 - boxHeight / 0.62 -- Center vertically
                local curTime = CurTime()
                
                -- Background with very low opacity
                surface.SetDrawColor(0, 0, 0, 255)
                surface.DrawRect(x, y, boxWidth, boxHeight)
                
                -- Update glitch effects
                treeGlitchTimer = treeGlitchTimer - FrameTime()
                if treeGlitchTimer <= 0 then
                    treeGlitchAmount = math.random() * 0.8
                    treeGlitchTimer = math.random(2, 6)
                end
                
                -- Draw noise-based distortion in background (very subtle)
                for i = 0, boxWidth, 10 do
                    for j = 0, boxHeight, 10 do
                        local noise = TreeNoise(i, j, curTime * 1.5) * 20
                        if math.abs(noise) > 15 then
                            surface.SetDrawColor(30, 30, 40, 40) -- Very low opacity
                            surface.DrawRect(x + i, y + j, 4, 1)
                        end
                    end
                end
                
                -- Draw header
                DrawTreeGlitchText("SYSTEM NETWORK STATUS", "SmallAmmo", 
                    x + 15, y + 15, Color(255, 255, 255, 30), 
                    TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP, treeGlitchAmount * 0.5)
                
                -- Draw tree connector lines (very subtle)
                surface.SetDrawColor(80, 80, 80, 100) -- Very low opacity
                
                -- Vertical connector line
                surface.DrawLine(x + 25, y + 40, x + 25, y + 40 + (#stationTreeData * 20))
                
                -- Draw station status entries
                for i, station in ipairs(stationTreeData) do
                    local stationY = y + 40 + (i-1) * 20
                    
                    -- Horizontal connector to station
                    surface.DrawLine(x + 25, stationY + 7, x + 40, stationY + 7)
                    
                    -- Station name and status
                    local stationText = station.name .. " [" .. station.status .. "]"
                    local glitchIntensity = treeGlitchAmount
                    
                    -- Current station pulses and glitches more
                    if station.status == "CURRENT" then
                        local pulse = (math.sin(curTime * 2) + 1) * 0.5
                        station.color = Color(
                            100,
                            220 * (0.7 + pulse * 0.3),
                            100,
                            80
                        )
                        glitchIntensity = glitchIntensity + math.abs(math.sin(curTime)) * 0.3
                    end
                    
                    DrawTreeGlitchText(stationText, "SmallAmmo", 
                        x + 45, stationY + 5, station.color, 
                        TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP, glitchIntensity)
                    
                    -- Small status ping time (even smaller font/dimmer)
                    DrawTreeGlitchText("LAST: " .. station.lastPing, "Vitals", 
                        x + 70, stationY + 5 + 10, Color(station.color.r, station.color.g, station.color.b, 20), 
                        TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP, glitchIntensity * 0.5)
                end
                
                -- Divider line
                surface.SetDrawColor(80, 80, 80, 8)
                surface.DrawLine(x + 15, y + 45 + (#stationTreeData * 20) + 10, 
                                x + boxWidth - 15, y + 45 + (#stationTreeData * 20) + 10)
                
                -- Draw location information
                local locationStartY = y + 60 + (#stationTreeData * 20) + 10
                for i, location in ipairs(locationData) do
                    local locationY = locationStartY + (i-1) * 25
                    
                    -- Label
                    DrawTreeGlitchText(location.label, "Vitals", 
                        x + 15, locationY, Color(150, 150, 150, 8), 
                        TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP, treeGlitchAmount * 0.3)
                    
                    -- Value
                    local valueGlitch = treeGlitchAmount
                    if location.label == "CURRENT LOCATION" then
                        valueGlitch = valueGlitch + math.abs(math.sin(curTime * 1.5)) * 0.4
                    end
                    
                    DrawTreeGlitchText(location.value, "SmallAmmo", 
                        x + 25, locationY + 12, location.color, 
                        TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP, valueGlitch)
                end
                
            cam.End2D()
        render.PopRenderTarget()
    end

    -- Draw the curved station tree HUD (using same curve method as terminal)
    local function DrawCurvedStationTreeHUD()
        local overlaySegments = 48
        local overlayCurveAmount = 100  -- Positive for convex curve
        
        UpdateStationTreeRT()
        render.SetMaterial(stationTreeMat)
        local scrW, scrH = ScrW(), ScrH()
        
        mesh.Begin(MATERIAL_TRIANGLES, overlaySegments * 2)
            for i = 0, overlaySegments - 1 do
                local u1 = i / overlaySegments
                local u2 = (i + 1) / overlaySegments
                local x1 = u1 * scrW
                local x2 = u2 * scrW
                local offset1 = math.sin(u1 * math.pi) * overlayCurveAmount
                local offset2 = math.sin(u2 * math.pi) * overlayCurveAmount
                
                local yTop1 = 0 + offset1
                local yTop2 = 0 + offset2
                local yBot1 = scrH + offset1
                local yBot2 = scrH + offset2
                
                -- First triangle
                mesh.Position(Vector(x1, yTop1, 0))
                mesh.TexCoord(0, u1, 0)
                mesh.Color(255, 255, 255, 255)
                mesh.AdvanceVertex()
                
                mesh.Position(Vector(x2, yTop2, 0))
                mesh.TexCoord(0, u2, 0)
                mesh.Color(255, 255, 255, 255)
                mesh.AdvanceVertex()
                
                mesh.Position(Vector(x2, yBot2, 0))
                mesh.TexCoord(0, u2, 1)
                mesh.Color(255, 255, 255, 255)
                mesh.AdvanceVertex()
                
                -- Second triangle
                mesh.Position(Vector(x1, yTop1, 0))
                mesh.TexCoord(0, u1, 0)
                mesh.Color(255, 255, 255, 255)
                mesh.AdvanceVertex()
                
                mesh.Position(Vector(x2, yBot2, 0))
                mesh.TexCoord(0, u2, 1)
                mesh.Color(255, 255, 255, 255)
                mesh.AdvanceVertex()
                
                mesh.Position(Vector(x1, yBot1, 0))
                mesh.TexCoord(0, u1, 1)
                mesh.Color(255, 255, 255, 255)
                mesh.AdvanceVertex()
            end
        mesh.End()
    end

    -- Main function to draw the station tree HUD
    function DrawSciFiStationTreeHUD()
        BakeStationTreeHUD()
        DrawCurvedStationTreeHUD()
    end

    -- Add periodic subtle glitches
    timer.Create("StationTreeGlitchTimer", 15, 0, function()
        treeGlitchAmount = math.random(0.2, 1.0)
        treeGlitchTimer = 0.8
    end)

    DrawSciFiAmmoHUD(client)
    DrawSciFiVitalsHUD(client)
    DrawSciFiTerminalHUD() -- Our new terminal HUD
    DrawSciFiStationTreeHUD()

    hook.Run("PostHUDPaint")
end

local elements = {
    ["CHUDQuickInfo"] = true,
    ["CHudAmmo"] = true,
    ["CHudBattery"] = true,
    ["CHudChat"] = true,
    ["CHudCrosshair"] = true,
    ["CHudDamageIndicator"] = true,
    ["CHudGeiger"] = true,
    ["CHudHealth"] = true,
    ["CHudHistoryResource"] = true,
    ["CHudPoisonDamageIndicator"] = true,
    ["CHudSecondaryAmmo"] = true,
    ["CHudSquadStatus"] = true,
    ["CHudSuitPower"] = true,
    ["CHudTrain"] = true,
    ["CHudVehicle"] = true
}

function GM:HUDShouldDraw(name)
    if ( elements[name] ) then
        return false
    end

    return true
end

function GM:LoadFonts()
    local scale4 = ScreenScale(4)
    local scale6 = ScreenScale(6)
    local scale8 = ScreenScale(8)
    local scale10 = ScreenScale(10)
    local scale12 = ScreenScale(12)
    local scale16 = ScreenScale(16)
    local scale20 = ScreenScale(20)
    local scale24 = ScreenScale(24)

    surface.CreateFont("parallax.tiny", {
        font = "GorDIN Regular",
        size = scale4,
        weight = 500,
        antialias = true
    })

    surface.CreateFont("parallax.tiny.bold", {
        font = "GorDIN Bold",
        size = scale4,
        weight = 700,
        antialias = true
    })

    surface.CreateFont("parallax.small", {
        font = "GorDIN Regular",
        size = scale6,
        weight = 500,
        antialias = true
    })

    surface.CreateFont("parallax.small.bold", {
        font = "GorDIN Bold",
        size = scale6,
        weight = 700,
        antialias = true
    })

    surface.CreateFont("parallax", {
        font = "GorDIN Regular",
        size = scale8,
        weight = 500,
        antialias = true
    })

    surface.CreateFont("parallax.bold", {
        font = "GorDIN Bold",
        size = scale8,
        weight = 700,
        antialias = true
    })

    surface.CreateFont("parallax.italic", {
        font = "GorDIN Regular",
        size = ScreenScale(8),
        weight = 500,
        italic = true,
        antialias = true
    })

    surface.CreateFont("parallax.italic.bold", {
        font = "GorDIN Bold",
        size = scale8,
        weight = 700,
        italic = true,
        antialias = true
    })

    surface.CreateFont("parallax.large", {
        font = "GorDIN Regular",
        size = ScreenScale(10),
        weight = 500,
        antialias = true
    })

    surface.CreateFont("parallax.large.bold", {
        font = "GorDIN Bold",
        size = scale10,
        weight = 700,
        antialias = true
    })

    surface.CreateFont("parallax.large.italic", {
        font = "GorDIN Regular",
        size = ScreenScale(10),
        weight = 500,
        italic = true,
        antialias = true
    })

    surface.CreateFont("parallax.large.italic.bold", {
        font = "GorDIN Bold",
        size = scale10,
        weight = 700,
        italic = true,
        antialias = true
    })

    surface.CreateFont("parallax.huge", {
        font = "GorDIN Regular",
        size = scale12,
        weight = 500,
        antialias = true
    })

    surface.CreateFont("parallax.huge.bold", {
        font = "GorDIN Bold",
        size = scale12,
        weight = 700,
        antialias = true
    })

    surface.CreateFont("parallax.huge.italic", {
        font = "GorDIN",
        size = scale12,
        weight = 500,
        italic = true,
        antialias = true
    })

    surface.CreateFont("parallax.huge.italic.bold", {
        font = "GorDIN Bold",
        size = scale12,
        weight = 700,
        italic = true,
        antialias = true
    })

    surface.CreateFont("parallax.button.large", {
        font = "GorDIN SemiBold",
        size = scale20,
        weight = 600,
        antialias = true
    })

    surface.CreateFont("parallax.button.large.hover", {
        font = "GorDIN Bold",
        size = scale20,
        weight = 700,
        antialias = true
    })

    surface.CreateFont("parallax.button", {
        font = "GorDIN SemiBold",
        size = scale16,
        weight = 600,
        antialias = true
    })

    surface.CreateFont("parallax.button.hover", {
        font = "GorDIN Bold",
        size = scale16,
        weight = 700,
        antialias = true
    })

    surface.CreateFont("parallax.button.small", {
        font = "GorDIN SemiBold",
        size = scale12,
        weight = 600,
        antialias = true
    })

    surface.CreateFont("parallax.button.small.hover", {
        font = "GorDIN Bold",
        size = scale12,
        weight = 700,
        antialias = true
    })

    surface.CreateFont("parallax.button.tiny", {
        font = "GorDIN SemiBold",
        size = scale10,
        weight = 600,
        antialias = true
    })

    surface.CreateFont("parallax.button.tiny.hover", {
        font = "GorDIN Bold",
        size = scale10,
        weight = 700,
        antialias = true
    })

    surface.CreateFont("parallax.title", {
        font = "GorDIN Bold",
        size = scale24,
        weight = 700,
        antialias = true,
    })

    surface.CreateFont("parallax.subtitle", {
        font = "GorDIN SemiBold",
        size = scale16,
        weight = 600,
        antialias = true,
    })

    surface.CreateFont("parallax.developer", {
        font = "Courier New",
        size = 16,
        weight = 500,
        antialias = true
    })

    surface.CreateFont("parallax.chat", {
        font = "GorDIN Regular",
        size = ScreenScale(8) * ax.option:Get("chat.size.font", 1),
        weight = 500,
        antialias = true
    })

    hook.Run("PostLoadFonts")
end

function GM:OnPauseMenuShow()
    if ( IsValid(ax.gui.tab) ) then
        ax.gui.tab:Close()
        return false
    end

    if ( IsValid(ax.gui.chatbox) and ax.gui.chatbox:GetAlpha() == 255 ) then
        ax.gui.chatbox:SetVisible(false)
        return false
    end

    if ( !IsValid(ax.gui.mainmenu) ) then
        ax.client:ScreenFade(SCREENFADE.OUT, color_black, 1, 1)
        timer.Simple(1, function()
            vgui.Create("ax.mainmenu")
            ax.gui.mainmenu:SetAlpha(0)
            ax.gui.mainmenu:AlphaTo(255, 1, 0, function()
                ax.client:ScreenFade(SCREENFADE.IN, color_black, 1, 0)
            end)
        end)
    else
        if ( ax.client:GetCharacter() ) then
            ax.gui.mainmenu:Remove()
            return
        end
    end

    return false
end

function GM:PreHUDPaint()
end

function GM:PostHUDPaint()
end

function GM:ShouldDrawCrosshair()
    if ( IsValid(ax.gui.mainmenu) ) then return false end
    if ( IsValid(ax.gui.tab) ) then return false end

    return true
end

function GM:ShouldDrawAmmoBox()
    if ( IsValid(ax.gui.mainmenu) ) then return false end
    if ( IsValid(ax.gui.tab) ) then return false end

    return true
end

function GM:ShouldDrawDebugHUD()
    if ( !ax.config:Get("debug.developer") ) then return false end
    if ( IsValid(ax.gui.mainmenu) ) then return false end
    if ( IsValid(ax.gui.tab) ) then return false end

    return ax.client:IsDeveloper()
end

function GM:ShouldDrawPreviewHUD()
    if ( !ax.config:Get("debug.preview") ) then return false end
    if ( IsValid(ax.gui.mainmenu) ) then return false end
    if ( IsValid(ax.gui.tab) ) then return false end

    return !hook.Run("ShouldDrawDebugHUD")
end

function GM:ShouldDrawVignette()
    if ( IsValid(ax.gui.mainmenu) ) then return false end
    if ( !ax.option:Get("vignette", true) ) then return false end

    return true
end

function GM:ShouldDrawDefaultVignette()
    if ( !IsValid(vignette) ) then
        return false
    end
end

function GM:ShouldShowInventory()
    return true
end

function GM:GetCharacterName(client, target)
    -- TODO: Empty hook, implement this in the future
end

function GM:PopulateTabButtons(buttons)
    if ( CAMI.PlayerHasAccess(ax.client, "Parallax - Manage Config", nil) ) then
        buttons["tab.config"] = {
            Populate = function(this, container)
                container:Add("ax.tab.config")
            end
        }
    end

    buttons["tab.help"] = {
        Populate = function(this, container)
            container:Add("ax.tab.help")
        end
    }

    if ( hook.Run("ShouldShowInventory") != false ) then
        buttons["tab.inventory"] = {
            Populate = function(this, container)
                container:Add("ax.tab.inventory")
            end
        }
    end

    buttons["tab.inventory"] = {
        Populate = function(this, container)
            container:Add("ax.tab.inventory")
        end
    }

    buttons["tab.scoreboard"] = {
        Populate = function(this, container)
            container:Add("ax.tab.scoreboard")
        end
    }

    buttons["tab.settings"] = {
        Populate = function(this, container)
            container:Add("ax.tab.settings")
        end
    }
end

function GM:PopulateHelpCategories(categories)
    categories["flags"] = function(container)
        local scroller = container:Add("DScrollPanel")
        scroller:Dock(FILL)
        scroller:GetVBar():SetWide(0)
        scroller.Paint = nil

        for k, v in SortedPairs(ax.flag.stored) do
            local char = ax.client:GetCharacter()
            if ( !char ) then return end

            local hasFlag = char:HasFlag(k)

            local button = scroller:Add("ax.button.small")
            button:Dock(TOP)
            button:SetText("")
            button:SetBackgroundAlphaHovered(1)
            button:SetBackgroundAlphaUnHovered(0.5)
            button:SetBackgroundColor(hasFlag and ax.color:Get("success") or ax.color:Get("error"))

            local key = button:Add("ax.text")
            key:Dock(LEFT)
            key:DockMargin(ScreenScale(8), 0, 0, 0)
            key:SetFont("parallax.button.hover")
            key:SetText(k)

            local seperator = button:Add("ax.text")
            seperator:Dock(LEFT)
            seperator:SetFont("parallax.button")
            seperator:SetText(" - ")

            local description = button:Add("ax.text")
            description:Dock(LEFT)
            description:SetFont("parallax.button")
            description:SetText(v.description)

            local function Think(this)
                this:SetTextColor(button:GetTextColor())
            end

            key.Think = Think
            seperator.Think = Think
            description.Think = Think
        end
    end
end

-- Idk if this is good
local suggestionIndex = 1
local lastText = ""
local lastSuggestions = {}

function GM:OnChatTab(text)
    if ( !text:StartWith("/") ) then return end

    local split = string.Explode(" ", text)
    local cmd = string.sub(split[1], 2)
    local command = ax.command.stored[cmd]

    if ( command and command.AutoComplete ) then
        if ( text != lastText ) then
            lastSuggestions = command.AutoComplete(ax.client, split) or {}
            suggestionIndex = 1
        else
            suggestionIndex = ( suggestionIndex % #lastSuggestions ) + 1
        end

        lastText = text

        return lastSuggestions[suggestionIndex]
    end
end

function GM:GetChatboxSize()
    local width = ScrW() * 0.4
    local height = ScrH() * 0.35

    return width, height
end

function GM:GetChatboxPos()
    local _, height = self:GetChatboxSize()
    local x = ScrW() * 0.0125
    local y = ScrH() * 0.025
    y = ScrH() - height - y

    return x, y
end

function GM:PlayerBindPress(client, bind, pressed)
    bind = bind:lower()

    if ( bind:find("messagemode") and pressed ) then
        ax.gui.chatbox:SetVisible(true)

        for _, pnl in ipairs(ax.chat.messages) do
            if ( IsValid(pnl) ) then
                pnl.alpha = 1
            end
        end

        return true
    end
end

function GM:StartChat()
end

function GM:FinishChat()
end

function GM:ForceDermaSkin()
    return "Parallax"
end