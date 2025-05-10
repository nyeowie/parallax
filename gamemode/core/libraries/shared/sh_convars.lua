--- Convars library for Parallax gamemode
-- This library is responsible for creating and managing console variables (convars) used in the Parallax gamemode.

-- @module ax.convars

ax.convars = ax.convars or {}
ax.convars.stored = ax.convars.stored or {}

function ax.convars:Get(name)
    return self.stored[name]
end

function ax.convars:Create(name, default, flags, help, min, max)
    local convar = CreateConVar(name, default, flags, help, min, max)
    self.stored[name] = convar
end

function ax.convars:CreateClient(name, default, shouldsave, userinfo, helptext, min, max)
    local convar = CreateClientConVar(name, default, shouldsave, userinfo, helptext, min, max)
    self.stored[name] = convar
end

ax.convars:Create("ax_debug", "0", {FCVAR_REPLICATED, FCVAR_ARCHIVE}, "Enable debug mode.", 0, 1)
ax.convars:Create("ax_preview", "0", {FCVAR_REPLICATED, FCVAR_ARCHIVE}, "Enable preview mode.", 0, 1)