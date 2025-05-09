--- Font library.
-- @module ax.font

ax.font = {}
ax.font.stored = {}

surface.axCreateFont = surface.axCreateFont or surface.CreateFont

--- Registers a new font.
-- @realm client
-- @string name The name of the font.
-- @tab data The font data.
function surface.CreateFont(name, data)
    if ( string.sub(name, 1, 2) == "ax" ) then
        ax.font.stored[name] = data
    end

    surface.axCreateFont(name, data)
end

--- Returns a font by its name.
-- @realm shared
-- @string name The name of the font.
-- @return tab The font.
function ax.font:Get(name)
    return self.stored[name]
end

concommand.Add("ax_list_font", function(client)
    for name, data in pairs(ax.font.stored) do
        ax.util:Print("Font: ", ax.color:Get("cyan"), name)
        PrintTable(data)
    end
end)