local Module = ExtraStats.modules:NewModule("settings")

local categories = {
    base = {
        label = ExtraStats:translate("stats.base"),
        desc = ExtraStats:translate("settings.category.base_desc")
    },
    attributes = {
        label = PLAYERSTAT_BASE_STATS,
        desc = ExtraStats:translate("settings.category.attributes_desc")
    },
    melee = {
        label = PLAYERSTAT_MELEE_COMBAT,
        desc = ExtraStats:translate("settings.category.melee_desc")
    },
    ranged = {
        label = PLAYERSTAT_RANGED_COMBAT,
        desc = ExtraStats:translate("settings.category.ranged_desc")
    },
    spell = {
        label = PLAYERSTAT_SPELL_COMBAT,
        desc = ExtraStats:translate("settings.category.spell_desc")
    },
    defenses = {
        label = PLAYERSTAT_DEFENSES,
        desc = ExtraStats:translate("settings.category.defenses_desc")
    },
    enhancements = {
        label = ExtraStats:translate("stats.enhancements"),
        desc = ExtraStats:translate("settings.category.enhancements_desc")
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
        name = ExtraStats:translate("settings.categories"),
        type = "group",
        inline = true,
        order = 1,
        args = categoriesSettings
    }

    tab.categories.args.support = {
        name = ExtraStats:translate("settings.support"),
        type = "group",
        inline = true,
        order = 2,
        args = {
            message = {
                name = ExtraStats:translate("settings.support_desc"),
                type = "description",
                order = 1,
                width = "full"
            },
            url = {
                name = ExtraStats:translate("settings.patreon"),
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
