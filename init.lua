-- player_recorder/init.lua

local recording = false
local recorded_positions = {}
local tick_count = 0

-- Function to start recording
local function start_recording(player)
    recording = true
    recorded_positions = {}
    tick_count = 0
    minetest.chat_send_player(player:get_player_name(), "Recording started.")
end

-- Function to stop recording
local function stop_recording(player)
    recording = false
    minetest.chat_send_player(player:get_player_name(), "Recording stopped.")
end

-- Function to save recorded positions
local function save_recording(player)
    local name = player:get_player_name()
    local file = io.open(minetest.get_worldpath() .. "/recording_" .. name .. ".txt", "w")
    for _, record in ipairs(recorded_positions) do
        file:write(minetest.pos_to_string(record.pos) .. " " .. record.yaw .. " " .. record.tick .. "\n")
    end
    file:close()
    minetest.chat_send_player(name, "Recording saved.")
end

-- Register chat commands
minetest.register_chatcommand("start_rec", {
    description = "Start recording player movements",
    func = function(name)
        local player = minetest.get_player_by_name(name)
        if player then
            start_recording(player)
        end
    end
})

minetest.register_chatcommand("stop_rec", {
    description = "Stop recording player movements",
    func = function(name)
        local player = minetest.get_player_by_name(name)
        if player then
            stop_recording(player)
        end
    end
})

minetest.register_chatcommand("save_recording", {
    description = "Save recorded movements",
    func = function(name)
        local player = minetest.get_player_by_name(name)
        if player then
            save_recording(player)
        end
    end
})

-- Globalstep function to record player position and yaw with tick count
minetest.register_globalstep(function(dtime)
    if recording then
        tick_count = tick_count + 1
        for _, player in ipairs(minetest.get_connected_players()) do
            table.insert(recorded_positions, {
                pos = player:get_pos(),
                yaw = player:get_look_horizontal(),
                tick = tick_count
            })
        end
    end
end)
-- Function to interpolate between two values
local function lerp(a, b, t)
    return a + (b - a) * t
end

-- Function to interpolate between two positions and yaws
local function interpolate_state(state1, state2, t)
    return {
        pos = {
            x = lerp(state1.pos.x, state2.pos.x, t),
            y = lerp(state1.pos.y, state2.pos.y, t),
            z = lerp(state1.pos.z, state2.pos.z, t)
        },
        yaw = lerp(state1.yaw, state2.yaw, t)
    }
end

-- Function to move a mob along the recorded path with interpolation
local function move_mob_along_path(mob, path)
    local step = 1
    local current_tick = 0

    minetest.register_globalstep(function(dtime)
        current_tick = current_tick + 1
        if step < #path then
            local t = (current_tick - path[step].tick) / (path[step + 1].tick - path[step].tick)

            -- Interpolate between the current and next state
            local interpolated_state = interpolate_state(path[step], path[step + 1], t)

            -- Set the mob's position and yaw
            mob:set_pos(interpolated_state.pos)
            mob:set_yaw(interpolated_state.yaw)

            -- Move to the next step if the tick count has passed
            if current_tick >= path[step + 1].tick then
                step = step + 1
            end
        end
    end)
end

-- Define a custom mob entity
minetest.register_entity("mocapformt:notplayer", {
    initial_properties = {
        physical = true,
        collide_with_objects = true,
        collisionbox = {-0.35, -0.5, -0.35, 0.35, 1, 0.35},
        visual = "mesh",
        mesh = "character.b3d",
        textures = {"character.png"},
    },
    on_activate = function(self, staticdata, dtime_s)
        -- Load the path from the recorded positions
        move_mob_along_path(self.object, recorded_positions)
    end,
})


minetest.register_chatcommand("playback", {
    description = "Playback the recorded path with a custom mob",
    func = function(name)
        local player = minetest.get_player_by_name(name)
        if player then
            local pos = player:get_pos()
            pos.y = pos.y + 1 -- Spawn mob slightly above the player
            local mob = minetest.add_entity(pos, "mocapformt:notplayer")
            move_mob_along_path(mob, recorded_positions)
        end
    end
})
minetest.register_chatcommand("show_rec", {
    description = "Playback the recorded path with a custom mob",
    func = function(name)
        local player = minetest.get_player_by_name(name)
        if player then
            local pos = player:get_pos()
            pos.y = pos.y + 1 -- Spawn mob slightly above the player
            local mob = minetest.add_entity(pos, "mocapformt:notplayer")
            move_mob_along_path(mob, recorded_positions)
        end
    end
})