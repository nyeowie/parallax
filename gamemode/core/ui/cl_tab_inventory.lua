DEFINE_BASECLASS("EditablePanel")

local PANEL = {}

function PANEL:Init()
    self:Dock(FILL)

    local title = self:Add("ax.text")
    title:Dock(TOP)
    title:SetFont("parallax.title")
    title:SetText("INVENTORY")

    local inventory = self:Add("ax.inventory")
    inventory:Dock(FILL)
    inventory:SetInventory()
end

vgui.Register("ax.tab.inventory", PANEL, "EditablePanel")