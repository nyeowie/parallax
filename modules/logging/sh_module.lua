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

    return client:SteamName() .. " (" .. client:Name() .. " / " .. client:SteamID64() .. ")"
end

function MODULE:FormatEntity(ent)
    if ( !IsValid(ent) or ent == Entity(0) ) then return "world" end

    if ( ent:IsPlayer() ) then
        return self:FormatPlayer(ent)
    end

    return ent:GetClass() .. " (" .. ent:GetModel() .. " / " .. ent:EntIndex() .. ")"
end

ax.color:Register("log.message", Color(250, 200, 25))

ax.util:LoadFile("cl_module.lua")
ax.util:LoadFile("sv_module.lua")

ax.util:LoadFile("sv_hooks.lua")

ax.log = MODULE