local function spawn_fingore(pos, is_spawner)

    if not pos then return false end

    local node = core.get_node_or_nil(pos)
    if not node or node.name ~= "air" then
        return false
    end

    local entity_name

    if is_spawner and math.random(1,10) == 1 then
        entity_name = "fingore:sunglasses"
    else
        entity_name = "fingore:scripulous"
    end

    local ent = core.add_entity(pos, entity_name)

    return ent ~= nil
end

core.register_craftitem("fingore:fingore_egg",{
    description = "Egg of Scripulous Fingore",
    inventory_image = "fingore_egg.png",

    on_place = function(itemstack, placer)

        if not placer or not placer:is_player() then
            return itemstack
        end

        local pos = vector.add(placer:get_pos(), {x=0,y=1,z=0})

        if spawn_fingore(pos, false) then
            itemstack:take_item()
        else
            core.chat_send_player(
                placer:get_player_name(),
                "Not enough space to place the egg"
            )
        end

        return itemstack
    end
})

-- Weapons
core.register_tool("fingore:fingore_hand",{
    description = "Hand of Fingore",
    inventory_image = "fingore_hand.png",

    tool_capabilities = {
        full_punch_interval = 0.8,
        max_drop_level = 3,
        groupcaps = {},
        damage_groups = {fleshy = 20},
    },

    sound = {breaks = "default_tool_breaks"}
})

core.register_tool("fingore:fingore_sunglasses", {
    description = "Fingore Sunglasses",
    inventory_image = "fingore_sunglasses.png",

    tool_capabilities = {
        full_punch_interval = 0.7,
        damage_groups = {fleshy = 5},
    },
})

local function player_has_sunglasses(player)
    local inv = player:get_inventory()
    local stack = inv:get_stack("main", player:get_wield_index())
    return stack:get_name() == "fingore:fingore_sunglasses"
end

local huds = {}

core.register_globalstep(function(dtime)
    for _, player in ipairs(core.get_connected_players()) do
        if not player or not player:is_player() then
            return
        end
        local name = player:get_player_name()
        local has = player_has_sunglasses(player)
        if has then
            local pos = player:get_pos()
            local light = core.get_node_light(pos, 0.5) or 0

            if light < 8 then
                player:set_properties({ glow = 5 })
            else
                player:set_properties({ glow = 0 })
            end
            if not huds[name] then
                huds[name] = player:hud_add({
                    hud_elem_type = "image",
                    position = {x = 0.5, y = 0.5},
                    scale = {x = -100, y = -100},
                    text = "fingore_sunglasses_overlay.png",
                    alignment = {x = 0, y = 0},
                    offset = {x = 0, y = 0},
                })
            end

        else
            player:set_physics_override({ speed = 1 })
            player:set_properties({ glow = 0 })

            if huds[name] then
                player:hud_remove(huds[name])
                huds[name] = nil
            end
        end
    end
end)


core.register_on_chat_message(function(name,message)

    if math.random(1,10) == 1 then
        core.after(0.1,function()
            core.chat_send_all("<Scripulous Fingore> Nuh uh")
        end)
    end

    return false
end)

-- Nodes
core.register_node("fingore:fingore_bone",{
    description = "Fingore Bone",
    tiles = {"fingore_bone.png"},
    groups = {cracky=2,oddly_breakable_by_hand=2},
    sounds = {},
    drop = "fingore:fingore_bone"
})


local SPAWN_RADIUS = 8
local MAX_MOBS = 2
local PLAYER_RANGE = 20

local function count_mobs(pos)
    local objs = core.get_objects_inside_radius(pos, SPAWN_RADIUS)
    local c = 0

    for _, obj in ipairs(objs) do
        local e = obj:get_luaentity()
        if e and (e.name == "fingore:scripulous" or e.name == "fingore:sunglasses") then
            c = c + 1
        end
    end

    return c
end

local function player_near(pos)
    for _, p in ipairs(core.get_connected_players()) do
        if vector.distance(pos, p:get_pos()) <= PLAYER_RANGE then
            return true
        end
    end
    return false
end

local function get_spawn_pos(center)
    for i = 1, 10 do
        local p = vector.add(center, {
            x = math.random(-SPAWN_RADIUS, SPAWN_RADIUS),
            y = math.random(-2, 2),
            z = math.random(-SPAWN_RADIUS, SPAWN_RADIUS)
        })

        local node = core.get_node(p)
        local below = core.get_node({x=p.x, y=p.y-1, z=p.z})
        local def = core.registered_nodes[below.name]

        if node.name == "air"
        and def and def.walkable then

            local light = core.get_node_light(p) or 0

            if light <= 8 then
                return p
            end
        end
    end

    return nil
end

local function spawn(pos)
    local name = (math.random(1,10) == 1)
        and "fingore:sunglasses"
        or "fingore:scripulous"

    return core.add_entity(pos, name)
end

core.register_node("fingore:fingore_spawner", {
    description = "Fingore Spawner",
    tiles = {"fingore_spawner.png"},
    groups = {cracky=1},
    drop = "",

    on_construct = function(pos)
        core.get_node_timer(pos):start(2)
    end,

    on_destruct = function(pos)
        core.get_node_timer(pos):stop()
    end,

    on_timer = function(pos)
        local timer = core.get_node_timer(pos)

        if not player_near(pos) then
            timer:start(5)
            return true
        end

        if count_mobs(pos) >= MAX_MOBS then
            timer:start(5)
            return true
        end

        local attempts = math.random(1,4)

        for i = 1, attempts do
            local p = get_spawn_pos(pos)
            if p then
                spawn(p)
            end
        end

        timer:start(math.random(2,4))
        return true
    end
})

core.register_lbm({
    name = "fingore:activate_spawner",
    nodenames = {"fingore:fingore_spawner"},
    run_at_every_load = true,

    action = function(pos, node)
        local timer = core.get_node_timer(pos)
        timer:stop()
        timer:start(math.random(1,3))
    end,
})

core.register_decoration({
    name = "fingore:fossil_spawn",
    deco_type = "schematic",
    place_on = {"group:stone"},
    sidelen = 16,
    fill_ratio = 0.00003,
    y_max = -10,
    y_min = -500,

    schematic = core.get_modpath("fingore") .. "/schematics/fingore_fossil.mts",
    flags = "place_center_x, place_center_z",
    rotation = "random"
})