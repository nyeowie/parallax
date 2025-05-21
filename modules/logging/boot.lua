local MODULE = MODULE

MODULE.Name = "Logging"
MODULE.Description = "Adds some sort of logging system."
MODULE.Author = "Riggs"

ax.config:Register("logging", {
    Name = "Logging",
    Description = "Enable or disable the logging system.",
    Type = ax.types.bool,
    Default = true
})

CAMI.RegisterPrivilege({
    Name = "Parallax - Logging",
    MinAccess = "admin"
})

function MODULE:FormatPlayer(client)
    if ( !IsValid(client) ) then return "Console" end

    return client:SteamName() .. " [" .. client:EntIndex() .. "][" .. client:SteamID64() .. "]"
end

function MODULE:Format(ent)
    if ( !IsValid(ent) or ent == Entity(0) ) then return "world" end

    if ( ent:IsPlayer() ) then
        return self:FormatPlayer(ent)
    end

    local tag = ent:GetModel()
    local name = ent.GetPrintName and ent:GetPrintName() or ent:GetName()
    if ( name != "" ) then
        tag = name
    end

    if ( tag == "" ) then
        tag = "unknown"
    end

    return ent:GetClass() .. " [" .. ent:EntIndex() .. "][" .. tag .. "]"
end

ax.log = MODULE