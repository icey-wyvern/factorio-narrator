local C = {}

C.OUTPUT_PATH = "factorio-narrator/factorio-narrator-output.txt"
C.APPEND_LINES = true
C.MAX_LINE_LEN = 300

-- After a GUI opens, suppress world selection chatter for a few ticks
C.SELECTION_AFTER_GUI_TICKS = 10

-- Custom input name for "read hovered prototype"
C.READ_HOVERED_INPUT = "factorio-narrator-read-hovered"

-- Map defines.gui_type numeric values -> readable names (built at runtime).
-- Example: C.GUI_TYPE_NAMES[defines.gui_type.entity] == "entity"
C.GUI_TYPE_NAMES = (function()
	local names = {}
	if defines and defines.gui_type then
		for k, v in pairs(defines.gui_type) do
			-- k is the string name (e.g., "entity"), v is the numeric id
			names[v] = tostring(k)
		end
	end
	return names
end)()

-- Optional prettified labels (underscores -> spaces), numeric id -> "pretty name".
-- Example: C.GUI_TYPE_LABELS[defines.gui_type.blueprint_library] == "blueprint library"
C.GUI_TYPE_LABELS = (function()
	local labels = {}
	for id, name in pairs(C.GUI_TYPE_NAMES) do
		labels[id] = name:gsub("_", " ")
	end
	return labels
end)()

return C
