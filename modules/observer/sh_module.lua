local MODULE = MODULE

MODULE.Name = "Observer"
MODULE.Author = "Riggs"
MODULE.Description = "Provides a system for observer mode."

local meta = FindMetaTable("Player")
function meta:InObserver()
    return self:GetMoveType() == MOVETYPE_NOCLIP and CAMI.PlayerHasAccess(self, "Parallax - Observer", nil)
end

CAMI.RegisterPrivilege({
    Name = "Parallax - Observer",
    MinAccess = "admin"
})

ax.util:LoadFile("sh_hooks.lua")
ax.util:LoadFile("sv_hooks.lua")