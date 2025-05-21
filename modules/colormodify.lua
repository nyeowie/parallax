local MODULE = MODULE

MODULE.name = "HL2 Beta Color Correction"
MODULE.author = "Custom"
MODULE.description = "Adds Half-Life 2 beta-style color correction"

if (CLIENT) then
    local colorModify = {
        ["$pp_colour_addr"] = 0.01,
        ["$pp_colour_addg"] = 0.01,
        ["$pp_colour_addb"] = 0.01,
        ["$pp_colour_brightness"] = -0.02,
        ["$pp_colour_contrast"] = 1.05,
        ["$pp_colour_colour"] = 0.35,        -- Reduced from 0.85 for lower saturation
        ["$pp_colour_mulr"] = 1,
        ["$pp_colour_mulg"] = 1,
        ["$pp_colour_mulb"] = 1
    }

    function MODULE:RenderScreenspaceEffects()
        DrawColorModify(colorModify)
    end
end