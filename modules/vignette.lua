local MODULE = MODULE or {}
MODULE.name = "Vignette"
MODULE.author = "setsunaok"
MODULE.description = "Adds a configurable black vignette effect to the player's HUD, with a red blood-like vignette based on the player's health."

local healthVignetteColor = Color(255, 0, 0, 150) 
local vignetteIntensity = 0.05 

if CLIENT then
    local vignetteMaterial = Material("materials/vignette.png")

    function MODULE:HUDPaint()
        local screenWidth, screenHeight = ScrW(), ScrH()

        surface.SetDrawColor(0, 0, 0, 255)  
        surface.SetMaterial(vignetteMaterial)
        surface.DrawTexturedRect(0, 0, screenWidth, screenHeight)

    end
end
