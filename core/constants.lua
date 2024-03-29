local name, stats = ...;

NOT_APPLICABLE = "n/a"

LE_UNIT_STAT_STRENGTH = 1
LE_UNIT_STAT_AGILITY = 2
LE_UNIT_STAT_STAMINA = 3
LE_UNIT_STAT_INTELLECT = 4
LE_UNIT_STAT_SPIRIT = 5

COMBAT_RATING_RESILIENCE_CRIT_TAKEN = 15;
COMBAT_RATING_RESILIENCE_PLAYER_DAMAGE_TAKEN = 16;

INDEX_CLASS_NONE = 0
INDEX_CLASS_WARRIOR = 1
INDEX_CLASS_PALADIN = 2
INDEX_CLASS_HUNTER = 3
INDEX_CLASS_ROGUE = 4
INDEX_CLASS_PRIEST = 5
INDEX_CLASS_DEATH_KNIGHT = 6
INDEX_CLASS_SHAMAN = 7
INDEX_CLASS_MAGE = 8
INDEX_CLASS_WARLOCK = 9
INDEX_CLASS_DRUID = 11

CLASS_ROLE_DAMAGER = "DAMAGER"
CLASS_ROLE_HEALER = "HEALER"
CLASS_ROLE_TANK = "TANK"

CURRENT_ROLE = CLASS_ROLE_DAMAGER;

CLASS_TALENTS_ROLE = {
    [INDEX_CLASS_WARRIOR] = {
        CLASS_ROLE_DAMAGER,
        CLASS_ROLE_DAMAGER,
        CLASS_ROLE_TANK,
    },
    [INDEX_CLASS_PALADIN] = {
        CLASS_ROLE_HEALER,
        CLASS_ROLE_TANK,
        CLASS_ROLE_DAMAGER,
    },
    [INDEX_CLASS_HUNTER] = {
        CLASS_ROLE_DAMAGER,
        CLASS_ROLE_DAMAGER,
        CLASS_ROLE_DAMAGER,
    },
    [INDEX_CLASS_ROGUE] = {
        CLASS_ROLE_DAMAGER,
        CLASS_ROLE_DAMAGER,
        CLASS_ROLE_DAMAGER,
    },
    [INDEX_CLASS_PRIEST] = {
        CLASS_ROLE_HEALER,
        CLASS_ROLE_HEALER,
        CLASS_ROLE_DAMAGER,
    },
    [INDEX_CLASS_DEATH_KNIGHT] = {
        CLASS_ROLE_TANK,
        CLASS_ROLE_DAMAGER,
        CLASS_ROLE_DAMAGER,
    },
    [INDEX_CLASS_SHAMAN] = {
        CLASS_ROLE_DAMAGER,
        CLASS_ROLE_DAMAGER,
        CLASS_ROLE_HEALER,
    },
    [INDEX_CLASS_MAGE] = {
        CLASS_ROLE_DAMAGER,
        CLASS_ROLE_DAMAGER,
        CLASS_ROLE_DAMAGER,
    },
    [INDEX_CLASS_WARLOCK] = {
        CLASS_ROLE_DAMAGER,
        CLASS_ROLE_DAMAGER,
        CLASS_ROLE_DAMAGER,
    },
    [INDEX_CLASS_DRUID] = {
        CLASS_ROLE_DAMAGER,
        CLASS_ROLE_TANK,
        CLASS_ROLE_HEALER,
    }
}

CR_WEAPON_SKILL = 1;
CR_DEFENSE_SKILL = 2;
CR_DODGE = 3;
CR_PARRY = 4;
CR_BLOCK = 5;
CR_HIT_MELEE = 6;
CR_HIT_RANGED = 7;
CR_HIT_SPELL = 8;
CR_CRIT_MELEE = 9;
CR_CRIT_RANGED = 10;
CR_CRIT_SPELL = 11;
CR_MULTISTRIKE = 12;
CR_READINESS = 13;
CR_SPEED = 14;
CR_RESILIENCE_CRIT_TAKEN = 15;
CR_RESILIENCE_PLAYER_DAMAGE_TAKEN = 16;
CR_LIFESTEAL = 17;
CR_HASTE_MELEE = 18;
CR_HASTE_RANGED = 19;
CR_HASTE_SPELL = 20;
CR_AVOIDANCE = 21;
CR_WEAPON_SKILL_OFFHAND = 22;
CR_WEAPON_SKILL_RANGED = 23;
CR_EXPERTISE = 24;
CR_ARMOR_PENETRATION = 25;
CR_MASTERY = 26;
CR_PVP_POWER = 27;
CR_VERSATILITY_DAMAGE_DONE = 29;
CR_VERSATILITY_DAMAGE_TAKEN = 31;