local C = require("src.core.constants")

local M = {}

function M.write_line(player_index, text)
	helpers.write_file(C.OUTPUT_PATH, text .. "\n", C.APPEND_LINES, player_index)
end

function M.write_once(text)
	helpers.write_file(C.OUTPUT_PATH, text .. "\n", false)
end

return M
