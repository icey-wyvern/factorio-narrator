-- domains/read_hovered.lua

local C = require("src.core.constants")
local Out = require("src.core.output")

local M = {}

local function prettify_identifier(s)
	if not s or s == "" then return "unknown" end
	return (s:gsub("[%-%_]", " "):gsub("%s+", " "):gsub("^%s+", ""):gsub("%s+$", ""))
end

local function format_selected_prototype(sp)
	-- selected_prototype is a table with fields like: name, type/base_type, quality (sometimes)
	local name = sp.name or "unknown"
	local kind = sp.type or sp.base_type or "prototype"

	local base = string.format("%s %s", prettify_identifier(kind), prettify_identifier(name))

	local quality = sp.quality
	if type(quality) == "string" and quality ~= "" then
		base = string.format("%s %s", base, prettify_identifier(quality))
	end

	return base
end

local function on_read_hovered(e)
	local player = game.get_player(e.player_index)
	if not (player and player.valid) then return end

	local sp = e.selected_prototype
	if not sp then
		-- Nothing hovered / not available; stay silent.
		return
	end

	Out.write_line(e.player_index, format_selected_prototype(sp))
end

function M.register()
	script.on_event(C.READ_HOVERED_INPUT, on_read_hovered)
end

return M
