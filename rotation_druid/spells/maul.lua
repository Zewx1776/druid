local my_utility = require("my_utility/my_utility");

local menu_elements_maul = 
{
    tree_tab              = tree_node:new(1),
    main_boolean          = checkbox:new(true, get_hash(my_utility.plugin_label .. "main_boolean_maul")),
    use_as_filler_only    = checkbox:new(true, get_hash(my_utility.plugin_label .. "maul_use_as_filler_only")),
}

local function menu()
    
    if menu_elements_maul.tree_tab:push("Maul") then
        menu_elements_maul.main_boolean:render("Enable Spell", "")

        if  menu_elements_maul.main_boolean:get() then
            menu_elements_maul.use_as_filler_only:render("Filler Only", "Prevent casting with a lot of spirit")
        end
 
        menu_elements_maul.tree_tab:pop()
    end
end

local local_player = get_local_player();
if local_player == nil then
    return
end

local spell_id_maul = 309070
local maul_data = spell_data:new(
    1.0,                             -- radius
    3.5,                            -- range
    0.2,                            -- cast_delay
    0.2,                            -- projectile_speed
    true,                          -- has_collision
    spell_id_maul,                  -- spell_id
    spell_geometry.rectangular,        -- geometry_type
    targeting_type.targeted        --targeting_type
)
local next_time_allowed_cast = 0.4;
local function logics(target)
    
    local menu_boolean = menu_elements_maul.main_boolean:get();
    local is_logic_allowed = my_utility.is_spell_allowed(
                menu_boolean, 
                next_time_allowed_cast,
                spell_id_maul);

    if not is_logic_allowed then
        return false;
    end;

    local player_local = get_local_player();
    
    local is_filler_enabled = menu_elements_maul.use_as_filler_only:get();  
    if is_filler_enabled then
        local current_resource_ws = player_local:get_primary_resource_current();
        local max_resource_ws = player_local:get_primary_resource_max();
        local spirit_perc = current_resource_ws / max_resource_ws 
        local low_in_spirit = spirit_perc < 0.6
        -- console.print("spirit % " .. spirit_perc)
    
        if not low_in_spirit then
            return false;
        end
    end;

    if cast_spell.target(target, maul_data, false) then

        local current_time = get_time_since_inject();
        next_time_allowed_cast = current_time + 0.2;

        return true;
    end;


    return false;
end

return
{
    menu = menu,
    logics = logics,
}
