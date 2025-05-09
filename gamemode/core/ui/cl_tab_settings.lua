DEFINE_BASECLASS("EditablePanel")

local PANEL = {}

function PANEL:Init()
    self:Dock(FILL)

    local title = self:Add("ax.text")
    title:Dock(TOP)
    title:SetFont("ax.fonts.title")
    title:SetText("SETTINGS")

    local settings = self:Add("ax.settings")
    settings:Dock(FILL)
end

vgui.Register("ax.tab.settings", PANEL, "EditablePanel")