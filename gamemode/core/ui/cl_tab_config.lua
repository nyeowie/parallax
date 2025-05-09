DEFINE_BASECLASS("EditablePanel")

local PANEL = {}

function PANEL:Init()
    self:Dock(FILL)

    local title = self:Add("ax.text")
    title:Dock(TOP)
    title:SetFont("ax.fonts.title")
    title:SetText("CONFIG")

    local config = self:Add("ax.config")
    config:Dock(FILL)
end

vgui.Register("ax.tab.config", PANEL, "EditablePanel")