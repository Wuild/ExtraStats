local Module = ExtraStats.modules:NewModule("settings")

local categories = {
    base = {
        label = "Base",
        desc = "Health and power."
    },
    attributes = {
        label = PLAYERSTAT_BASE_STATS,
        desc = "Primary attributes."
    },
    melee = {
        label = PLAYERSTAT_MELEE_COMBAT,
        desc = "Melee damage and ratings."
    },
    ranged = {
        label = PLAYERSTAT_RANGED_COMBAT,
        desc = "Ranged damage and ratings."
    },
    spell = {
        label = PLAYERSTAT_SPELL_COMBAT,
        desc = "Spell damage and ratings."
    },
    defenses = {
        label = PLAYERSTAT_DEFENSES,
        desc = "Mitigation and avoidance."
    },
    enhancements = {
        label = "Enhancements",
        desc = "Secondary bonuses."
    }
}

function Module:Settings(tab)
    local categoriesSettings = {}
    local index = 1
    local order = { "base", "attributes", "melee", "ranged", "spell", "defenses", "enhancements" }

    for _, name in ipairs(order) do
        local object = categories[name]
        if object then
            categoriesSettings["category." .. name] = {
                name = object.label or name,
                desc = object.desc,
                type = "toggle",
                order = index,
                width = "full",
                set = function(info, val)
                    ExtraStats.db.char.categories[name].enabled = val;
                    ExtraStats:UpdateStatsDelayed()
                end,
                get = function(info)
                    return ExtraStats.db.char.categories[name].enabled
                end
            }
            index = index + 1
        end
    end

    tab.categories.args.list = {
        name = "Visible Categories",
        type = "group",
        inline = true,
        order = 1,
        args = categoriesSettings
    }
end
