local function GetDodgeBlockParryChanceFromDefense()
    local base, modifier = UnitDefense("player");
    --local defensePercent = DODGE_PARRY_BLOCK_PERCENT_PER_DEFENSE * modifier;
    local defensePercent = DODGE_PARRY_BLOCK_PERCENT_PER_DEFENSE * ((base + modifier) - (UnitLevel("player") * 5));
    defensePercent = max(defensePercent, 0);
    return defensePercent;
end

local function Armor()
    local value, tooltip, tooltip2;
    local base, effectiveArmor, armor, posBuff, negBuff = UnitArmor("player");

    value, tooltip = ExtraStats:FormatStat(ARMOR, base, posBuff, negBuff);

    local armorReduction = PaperDollFrame_GetArmorReduction(effectiveArmor, UnitLevel("player"));
    tooltip2 = format(DEFAULT_STATARMOR_TOOLTIP, armorReduction);

    if (unit == "player") then
        local petBonus = ComputePetBonus("PET_BONUS_ARMOR", effectiveArmor);
        if (petBonus > 0) then
            tooltip2 = tooltip2 .. "\n" .. format(PET_BONUS_TOOLTIP_ARMOR, petBonus);
        end
    end

    return {
        value = value,
        tooltip = tooltip,
        tooltip2 = tooltip2
    }
end

local function Defense()
    local value, tooltip, tooltip2;
    local base, modifier = UnitDefense("player");
    local posBuff = 0;
    local negBuff = 0;
    if (modifier > 0) then
        posBuff = modifier;
    elseif (modifier < 0) then
        negBuff = modifier;
    end
    value, tooltip = ExtraStats:FormatStat(DEFENSE, base, posBuff, negBuff);

    local defensePercent = GetDodgeBlockParryChanceFromDefense();
    tooltip2 = format(DEFAULT_STATDEFENSE_TOOLTIP, GetCombatRating(CR_DEFENSE_SKILL), GetCombatRatingBonus(CR_DEFENSE_SKILL), defensePercent, defensePercent);

    return {
        value = value,
        tooltip = tooltip,
        tooltip2 = tooltip2
    }
end

local function Dodge()
    local chance = GetDodgeChance();
    local tooltip = HIGHLIGHT_FONT_COLOR_CODE .. format(PAPERDOLLFRAME_TOOLTIP_FORMAT, DODGE_CHANCE) .. " " .. string.format("%.02f", chance) .. "%" .. FONT_COLOR_CODE_CLOSE;
    local tooltip2 = format(CR_DODGE_TOOLTIP, GetCombatRating(CR_DODGE), GetCombatRatingBonus(CR_DODGE));

    return {
        value = format("%.2f%%", chance),
        tooltip = tooltip,
        tooltip2 = tooltip2
    }
end

local function Block()
    local chance = GetBlockChance();
    local tooltip = HIGHLIGHT_FONT_COLOR_CODE .. format(PAPERDOLLFRAME_TOOLTIP_FORMAT, BLOCK_CHANCE) .. " " .. string.format("%.02f", chance) .. "%" .. FONT_COLOR_CODE_CLOSE;
    local tooltip2 = format(CR_BLOCK_TOOLTIP, GetCombatRating(CR_BLOCK), GetCombatRatingBonus(CR_BLOCK), GetShieldBlock());

    return {
        value = format("%.2f%%", chance),
        tooltip = tooltip,
        tooltip2 = tooltip2
    }
end

local function Parry()
    local chance = GetParryChance();
    local tooltip = HIGHLIGHT_FONT_COLOR_CODE .. format(PAPERDOLLFRAME_TOOLTIP_FORMAT, PARRY_CHANCE) .. " " .. string.format("%.02f", chance) .. "%" .. FONT_COLOR_CODE_CLOSE;
    local tooltip2 = format(CR_PARRY_TOOLTIP, GetCombatRating(CR_PARRY), GetCombatRatingBonus(CR_PARRY));

    return {
        value = format("%.2f%%", chance),
        tooltip = tooltip,
        tooltip2 = tooltip2
    }
end

local Module = ExtraStats.modules:NewModule("defense")

function Module:OnEnable()
    local stats = ExtraStats:LoadModule("character.stats")

    local Category = stats:CreateCategory("defenses", ExtraStats:translate("stats.defense"), {
        order = 20,
        roles = { CLASS_ROLE_TANK },
    })

    Category:Add(ExtraStats:translate("stats.armor"), Armor)
    Category:Add(ExtraStats:translate("stats.defense"), Defense)
    Category:Add(ExtraStats:translate("stats.dodge"), Dodge)
    Category:Add(ExtraStats:translate("stats.block"), Block)
    Category:Add(ExtraStats:translate("stats.parry"), Parry)
end