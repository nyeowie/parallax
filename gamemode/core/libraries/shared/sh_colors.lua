--- Colors library
-- @module ax.color

ax.color = {}
ax.color.stored = {}

--- Registers a new color.
-- @realm shared
-- @param info A table containing information about the color.
function ax.color:Register(name, color)
    if ( !isstring(name) or #name == 0 ) then
        ax.util:PrintError("Attempted to register a color without a name!")
        return false
    end

    if ( !IsColor(color) ) then
        ax.util:PrintError("Attempted to register a color without a color!")
        return false
    end

    local bResult = hook.Run("PreColorRegistered", name, color)
    if ( bResult == false ) then return false end

    self.stored[name] = color
    hook.Run("OnColorRegistered", name, color)
end

--- Gets a color by its name.
-- @realm shared
-- @param name The name of the color.
-- @param copy boolean Whether to return a copy of the color (default: false).
-- @return The color.
function ax.color:Get(name, copy)
    if ( copy == nil ) then copy = false end

    local storedColor = self.stored[name]
    -- Copy ONLY if you intend to modify the color
    if ( IsColor(storedColor) ) then
        return copy and Color(storedColor.r, storedColor.g, storedColor.b, storedColor.a) or storedColor
    end

    ax.util:PrintError("Attempted to get an invalid color!")
    return false
end

--- Dims a color by a specified fraction.
-- @realm shared
-- @param col Color The color to dim.
-- @param frac number The fraction to dim the color by.
-- @return Color The dimmed color.
function ax.color:Dim(col, frac)
    return Color(col.r * frac, col.g * frac, col.b * frac, col.a)
end

if ( CLIENT ) then
    concommand.Add("ax_list_colours", function(client, cmd, args)
        for k, v in pairs(ax.color.stored) do
            ax.util:Print("Color: " .. k .. " >> ", ax.color:Get("cyan"), v, " Color Sample")
        end
    end)
end