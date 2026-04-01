local function get_nearest_player(pos)
    local nearest, dist = nil, math.huge

    for _, player in ipairs(core.get_connected_players()) do
        local p = player:get_pos()
        if p then
            local d = vector.distance(pos, p)
            if d < dist then
                dist = d
                nearest = player
            end
        end
    end

    return nearest, dist
end

local function move_towards(self, pos, target, speed)
    local dir = vector.direction(pos, target)
    self.object:set_velocity(vector.multiply(dir, speed))
    self.object:set_yaw(math.atan2(dir.x, dir.z))
    return dir
end


core.register_entity("fingore:scripulous", {
    initial_properties = {
        physical = true,
        collide_with_objects = true,
        collisionbox = {-0.3,-0.4,-0.3,1.3,1.4,1.3},
        visual = "mesh",
        mesh = "fingore.glb",
        textures = {"fingore.png"},
        visual_size = {x = 1, y = 1},
        damage_texture_modifier = "^[colorize:#ff0000:120",
        static_save = true,
    },

    timer = 0,
    attack_cooldown = 0,
    wander_dir = nil,
    speed = 1.5,
    damage = 15,

    on_activate = function(self)
        if math.random(1,5) == 1 then
            self.object:set_properties({mesh = "fingore_nuhuh.glb"})
        end

        self.speed = math.random(3,6)
        self.damage = math.random(10,20)
    end,

    on_step = function(self, dtime)
        self.timer = self.timer + dtime
        self.attack_cooldown = math.max(0, self.attack_cooldown - dtime)

        if self.timer < 0.2 then return end
        self.timer = 0

        local pos = self.object:get_pos()
        if not pos then return end

        local player, dist = get_nearest_player(pos)
        local light = core.get_node_light(pos, 0.5) or 15
        local rage = light <= 7

        if player then
            local target = player:get_pos()
            if not target then return end

            local speed = rage and self.speed * 1.8 or self.speed
            local dir = move_towards(self, pos, target, speed)

            if dist <= 1.5 and self.attack_cooldown <= 0 then
                player:punch(self.object, 1, {
                    full_punch_interval = 1,
                    damage_groups = {fleshy = self.damage}
                })
                self.object:set_velocity(vector.multiply(dir, 8))
                self.attack_cooldown = rage and 1 or 2
            end
        else
            if not self.wander_dir or math.random(1,10) == 1 then
                self.wander_dir = {
                    x = math.random(-1,1),
                    y = 0,
                    z = math.random(-1,1)
                }
            end

            self.object:set_velocity(vector.multiply(self.wander_dir, 1.5))
        end
    end,

    on_punch = function(self, hitter)
        local pos = self.object:get_pos()

        if pos and math.random(1,10) == 1 then
            core.add_item(pos, "fingore:fingore_egg")
        end

        core.add_particlespawner({
            amount = 20,
            time = 0.2,
            minpos = pos,
            maxpos = pos,
            texture = "fingore_hand.png",
        })

        self.object:remove()
    end
})

-- boss
core.register_entity("fingore:sunglasses",{

    initial_properties = {
        physical = true,
        collide_with_objects = true,
        collisionbox = {-0.3,-0.4,-0.3,1.3,1.4,1.3},
        visual = "mesh",
        mesh = "fingore_sunglasses_boss.glb",
        textures = {"fingore_sunglasses_boss.png"},
        visual_size = {x=1.4,y=1.4},
        damage_texture_modifier = "^[colorize:#ff0000:120",
        static_save = true
    },

    timer = 0,
    attack_cooldown = 1,
    hp = 120,
    speed = 2.5,

    on_activate = function(self)
        self.object:set_armor_groups({fleshy=50})
    end,

    on_step = function(self,dtime)
        self.timer = self.timer + dtime
        self.attack_cooldown = math.max(0,self.attack_cooldown - dtime)

        if self.timer < 0.2 then return end
        self.timer = 0

        local pos = self.object:get_pos()
        local nearest, dist = get_nearest_player(pos)

        if nearest then
            local target = nearest:get_pos()
            local dir = vector.direction(pos,target)

            self.object:set_velocity(vector.multiply(dir,5))
            self.object:set_yaw(math.atan2(dir.x,dir.z))

            if dist < 2 and self.attack_cooldown <= 0 then
                nearest:punch(self.object,1,{
                    full_punch_interval = 1,
                    damage_groups = {fleshy = 30}
                })

                self.object:set_velocity(vector.multiply(dir,8))
                self.attack_cooldown = 1.5
            end
        end
    end,

    on_punch = function(self)
        self.hp = self.hp - 10

        if self.hp <= 0 then
            local pos = self.object:get_pos()

            if pos then
                core.add_item(pos,"fingore:fingore_sunglasses")
                if math.random(1,30) == 1 then
                    core.add_item(pos,"fingore:fingore_hand")
                end
            end

            self.object:remove()
        end
    end
})