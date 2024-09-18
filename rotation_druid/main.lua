local local_player = get_local_player();
if local_player == nil then
    return
end

local character_id = local_player:get_character_class_id();
local is_druid = character_id == 5;
if not is_druid then
    return
end;

local menu = require("menu");

local pitboss       = require "pitboss"

local spells =
{
    tornado         = require("spells/tornado"),
    wind_shear      = require("spells/wind_shear"),
    hurricane       = require("spells/hurricane"),
    grizzly_rage    = require("spells/grizzly_rage"),
    cyclone_armor   = require("spells/cyclone_armor"),
    blood_howls     = require("spells/blood_howls"),
    storm_strike    = require("spells/storm_strike"),
    earth_spike     = require("spells/earth_spike"),
    landslide       = require("spells/landslide"),
    lightningstorm  = require("spells/lightningstorm"),
    earthen_bulwark = require("spells/earthen_bulwark"),
    wolves          = require("spells/wolves"),
    poison_creeper  = require("spells/poison_creeper"),
    ravens          = require("spells/ravens"),
    boulder         = require("spells/boulder"),
    petrify         = require("spells/petrify"),
    cataclysm       = require("spells/cataclysm"),
    claw            = require("spells/claw"),
    maul            = require("spells/maul"),
    pulverize       = require("spells/pulverize"),
    debilitating_roar = require("spells/debilitating_roar"),
    shred               = require("spells/shred"),
    rabies              = require("spells/rabies"),
    lacerate            = require("spells/lacerate"),
}

on_render_menu(function ()

    if not menu.main_tree:push("Druid: Base") then
        return;
    end;

    menu.main_boolean:render("Enable Plugin", "");

    if menu.main_boolean:get() == false then
      -- plugin not enabled, stop rendering menu elements
      menu.main_tree:pop();
      return;
    end;
 
    spells.earth_spike.menu();
    spells.tornado.menu();
    spells.wind_shear.menu();
    spells.hurricane.menu();
    spells.grizzly_rage.menu();
    spells.cyclone_armor.menu();
    spells.blood_howls.menu();
    spells.storm_strike.menu();
    spells.landslide.menu();
    spells.lightningstorm.menu();
    spells.earthen_bulwark.menu();
    spells.wolves.menu();
    spells.poison_creeper.menu();
    spells.ravens.menu();
    spells.boulder.menu();
    spells.petrify.menu();
    spells.cataclysm.menu();
    spells.claw.menu();
    spells.maul.menu();
    spells.pulverize.menu();
    spells.debilitating_roar.menu();
    spells.shred.menu();
    spells.rabies.menu();
    spells.lacerate.menu();
    menu.main_tree:pop();

end)

local cast_end_time = 0.0;

local claw_buff_name = "legendary_druid_100"
local claw_buff_name_hash = claw_buff_name
local claw_buff_name_hash_c = 1206403

local bear_buff_name = "druid_maul"
local bear_buff_name_hash = bear_buff_name
local bear_buff_name_hash = 309070

local mount_buff_name = "Generic_SetCannotBeAddedToAITargetList";
local mount_buff_name_hash = mount_buff_name;
local mount_buff_name_hash_c = 1923;

local my_utility = require("my_utility/my_utility");
local my_target_selector = require("my_utility/my_target_selector");

local max_hits = 0
local best_target = nil

-- Define scores for different enemy types
local normal_monster_value = 1
local elite_value = 2
local champion_value = 3
local boss_value = 20
local normal_monster_threshold = 5 -- Threshold to prioritize a large group of normal monsters

-- Cache for heavy function results
local last_check_time = 0.0 -- Time of last check for most hits
local check_interval = 1.0 -- 1 second cooldown between checks

local function check_and_update_best_target(unit, player_position, max_range)
    local unit_position = unit:get_position()
    local distance_sqr = unit_position:squared_dist_to_ignore_z(player_position)

    if distance_sqr < (max_range * max_range) then
        local area_data = target_selector.get_most_hits_target_circular_area_light(unit_position, 5, 4, false)
        
        if area_data then
            local total_score = 0
            local n_normals = area_data.n_hits
            local has_elite = unit:is_elite()
            local has_champion = unit:is_champion()
            local is_boss = unit:is_boss()

            -- Skip single normal monsters unless there are more than the threshold
            if n_normals < normal_monster_threshold and not (has_elite or has_champion or is_boss) then
                return -- Don't target single normal monsters or groups below threshold
            end

            -- Calculate score for normal monsters
            total_score = n_normals * normal_monster_value

            -- Add extra points for elite, champion, or boss
            if is_boss then
                total_score = total_score + boss_value
            elseif has_champion then
                total_score = total_score + champion_value
            elseif has_elite then
                total_score = total_score + elite_value
            end

            -- Prioritize based on score
            if total_score > max_hits then
                max_hits = total_score
                best_target = unit
            end
        end
    end
end

-- Updated function to get the closest valid enemy target
local function closest_target(player_position, entity_list, max_range)
    if not entity_list then
        return nil
    end

    local closest = nil
    local closest_dist_sqr = max_range * max_range

    for _, unit in ipairs(entity_list) do
        if target_selector.is_valid_enemy(unit) and unit:is_enemy() then
            local unit_position = unit:get_position()
            local distance_sqr = unit_position:squared_dist_to_ignore_z(player_position)
            if distance_sqr < closest_dist_sqr then
                closest = unit
                closest_dist_sqr = distance_sqr
            end
        end
    end

    return closest
end

-- on_update callback
on_update(function ()

    pitboss.initialize()
    
    local local_player = get_local_player();
    if not local_player then
        return;
    end
    
    if menu.main_boolean:get() == false then
        -- if plugin is disabled dont do any logic
        return;
    end;

    local current_time = get_time_since_inject()
    if current_time < cast_end_time then
        return;
    end;

    if not my_utility.is_action_allowed() then
        return;
    end  

    local screen_range = 16.0;
    local player_position = get_player_position();

    local collision_table = { false, 2.0 };
    local floor_table = { true, 5.0 };
    local angle_table = { false, 90.0 };

    local max_range = 10.0;
    local is_auto_play_active = auto_play.is_active();
    if is_auto_play_active then
        max_range = 12.0;
    end

    -- Move entity_list declaration outside the cooldown check
    local entity_list = my_target_selector.get_target_list(
        player_position,
        screen_range, 
        collision_table, 
        floor_table, 
        angle_table);

    -- Only update best_target if cooldown has expired
    if current_time >= last_check_time + check_interval then
        -- Use the already fetched entity_list here
        local target_selector_data = my_target_selector.get_target_selector_data(
            player_position, 
            entity_list);

        if target_selector_data and target_selector_data.is_valid then
            max_hits = 0
            best_target = nil

            -- Check normal units and apply the priority-based logic
            for _, unit in ipairs(target_selector_data.list) do
                check_and_update_best_target(unit, player_position, max_range)
            end

            -- Update last check time
            last_check_time = current_time
        end
    end

    -- If no target meets the threshold, skip further logic and keep searching in future updates
    if not best_target then
        return
    end

    -- If best_target exists, continue with the rest of the logic
    local best_target_position = best_target:get_position();
    local distance_sqr = best_target_position:squared_dist_to_ignore_z(player_position);

    if distance_sqr > (max_range * max_range) then            
        return
    end

    -- Spell logic follows...
    -- Check if Petrify should be cast first
    if spells.petrify and spells.petrify.should_cast_petrify then
        if spells.petrify.should_cast_petrify() then
            if spells.petrify.logics() then
                cast_end_time = current_time + 0.2;
                return;
            end
        end
    end

    if spells.claw.logics(best_target)then
        cast_end_time = current_time + 0.4;
        return;
    end;

    if spells.maul.logics(best_target)then
        cast_end_time = current_time + 0.4;
        return;
    end;

    if spells.lacerate.logics()then
        cast_end_time = current_time + 2.5;
        return;
    end;

    if spells.debilitating_roar.logics()then
        cast_end_time = current_time + 0.4;
        return;
    end;

    if spells.earthen_bulwark.logics()then
        cast_end_time = current_time + 0.4;
        return;
    end;

    if spells.rabies.logics(best_target)then
        cast_end_time = current_time + 0.4;
        return;
    end;

    if spells.grizzly_rage.logics() then
        cast_end_time = current_time + 0.2;
        return;
    end;

    if spells.hurricane.logics(player_position) then
        cast_end_time = current_time + 0.2;
        return;
    end;

    if spells.cyclone_armor.logics() then
        cast_end_time = current_time + 0.2;
        return;
    end;

    if spells.blood_howls.logics() then
        cast_end_time = current_time + 0.2;
        return;
    end;

    if spells.tornado.logics(best_target) then
        cast_end_time = current_time + 0.5;
        return;
    end;

    if spells.shred.logics(best_target) then
        cast_end_time = current_time + 0.5;
        return;
    end;

    if spells.earth_spike.logics(best_target)then
        cast_end_time = current_time + 0.4;
        return;
    end;

    if spells.lightningstorm.logics(best_target)then
        cast_end_time = current_time + 0.4;
        return;
    end;

    if spells.wolves.logics(best_target)then
        cast_end_time = current_time + 0.4;
        return;
    end;

    if spells.poison_creeper.logics()then
        cast_end_time = current_time + 0.2;
        return;
    end;

    if spells.ravens.logics(best_target)then
        cast_end_time = current_time + 0.2;
        return;
    end;

    if spells.boulder.logics(best_target)then
        cast_end_time = current_time + 0.2;
        return;
    end;

    if spells.pulverize.logics(best_target)then
        cast_end_time = current_time + 0.2;
        return;
    end;

    if spells.petrify.logics()then
        cast_end_time = current_time + 0.2;
        return;
    end;

    if spells.cataclysm.logics()then
        cast_end_time = current_time + 0.2;
        return;
    end;

    -- In the main spell casting logic, update the storm_strike section:
    if entity_list then
        local closest_storm_strike_target = closest_target(player_position, entity_list, max_range)
        
        if closest_storm_strike_target and spells.storm_strike.logics(closest_storm_strike_target) then
            cast_end_time = current_time + 0.1;
            return;
        end;
    else
        console.print("Warning: entity_list is nil, skipping storm_strike")
    end

    if spells.wind_shear.logics(best_target)then
        cast_end_time = current_time + 0.4;
        return;
    end;

    if spells.landslide.logics(best_target)then
        cast_end_time = current_time + 0.01;
        return;
    end;

end)


local draw_player_circle = false;
local draw_enemy_circles = false;

on_render(function ()

    if menu.main_boolean:get() == false then
        return;
    end;

    local local_player = get_local_player();
    if not local_player then
        return;
    end

    local player_position = local_player:get_position();
    local player_screen_position = graphics.w2s(player_position);
    if player_screen_position:is_zero() then
        return;
    end

    if draw_player_circle then
        graphics.circle_3d(player_position, 8, color_white(85), 3.5, 144)
        graphics.circle_3d(player_position, 6, color_white(85), 2.5, 144)
    end    

    if draw_enemy_circles then
        local enemies = actors_manager.get_enemy_npcs()

        for i,obj in ipairs(enemies) do
        local position = obj:get_position();
        local distance_sqr = position:squared_dist_to_ignore_z(player_position);
        local is_close = distance_sqr < (8.0 * 8.0);
            graphics.circle_3d(position, 1, color_white(100));

            local future_position = prediction.get_future_unit_position(obj, 0.4);
            graphics.circle_3d(future_position, 0.5, color_yellow(100));
        end;
    end

    local screen_range = 16.0;
    local player_position = get_player_position();

    local collision_table = { false, 2.0 };
    local floor_table = { true, 5.0 };
    local angle_table = { false, 90.0 };

    local entity_list = my_target_selector.get_target_list(
        player_position,
        screen_range, 
        collision_table, 
        floor_table, 
        angle_table);

    local target_selector_data = my_target_selector.get_target_selector_data(
        player_position, 
        entity_list);

    if not target_selector_data or not target_selector_data.is_valid then
        return;
    end
 
    local is_auto_play_active = auto_play.is_active();
    local max_range = 10.0;
    if is_auto_play_active then
        max_range = 12.0;
    end

    max_hits = 0
    best_target = nil

    -- Use check_and_update_best_target for the final target selection logic
    for _, unit in ipairs(target_selector_data.list) do
        check_and_update_best_target(unit, player_position, max_range)
    end

    if not best_target then
        return;
    end

    if best_target and best_target:is_enemy()  then
        local glow_target_position = best_target:get_position();
        local glow_target_position_2d = graphics.w2s(glow_target_position);
        graphics.line(glow_target_position_2d, player_screen_position, color_red(180), 2.5)
        graphics.circle_3d(glow_target_position, 0.80, color_red(200), 2.0);
    end

    -- New visualization for Storm Strike target
    if entity_list then
        local closest_storm_strike_target = closest_target(player_position, entity_list, max_range)
        
        if closest_storm_strike_target then
            local storm_target_position = closest_storm_strike_target:get_position();
            local storm_target_position_2d = graphics.w2s(storm_target_position);
            graphics.line(storm_target_position_2d, player_screen_position, color_green(180), 2.5)
            graphics.circle_3d(storm_target_position, 0.80, color_green(200), 2.0);
        end
    end

end);

console.print("Lua Plugin - Druid Base - Version 1.6");
