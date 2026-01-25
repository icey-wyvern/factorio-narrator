local EntityDirection = {}

-- Exact 2.0 API basis:
-- LuaEntity.direction is a number 0..15 using defines.direction order:
-- north, northnortheast, northeast, eastnortheast, east, eastsoutheast, southeast, southsoutheast,
-- south, southsouthwest, southwest, westsouthwest, west, westnorthwest, northwest, northnorthwest.
-- We normalize 16-way values to 8 compass points for clear narration.

local dir8_labels = {
	[0] = "north",
	[1] = "northeast",
	[2] = "east",
	[3] = "southeast",
	[4] = "south",
	[5] = "southwest",
	[6] = "west",
	[7] = "northwest",
}

local function prototype_of(entity)
	if not (entity and entity.valid) then return nil end
	if entity.type == "entity-ghost" and entity.ghost_prototype then
		return entity.ghost_prototype
	end
	return entity.prototype
end

local function supports_rotation(entity)
	local proto = prototype_of(entity)
	if not proto then return false end
	return proto.supports_direction == true
end

local function normalize_to_dir8(dir16)
	-- Map 0..15 to 0..7 by bucketing every two steps
	-- examples: 0->0 N, 1->0 N, 2->1 NE, 3->1 NE, 8->4 S, 12->6 W
	return math.floor((dir16 % 16) / 2)
end

local function label_for_entity_direction(entity)
	if not (entity and entity.valid) then return nil end
	local dir = entity.direction
	if type(dir) ~= "number" then return nil end
	local d8 = normalize_to_dir8(dir)
	return dir8_labels[d8]
end

-- Determine an 8-way compass direction for a delta (dx, dy) in Factorio coords.
-- Factorio: +x = east, +y = south. We bucket into 8 octants with 22.5°/67.5° boundaries.
local function dir8_from_delta(dx, dy)
	if dx == 0 and dy == 0 then return "here" end
	local ax, ay = math.abs(dx), math.abs(dy)

	-- Strongly horizontal
	if ay * 2 <= ax then
		return (dx > 0) and "east" or "west"
	end

	-- Strongly vertical
	if ax * 2 <= ay then
		return (dy > 0) and "south" or "north"
	end

	-- Diagonals
	if dx > 0 and dy < 0 then return "northeast" end
	if dx > 0 and dy > 0 then return "southeast" end
	if dx < 0 and dy > 0 then return "southwest" end
	return "northwest"
end

function EntityDirection.describe_direction(entity)
	if not supports_rotation(entity) then
		return nil
	end
	local label = label_for_entity_direction(entity)
	if not label then
		return nil
	end
	return "facing " .. label
end

function EntityDirection.between(from_pos, to_pos)
	if not (from_pos and to_pos) then return nil end
	local dx = (to_pos.x or 0) - (from_pos.x or 0)
	local dy = (to_pos.y or 0) - (from_pos.y or 0)
	return dir8_from_delta(dx, dy)
end

return EntityDirection
