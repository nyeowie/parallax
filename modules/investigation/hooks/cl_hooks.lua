
local activeSubtitles = {}
local fadingMarkers = {}
local MODULE = MODULE -- Reference to the parent module

net.Receive("InvestigationPoint_Display", function()
    local entity = net.ReadEntity()
    
    if IsValid(entity) then
        local title = entity:GetNWString("Title")
        local description = entity:GetNWString("Description")
        local soundPath = entity:GetNWString("SoundPath", "buttons/button15.wav")
        local subtitleDuration = entity:GetNWFloat("SubtitleDuration", 7)
        
        -- Add to active subtitles
        local id = #activeSubtitles + 1
        activeSubtitles[id] = {
            title = title,
            description = description,
            startTime = CurTime(),
            endTime = CurTime() + subtitleDuration,
            duration = subtitleDuration,
            alpha = 0
        }
        
        -- Play sound on the client if a sound path is provided
        if soundPath and soundPath ~= "" then
            -- Create a localized sound source
            local emitter = LocalPlayer()
            sound.Play(soundPath, emitter:GetPos(), 75, 100, 1)
        end
    end
end)

-- Draw floating markers and handle fading
hook.Add("PostDrawTranslucentRenderables", "DrawInvestigationMarkers", function()
    local ply = LocalPlayer()
    if not IsValid(ply) then return end
    
    local playerPos = ply:GetPos()
    local playerAngle = ply:EyeAngles()
    
    -- Draw markers for all investigation points
    for _, entity in pairs(ents.FindByClass("investigation_point")) do
        if IsValid(entity) then
            local entPos = entity:GetPos() + Vector(0, 0, 30) -- Offset marker a bit above the entity
            local dist = playerPos:Distance(entPos)
            
            -- Only process if within max fade distance
            if dist <= MODULE.config.fadeDistance then
                -- Calculate alpha based on distance
                local alpha = 255 * (1 - math.Clamp((dist - MODULE.config.fullVisibleDistance) / 
                                    (MODULE.config.fadeDistance - MODULE.config.fullVisibleDistance), 0, 1))
                
                -- Store in fading markers table for use in HUD drawing
                fadingMarkers[entity:EntIndex()] = {
                    pos = entPos,
                    alpha = alpha,
                    entity = entity
                }
                
                -- Calculate angle to face the player
                local angle = (playerPos - entPos):Angle()
                angle:RotateAroundAxis(angle:Up(), 100)
                
                -- Draw 3D text
                cam.Start3D2D(entPos, Angle(0, angle.y, 90), 0.4)
                    -- Shadow for better visibility
                    draw.SimpleText(MODULE.config.markerText, MODULE.config.markerFont, 2, 2, Color(0, 0, 0, alpha * 0.5), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
                    draw.SimpleText(MODULE.config.markerText, MODULE.config.markerFont, 0, 0, Color(255, 255, 255, alpha), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
                cam.End3D2D()
            else
                -- Remove from fading markers if exists but too far
                fadingMarkers[entity:EntIndex()] = nil
            end
        end
    end
end)

net.Receive("InvestigationPoint_OpenEditor", function()
    local entity = net.ReadEntity()
    local title = net.ReadString()
    local description = net.ReadString()
    local soundPath = net.ReadString()
    local fadeDistance = net.ReadFloat()
    local fullVisibleDistance = net.ReadFloat()
    local subtitleDuration = net.ReadFloat()
    
    if not IsValid(entity) then return end
    
    -- Create the VGUI
    local frame = vgui.Create("DFrame")
    frame:SetSize(600, 600)
    frame:SetTitle("Edit Investigation Point")
    frame:Center()
    frame:MakePopup()
    
    -- Title label
    local titleLabel = vgui.Create("DLabel", frame)
    titleLabel:SetPos(20, 30)
    titleLabel:SetSize(560, 20)
    titleLabel:SetText("Title:")
    
    -- Title input
    local titleInput = vgui.Create("DTextEntry", frame)
    titleInput:SetPos(20, 50)
    titleInput:SetSize(560, 30)
    titleInput:SetText(title)
    titleInput:SetPlaceholderText("Enter the investigation point title...")
    
    -- Description label
    local descLabel = vgui.Create("DLabel", frame)
    descLabel:SetPos(20, 90)
    descLabel:SetSize(560, 20)
    descLabel:SetText("Description:")
    
    -- Description input (multiline with no character limit)
    local descInput = vgui.Create("DTextEntry", frame)
    descInput:SetPos(20, 110)
    descInput:SetSize(560, 150)
    descInput:SetText(description)
    descInput:SetPlaceholderText("Enter the investigation point description...")
    descInput:SetMultiline(true)
    descInput:SetUpdateOnType(true)
    -- Remove character limit
    descInput.OnTextChanged = function() end
    descInput:SetMaximumCharCount(9999)
    
    -- Sound path label
    local soundLabel = vgui.Create("DLabel", frame)
    soundLabel:SetPos(20, 270)
    soundLabel:SetSize(560, 20)
    soundLabel:SetText("Sound Path:")
    
    -- Sound path input
    local soundInput = vgui.Create("DTextEntry", frame)
    soundInput:SetPos(20, 290)
    soundInput:SetSize(410, 30)
    soundInput:SetText(soundPath)
    soundInput:SetPlaceholderText("Enter the sound path to play when interacted with (can be empty)...")
    
    -- Currently playing sound channel
    local currentSoundChannel = nil
    
    -- Test sound button
    local testSoundBtn = vgui.Create("DButton", frame)
    testSoundBtn:SetPos(440, 290)
    testSoundBtn:SetSize(70, 30)
    testSoundBtn:SetText("Test")
    testSoundBtn.DoClick = function()
        local soundPath = soundInput:GetValue()
        if soundPath and soundPath ~= "" then
            -- Stop any currently playing sound first
            if currentSoundChannel then
                currentSoundChannel:Stop()
            end
            
            -- Play and store the channel
            currentSoundChannel = CreateSound(LocalPlayer(), soundPath)
            if currentSoundChannel then
                currentSoundChannel:Play()
            else
                surface.PlaySound(soundPath)
            end
        end
    end
    
    -- Stop sound button
    local stopSoundBtn = vgui.Create("DButton", frame)
    stopSoundBtn:SetPos(520, 290)
    stopSoundBtn:SetSize(60, 30)
    stopSoundBtn:SetText("Stop")
    stopSoundBtn.DoClick = function()
        if currentSoundChannel then
            currentSoundChannel:Stop()
            currentSoundChannel = nil
        end
    end
    
    -- Visibility settings
    local visibilityLabel = vgui.Create("DLabel", frame)
    visibilityLabel:SetPos(20, 330)
    visibilityLabel:SetSize(560, 20)
    visibilityLabel:SetText("Visibility Settings:")
    
    -- Fade distance label
    local fadeDistLabel = vgui.Create("DLabel", frame)
    fadeDistLabel:SetPos(20, 360)
    fadeDistLabel:SetSize(200, 20)
    fadeDistLabel:SetText("Fade Distance:")
    
    -- Fade distance slider
    local fadeDistSlider = vgui.Create("DNumSlider", frame)
    fadeDistSlider:SetPos(20, 380)
    fadeDistSlider:SetSize(560, 30)
    fadeDistSlider:SetMin(100)
    fadeDistSlider:SetMax(1000)
    fadeDistSlider:SetDecimals(0)
    fadeDistSlider:SetValue(fadeDistance)
    
    -- Full visible distance label
    local fullVisLabel = vgui.Create("DLabel", frame)
    fullVisLabel:SetPos(20, 410)
    fullVisLabel:SetSize(200, 20)
    fullVisLabel:SetText("Full Visible Distance:")
    
    -- Full visible distance slider
    local fullVisSlider = vgui.Create("DNumSlider", frame)
    fullVisSlider:SetPos(20, 430)
    fullVisSlider:SetSize(560, 30)
    fullVisSlider:SetMin(50)
    fullVisSlider:SetMax(500)
    fullVisSlider:SetDecimals(0)
    fullVisSlider:SetValue(fullVisibleDistance)
    
    -- Subtitle duration label
    local durationLabel = vgui.Create("DLabel", frame)
    durationLabel:SetPos(20, 460)
    durationLabel:SetSize(200, 20)
    durationLabel:SetText("Subtitle Duration (seconds):")
    
    -- Subtitle duration slider
    local durationSlider = vgui.Create("DNumSlider", frame)
    durationSlider:SetPos(20, 480)
    durationSlider:SetSize(560, 30)
    durationSlider:SetMin(1)
    durationSlider:SetMax(20)
    durationSlider:SetDecimals(1)
    durationSlider:SetValue(subtitleDuration)
    
    -- Preview label
    local previewLabel = vgui.Create("DLabel", frame)
    previewLabel:SetPos(20, 510)
    previewLabel:SetSize(560, 20)
    previewLabel:SetText("Preview:")
    
    -- Preview panel
    local previewPanel = vgui.Create("DPanel", frame)
    previewPanel:SetPos(20, 530)
    previewPanel:SetSize(560, 60)
    
    previewPanel.Paint = function(self, w, h)
        draw.RoundedBox(4, 0, 0, w, h, Color(30, 30, 30))
        
        local title = titleInput:GetValue() ~= "" and titleInput:GetValue() or "Preview Title"
        local desc = descInput:GetValue() ~= "" and descInput:GetValue() or "Preview description text will appear here..."
        
        -- Draw title
        draw.SimpleText(title, "InvestigationTitle", w/2, 5, Color(255, 255, 255), TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP)
        
        -- Draw description (simplified preview)
        draw.SimpleText(desc:sub(1, 50) .. (desc:len() > 50 and "..." or ""), "InvestigationText", w/2, 35, Color(200, 200, 200), TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP)
    end
    
    -- Save button
    local saveBtn = vgui.Create("DButton", frame)
    saveBtn:SetPos(20, 600)
    saveBtn:SetSize(270, 30)
    saveBtn:SetText("Save Changes")
    saveBtn.DoClick = function()
        local title = titleInput:GetValue()
        local desc = descInput:GetValue()
        local soundPath = soundInput:GetValue()
        local fadeDistance = fadeDistSlider:GetValue()
        local fullVisibleDistance = fullVisSlider:GetValue()
        local subtitleDuration = durationSlider:GetValue()
        
        -- Remove sound path validation
        if title == "" then
            notification.AddLegacy("Title cannot be empty!", NOTIFY_ERROR, 3)
            return
        end
        
        if desc == "" then
            notification.AddLegacy("Description cannot be empty!", NOTIFY_ERROR, 3)
            return
        end
        
        -- Send to server
        net.Start("InvestigationPoint_Edit")
        net.WriteEntity(entity)
        net.WriteString(title)
        net.WriteString(desc)
        net.WriteString(soundPath)
        net.WriteFloat(fadeDistance)
        net.WriteFloat(fullVisibleDistance)
        net.WriteFloat(subtitleDuration)
        net.SendToServer()
        
        frame:Close()
    end
    
    -- Cancel button
    local cancelBtn = vgui.Create("DButton", frame)
    cancelBtn:SetPos(310, 600)
    cancelBtn:SetSize(270, 30)
    cancelBtn:SetText("Cancel")
    cancelBtn.DoClick = function()
        frame:Close()
    end
    
    -- Make the frame taller to accommodate all the new controls
    frame:SetTall(640)
end)

net.Receive("InvestigationPoint_OpenCreator", function()
    -- Create the VGUI
    local frame = vgui.Create("DFrame")
    frame:SetSize(600, 600)
    frame:SetTitle("Create Investigation Point")
    frame:Center()
    frame:MakePopup()
    
    -- Title label
    local titleLabel = vgui.Create("DLabel", frame)
    titleLabel:SetPos(20, 30)
    titleLabel:SetSize(560, 20)
    titleLabel:SetText("Title:")
    
    -- Title input
    local titleInput = vgui.Create("DTextEntry", frame)
    titleInput:SetPos(20, 50)
    titleInput:SetSize(560, 30)
    titleInput:SetPlaceholderText("Enter the investigation point title...")
    
    -- Description label
    local descLabel = vgui.Create("DLabel", frame)
    descLabel:SetPos(20, 90)
    descLabel:SetSize(560, 20)
    descLabel:SetText("Description:")
    
    -- Description input (multiline with no character limit)
    local descInput = vgui.Create("DTextEntry", frame)
    descInput:SetPos(20, 110)
    descInput:SetSize(560, 150)
    descInput:SetPlaceholderText("Enter the investigation point description...")
    descInput:SetMultiline(true)
    descInput:SetUpdateOnType(true)
    -- Remove character limit
    descInput.OnTextChanged = function() end
    descInput:SetMaximumCharCount(9999)
    
    -- Sound path label
    local soundLabel = vgui.Create("DLabel", frame)
    soundLabel:SetPos(20, 270)
    soundLabel:SetSize(560, 20)
    soundLabel:SetText("Sound Path:")
    
    -- Sound path input
    local soundInput = vgui.Create("DTextEntry", frame)
    soundInput:SetPos(20, 290)
    soundInput:SetSize(410, 30)
    soundInput:SetText("buttons/button15.wav")
    soundInput:SetPlaceholderText("Enter the sound path to play when interacted with (can be empty)...")
    
    -- Currently playing sound channel
    local currentSoundChannel = nil
    
    -- Test sound button
    local testSoundBtn = vgui.Create("DButton", frame)
    testSoundBtn:SetPos(440, 290)
    testSoundBtn:SetSize(70, 30)
    testSoundBtn:SetText("Test")
    testSoundBtn.DoClick = function()
        local soundPath = soundInput:GetValue()
        if soundPath and soundPath ~= "" then
            -- Stop any currently playing sound first
            if currentSoundChannel then
                currentSoundChannel:Stop()
            end
            
            -- Play and store the channel
            currentSoundChannel = CreateSound(LocalPlayer(), soundPath)
            if currentSoundChannel then
                currentSoundChannel:Play()
            else
                surface.PlaySound(soundPath)
            end
        end
    end
    
    -- Stop sound button
    local stopSoundBtn = vgui.Create("DButton", frame)
    stopSoundBtn:SetPos(520, 290)
    stopSoundBtn:SetSize(60, 30)
    stopSoundBtn:SetText("Stop")
    stopSoundBtn.DoClick = function()
        if currentSoundChannel then
            currentSoundChannel:Stop()
            currentSoundChannel = nil
        end
    end
    
    -- Visibility settings
    local visibilityLabel = vgui.Create("DLabel", frame)
    visibilityLabel:SetPos(20, 330)
    visibilityLabel:SetSize(560, 20)
    visibilityLabel:SetText("Visibility Settings:")
    
    -- Fade distance label
    local fadeDistLabel = vgui.Create("DLabel", frame)
    fadeDistLabel:SetPos(20, 360)
    fadeDistLabel:SetSize(200, 20)
    fadeDistLabel:SetText("Fade Distance:")
    
    -- Fade distance slider
    local fadeDistSlider = vgui.Create("DNumSlider", frame)
    fadeDistSlider:SetPos(20, 380)
    fadeDistSlider:SetSize(560, 30)
    fadeDistSlider:SetMin(100)
    fadeDistSlider:SetMax(1000)
    fadeDistSlider:SetDecimals(0)
    fadeDistSlider:SetValue(300)
    
    -- Full visible distance label
    local fullVisLabel = vgui.Create("DLabel", frame)
    fullVisLabel:SetPos(20, 410)
    fullVisLabel:SetSize(200, 20)
    fullVisLabel:SetText("Full Visible Distance:")
    
    -- Full visible distance slider
    local fullVisSlider = vgui.Create("DNumSlider", frame)
    fullVisSlider:SetPos(20, 430)
    fullVisSlider:SetSize(560, 30)
    fullVisSlider:SetMin(50)
    fullVisSlider:SetMax(500)
    fullVisSlider:SetDecimals(0)
    fullVisSlider:SetValue(150)
    
    -- Subtitle duration label
    local durationLabel = vgui.Create("DLabel", frame)
    durationLabel:SetPos(20, 460)
    durationLabel:SetSize(200, 20)
    durationLabel:SetText("Subtitle Duration (seconds):")
    
    -- Subtitle duration slider
    local durationSlider = vgui.Create("DNumSlider", frame)
    durationSlider:SetPos(20, 480)
    durationSlider:SetSize(560, 30)
    durationSlider:SetMin(1)
    durationSlider:SetMax(20)
    durationSlider:SetDecimals(1)
    durationSlider:SetValue(7)
    
    -- Preview label
    local previewLabel = vgui.Create("DLabel", frame)
    previewLabel:SetPos(20, 510)
    previewLabel:SetSize(560, 20)
    previewLabel:SetText("Preview:")
    
    -- Preview panel
    local previewPanel = vgui.Create("DPanel", frame)
    previewPanel:SetPos(20, 530)
    previewPanel:SetSize(560, 60)
    
    previewPanel.Paint = function(self, w, h)
        draw.RoundedBox(4, 0, 0, w, h, Color(30, 30, 30))
        
        local title = titleInput:GetValue() ~= "" and titleInput:GetValue() or "Preview Title"
        local desc = descInput:GetValue() ~= "" and descInput:GetValue() or "Preview description text will appear here..."
        
        -- Draw title
        draw.SimpleText(title, "InvestigationTitle", w/2, 5, Color(255, 255, 255), TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP)
        
        -- Draw description (simplified preview)
        draw.SimpleText(desc:sub(1, 50) .. (desc:len() > 50 and "..." or ""), "InvestigationText", w/2, 35, Color(200, 200, 200), TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP)
    end
    
    -- Create button
    local createBtn = vgui.Create("DButton", frame)
    createBtn:SetPos(20, 600)
    createBtn:SetSize(270, 30)
    createBtn:SetText("Create at Crosshair")
    createBtn.DoClick = function()
        local title = titleInput:GetValue()
        local desc = descInput:GetValue()
        local soundPath = soundInput:GetValue()
        local fadeDistance = fadeDistSlider:GetValue()
        local fullVisibleDistance = fullVisSlider:GetValue()
        local subtitleDuration = durationSlider:GetValue()
        
        -- Remove sound path empty validation
        if title == "" then
            notification.AddLegacy("Title cannot be empty!", NOTIFY_ERROR, 3)
            return
        end
        
        if desc == "" then
            notification.AddLegacy("Description cannot be empty!", NOTIFY_ERROR, 3)
            return
        end
        
        -- Send to server
        net.Start("InvestigationPoint_Create")
        net.WriteString(title)
        net.WriteString(desc)
        net.WriteString(soundPath)
        net.WriteFloat(fadeDistance)
        net.WriteFloat(fullVisibleDistance)
        net.WriteFloat(subtitleDuration)
        net.SendToServer()
        
        frame:Close()
    end
    
    -- Cancel button
    local cancelBtn = vgui.Create("DButton", frame)
    cancelBtn:SetPos(310, 600)
    cancelBtn:SetSize(270, 30)
    cancelBtn:SetText("Cancel")
    cancelBtn.DoClick = function()
        frame:Close()
    end
    
    -- Make the frame taller to accommodate all the new controls
    frame:SetTall(640)
end)

-- Handle player looking at and pressing E on a marker
hook.Add("KeyPress", "InvestigationPointInteraction", function(ply, key)
    if key == MODULE.config.useKey and IsValid(ply) and ply == LocalPlayer() then
        -- Check if player is looking at an investigation point
        local trace = ply:GetEyeTrace()
        if not trace.Entity or not IsValid(trace.Entity) or trace.Entity:GetClass() != "investigation_point" then return end
        
        -- Check if within interaction distance
        if trace.HitPos:Distance(ply:GetPos()) > 100 then return end
        
        -- Already handled by server's Use function
    end
end)

-- Draw subtitles
hook.Add("HUDPaint", "DrawInvestigationSubtitles", function()
    local curTime = CurTime()
    local screenW, screenH = ScrW(), ScrH()
    
    -- Remove expired subtitles
    for id, subtitle in pairs(activeSubtitles) do
        if curTime > subtitle.endTime then
            activeSubtitles[id] = nil
        end
    end
    
    -- Draw active subtitles
    for _, subtitle in pairs(activeSubtitles) do
        -- Calculate fade in/out
        local timeProgress = (curTime - subtitle.startTime) / subtitle.duration
        local alpha = 255
        
        -- Fade in for first 10% of duration
        if timeProgress < 0.1 then
            alpha = math.Clamp(255 * (timeProgress / 0.1), 0, 255)
        -- Fade out for last 20% of duration
        elseif timeProgress > 0.8 then
            alpha = math.Clamp(255 * (1 - (timeProgress - 0.8) / 0.2), 0, 255)
        end
        
        -- Draw title and description
        local titleY = screenH * 0.75
        local titleFont = "DisclaimerFont"
        local descFont = "SmallAmmo"
        
        -- Draw title
        draw.SimpleText(subtitle.title, titleFont, screenW / 2, titleY, Color(255, 255, 255, alpha), TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP)
        
        -- Draw description (wrapped text)
        local descY = titleY + 40
        local descWidth = screenW * 0.5
        
        -- Wrap text and draw each line
        local descLines = {}
        local words = string.Explode(" ", subtitle.description)
        local currentLine = ""
        
        surface.SetFont(descFont)
        for _, word in ipairs(words) do
            local testLine = currentLine .. " " .. word
            local width = surface.GetTextSize(testLine)
            
            if width > descWidth then
                table.insert(descLines, currentLine)
                currentLine = word
            else
                if currentLine == "" then
                    currentLine = word
                else
                    currentLine = testLine
                end
            end
        end
        
        -- Add the last line
        if currentLine != "" then
            table.insert(descLines, currentLine)
        end
        
        -- Draw each line centered
        for i, line in ipairs(descLines) do
            draw.SimpleText(line, descFont, screenW / 2, descY + ((i-1) * 25), Color(200, 200, 200, alpha), TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP)
        end
    end
end)