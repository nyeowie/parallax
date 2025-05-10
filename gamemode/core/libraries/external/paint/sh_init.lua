if ( CLIENT and !surface.GetPanelPaintState ) then
	---@class paint.PanelPaintState
	---@field translate_x integer
	---@field translate_y integer
	---@field scissor_enabled boolean
	---@field scissor_left integer
	---@field scissor_top integer
	---@field scissor_right integer
	---@field scissor_bottom integer

	local panelState = {
		translate_x = 0,
		translate_y = 0,
		scissor_enabled = false,
		scissor_left = 0,
		scissor_bottom = 0,
		scissor_right = 0,
		scissor_top = 0
	}

	---@return paint.PanelPaintState
	---@diagnostic disable-next-line: duplicate-set-field
	function surface.GetPanelPaintState()
		return panelState
	end

	MsgC(Color(255, 20, 20), "[Warning] ", color_white, "Paint library made a stub for surface.GetPanelPaintState.\n", Color(100, 255, 100), "It will likely break stuff. Sorry for that.\nWill be removed when surface.GetPanelPaintState will be implemented in gmod\n")
end

ax.util:LoadFile("parallax/gamemode/external/paint/main_cl.lua", "client")
ax.util:LoadFile("parallax/gamemode/external/paint/batch_cl.lua", "client")
ax.util:LoadFile("parallax/gamemode/external/paint/lines_cl.lua", "client")
ax.util:LoadFile("parallax/gamemode/external/paint/rects_cl.lua", "client")
ax.util:LoadFile("parallax/gamemode/external/paint/rounded_boxes_cl.lua", "client")
ax.util:LoadFile("parallax/gamemode/external/paint/outlines_cl.lua", "client")
ax.util:LoadFile("parallax/gamemode/external/paint/blur_cl.lua", "client")
ax.util:LoadFile("parallax/gamemode/external/paint/circles_cl.lua", "client")
ax.util:LoadFile("parallax/gamemode/external/paint/api_cl.lua", "client")
ax.util:LoadFile("parallax/gamemode/external/paint/svg_cl.lua", "client")
ax.util:LoadFile("parallax/gamemode/external/paint/masks_cl.lua", "client")
ax.util:LoadFile("parallax/gamemode/external/paint/downsampling_cl.lua", "client")