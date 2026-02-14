local C = require("src.core.constants")
local EntityDirection = require("src.domains.entity_direction")

local Format = {}

local COORDINATE_TRAILER = "%s*@%s*%([^)]*%)%s*$"

local function remove_coordinates(text)
	if not text then return text end
	return text:gsub(COORDINATE_TRAILER, "")
end

local function prettify_identifier(s)
	if not s or s == "" then return "unknown" end
	local t = s:gsub("[%-%_]", " "):gsub("%s+", " "):gsub("^%s+", ""):gsub("%s+$", "")
	return t
end

local function normalize_for_compare(s)
	return (s or ""):lower():gsub("[%s%-%_]", "")
end

local function prototype_of(entity)
	if not (entity and entity.valid) then return nil end
	if entity.type == "entity-ghost" and entity.ghost_prototype then
		return entity.ghost_prototype, true
	end
	return entity.prototype, false
end

local function entity_kind(entity, is_ghost)
	if is_ghost then
		return "ghost"
	end
	return prettify_identifier(entity.type or "entity")
end

local function entity_display_name(entity, proto)
	local name = (proto and proto.name) or entity.name or "unknown"
	return prettify_identifier(name)
end

local function merge_kind_and_name(kind, name)
	local nk, nn = normalize_for_compare(kind), normalize_for_compare(name)
	if nk == nn or nn == "" then
		return name ~= "" and name or kind
	end
	return string.format("%s %s", kind, name)
end

local function is_inserter(proto, entity)
	local t = (proto and proto.type) or (entity and entity.type)
	return t == "inserter"
end

local function inserter_move_phrase(entity, proto)
	local type_name = prettify_identifier((proto and proto.name) or entity.name)
	local from = EntityDirection.between(entity.position, entity.pickup_position)
	local to = EntityDirection.between(entity.position, entity.drop_position)
	if from and to then
		return string.format("%s %s to %s", type_name, from, to)
	end
	return type_name
end

local function pretty_amount(n)
	if type(n) ~= "number" then return nil end
	local v = math.floor(n + 0.5)
	if v >= 1000000 then
		local m = string.format("%.1f", v / 1000000):gsub("%.0$", "")
		return m .. "M"
	end
	if v >= 1000 then
		local k = string.format("%.1f", v / 1000):gsub("%.0$", "")
		return k .. "k"
	end
	return tostring(v)
end

local function resource_amount_phrase(entity, proto)
	local t = (proto and proto.type) or (entity and entity.type)
	if t ~= "resource" then return nil end
	local ok, amount = pcall(function()
		return entity.amount
	end)
	if not ok then return nil end
	local shown = pretty_amount(amount)
	if not shown then return nil end
	return shown .. " remaining"
end

function Format.truncate(text, max_len)
	if not text then return "" end
	if not max_len or #text <= max_len then return text end
	if max_len <= 3 then return string.sub(text, 1, max_len) end
	return string.sub(text, 1, max_len - 3) .. "..."
end

function Format.entity_label(entity)
	if not (entity and entity.valid) then
		return "invalid entity"
	end

	local proto, is_ghost = prototype_of(entity)

	if is_inserter(proto, entity) and not is_ghost then
		return remove_coordinates(inserter_move_phrase(entity, proto))
	end

	local kind = entity_kind(entity, is_ghost)
	local name = entity_display_name(entity, proto)
	local base = merge_kind_and_name(kind, name)
	local resource_amount = resource_amount_phrase(entity, proto)
	if resource_amount then
		base = string.format("%s %s", base, resource_amount)
	end

	local dir_phrase = EntityDirection.describe_direction(entity)
	if dir_phrase then
		base = string.format("%s %s", base, dir_phrase)
	end

	return remove_coordinates(base)
end

function Format.gui_label(e)
	if e.entity and e.entity.valid then
		return "Opened " .. Format.entity_label(e.entity)
	end
	if e.item and e.item.name then
		return "Opened item: " .. prettify_identifier(e.item.name)
	end
	if e.equipment and e.equipment.name then
		return "Opened equipment: " .. prettify_identifier(e.equipment.name)
	end
	if e.gui_type ~= nil then
		local label = (C.GUI_TYPE_LABELS and C.GUI_TYPE_LABELS[e.gui_type]) or tostring(e.gui_type)
		return "Opened GUI: " .. label
	end
	return "Opened GUI"
end

function Format.selection_label(player)
	local ent = player and player.valid and player.selected or nil
	if ent and ent.valid then
		return Format.entity_label(ent)
	end
	return "terrain"
end

return Format
