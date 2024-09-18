local my_utility = require("my_utility/my_utility")
local my_target_selector = require("my_utility/my_target_selector")

local petrify_menu_elements =
{
    tree_tab           = tree_node:new(1),
    main_boolean       = checkbox:new(true, get_hash(my_utility.plugin_label .. "disable_enable_ability")),
    min_max_targets    = slider_int:new(0, 30, 5, get_hash(my_utility.plugin_label .. "min_max_number_of_targets_for_cast"))
}

local function menu()
    if petrify_menu_elements.tree_tab:push("Petrify") then
        petrify_menu_elements.main_boolean:render("Enable Spell", "")
 
        if petrify_menu_elements.main_boolean:get() then
            petrify_menu_elements.min_max_targets:render("Min hits", "Amount of targets to cast the spell", 0)
        end

        petrify_menu_elements.tree_tab:pop()
    end
end

local spell_id_petrify = 351722
local next_time_allowed_cast = 0.0

local function logics()
    local menu_boolean = petrify_menu_elements.main_boolean:get()
    local is_logic_allowed = my_utility.is_spell_allowed(
                menu_boolean, 
                next_time_allowed_cast, 
                spell_id_petrify)

    if not is_logic_allowed then
        return false
    end

    -- Get the list of monsters in the area
    local player_position = get_player_position()
    local range = 8
    local collision_table = {is_enabled = false}
    local floor_table = {is_enabled = false}
    local angle_table = {is_enabled = false}
    local target_list = my_target_selector.get_target_list(player_position, range, collision_table, floor_table, angle_table)

    -- Calculate weighted units
    local weighted_units = 0
    for _, unit in ipairs(target_list) do
        if unit:is_elite() or unit:is_boss() or unit:is_champion() then
            weighted_units = weighted_units + 10
        else
            weighted_units = weighted_units + 1
        end
    end

    -- Print the weighted score
    console.print("Weighted Units: " .. weighted_units)

    if weighted_units < petrify_menu_elements.min_max_targets:get() then
        return false
    end

    if cast_spell.self(spell_id_petrify, 0.2) then
        local current_time = get_time_since_inject()
        next_time_allowed_cast = current_time + 0.001
        console.print("Druid Plugin, Petrify")
        return true
    end
    
    return false
end

-- New function to check if Petrify should be cast
local function should_cast_petrify()
    local menu_boolean = petrify_menu_elements.main_boolean:get()
    local is_logic_allowed = my_utility.is_spell_allowed(
                menu_boolean, 
                next_time_allowed_cast, 
                spell_id_petrify)

    if not is_logic_allowed then
        return false
    end

    local player_position = get_player_position()
    local range = 8
    local collision_table = {is_enabled = false}
    local floor_table = {is_enabled = false}
    local angle_table = {is_enabled = false}
    local target_list = my_target_selector.get_target_list(player_position, range, collision_table, floor_table, angle_table)

    local weighted_units = 0
    for _, unit in ipairs(target_list) do
        if unit:is_elite() or unit:is_boss() or unit:is_champion() then
            weighted_units = weighted_units + 10
        else
            weighted_units = weighted_units + 1
        end
    end

    return weighted_units >= petrify_menu_elements.min_max_targets:get()
end

return
{
    menu = menu,
    logics = logics,
    should_cast_petrify = should_cast_petrify
}