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

local categoryOrder = { "base", "attributes", "melee", "ranged", "spell", "defenses", "enhancements" }

function Module:Settings(tab)
    local categoriesSettings = {}
    local index = 1

    for _, name in ipairs(categoryOrder) do
        local categoryId = name
        local object = categories[categoryId]
        if object then
            categoriesSettings["category." .. categoryId] = {
                name = object.label or categoryId,
                desc = object.desc,
                type = "toggle",
                order = index,
                width = "full",
                set = function(info, val)
                    ExtraStats.db.char.categories[categoryId].enabled = val;
                    ExtraStats:UpdateStats()
                end,
                get = function(info)
                    return ExtraStats.db.char.categories[categoryId].enabled
                end
            }
            index = index + 1
        end
    end

    tab.categories.args.list = {
        name = "Categories",
        type = "group",
        inline = true,
        order = 1,
        args = categoriesSettings
    }

    tab.categories.args.support = {
        name = "Support",
        type = "group",
        inline = true,
        order = 2,
        args = {
            message = {
                name = "If you want to support ExtraStats, check out the Patreon below.",
                type = "description",
                order = 1,
                width = "full"
            },
            url = {
                name = "Patreon",
                type = "input",
                order = 2,
                width = "full",
                set = function() end,
                get = function()
                    return "https://www.patreon.com/c/Wuild"
                end
            }
        }
    }
end
