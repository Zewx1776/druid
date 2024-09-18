local my_utility = require("my_utility/my_utility")


local storm_strike_base_menu =
{
    tree_tab            = tree_node:new(1),
    main_boolean        = checkbox:new(true, get_hash(my_utility.plugin_label .. "storm_strike_main")),
    use_as_filler_only  = checkbox:new(true, get_hash(my_utility.plugin_label .. "storm_strike_filler"))
}

local function menu()
    if storm_strike_base_menu.tree_tab:push("Storm Strike") then
        storm_strike_base_menu.main_boolean:render("Enable Spell", "")
 
         if storm_strike_base_menu.main_boolean:get() then
            storm_strike_base_menu.use_as_filler_only:render("Filler Only", "Prevent casting with a lot of spirit")
         end

         storm_strike_base_menu.tree_tab:pop()
        end
    end

local spell_id_storm_strike = 309320;

local storm_spell_data = spell_data:new(
    1.0,                        -- radius
    0,                       -- range
    0.7,                       -- cast_delay
    0.4,                       -- projectile_speed
    true,                      -- has_collision
    spell_id_storm_strike,        -- spell_id
    spell_geometry.rectangular, -- geometry_type
    targeting_type.skillshot    --targeting_type
)
local next_time_allowed_cast = 0.0;
local function logics(target)
    --console.print("Storm Strike - Starting logics function")
    
    local menu_boolean = storm_strike_base_menu.main_boolean:get();
    local is_logic_allowed = my_utility.is_spell_allowed(
                menu_boolean, 
                next_time_allowed_cast, 
                spell_id_storm_strike);

    --console.print("Storm Strike - Is logic allowed: " .. tostring(is_logic_allowed))

    if not is_logic_allowed then
        --console.print("Storm Strike - Logic not allowed, exiting")
        return false;
    end;

    local player_local = get_local_player();
    
    local is_filler_enabled = storm_strike_base_menu.use_as_filler_only:get();  
    --console.print("Storm Strike - Is filler enabled: " .. tostring(is_filler_enabled))

    if is_filler_enabled then
        local current_resource_ws = player_local:get_primary_resource_current();
        local max_resource_ws = player_local:get_primary_resource_max();
        local spirit_perc = current_resource_ws / max_resource_ws 
        local low_in_spirit = spirit_perc < 0.4
        --console.print("Storm Strike - Spirit percentage: " .. spirit_perc)
        --console.print("Storm Strike - Low in spirit: " .. tostring(low_in_spirit))
    
        if not low_in_spirit then
            --console.print("Storm Strike - Not low in spirit, exiting")
            return false;
        end
    end;
    
    local player_position = get_player_position();
    if player_position then
        --console.print(string.format("Storm Strike - Player position: x=%.2f, y=%.2f, z=%.2f", 
        --    player_position:x(), player_position:y(), player_position:z()))
    else
        --console.print("Storm Strike - Error: Could not get player position")
        return false
    end
    
    if target == nil then
        --console.print("Storm Strike - Error: Target is nil")
        return false
    end

    local target_position = target:get_position();
    
    if target_position == nil then
        --console.print("Storm Strike - Error: Target position is nil")
        return false
    end

    -- Add distance check
    local distance = player_position:dist_to_ignore_z(target_position)
    --console.print(string.format("Storm Strike - Distance to target: %.2f", distance))

    if distance > 1.5 then
        --console.print("Storm Strike - Target is too far, moving closer")
        pathfinder.request_move(target_position)
        return false
    end

    local x = target_position:x()
    local y = target_position:y()
    local z = target_position:z()

    if x == nil or y == nil or z == nil then
        --console.print("Storm Strike - Error: Invalid target position coordinates")
        return false
    end

    --console.print(string.format("Storm Strike - Target Position: x=%.2f, y=%.2f, z=%.2f", x, y, z))

    --console.print("Storm Strike - Attempting to cast spell")
    if cast_spell.target(target, storm_spell_data, false) then
        local current_time = get_time_since_inject();
        next_time_allowed_cast = current_time + 0.1;

        --console.print("Storm Strike - Successfully cast")
        --console.print(string.format("Storm Strike cast at target: x=%.2f, y=%.2f, z=%.2f", x, y, z));
        return true;
    else
        --console.print("Storm Strike - Failed to cast")
    end;
            
    --console.print("Storm Strike - Exiting logics function")
    return false;
end


return 
{
    menu = menu,
    logics = logics,   
}