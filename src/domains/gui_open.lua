local C = require("src.core.constants")
local F = require("src.core.format")
local Out = require("src.core.output")

local M = {}

local function narrator_tbl()
	local g = rawget(_G, "global")
	if type(g) ~= "table" then return nil end
	g.narrator = g.narrator or {}
	return g.narrator
end

local function mark_gui_open(player_index)
	local nt = narrator_tbl()
	if not nt then return end
	nt.last_gui_open_tick = nt.last_gui_open_tick or {}
	nt.last_gui_open_tick[player_index] = game.tick
end

local function clear_gui_open(player_index)
	local nt = narrator_tbl()
	if not nt or not nt.last_gui_open_tick then return end
	nt.last_gui_open_tick[player_index] = nil
end

local function cancel_pending_terrain(player_index)
	local nt = narrator_tbl()
	if not nt then return end
	nt.pending_terrain_until = nt.pending_terrain_until or {}
	nt.pending_terrain_until[player_index] = nil
	if nt.pending_terrain_tick then nt.pending_terrain_tick[player_index] = nil end
	if nt.pending_terrain then nt.pending_terrain[player_index] = nil end
end

local function handle_gui_opened(e)
	local player = game.get_player(e.player_index)
	if not (player and player.valid) then return end
	mark_gui_open(e.player_index)
	cancel_pending_terrain(e.player_index)
	Out.write_line(e.player_index, F.truncate(F.gui_label(e), C.MAX_LINE_LEN))
end

local function handle_gui_closed(e)
	cancel_pending_terrain(e.player_index)
	clear_gui_open(e.player_index)
end

function M.register()
	script.on_event(defines.events.on_gui_opened, handle_gui_opened)
	script.on_event(defines.events.on_gui_closed, handle_gui_closed)
end

return M
