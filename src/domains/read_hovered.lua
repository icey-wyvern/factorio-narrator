local C = require("src.core.constants")
local F = require("src.core.format")
local Out = require("src.core.output")

local M = {}

local function prettify_identifier(s)
	if not s or s == "" then return "unknown" end
	return (s:gsub("[%-%_]", " "):gsub("%s+", " "):gsub("^%s+", ""):gsub("%s+$", ""))
end

local function safe_call(target, method_name, ...)
	if not target then return nil end
	local fn = target[method_name]
	if type(fn) ~= "function" then return nil end
	local ok, res = pcall(fn, target, ...)
	if not ok then return nil end
	return res
end

local function safe_property(target, property_name)
	if not target then return nil end
	local ok, res = pcall(function()
		return target[property_name]
	end)
	if not ok then return nil end
	return res
end

local function format_selected_prototype(sp)
	local name = sp.name or "unknown"
	local kind = sp.type or sp.base_type or "prototype"
	local base = string.format("%s %s", prettify_identifier(kind), prettify_identifier(name))
	local quality = sp.quality
	if type(quality) == "string" and quality ~= "" then
		base = string.format("%s %s", base, prettify_identifier(quality))
	end
	return base
end

local function format_amount(value)
	local n = tonumber(value)
	if not n then return "?" end
	if n == math.floor(n) then
		return tostring(math.floor(n))
	end
	local s = string.format("%.2f", n)
	return (s:gsub("0+$", ""):gsub("%.$", ""))
end

local function format_signal(signal)
	if type(signal) ~= "table" then return nil end
	local signal_type = signal.type or "signal"
	local signal_name = signal.name
	if type(signal_name) ~= "string" or signal_name == "" then return nil end
	local text = string.format("%s %s", prettify_identifier(signal_type), prettify_identifier(signal_name))
	return {
		kind = signal_type,
		name = signal_name,
		text = text,
	}
end

local function descriptor_from_sprite(sprite)
	if type(sprite) ~= "string" or sprite == "" then return nil end
	local kind, name = sprite:match("^([%w%-_]+)/([%w%-_%.]+)$")
	if not kind or not name then return nil end
	return {
		kind = kind,
		name = name,
		text = string.format("%s %s", prettify_identifier(kind), prettify_identifier(name)),
	}
end

local function descriptor_from_hovered_gui_element(player)
	local elem = safe_property(player, "hovered_gui_element")
	if not (elem and elem.valid) then return nil end

	local elem_type = safe_property(elem, "elem_type")
	local elem_value = safe_property(elem, "elem_value")
	if type(elem_type) == "string" and elem_type ~= "" then
		if type(elem_value) == "string" and elem_value ~= "" then
			return {
				kind = elem_type,
				name = elem_value,
				text = string.format("%s %s", prettify_identifier(elem_type), prettify_identifier(elem_value)),
			}
		end
		local signal_desc = format_signal(elem_value)
		if signal_desc then return signal_desc end
	end

	return descriptor_from_sprite(safe_property(elem, "sprite"))
end

local function summarize_inserter_filters(entity)
	if entity.type ~= "inserter" then return nil end
	local slots = tonumber(safe_property(entity, "filter_slot_count")) or 0
	if slots <= 0 then return nil end
	local names = {}
	for i = 1, slots do
		local f = safe_call(entity, "get_filter", i)
		if type(f) == "string" and f ~= "" then
			names[#names + 1] = prettify_identifier(f)
			if #names >= C.MAX_FILTER_SUMMARY then break end
		end
	end
	if #names == 0 then
		return "no inserter filters set"
	end
	return "inserter filters: " .. table.concat(names, ", ")
end

local function summarize_infinity_filters(entity)
	if entity.type ~= "infinity-container" then return nil end
	local slots = tonumber(safe_property(entity, "infinity_container_filter_slot_count")) or 0
	if slots <= 0 then return nil end
	local parts = {}
	for i = 1, slots do
		local filter = safe_call(entity, "get_infinity_container_filter", i)
		if type(filter) == "table" and filter.name and filter.name ~= "" then
			local name = prettify_identifier(filter.name)
			local count = tonumber(filter.count) or 0
			if count > 0 then
				parts[#parts + 1] = string.format("%s x%d", name, count)
			else
				parts[#parts + 1] = name
			end
			if #parts >= C.MAX_FILTER_SUMMARY then break end
		end
	end
	if #parts == 0 then
		return "no infinity filters set"
	end
	return "infinity filters: " .. table.concat(parts, ", ")
end

local function all_recipe_prototypes()
	local proto_root = rawget(_G, "prototypes")
	if type(proto_root) == "table" and type(proto_root.recipe) == "table" then
		return proto_root.recipe
	end

	local ok, recipes = pcall(function()
		return game.recipe_prototypes
	end)
	if ok and type(recipes) == "table" then
		return recipes
	end

	return nil
end

local function recipe_prototype_by_name(recipe_name)
	local recipes = all_recipe_prototypes()
	if not recipes then return nil end
	return recipes[recipe_name]
end

local function recipe_details_by_name(recipe_name)
	if type(recipe_name) ~= "string" or recipe_name == "" then return nil end
	local proto = recipe_prototype_by_name(recipe_name)
	if not proto then return nil end
	local ingredients = proto.ingredients or {}
	if #ingredients == 0 then
		return "recipe " .. prettify_identifier(recipe_name)
	end
	local parts = {}
	for i, ingredient in ipairs(ingredients) do
		local ingredient_name = ingredient.name
		if type(ingredient_name) == "string" and ingredient_name ~= "" then
			parts[#parts + 1] = prettify_identifier(ingredient_name) .. " x" .. format_amount(ingredient.amount)
		end
		if i >= C.MAX_FILTER_SUMMARY then break end
	end
	if #parts == 0 then
		return "recipe " .. prettify_identifier(recipe_name)
	end
	return "recipe " .. prettify_identifier(recipe_name) .. ": " .. table.concat(parts, ", ")
end

local function recipe_produces(proto, target_kind, target_name)
	if not (proto and target_kind and target_name) then return false end
	local products = proto.products or {}
	for _, product in ipairs(products) do
		if type(product) == "table" then
			local p_kind = product.type or "item"
			if p_kind == target_kind and product.name == target_name then
				return true
			end
		end
	end
	return false
end

local function find_recipe_for_product(target_kind, target_name)
	if type(target_name) ~= "string" or target_name == "" then return nil end
	local recipes = all_recipe_prototypes()
	if not recipes then return nil end

	local exact = recipes[target_name]
	if recipe_produces(exact, target_kind, target_name) then
		return exact
	end

	local first_match = nil
	for _, proto in pairs(recipes) do
		if recipe_produces(proto, target_kind, target_name) then
			if proto.hidden ~= true then
				return proto
			end
			if not first_match then
				first_match = proto
			end
		end
	end
	return first_match
end

local function recipe_details_for_target(target_kind, target_name)
	if target_kind == "recipe" then
		return recipe_details_by_name(target_name)
	end
	if target_kind ~= "item" and target_kind ~= "fluid" then return nil end
	local recipe = find_recipe_for_product(target_kind, target_name)
	if not recipe then return nil end
	return recipe_details_by_name(recipe.name)
end

local function summarize_recipe(entity)
	local recipe = safe_call(entity, "get_recipe")
	if recipe and recipe.valid and recipe.name then
		return "recipe: " .. prettify_identifier(recipe.name)
	end
	return nil
end

local function detailed_entity_label(entity)
	local text = F.entity_label(entity)
	local extras = {}
	local recipe = summarize_recipe(entity)
	if recipe then extras[#extras + 1] = recipe end
	local inserter_filters = summarize_inserter_filters(entity)
	if inserter_filters then extras[#extras + 1] = inserter_filters end
	local infinity_filters = summarize_infinity_filters(entity)
	if infinity_filters then extras[#extras + 1] = infinity_filters end
	if #extras == 0 then return text end
	return text .. ". " .. table.concat(extras, ". ")
end

local function describe_entity_focus(player)
	local opened = player.opened
	if opened and opened.valid and opened.object_name == "LuaEntity" then
		return "No hovered item in " .. detailed_entity_label(opened)
	end
	local selected = player.selected
	if selected and selected.valid then
		return detailed_entity_label(selected)
	end
	return nil
end

local function read_simple_focus(player, selected_prototype)
	local sp = selected_prototype or safe_property(player, "selected_prototype")
	if sp then
		return format_selected_prototype(sp)
	end
	local desc = descriptor_from_hovered_gui_element(player)
	if desc and desc.text then
		return desc.text
	end
	return nil
end

local function read_detailed_focus(player, selected_prototype)
	local sp = selected_prototype or safe_property(player, "selected_prototype")
	if sp then
		local kind = sp.type or sp.base_type
		local details = recipe_details_for_target(kind, sp.name)
		if details then
			return details
		end
		return format_selected_prototype(sp)
	end

	local desc = descriptor_from_hovered_gui_element(player)
	if desc then
		local details = recipe_details_for_target(desc.kind, desc.name)
		if details then
			return details
		end
		return desc.text
	end

	return describe_entity_focus(player)
end

local function on_read_hovered(e)
	local player = game.get_player(e.player_index)
	if not (player and player.valid) then return end
	local text = read_simple_focus(player, e.selected_prototype)
	if not text or text == "" then return end
	Out.write_line(e.player_index, F.truncate(text, C.MAX_LINE_LEN))
end

function M.register()
	script.on_event(C.READ_HOVERED_INPUT, on_read_hovered)
end

return M
