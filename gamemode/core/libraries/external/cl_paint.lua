if ( !surface.GetPanelPaintState ) then
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

ax.util:LoadFile("paint/main_cl.lua", "client")
ax.util:LoadFile("paint/batch_cl.lua", "client")
ax.util:LoadFile("paint/lines_cl.lua", "client")
ax.util:LoadFile("paint/rects_cl.lua", "client")
ax.util:LoadFile("paint/rounded_boxes_cl.lua", "client")
ax.util:LoadFile("paint/outlines_cl.lua", "client")
ax.util:LoadFile("paint/blur_cl.lua", "client")
ax.util:LoadFile("paint/circles_cl.lua", "client")
ax.util:LoadFile("paint/api_cl.lua", "client")
ax.util:LoadFile("paint/svg_cl.lua", "client")
ax.util:LoadFile("paint/masks_cl.lua", "client")
ax.util:LoadFile("paint/downsampling_cl.lua", "client")