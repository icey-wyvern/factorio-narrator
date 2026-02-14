local C = require("src.core.constants")
local Out = require("src.core.output")

local HoverEntity = require("src.domains.hover_entity")
local GuiOpen = require("src.domains.gui_open")
local ReadHovered = require("src.domains.read_hovered")

script.on_init(function()
	Out.write_once("factorio-narrator: ready")
end)

HoverEntity.register()
GuiOpen.register()
ReadHovered.register()
script.on_nth_tick(C.LOG_MAINTENANCE_INTERVAL_TICKS, Out.trim_if_needed)
