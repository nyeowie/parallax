local FONT_NAME = "DisclaimerFont"
local FONT_SIZE = 16
local SUBTITLE_FONT_NAME = "DisclaimerSubtitleFont"
local SUBTITLE_FONT_SIZE = 12
local WIP_FONT_NAME = "DisclaimerFont"
local WIP_FONT_SIZE = 18
local PIXEL_FONT = true
local surface = surface

surface.CreateFont(FONT_NAME, {
    font = "Consolas", 
    size = FONT_SIZE,
    weight = 800,
    antialias = false,
    blursize = 0,
    shadow = true
})

surface.CreateFont(SUBTITLE_FONT_NAME, {
    font = "Consolas", 
    size = SUBTITLE_FONT_SIZE,
    weight = 600,
    antialias = false, 
    blursize = 0,
    scanlines = 1, 
    shadow = true
})

surface.CreateFont("Vitals", {
    font = "Consolas", 
    size = 12,
    weight = 800,
    antialias = false,
    blursize = 0,
    shadow = true
})

surface.CreateFont("SmallAmmo", {
    font = "Consolas", 
    size = 14,
    weight = 800,
    antialias = false,
    blursize = 0,
    shadow = true
})

surface.CreateFont("AmmoSub", {
    font = "Consolas", 
    size = 14,
    weight = 800,
    antialias = false,
    blursize = 0,
    shadow = true
})

surface.CreateFont("MainThing", {
    font = "Consolas", 
    size = 20,
    weight = 600,
    antialias = false, 
    blursize = 0,
    scanlines = 1, 
    shadow = true
})

surface.CreateFont("AmmoThing", {
    font = "Consolas", 
    size = 32,
    weight = 600,
    antialias = false, 
    blursize = 0,
    scanlines = 1, 
    shadow = true
})

local TEXT_COLOR = Color(255, 255, 255, 200)
local SUBTITLE_COLOR = Color(200, 200, 200, 180)
local SHADOW_COLOR = Color(0, 0, 0, 100)
local WIP_COLOR = Color(200, 200, 200, 55)

function MODULE:Initialize()
    hook.Add("HUDPaint", "DrawDisclaimer", function()
        self:DrawDisclaimer()
        self:DrawWorkInProgress()
    end)
end

function MODULE:DrawWorkInProgress()
    local wip_text = "W O R K   I N   P R O G R E S S"
    local padding = 30 
    
    surface.SetFont(WIP_FONT_NAME)
    local textWidth, textHeight = surface.GetTextSize(wip_text)
    
    local posX = padding
    local posY = padding
    
    surface.SetTextColor(SHADOW_COLOR)
    surface.SetTextPos(posX + 1, posY + 1)
    surface.DrawText(wip_text)
    
    surface.SetTextColor(WIP_COLOR)
    surface.SetTextPos(posX, posY)
    surface.DrawText(wip_text)
end

function MODULE:DrawDisclaimer()
    local disclaimer_text = "> B E T A   S T A S I S _   |   P R E - A L P H A"
    local build_text = ":: BUILD " .. os.date("%m%d%y")
    local padding = 10
    
    -- Get screen dimensions
    local screenWidth = ScrW()
    local screenHeight = ScrH()
    
    surface.SetFont(FONT_NAME)
    local textWidth, textHeight = surface.GetTextSize(disclaimer_text)
    
    local posX = padding
    local posY = screenHeight - textHeight - padding
    
    surface.SetTextColor(SHADOW_COLOR)
    surface.SetTextPos(posX + 1, posY + 1)
    surface.DrawText(disclaimer_text)
    
    surface.SetTextColor(TEXT_COLOR)
    surface.SetTextPos(posX, posY)
    surface.DrawText(disclaimer_text)
    
    surface.SetFont(SUBTITLE_FONT_NAME)
    local buildWidth, buildHeight = surface.GetTextSize(build_text)
    
    local spacing = 12
    local buildPosX = posX + textWidth + spacing
    local buildPosY = posY + (textHeight - buildHeight) / 2
    
    if (buildPosX + buildWidth) > (screenWidth - padding) then
        buildPosX = posX + 12
        buildPosY = posY + textHeight + 2
    end
    
    surface.SetTextColor(SHADOW_COLOR)
    surface.SetTextPos(buildPosX + 1, buildPosY + 1)
    surface.DrawText(build_text)
    
    surface.SetTextColor(SUBTITLE_COLOR)
    surface.SetTextPos(buildPosX, buildPosY)
    surface.DrawText(build_text)
end

MODULE:Initialize()

return MODULE