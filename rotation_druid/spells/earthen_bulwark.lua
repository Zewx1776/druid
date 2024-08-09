local my_utility = require("my_utility/my_utility");

local menu_elements_bulk = 
{
    tree_tab              = tree_node:new(1),
    main_boolean          = checkbox:new(true, get_hash(my_utility.plugin_label .. "main_boolean_bulwark")),
    hp_usage_shield       = slider_float:new(0.0, 1.0, 0.30, get_hash(my_utility.plugin_label .. "%_in_which_shield_will_cast")),
    spirit_usage_shield   = slider_float:new(0.0, 1.0, 0.40, get_hash(my_utility.plugin_label .. "%_in_which_shield_will_cast_spirit"))
}

local function menu()
    if menu_elements_bulk.tree_tab:push("Earthen Bulwark") then
        menu_elements_bulk.main_boolean:render("Enable Spell", "")

        if menu_elements_bulk.main_boolean:get() then
            menu_elements_bulk.hp_usage_shield:render("Min cast HP Percent", "", 2)
            menu_elements_bulk.spirit_usage_shield:render("Min cast Spirit Percent", "", 2)
        end

        menu_elements_bulk.tree_tab:pop()
    end 
end

local next_time_allowed_cast = 0.0;
local spell_id_bulk = 333421
local function logics()
    local menu_boolean = menu_elements_bulk.main_boolean:get();
    local is_logic_allowed = my_utility.is_spell_allowed(
                menu_boolean,
                next_time_allowed_cast,
                spell_id_bulk);

    if not is_logic_allowed then
        return false;
    end;
    
    local local_player = get_local_player();
    local player_current_health = local_player:get_current_health();
    local player_max_health = local_player:get_max_health();
    local health_percentage = player_current_health / player_max_health;
    local menu_min_health_percentage = menu_elements_bulk.hp_usage_shield:get();

    local current_resource_ws = local_player:get_primary_resource_current();
    local max_resource_ws = local_player:get_primary_resource_max();
    local spirit_percentage = current_resource_ws / max_resource_ws;
    local menu_min_spirit_percentage = menu_elements_bulk.spirit_usage_shield:get();

    local should_cast = health_percentage <= menu_min_health_percentage or spirit_percentage <= menu_min_spirit_percentage;

    if should_cast then
        if cast_spell.self(spell_id_bulk, 0.0) then
            local current_time = get_time_since_inject();
            next_time_allowed_cast = current_time + 0.2;
            return true;
        end
    end

    return false;
end

return 
{
    menu = menu,
    logics = logics,   
}
