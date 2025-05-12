DEFINE_BASECLASS("DTextEntry")

local PANEL = {}

function PANEL:Init()
    self:SetFont("parallax")
    self:SetTextColor(color_white)
    self:SetPaintBackground(false)
    self:SetUpdateOnType(true)
    self:SetCursorColor(color_white)
    self:SetHighlightColor(color_white)

    self:SetTall(ScreenScale(12))
end

function PANEL:SizeToContents()
    BaseClass.SizeToContents(self)

    local width, height = self:GetSize()
    self:SetSize(width + 8, height + 4)
end

function PANEL:Paint(width, height)
    BaseClass.Paint(self, width, height)

    surface.SetDrawColor(ax.color:Get("background.transparent"))
    surface.DrawRect(0, 0, width, height)
end

vgui.Register("ax.text.entry", PANEL, "DTextEntry")