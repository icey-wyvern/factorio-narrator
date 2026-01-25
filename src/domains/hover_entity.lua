local C = require("src.core.constants")
local F = require("src.core.format")
local Out = require("src.core.output")

local M = {}
local function narrator_tbl(create)
	local g = rawget(_G, "global")
	if type(g) ~= "table" then return nil end
	g.narrator = g.narrator or {}
	if create then
		g.narrator.pending_terrain_until = g.narrator.pending_terrain_until or {}
	end
	return g.narrator
end

local function just_opened_gui(player_index)
	local nt = narrator_tbl(false)
	if not nt or not nt.last_gui_open_tick then return false end
	local t = nt.last_gui_open_tick[player_index]
	return t and (game.tick - t) <= (C.SELECTION_AFTER_GUI_TICKS or 0)
end

local function schedule_terrain_fallback(player_index, ticks)
	local nt = narrator_tbl(true)
	if not nt then return end
	local until_tick = game.tick + (ticks or 3)
	nt.pending_terrain_until[player_index] = until_tick
end

local function cancel_terrain_fallback(player_index)
	local nt = narrator_tbl(false)
	if not nt or not nt.pending_terrain_until then return end
	nt.pending_terrain_until[player_index] = nil
end

local function on_selected_entity_changed(e)
	local player = game.get_player(e.player_index)
	if not (player and player.valid) then return end

	if just_opened_gui(e.player_index) then return end

	local ent = player.selected
	if ent and ent.valid then
		cancel_terrain_fallback(e.player_index)
		Out.write_line(e.player_index, F.truncate(F.selection_label(player), C.MAX_LINE_LEN))
		return
	end

	if player.opened then return end

	schedule_terrain_fallback(e.player_index, 5)
end

local function on_tick(_)
	local nt = narrator_tbl(false)
	if not nt or not nt.pending_terrain_until then return end

	for player_index, until_tick in pairs(nt.pending_terrain_until) do
		if until_tick and game.tick >= until_tick then
			local player = game.get_player(player_index)
			if player and player.valid then
				if not player.opened and not (player.selected and player.selected.valid) and not just_opened_gui(player_index) then
					Out.write_line(player_index, F.truncate(F.selection_label(player), C.MAX_LINE_LEN))
				end
			end
			nt.pending_terrain_until[player_index] = nil
		end
	end
end

function M.register()
	script.on_event(defines.events.on_selected_entity_changed, on_selected_entity_changed)
	script.on_event(defines.events.on_tick, on_tick)
end

return M
