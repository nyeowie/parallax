--[[--
Physical representation of connected player.

`Player`s are a type of `Entity`. They are a physical representation of a `Character` - and can possess at most one `Character`
object at a time that you can interface with.

See the [Garry's Mod Wiki](https://wiki.garrysmod.com/page/Category:Player) for all other methods that the `Player` class has.
]]
-- @classmod Player

local PLAYER = FindMetaTable("Player")

function PLAYER:GetData(key, default)
    local tbl = self:GetTable()
    local axDatabase = tbl.axDatabase
    if ( !axDatabase ) then
        ax.util:PrintError("Player does not have a database connection, unable to get data.")
        return default
    end

    local data = axDatabase.data or {}
    if ( isstring(data) ) then
        data = util.JSONToTable(data) or {}
    else
        data = data or {}
    end

    return data[key] or default
end