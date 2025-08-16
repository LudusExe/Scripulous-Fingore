minetest.register_entity("fingore:scripulous", {
    initial_properties = {
        physical = true,
        collide_with_objects = true,
        collisionbox = {-1, -1, -1, 1, 1, 1},
        visual = "mesh",
        mesh = "fingore.gltf",
        textures = {"fingore.png"},
        visual_size = {x = 1, y = 1},
        damage_texture_modifier = "^[colorize:#ff0000:120",
        static_save = true,
        makes_footstep_sound = false,
    },

    timer = 0,
    attack_cooldown = 0,

    on_step = function(self, dtime)
        self.timer = self.timer + dtime
        self.attack_cooldown = math.max(0, self.attack_cooldown - dtime)
        if self.timer < 0.2 then return end
        self.timer = 0

        local pos = self.object:get_pos()
        if not pos then return end

        local nearest_player
        local nearest_dist_sq = 100

        for _, player in ipairs(minetest.get_connected_players()) do
            local ppos = player:get_pos()
            if ppos then
                local dist_sq = vector.distance(pos, ppos)^2
                if dist_sq <= nearest_dist_sq then
                    nearest_player = player
                    nearest_dist_sq = dist_sq
                end
            end
        end

        if nearest_player then
            local target_pos = nearest_player:get_pos()
            if target_pos then
                local dir = vector.subtract(target_pos, pos)
                local dist = vector.length(dir)
                if dist > 0 then
                    dir = vector.normalize(dir)
                    self.object:set_velocity(vector.multiply(dir, 2))
                    self.object:set_yaw(math.atan2(dir.x, dir.z))
                end
                if dist <= 1.5 and self.attack_cooldown <= 0 then
                    nearest_player:punch(self.object, 1.0, {
                        full_punch_interval = 1.0,
                        damage_groups = {fleshy = 15},
                    }, nil)
                    self.attack_cooldown = 2
                end
            end
        else
            local velocity = self.object:get_velocity()
            self.object:set_velocity({x = 0, y = velocity.y, z = 0})
        end
    end,
on_punch = function(self, hitter)
        if hitter and hitter:is_player() then
            minetest.chat_send_all("Scripulous Fingore fades into the darkness...")

            local pos = self.object:get_pos()
            if pos then
                if math.random(25, 100) == 25 then --25%
                minetest.add_item(pos, "fingore:fingore_egg")
                if math.random(1, 100) == 1 then --1%
                    minetest.add_item(pos, "fingore:fingore_hand")
                end
            end
        end
    end
        self.object:remove()
    end,
})

minetest.register_chatcommand("spawn_fingore", {
    description = "Spawn Scripulous Fingore",
    privs = {give = true},
    func = function(name)
        local player = minetest.get_player_by_name(name)
        if not player then
            return false, "Player not found."
        end

        local spawn_pos = vector.add(player:get_pos(), {x = 3, y = 0, z = 0})
        local node = minetest.get_node_or_nil(spawn_pos)
        if node and node.name ~= "air" then
            return false, "Cannot spawn Fingore: no air space above player."
        end

        local entity = minetest.add_entity(spawn_pos, "fingore:scripulous")
        if entity then
            return true, "Scripulous Fingore has spawned..."
        else
            return false, "Failed to spawn Fingore."
        end
    end
})

local function try_spawn_fingore()
    for _, player in ipairs(minetest.get_connected_players()) do
        local pos = player:get_pos()
        if pos and pos.y < 0 then
            local under_pos = vector.offset(pos, 0, -1, 0)
            local node = minetest.get_node_or_nil(under_pos)

            if node and node.name ~= "ignore" then
                local light = minetest.get_node_light(pos, 0.5) or 15
                if light <= 7 and math.random(1, 7000) == 1 then
                    local spawn_offset = {
                        x = math.random(-3, 3),
                        y = 1,
                        z = math.random(-3, 3),
                    }
                    local spawn_pos = vector.add(pos, spawn_offset)
                    local spawn_node = minetest.get_node_or_nil(spawn_pos)
                    if spawn_node and spawn_node.name == "air" then
                        minetest.add_entity(spawn_pos, "fingore:scripulous")
                        minetest.chat_send_all("You feel an evil presence lurking nearby...")
                    end
                end
            end
        end
    end
end

local global_timer = 0
minetest.register_globalstep(function(dtime)
    global_timer = global_timer + dtime
    if global_timer >= 10 then
        try_spawn_fingore()
        global_timer = 0
    end
end)

minetest.register_craftitem("fingore:fingore_egg", {
    description = "Egg of Scripulous Fingore",
    inventory_image = "fingore_egg.png",
    on_place = function(itemstack, placer, pointed_thing)
        if placer and placer:is_player() then
            local pos = placer:get_pos()
            local spawn_pos = vector.add(pos, {x = 0, y = 1, z = 0})
            local node = minetest.get_node_or_nil(spawn_pos)
            if node and node.name == "air" then
                minetest.add_entity(spawn_pos, "fingore:scripulous")
                itemstack:take_item()
                return itemstack
            else
                minetest.chat_send_player(placer:get_player_name(), "Not enough space to hatch the egg!")
                return itemstack
            end
        end
    end,
})

minetest.register_tool("fingore:fingore_hand", {
    description = "Hand of Fingore",
    inventory_image = "fingore_hand.png",
    tool_capabilities = {
        full_punch_interval = 0.8,
        max_drop_level = 3,
        groupcaps = {
        },
        damage_groups = {fleshy = 20},
    },
    sound = {breaks = "default_tool_breaks"},
})
