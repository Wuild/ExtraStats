local name, stats = ...

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

LibStub("AceConfig-3.0"):RegisterOptionsTable("ExtraStats", {
    type = "group",
    childGroups = "tab",
    args = {
        dynamic = {
            name = "Dynamic",
            type = "toggle",
            order = index,
            set = function(info, val)
                ExtraStats.db.char.dynamic = val;
                ExtraStats:UpdateStatsDelayed()
            end,
            get = function(info)
                return ExtraStats.db.char.dynamic
            end
        },

        tracking = {
            name = function()
                return "Categories";
            end,
            type = "group",
            order = 1,
            args = categoriesSettings
        }
    },

})

LibStub("AceConfigDialog-3.0"):AddToBlizOptions("ExtraStats", "Extra Stats");