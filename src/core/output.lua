local C = require("src.core.constants")

local M = {}

local function narrator_tbl()
	local g = rawget(_G, "global")
	if type(g) ~= "table" then return nil end
	g.narrator = g.narrator or {}
	g.narrator.output = g.narrator.output or {}
	return g.narrator.output
end

local function count_bytes(text)
	return #(text or "")
end

local function track_write(text, append_mode)
	local output = narrator_tbl()
	if not output then return end
	local bytes = count_bytes(text)
	if append_mode then
		output.bytes = (output.bytes or 0) + bytes
	else
		output.bytes = bytes
	end
end

function M.write_line(player_index, text)
	local payload = (text or "") .. "\n"
	helpers.write_file(C.OUTPUT_PATH, payload, C.APPEND_LINES, player_index)
	track_write(payload, C.APPEND_LINES)
end

function M.write_once(text)
	local payload = (text or "") .. "\n"
	helpers.write_file(C.OUTPUT_PATH, payload, false)
	track_write(payload, false)
end

function M.trim_if_needed()
	local output = narrator_tbl()
	if not output then return end
	if (output.bytes or 0) <= C.LOG_MAX_BYTES then return end
	helpers.write_file(C.OUTPUT_PATH, "", false)
	output.bytes = 0
end

return M
