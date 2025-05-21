util.AddNetworkString("InvestigationPoint_Display")
util.AddNetworkString("InvestigationPoint_OpenCreator") -- For VGUI
util.AddNetworkString("InvestigationPoint_Create") -- For VGUI
util.AddNetworkString("InvestigationPoint_OpenEditor") -- For VGUI
util.AddNetworkString("InvestigationPoint_Edit") -- For VGUI

hook.Add("Initialize", "IncreaseNetMessageSize", function()
    net.SetMaxFileSize(65536) -- Increase to 64KB, should be enough for descriptions
end)

-- Save investigation points to a file when the server shuts down
hook.Add("ShutDown", "SaveInvestigationPoints", function()
    local points = {}
    
    for _, ent in pairs(ents.FindByClass("investigation_point")) do
        if IsValid(ent) then
            table.insert(points, {
                pos = ent:GetPos(),
                title = ent:GetNWString("Title"),
                description = ent:GetNWString("Description"),
                soundPath = ent:GetNWString("SoundPath", "buttons/button15.wav"),
                fadeDistance = ent:GetNWFloat("FadeDistance", 300),
                fullVisibleDistance = ent:GetNWFloat("FullVisibleDistance", 150),
                subtitleDuration = ent:GetNWFloat("SubtitleDuration", 7)
            })
        end
    end
    
    if #points > 0 then
        file.CreateDir("investigation_points")
        file.Write("investigation_points/saved_points.json", util.TableToJSON(points, true))
        print("[Investigation Points] Saved " .. #points .. " investigation points.")
    end
end)

-- Load investigation points when the server initializes
hook.Add("InitPostEntity", "LoadInvestigationPoints", function()
    timer.Simple(1, function() -- Small delay to ensure map is fully loaded
        if file.Exists("investigation_points/saved_points.json", "DATA") then
            local points = util.JSONToTable(file.Read("investigation_points/saved_points.json", "DATA"))
            
            if points then
                for _, data in pairs(points) do
                    local point = ents.Create("investigation_point")
                    
                    if IsValid(point) then
                        point:SetPos(data.pos)
                        point:Spawn()
                        
                        -- Set properties after spawn
                        point:SetNWString("Title", data.title)
                        point:SetNWString("Description", data.description)
                        
                        -- Set optional properties with fallbacks
                        point:SetNWString("SoundPath", data.soundPath or "buttons/button15.wav")
                        point:SetNWFloat("FadeDistance", data.fadeDistance or 300)
                        point:SetNWFloat("FullVisibleDistance", data.fullVisibleDistance or 150)
                        point:SetNWFloat("SubtitleDuration", data.subtitleDuration or 7)
                    end
                end
                
                print("[Investigation Points] Loaded " .. #points .. " investigation points.")
            end
        end
    end)
end)

net.Receive("InvestigationPoint_Create", function(len, client)
    if not client:IsAdmin() then return end
    
    local title = net.ReadString()
    local description = net.ReadString()
    local soundPath = net.ReadString()
    local fadeDistance = net.ReadFloat()
    local fullVisibleDistance = net.ReadFloat()
    local subtitleDuration = net.ReadFloat()
    
    -- Create the entity
    local trace = client:GetEyeTrace()
    local point = ents.Create("investigation_point")
    
    if IsValid(point) then
        point:SetPos(trace.HitPos + Vector(0, 0, 10))
        point:Spawn()
        
        -- Set properties after spawn
        point:SetNWString("Title", title)
        point:SetNWString("Description", description)
        point:SetNWString("SoundPath", soundPath)
        point:SetNWFloat("FadeDistance", fadeDistance)
        point:SetNWFloat("FullVisibleDistance", fullVisibleDistance)
        point:SetNWFloat("SubtitleDuration", subtitleDuration)
        
        client:Notify("Created investigation point: " .. title, NOTIFY_HINT)
    end
end)

-- Handle edit requests from the VGUI
net.Receive("InvestigationPoint_Edit", function(len, client)
    if not client:IsAdmin() then return end
    
    local entity = net.ReadEntity()
    local title = net.ReadString()
    local description = net.ReadString()
    local soundPath = net.ReadString()
    local fadeDistance = net.ReadFloat()
    local fullVisibleDistance = net.ReadFloat()
    local subtitleDuration = net.ReadFloat()
    
    if IsValid(entity) and entity:GetClass() == "investigation_point" then
        entity:SetNWString("Title", title)
        entity:SetNWString("Description", description)
        entity:SetNWString("SoundPath", soundPath)
        entity:SetNWFloat("FadeDistance", fadeDistance)
        entity:SetNWFloat("FullVisibleDistance", fullVisibleDistance)
        entity:SetNWFloat("SubtitleDuration", subtitleDuration)
        
        client:Notify("Updated investigation point: " .. title, NOTIFY_HINT)
    end
end)


net.Receive("InvestigationPoint_OpenEditor", function(len, client)
    if not client:IsAdmin() then return end
    
    -- Find closest point
    local closestPoint = nil
    local closestDist = 300 -- Max distance for editing
    local clientPos = client:GetPos()
    
    for _, ent in pairs(ents.FindByClass("investigation_point")) do
        if IsValid(ent) then
            local dist = clientPos:Distance(ent:GetPos())
            if dist < closestDist then
                closestDist = dist
                closestPoint = ent
            end
        end
    end
    
    if IsValid(closestPoint) then
        -- Send the entity info to the client for editing
        net.Start("InvestigationPoint_OpenEditor")
        net.WriteEntity(closestPoint)
        net.WriteString(closestPoint:GetNWString("Title", ""))
        net.WriteString(closestPoint:GetNWString("Description", ""))
        net.WriteString(closestPoint:GetNWString("SoundPath", "buttons/button15.wav"))
        net.WriteFloat(closestPoint:GetNWFloat("FadeDistance", 300))
        net.WriteFloat(closestPoint:GetNWFloat("FullVisibleDistance", 150))
        net.WriteFloat(closestPoint:GetNWFloat("SubtitleDuration", 7))
        net.Send(client)
    else
        client:Notify("No investigation points found nearby.", NOTIFY_ERROR)
    end
end)

util.AddNetworkString("InvestigationPoint_Display")
util.AddNetworkString("InvestigationPoint_OpenCreator") -- For VGUI
util.AddNetworkString("InvestigationPoint_Create") -- For VGUI
util.AddNetworkString("InvestigationPoint_OpenEditor") -- For VGUI
util.AddNetworkString("InvestigationPoint_Edit") -- For VGUI

-- Save investigation points to a file when the server shuts down
hook.Add("ShutDown", "SaveInvestigationPoints", function()
    local points = {}
    
    for _, ent in pairs(ents.FindByClass("investigation_point")) do
        if IsValid(ent) then
            table.insert(points, {
                pos = ent:GetPos(),
                title = ent:GetNWString("Title"),
                description = ent:GetNWString("Description"),
                soundPath = ent:GetNWString("SoundPath", "buttons/button15.wav"),
                fadeDistance = ent:GetNWFloat("FadeDistance", 300),
                fullVisibleDistance = ent:GetNWFloat("FullVisibleDistance", 150),
                subtitleDuration = ent:GetNWFloat("SubtitleDuration", 7)
            })
        end
    end
    
    if #points > 0 then
        file.CreateDir("investigation_points")
        file.Write("investigation_points/saved_points.json", util.TableToJSON(points, true))
        print("[Investigation Points] Saved " .. #points .. " investigation points.")
    end
end)

-- Load investigation points when the server initializes
hook.Add("InitPostEntity", "LoadInvestigationPoints", function()
    timer.Simple(1, function() -- Small delay to ensure map is fully loaded
        if file.Exists("investigation_points/saved_points.json", "DATA") then
            local points = util.JSONToTable(file.Read("investigation_points/saved_points.json", "DATA"))
            
            if points then
                for _, data in pairs(points) do
                    local point = ents.Create("investigation_point")
                    
                    if IsValid(point) then
                        point:SetPos(data.pos)
                        point:Spawn()
                        
                        -- Set properties after spawn
                        point:SetNWString("Title", data.title)
                        point:SetNWString("Description", data.description)
                        
                        -- Set optional properties with fallbacks
                        point:SetNWString("SoundPath", data.soundPath or "buttons/button15.wav")
                        point:SetNWFloat("FadeDistance", data.fadeDistance or 300)
                        point:SetNWFloat("FullVisibleDistance", data.fullVisibleDistance or 150)
                        point:SetNWFloat("SubtitleDuration", data.subtitleDuration or 7)
                    end
                end
                
                print("[Investigation Points] Loaded " .. #points .. " investigation points.")
            end
        end
    end)
end)

net.Receive("InvestigationPoint_Create", function(len, client)
    if not client:IsAdmin() then return end
    
    local title = net.ReadString()
    local description = net.ReadString()
    local soundPath = net.ReadString()
    local fadeDistance = net.ReadFloat()
    local fullVisibleDistance = net.ReadFloat()
    local subtitleDuration = net.ReadFloat()
    
    -- Create the entity
    local trace = client:GetEyeTrace()
    local point = ents.Create("investigation_point")
    
    if IsValid(point) then
        point:SetPos(trace.HitPos + Vector(0, 0, 10))
        point:Spawn()
        
        -- Set properties after spawn
        point:SetNWString("Title", title)
        point:SetNWString("Description", description)
        point:SetNWString("SoundPath", soundPath)
        point:SetNWFloat("FadeDistance", fadeDistance)
        point:SetNWFloat("FullVisibleDistance", fullVisibleDistance)
        point:SetNWFloat("SubtitleDuration", subtitleDuration)
        
        client:Notify("Created investigation point: " .. title, NOTIFY_HINT)
    end
end)

-- Handle edit requests from the VGUI
net.Receive("InvestigationPoint_Edit", function(len, client)
    if not client:IsAdmin() then return end
    
    local entity = net.ReadEntity()
    local title = net.ReadString()
    local description = net.ReadString()
    local soundPath = net.ReadString()
    local fadeDistance = net.ReadFloat()
    local fullVisibleDistance = net.ReadFloat()
    local subtitleDuration = net.ReadFloat()
    
    if IsValid(entity) and entity:GetClass() == "investigation_point" then
        entity:SetNWString("Title", title)
        entity:SetNWString("Description", description)
        entity:SetNWString("SoundPath", soundPath)
        entity:SetNWFloat("FadeDistance", fadeDistance)
        entity:SetNWFloat("FullVisibleDistance", fullVisibleDistance)
        entity:SetNWFloat("SubtitleDuration", subtitleDuration)
        
        client:Notify("Updated investigation point: " .. title, NOTIFY_HINT)
    end
end)


net.Receive("InvestigationPoint_OpenEditor", function(len, client)
    if not client:IsAdmin() then return end
    
    -- Find closest point
    local closestPoint = nil
    local closestDist = 300 -- Max distance for editing
    local clientPos = client:GetPos()
    
    for _, ent in pairs(ents.FindByClass("investigation_point")) do
        if IsValid(ent) then
            local dist = clientPos:Distance(ent:GetPos())
            if dist < closestDist then
                closestDist = dist
                closestPoint = ent
            end
        end
    end
    
    if IsValid(closestPoint) then
        -- Send the entity info to the client for editing
        net.Start("InvestigationPoint_OpenEditor")
        net.WriteEntity(closestPoint)
        net.WriteString(closestPoint:GetNWString("Title", ""))
        net.WriteString(closestPoint:GetNWString("Description", ""))
        net.WriteString(closestPoint:GetNWString("SoundPath", "buttons/button15.wav"))
        net.WriteFloat(closestPoint:GetNWFloat("FadeDistance", 300))
        net.WriteFloat(closestPoint:GetNWFloat("FullVisibleDistance", 150))
        net.WriteFloat(closestPoint:GetNWFloat("SubtitleDuration", 7))
        net.Send(client)
    else
        client:Notify("No investigation points found nearby.", NOTIFY_ERROR)
    end
end)

