local my_utility = require("my_utility/my_utility");

local menu_elements_land = 
{
    tree_tab              = tree_node:new(1),
    main_boolean          = checkbox:new(true, get_hash(my_utility.plugin_label .. "main_boolean_land_slide")),
}

local function menu()
    
    if menu_elements_land.tree_tab:push("Land Slide")then
        menu_elements_land.main_boolean:render("Enable Spell", "")
 
        menu_elements_land.tree_tab:pop()
    end
end

local spell_id_land = 313893
local landslide_data = spell_data:new(
    1.0,                             -- radius
    0.5,                             -- range (same as maul for melee range)
    0.2,                             -- cast_delay
    0.2,                             -- projectile_speed
    true,                            -- has_collision
    spell_id_land,                   -- spell_id
    spell_geometry.rectangular,      -- geometry_type
    targeting_type.targeted          -- targeting_type
)
local next_time_allowed_cast = 0.0;
local function logics(target)
    
    local menu_boolean = menu_elements_land.main_boolean:get();
    local is_logic_allowed = my_utility.is_spell_allowed(
                menu_boolean, 
                next_time_allowed_cast, 
                spell_id_land);

    if not is_logic_allowed then
        return false;
    end;

    local player = get_local_player()
    if player then
        local player_position = player:get_position()
        if player_position then
            if evade.is_dangerous_position(player_position) then
                console.print("Druid Plugin, Cannot cast Land Slide - position is dangerous");
                return false;
            end
        else
            return false;
        end
    else
        return false;
    end;

    if cast_spell.target(target, landslide_data, false) then
        local current_time = get_time_since_inject();
        next_time_allowed_cast = current_time + 0.15;
        
        console.print("Druid Plugin, Casted Land Slide");
        return true;
    end

    return false;
end

return 
{
    menu = menu,
    logics = logics,   
}