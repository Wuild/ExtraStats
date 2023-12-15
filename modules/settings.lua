local Module = ExtraStats.modules:NewModule("settings")

local categories = {
    base = {
        stats = {
            health,
            power
        }
    },
    attributes = {
        stats = {
            strength,
            agility,
            stamina,
            intellect,
            spirit
        }
    },
    melee = {
        stats = {
            damage,
            attackspeed,
            attackpower,
            hitrating,
            critchance,
        }
    },
    ranged = {
        stats = {
            ranged_damage,
            ranged_attackspeed,
            ranged_attackpower,
            ranged_hitrating,
            ranged_critchance,
        }
    },
    spell = {
        stats = {
            spell_damage,
            spell_hitrating,
            spell_critchance,
            spell_regen,
        }
    },
    defenses = {
        stats = {
            armor,
            defense,
            dodge,
            parry,
            block,
        }
    },
    enhancements = {
        stats = {
            expertise,
            resiliance
        }
    }
}

local categoriesSettings = {}

function Module:Settings(tab)

    local index = 0
    for name, object in pairs(categories) do
        categoriesSettings["category." .. name] = {
            name = name,
            type = "toggle",
            order = index,
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

    tab.categories.args = categoriesSettings;
end