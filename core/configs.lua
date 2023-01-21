local name, stats = ...;

stats.name = name;
stats.version = GetAddOnMetadata(name, "version");

ExtraStats = LibStub("AceAddon-3.0"):NewAddon("ExtraStats", "AceConsole-3.0", "AceEvent-3.0", "AceTimer-3.0", "AceComm-3.0", "AceSerializer-3.0")

ExtraStats.modules = {}
ExtraStats.plugins = {}

ExtraStats.modules = {}

ExtraStats.categoryYOffset = -5;
ExtraStats.statYOffset = 0;

stats.DEBUG_DEFAULT = 1;
stats.DEBUG_NODE = 2;
stats.DEBUG_FRAME = 3;
stats.DEBUG_P2P = 4;

stats.debug = {
    [stats.DEBUG_DEFAULT] = "default",
    [stats.DEBUG_P2P] = "p2p",
}

stats.window = {
    width = 237,
    height = 400
}

stats.role = GetTalentGroupRole(GetActiveTalentGroup());

stats.iconPath = "Interface\\AddOns\\" .. name .. "\\"

UIPanelWindows["CharacterFrame"] = { area = "left", pushable = 3, whileDead = 1, width = 580 };

stats.configsDefaults = {
    global = {
        debug = {
            enabled = false
        },
    },
    char = {
        enabled = true,
        dynamic = true,
        disabledPlugins = {},
        sets = {},
        categories = {
            base = {
                enabled = true,
                stats = {
                    health = true,
                    power = true,
                }
            },
            attributes = {
                enabled = true,
                stats = {
                    strength = true,
                    agility = true,
                    stamina = true,
                    intellect = true,
                    spirit = true
                }
            },
            melee = {
                enabled = true,
                stats = {
                    damage = true,
                    attackspeed = true,
                    attackpower = true,
                    hitrating = true,
                    critchance = true,
                    haste = true,
                }
            },
            ranged = {
                enabled = true,
                stats = {
                    ranged_damage = true,
                    ranged_attackspeed = true,
                    ranged_attackpower = true,
                    ranged_hitrating = true,
                    ranged_critchance = true,
                }
            },
            spell = {
                enabled = true,
                stats = {
                    spell_damage = true,
                    spell_healing = true,
                    spell_hitrating = true,
                    spell_critchance = true,
                    spell_haste = true,
                    spell_regen = true,
                }
            },
            defenses = {
                enabled = true,
                stats = {
                    armor = true,
                    defense = true,
                    dodge = true,
                    parry = true,
                    block = true,
                }
            },
            enhancements = {
                enabled = true,
                stats = {
                    expertise = true,
                    resiliance = true
                }
            }
        }
    },
    profile = {

    }
}