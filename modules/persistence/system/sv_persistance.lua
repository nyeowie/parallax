local MODULE = MODULE

local savedEntities = {}

--- Saves all persistent entities and their custom data.
function MODULE:SaveEntities()
    ax.log:Send("Saving persistent entities...")

    savedEntities = {}

    for class, methods in pairs(self.PersistentEntities) do
        for _, ent in ipairs(ents.FindByClass(class)) do
            if ( !IsValid(ent) ) then continue end

            local data = methods.Save and methods.Save(ent) or {}

            table.insert(savedEntities, {
                class = class,
                pos = ent:GetPos(),
                ang = ent:GetAngles(),
                mdl = ent:GetModel(),
                data = data
            })
        end
    end

    ax.log:Send("Saved " .. #savedEntities .. " persistent entities.")
    ax.data:Set("persistent_entities", savedEntities)
end

--- Loads all previously saved persistent entities.
function MODULE:LoadEntities()
    ax.log:Send("Loading persistent entities...")

    for k, v in pairs(savedEntities) do
        for _, ent in ipairs(ents.FindByClass(v.class)) do
            if ( ent.axPersistent != true ) then continue end

            SafeRemoveEntity(ent)
        end
    end

    savedEntities = ax.data:Get("persistent_entities", {})

    for _, entData in ipairs(savedEntities) do
        local class = entData.class
        local ent = ents.Create(class)
        if ( !IsValid(ent) ) then continue end

        ent:SetPos(entData.pos)
        ent:SetAngles(entData.ang)

        local mdl = Model(entData.mdl)
        ent:SetModel(mdl)

        ent:Spawn()
        ent:Activate()

        local handler = self.PersistentEntities[class]
        if ( handler and handler.Load and entData.data ) then
            handler.Load(ent, entData.data)
        end

        ent.axPersistent = true
    end

    ax.log:Send("Loaded " .. #savedEntities .. " persistent entities.")
end

concommand.Add("ax_persistence_save", function(client, cmd, arguments)
    if ( IsValid(client) and !client:IsAdmin() ) then
        client:Notify("You do not have permission to use this command!")
        return
    end

    MODULE:SaveEntities()
    ax.log:Send(ax.log:Format(client) .. " manually saved all persistent entities.")
    client:Notify("Saved all persistent entities.")
end)

concommand.Add("ax_persistence_load", function(client, cmd, arguments)
    if ( IsValid(client) and !client:IsAdmin() ) then
        client:Notify("You do not have permission to use this command!")
        return
    end

    MODULE:LoadEntities()
    ax.log:Send(ax.log:Format(client) .. " manually loaded all persistent entities.")
    client:Notify("Loaded all persistent entities.")
end)

concommand.Add("ax_persistence_mark", function(client, cmd, arguments)
    if ( !IsValid(client) or !client:IsAdmin() ) then
        client:Notify("You do not have permission to use this command!")
        return
    end

    local ent = client:GetEyeTrace().Entity
    if ( !IsValid(ent) ) then return end

    ent.axPersistent = true
    ax.log:Send(ax.log:Format(client) .. " marked entity " .. tostring(ent) .. " as persistent.")
    client:Notify("Marked entity " .. tostring(ent) .. " as persistent.")
end)