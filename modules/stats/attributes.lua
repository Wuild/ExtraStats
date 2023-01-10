local L = LibStub("AceLocale-3.0"):GetLocale("ExtraStats", true)

local function GetStat(statIndex)
    local textValue;
    local stat;
    local effectiveStat;
    local posBuff;
    local negBuff;
    local tooltip;
    local tooltip2;
    local unit = "player"
    stat, effectiveStat, posBuff, negBuff = UnitStat(unit, statIndex);
    local statName = _G["SPELL_STAT" .. statIndex .. "_NAME"];
    -- Set the tooltip text
    local tooltipText = HIGHLIGHT_FONT_COLOR_CODE .. format(PAPERDOLLFRAME_TOOLTIP_FORMAT, statName) .. " ";

    if ((posBuff == 0) and (negBuff == 0)) then
        textValue = effectiveStat
        tooltip = tooltipText .. effectiveStat .. FONT_COLOR_CODE_CLOSE;
    else
        tooltipText = tooltipText .. effectiveStat;
        if (posBuff > 0 or negBuff < 0) then
            tooltipText = tooltipText .. " (" .. (stat - posBuff - negBuff) .. FONT_COLOR_CODE_CLOSE;
        end
        if (posBuff > 0) then
            tooltipText = tooltipText .. FONT_COLOR_CODE_CLOSE .. GREEN_FONT_COLOR_CODE .. "+" .. posBuff .. FONT_COLOR_CODE_CLOSE;
        end
        if (negBuff < 0) then
            tooltipText = tooltipText .. RED_FONT_COLOR_CODE .. " " .. negBuff .. FONT_COLOR_CODE_CLOSE;
        end
        if (posBuff > 0 or negBuff < 0) then
            tooltipText = tooltipText .. HIGHLIGHT_FONT_COLOR_CODE .. ")" .. FONT_COLOR_CODE_CLOSE;
        end
        tooltip = tooltipText;

        -- If there are any negative buffs then show the main number in red even if there are
        -- positive buffs. Otherwise show in green.
        if (negBuff < 0) then
            textValue = RED_FONT_COLOR_CODE .. effectiveStat .. FONT_COLOR_CODE_CLOSE;
        else
            textValue = GREEN_FONT_COLOR_CODE .. effectiveStat .. FONT_COLOR_CODE_CLOSE;
        end
    end
    local _, unitClass = UnitClass("player");
    unitClass = strupper(unitClass);

    tooltip2 = _G["DEFAULT_STAT" .. statIndex .. "_TOOLTIP"];

    if (statIndex == 1) then
        local attackPower = GetAttackPowerForStat(statIndex, effectiveStat);
        tooltip2 = format(tooltip2, attackPower);
        if (unitClass == "WARRIOR" or unitClass == "SHAMAN" or unitClass == "PALADIN") then
            tooltip2 = tooltip2 .. "\n" .. format(STAT_BLOCK_TOOLTIP, max(0, effectiveStat * BLOCK_PER_STRENGTH - 10));
        end
    elseif (statIndex == 3) then
        local baseStam = min(20, effectiveStat);
        local moreStam = effectiveStat - baseStam;
        tooltip2 = format(tooltip2, (baseStam + (moreStam * HEALTH_PER_STAMINA)) * GetUnitMaxHealthModifier("player"));
        local petStam = ComputePetBonus("PET_BONUS_STAM", effectiveStat);
        if (petStam > 0) then
            tooltip2 = tooltip2 .. "\n" .. format(PET_BONUS_TOOLTIP_STAMINA, petStam);
        end
    elseif (statIndex == 2) then
        local attackPower = GetAttackPowerForStat(statIndex, effectiveStat);
        if (attackPower > 0) then
            tooltip2 = format(STAT_ATTACK_POWER, attackPower) .. format(tooltip2, GetCritChanceFromAgility("player"), effectiveStat * ARMOR_PER_AGILITY);
        else
            tooltip2 = format(tooltip2, GetCritChanceFromAgility("player"), effectiveStat * ARMOR_PER_AGILITY);
        end
    elseif (statIndex == 4) then
        local baseInt = min(20, effectiveStat);
        local moreInt = effectiveStat - baseInt
        if (UnitHasMana("player")) then
            tooltip2 = format(tooltip2, baseInt + moreInt * MANA_PER_INTELLECT, GetSpellCritChanceFromIntellect("player"));
        else
            tooltip2 = nil;
        end
        local petInt = ComputePetBonus("PET_BONUS_INT", effectiveStat);
        if (petInt > 0) then
            if (not tooltip2) then
                tooltip2 = "";
            end
            tooltip2 = tooltip2 .. "\n" .. format(PET_BONUS_TOOLTIP_INTELLECT, petInt);
        end
    elseif (statIndex == 5) then
        -- All mana regen stats are displayed as mana/5 sec.
        tooltip2 = format(tooltip2, GetUnitHealthRegenRateFromSpirit("player"));
        if (UnitHasMana("player")) then
            local regen = GetUnitManaRegenRateFromSpirit("player");
            regen = floor(regen * 5.0);
            tooltip2 = tooltip2 .. "\n" .. format(MANA_REGEN_FROM_SPIRIT, regen);
        end
    end

    return {
        value = textValue,
        tooltip = tooltip,
        tooltip2 = tooltip2,
    }
end

local Module = {  }

function Module:Setup()
    local Category = ExtraStats:CreateCategory("attributes", ExtraStats:translate("stats.attributes"), {
        order = -10
    })

    Category:Add(ExtraStats:translate("stats.attributes.strength"), function()
        return GetStat(LE_UNIT_STAT_STRENGTH)
    end, {
        classes = { INDEX_CLASS_PALADIN, INDEX_CLASS_WARRIOR, INDEX_CLASS_DRUID, INDEX_CLASS_DEATH_KNIGHT }
    })

    Category:Add(ExtraStats:translate("stats.attributes.agility"), function()
        return GetStat(LE_UNIT_STAT_AGILITY)
    end, {
        classes = { INDEX_CLASS_ROGUE, INDEX_CLASS_WARRIOR, INDEX_CLASS_DRUID, INDEX_CLASS_HUNTER }
    })

    Category:Add(ExtraStats:translate("stats.attributes.stamina"), function()
        return GetStat(LE_UNIT_STAT_STAMINA)
    end)

    Category:Add(ExtraStats:translate("stats.attributes.intellect"), function()
        return GetStat(LE_UNIT_STAT_INTELLECT)
    end, {
        classes = { INDEX_CLASS_PALADIN, INDEX_CLASS_MAGE, INDEX_CLASS_PRIEST, INDEX_CLASS_DRUID, INDEX_CLASS_WARLOCK, INDEX_CLASS_SHAMAN },
    })

    Category:Add(ExtraStats:translate("stats.attributes.spirit"), function()
        return GetStat(LE_UNIT_STAT_SPIRIT)
    end, {
        classes = { INDEX_CLASS_PALADIN, INDEX_CLASS_PRIEST, INDEX_CLASS_DRUID, INDEX_CLASS_SHAMAN },
    })
end

do
    table.insert(ExtraStats.modules, Module)
end