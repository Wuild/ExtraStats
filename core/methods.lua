local name, stats = ...;

local Semver = LibStub("Semver");

ExtraStats.stats = {}

function ExtraStats:print(...)
    print(ExtraStats:Colorize("<" .. name .. ">", "cyan"), ...)
end

function ExtraStats:debug(...)
    if (ExtraStats.db.global.debug.enabled) then
        print(ExtraStats:Colorize("<" .. stats.name .. " - " .. (stats.debug[stats.DEBUG_DEFAULT]) .. ">", "blue"), ...)
    end
end

function ExtraStats:Colorize(str, color)
    local c = '';
    if color == 'red' then
        c = '|cffff0000';
    elseif color == 'gray' then
        c = '|cFFCFCFCF';
    elseif color == 'purple' then
        c = '|cFFB900FF';
    elseif color == 'blue' then
        c = '|cB900FFFF';
    elseif color == 'yellow' then
        c = '|cFFFFB900';
    elseif color == 'green' then
        c = "|cFF00FF00";
    elseif color == 'white' then
        c = "|cffffffff"
    elseif color == 'cyan' then
        c = "|cff00FFFF"
    end
    return c .. str .. "|r"
end

function ExtraStats:GetCurrentClass()
    local localizedClass, englishClass, classIndex = UnitClass("Player");
    return classIndex
end

function ExtraStats:IsMelee()
    local classIndex = ExtraStats:GetCurrentClass();

    if classIndex == INDEX_CLASS_PALADIN then
        return true
    end

    if classIndex == INDEX_CLASS_WARRIOR then
        return true
    end

    if classIndex == INDEX_CLASS_ROGUE then
        return true
    end

    if classIndex == INDEX_CLASS_DRUID then
        return true
    end

    if classIndex == INDEX_CLASS_DEATH_KNIGHT then
        return true
    end

    if classIndex == INDEX_CLASS_HUNTER then
        return true
    end

    if classIndex == INDEX_CLASS_SHAMAN then
        return true
    end
end

function ExtraStats:IsRanged()
    local classIndex = ExtraStats:GetCurrentClass();

    if classIndex == INDEX_CLASS_HUNTER then
        return true
    end
end

function ExtraStats:IsSpellUser()
    local classIndex = ExtraStats:GetCurrentClass();

    if classIndex == INDEX_CLASS_PALADIN then
        return true
    end

    if classIndex == INDEX_CLASS_PRIEST then
        return true
    end

    if classIndex == INDEX_CLASS_DRUID then

        return true
    end

    if classIndex == INDEX_CLASS_WARLOCK then
        return true
    end

    if classIndex == INDEX_CLASS_MAGE then
        return true
    end

    if classIndex == INDEX_CLASS_SHAMAN then
        return true
    end

end

function ExtraStats.stats:PaperDollFormatStat(name, base, posBuff, negBuff, frame, textString)
    local effective = max(0, base + posBuff + negBuff);
    local text = HIGHLIGHT_FONT_COLOR_CODE .. format(PAPERDOLLFRAME_TOOLTIP_FORMAT, name) .. " " .. effective;
    if ((posBuff == 0) and (negBuff == 0)) then
        text = text .. FONT_COLOR_CODE_CLOSE;
        textString:SetText(effective);
    else
        if (posBuff > 0 or negBuff < 0) then
            text = text .. " (" .. base .. FONT_COLOR_CODE_CLOSE;
        end
        if (posBuff > 0) then
            text = text .. FONT_COLOR_CODE_CLOSE .. GREEN_FONT_COLOR_CODE .. "+" .. posBuff .. FONT_COLOR_CODE_CLOSE;
        end
        if (negBuff < 0) then
            text = text .. RED_FONT_COLOR_CODE .. " " .. negBuff .. FONT_COLOR_CODE_CLOSE;
        end
        if (posBuff > 0 or negBuff < 0) then
            text = text .. HIGHLIGHT_FONT_COLOR_CODE .. ")" .. FONT_COLOR_CODE_CLOSE;
        end

        -- if there is a negative buff then show the main number in red, even if there are
        -- positive buffs. Otherwise show the number in green
        if (negBuff < 0) then
            textString:SetText(RED_FONT_COLOR_CODE .. effective .. FONT_COLOR_CODE_CLOSE);
        else
            textString:SetText(GREEN_FONT_COLOR_CODE .. effective .. FONT_COLOR_CODE_CLOSE);
        end
    end
    frame.tooltip = text;
end

function ExtraStats.stats:SetLabelAndText(statFrame, label, text, isPercentage)
    statFrame.Label:SetText(format(STAT_FORMAT, label));
    if (isPercentage) then
        text = format("%.2f%%", text);
    end
    statFrame.Value:SetText(text);
end

function ExtraStats.stats:SetHealth(statFrame, unit)
    if (not unit) then
        unit = "player";
    end
    local health = UnitHealthMax(unit);
    local healthText = BreakUpLargeNumbers(health);
    ExtraStats.stats:SetLabelAndText(statFrame, HEALTH, healthText, false, health);
    statFrame.tooltip = HIGHLIGHT_FONT_COLOR_CODE .. format(PAPERDOLLFRAME_TOOLTIP_FORMAT, HEALTH) .. " " .. healthText .. FONT_COLOR_CODE_CLOSE;
    if (unit == "player") then
        statFrame.tooltip2 = STAT_HEALTH_TOOLTIP;
    elseif (unit == "pet") then
        statFrame.tooltip2 = STAT_HEALTH_PET_TOOLTIP;
    end
    statFrame:Show();
end

function ExtraStats.stats:SetPower(statFrame, unit)
    if (not unit) then
        unit = "player";
    end
    local powerType, powerToken = UnitPowerType(unit);
    local power = UnitPowerMax(unit) or 0;
    local powerText = BreakUpLargeNumbers(power);
    if (powerToken and _G[powerToken]) then
        ExtraStats.stats:SetLabelAndText(statFrame, _G[powerToken], powerText, false, power);
        statFrame.tooltip = HIGHLIGHT_FONT_COLOR_CODE .. format(PAPERDOLLFRAME_TOOLTIP_FORMAT, _G[powerToken]) .. " " .. powerText .. FONT_COLOR_CODE_CLOSE;
        statFrame.tooltip2 = _G["STAT_" .. powerToken .. "_TOOLTIP"];
        statFrame:Show();
    else
        statFrame:Hide();
    end
end

function ExtraStats.stats:SetStat(statFrame, unit, statIndex)
    local label = statFrame.Label;
    local text = statFrame.Value
    local stat;
    local effectiveStat;
    local posBuff;
    local negBuff;
    stat, effectiveStat, posBuff, negBuff = UnitStat(unit, statIndex);
    local statName = _G["SPELL_STAT" .. statIndex .. "_NAME"];
    label:SetText(format(STAT_FORMAT, statName));

    -- Set the tooltip text
    local tooltipText = HIGHLIGHT_FONT_COLOR_CODE .. format(PAPERDOLLFRAME_TOOLTIP_FORMAT, statName) .. " ";

    if ((posBuff == 0) and (negBuff == 0)) then
        text:SetText(effectiveStat);
        statFrame.tooltip = tooltipText .. effectiveStat .. FONT_COLOR_CODE_CLOSE;
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
        statFrame.tooltip = tooltipText;

        -- If there are any negative buffs then show the main number in red even if there are
        -- positive buffs. Otherwise show in green.
        if (negBuff < 0) then
            text:SetText(RED_FONT_COLOR_CODE .. effectiveStat .. FONT_COLOR_CODE_CLOSE);
        else
            text:SetText(GREEN_FONT_COLOR_CODE .. effectiveStat .. FONT_COLOR_CODE_CLOSE);
        end
    end
    statFrame.tooltip2 = _G["DEFAULT_STAT" .. statIndex .. "_TOOLTIP"];
    local _, unitClass = UnitClass("player");
    unitClass = strupper(unitClass);

    if (statIndex == 1) then
        local attackPower = GetAttackPowerForStat(statIndex, effectiveStat);
        statFrame.tooltip2 = format(statFrame.tooltip2, attackPower);
        if (unitClass == "WARRIOR" or unitClass == "SHAMAN" or unitClass == "PALADIN") then
            statFrame.tooltip2 = statFrame.tooltip2 .. "\n" .. format(STAT_BLOCK_TOOLTIP, max(0, effectiveStat * BLOCK_PER_STRENGTH - 10));
        end
    elseif (statIndex == 3) then
        local baseStam = min(20, effectiveStat);
        local moreStam = effectiveStat - baseStam;
        statFrame.tooltip2 = format(statFrame.tooltip2, (baseStam + (moreStam * HEALTH_PER_STAMINA)) * GetUnitMaxHealthModifier("player"));
        local petStam = ComputePetBonus("PET_BONUS_STAM", effectiveStat);
        if (petStam > 0) then
            statFrame.tooltip2 = statFrame.tooltip2 .. "\n" .. format(PET_BONUS_TOOLTIP_STAMINA, petStam);
        end
    elseif (statIndex == 2) then
        local attackPower = GetAttackPowerForStat(statIndex, effectiveStat);
        if (attackPower > 0) then
            statFrame.tooltip2 = format(STAT_ATTACK_POWER, attackPower) .. format(statFrame.tooltip2, GetCritChanceFromAgility("player"), effectiveStat * ARMOR_PER_AGILITY);
        else
            statFrame.tooltip2 = format(statFrame.tooltip2, GetCritChanceFromAgility("player"), effectiveStat * ARMOR_PER_AGILITY);
        end
    elseif (statIndex == 4) then
        local baseInt = min(20, effectiveStat);
        local moreInt = effectiveStat - baseInt
        if (UnitHasMana("player")) then
            statFrame.tooltip2 = format(statFrame.tooltip2, baseInt + moreInt * MANA_PER_INTELLECT, GetSpellCritChanceFromIntellect("player"));
        else
            statFrame.tooltip2 = nil;
        end
        local petInt = ComputePetBonus("PET_BONUS_INT", effectiveStat);
        if (petInt > 0) then
            if (not statFrame.tooltip2) then
                statFrame.tooltip2 = "";
            end
            statFrame.tooltip2 = statFrame.tooltip2 .. "\n" .. format(PET_BONUS_TOOLTIP_INTELLECT, petInt);
        end
    elseif (statIndex == 5) then
        -- All mana regen stats are displayed as mana/5 sec.
        statFrame.tooltip2 = format(statFrame.tooltip2, GetUnitHealthRegenRateFromSpirit("player"));
        if (UnitHasMana("player")) then
            local regen = GetUnitManaRegenRateFromSpirit("player");
            regen = floor(regen * 5.0);
            statFrame.tooltip2 = statFrame.tooltip2 .. "\n" .. format(MANA_REGEN_FROM_SPIRIT, regen);
        end
    end
    statFrame:Show();
end

function ExtraStats.stats:SetRating(statFrame, ratingIndex)
    local label = statFrame.Label;
    local text = statFrame.Value
    local statName = _G["COMBAT_RATING_NAME" .. ratingIndex];
    label:SetText(format(STAT_FORMAT, statName));
    local rating = GetCombatRating(ratingIndex);
    local ratingBonus = GetCombatRatingBonus(ratingIndex);
    text:SetText(rating);

    -- Set the tooltip text
    statFrame.tooltip = HIGHLIGHT_FONT_COLOR_CODE .. format(PAPERDOLLFRAME_TOOLTIP_FORMAT, statName) .. " " .. rating .. FONT_COLOR_CODE_CLOSE;
    -- Can probably axe this if else tree if all rating tooltips follow the same format
    if (ratingIndex == CR_HIT_MELEE) then
        statFrame.tooltip2 = format(CR_HIT_MELEE_TOOLTIP, UnitLevel("player"), ratingBonus, GetCombatRating(CR_ARMOR_PENETRATION), GetArmorPenetration());
    elseif (ratingIndex == CR_HIT_RANGED) then
        statFrame.tooltip2 = format(CR_HIT_RANGED_TOOLTIP, UnitLevel("player"), ratingBonus, GetCombatRating(CR_ARMOR_PENETRATION), GetArmorPenetration());
    elseif (ratingIndex == CR_DODGE) then
        statFrame.tooltip2 = format(CR_DODGE_TOOLTIP, ratingBonus);
    elseif (ratingIndex == CR_PARRY) then
        statFrame.tooltip2 = format(CR_PARRY_TOOLTIP, ratingBonus);
    elseif (ratingIndex == CR_BLOCK) then
        statFrame.tooltip2 = format(CR_PARRY_TOOLTIP, ratingBonus);
    elseif (ratingIndex == CR_HIT_SPELL) then
        local spellPenetration = GetSpellPenetration();
        statFrame.tooltip2 = format(CR_HIT_SPELL_TOOLTIP, UnitLevel("player"), ratingBonus, spellPenetration, spellPenetration);
    elseif (ratingIndex == CR_CRIT_SPELL) then
        local holySchool = 2;
        local minCrit = GetSpellCritChance(holySchool);
        statFrame.spellCrit = {};
        statFrame.spellCrit[holySchool] = minCrit;
        local spellCrit;
        for i = (holySchool + 1), MAX_SPELL_SCHOOLS do
            spellCrit = GetSpellCritChance(i);
            minCrit = min(minCrit, spellCrit);
            statFrame.spellCrit[i] = spellCrit;
        end
        minCrit = format("%.2f%%", minCrit);
        statFrame.minCrit = minCrit;
    elseif (ratingIndex == CR_EXPERTISE) then
        statFrame.tooltip2 = format(CR_EXPERTISE_TOOLTIP, ratingBonus);
    else
        statFrame.tooltip2 = HIGHLIGHT_FONT_COLOR_CODE .. _G["COMBAT_RATING_NAME" .. ratingIndex] .. " " .. rating;
    end

    statFrame:Show();
end

function ExtraStats.stats:SetArmor(statFrame, unit)
    if (not unit) then
        unit = "player";
    end
    local base, effectiveArmor, armor, posBuff, negBuff = UnitArmor(unit);
    statFrame.Label:SetText(format(STAT_FORMAT, ARMOR));
    local text = statFrame.Value;

    ExtraStats.stats:PaperDollFormatStat(ARMOR, base, posBuff, negBuff, statFrame, text);
    local armorReduction = PaperDollFrame_GetArmorReduction(effectiveArmor, UnitLevel(unit));
    statFrame.tooltip2 = format(DEFAULT_STATARMOR_TOOLTIP, armorReduction);

    if (unit == "player") then
        local petBonus = ComputePetBonus("PET_BONUS_ARMOR", effectiveArmor);
        if (petBonus > 0) then
            statFrame.tooltip2 = statFrame.tooltip2 .. "\n" .. format(PET_BONUS_TOOLTIP_ARMOR, petBonus);
        end
    end

    statFrame:Show();
end

function ExtraStats.stats:SetDefense(statFrame, unit)
    if (not unit) then
        unit = "player";
    end
    local base, modifier = UnitDefense(unit);
    local posBuff = 0;
    local negBuff = 0;
    if (modifier > 0) then
        posBuff = modifier;
    elseif (modifier < 0) then
        negBuff = modifier;
    end

    statFrame.Label:SetText(format(STAT_FORMAT, DEFENSE));
    local text = statFrame.Value;

    ExtraStats.stats:PaperDollFormatStat(DEFENSE, base, posBuff, negBuff, statFrame, text);
    local defensePercent = GetDodgeBlockParryChanceFromDefense();
    statFrame.tooltip2 = format(DEFAULT_STATDEFENSE_TOOLTIP, GetCombatRating(CR_DEFENSE_SKILL), GetCombatRatingBonus(CR_DEFENSE_SKILL), defensePercent, defensePercent);
    statFrame:Show();
end

function ExtraStats.stats:SetDodge(statFrame)
    local chance = GetDodgeChance();
    ExtraStats.stats:SetLabelAndText(statFrame, STAT_DODGE, chance, 1);
    statFrame.tooltip = HIGHLIGHT_FONT_COLOR_CODE .. format(PAPERDOLLFRAME_TOOLTIP_FORMAT, DODGE_CHANCE) .. " " .. string.format("%.02f", chance) .. "%" .. FONT_COLOR_CODE_CLOSE;
    statFrame.tooltip2 = format(CR_DODGE_TOOLTIP, GetCombatRating(CR_DODGE), GetCombatRatingBonus(CR_DODGE));
    statFrame:Show();
end

function ExtraStats.stats:SetBlock(statFrame)
    local chance = GetBlockChance();
    ExtraStats.stats:SetLabelAndText(statFrame, STAT_BLOCK, chance, 1);
    statFrame.tooltip = HIGHLIGHT_FONT_COLOR_CODE .. format(PAPERDOLLFRAME_TOOLTIP_FORMAT, BLOCK_CHANCE) .. " " .. string.format("%.02f", chance) .. "%" .. FONT_COLOR_CODE_CLOSE;
    statFrame.tooltip2 = format(CR_BLOCK_TOOLTIP, GetCombatRating(CR_BLOCK), GetCombatRatingBonus(CR_BLOCK), GetShieldBlock());
    statFrame:Show();
end

function ExtraStats.stats:SetParry(statFrame)
    local chance = GetParryChance();
    ExtraStats.stats:SetLabelAndText(statFrame, STAT_PARRY, chance, 1);
    statFrame.tooltip = HIGHLIGHT_FONT_COLOR_CODE .. format(PAPERDOLLFRAME_TOOLTIP_FORMAT, PARRY_CHANCE) .. " " .. string.format("%.02f", chance) .. "%" .. FONT_COLOR_CODE_CLOSE;
    statFrame.tooltip2 = format(CR_PARRY_TOOLTIP, GetCombatRating(CR_PARRY), GetCombatRatingBonus(CR_PARRY));
    statFrame:Show();
end

function ExtraStats.stats:GetDodgeBlockParryChanceFromDefense()
    local base, modifier = UnitDefense("player");
    --local defensePercent = DODGE_PARRY_BLOCK_PERCENT_PER_DEFENSE * modifier;
    local defensePercent = DODGE_PARRY_BLOCK_PERCENT_PER_DEFENSE * ((base + modifier) - (UnitLevel("player") * 5));
    defensePercent = max(defensePercent, 0);
    return defensePercent;
end

function ExtraStats.stats:SetResilience(statFrame)

    local label = statFrame.Label;
    local text = statFrame.Value

    local resilienceRating = BreakUpLargeNumbers(GetCombatRating(COMBAT_RATING_RESILIENCE_PLAYER_DAMAGE_TAKEN));
    local ratingBonus = GetCombatRatingBonus(COMBAT_RATING_RESILIENCE_PLAYER_DAMAGE_TAKEN);
    local damageReduction = ratingBonus + GetCombatRatingBonus(COMBAT_RATING_RESILIENCE_PLAYER_DAMAGE_TAKEN);
    label:SetText(format(STAT_FORMAT, STAT_RESILIENCE));

    text:SetText(resilienceRating);

    statFrame.tooltip = HIGHLIGHT_FONT_COLOR_CODE .. format(PAPERDOLLFRAME_TOOLTIP_FORMAT, STAT_RESILIENCE) .. " " .. damageReduction .. FONT_COLOR_CODE_CLOSE;
    statFrame.tooltip2 = format(RESILIENCE_TOOLTIP, ratingBonus, damageReduction, damageReduction);
    statFrame:Show();
end

function ExtraStats.stats:SetDamage(statFrame, unit)
    if (not unit) then
        unit = "player";
    end

    statFrame.Label:SetText(format(STAT_FORMAT, DAMAGE));
    local text = statFrame.Value;
    local speed, offhandSpeed = UnitAttackSpeed(unit);

    local minDamage;
    local maxDamage;
    local minOffHandDamage;
    local maxOffHandDamage;
    local physicalBonusPos;
    local physicalBonusNeg;
    local percent;
    minDamage, maxDamage, minOffHandDamage, maxOffHandDamage, physicalBonusPos, physicalBonusNeg, percent = UnitDamage(unit);
    local displayMin = max(floor(minDamage), 1);
    local displayMax = max(ceil(maxDamage), 1);

    minDamage = (minDamage / percent) - physicalBonusPos - physicalBonusNeg;
    maxDamage = (maxDamage / percent) - physicalBonusPos - physicalBonusNeg;

    local baseDamage = (minDamage + maxDamage) * 0.5;
    local fullDamage = (baseDamage + physicalBonusPos + physicalBonusNeg) * percent;
    local totalBonus = (fullDamage - baseDamage);
    local damagePerSecond = (max(fullDamage, 1) / speed);
    local damageTooltip = max(floor(minDamage), 1) .. " - " .. max(ceil(maxDamage), 1);

    local colorPos = "|cff20ff20";
    local colorNeg = "|cffff2020";

    -- epsilon check
    if (totalBonus < 0.1 and totalBonus > -0.1) then
        totalBonus = 0.0;
    end

    if (totalBonus == 0) then
        if ((displayMin < 100) and (displayMax < 100)) then
            text:SetText(displayMin .. " - " .. displayMax);
        else
            text:SetText(displayMin .. "-" .. displayMax);
        end
    else

        local color;
        if (totalBonus > 0) then
            color = colorPos;
        else
            color = colorNeg;
        end
        if ((displayMin < 100) and (displayMax < 100)) then
            text:SetText(color .. displayMin .. " - " .. displayMax .. "|r");
        else
            text:SetText(color .. displayMin .. "-" .. displayMax .. "|r");
        end
        if (physicalBonusPos > 0) then
            damageTooltip = damageTooltip .. colorPos .. " +" .. physicalBonusPos .. "|r";
        end
        if (physicalBonusNeg < 0) then
            damageTooltip = damageTooltip .. colorNeg .. " " .. physicalBonusNeg .. "|r";
        end
        if (percent > 1) then
            damageTooltip = damageTooltip .. colorPos .. " x" .. floor(percent * 100 + 0.5) .. "%|r";
        elseif (percent < 1) then
            damageTooltip = damageTooltip .. colorNeg .. " x" .. floor(percent * 100 + 0.5) .. "%|r";
        end

    end
    statFrame.damage = damageTooltip;
    statFrame.attackSpeed = speed;
    statFrame.dps = damagePerSecond;

    -- If there's an offhand speed then add the offhand info to the tooltip
    if (offhandSpeed) then
        minOffHandDamage = (minOffHandDamage / percent) - physicalBonusPos - physicalBonusNeg;
        maxOffHandDamage = (maxOffHandDamage / percent) - physicalBonusPos - physicalBonusNeg;

        local offhandBaseDamage = (minOffHandDamage + maxOffHandDamage) * 0.5;
        local offhandFullDamage = (offhandBaseDamage + physicalBonusPos + physicalBonusNeg) * percent;
        local offhandDamagePerSecond = (max(offhandFullDamage, 1) / offhandSpeed);
        local offhandDamageTooltip = max(floor(minOffHandDamage), 1) .. " - " .. max(ceil(maxOffHandDamage), 1);
        if (physicalBonusPos > 0) then
            offhandDamageTooltip = offhandDamageTooltip .. colorPos .. " +" .. physicalBonusPos .. "|r";
        end
        if (physicalBonusNeg < 0) then
            offhandDamageTooltip = offhandDamageTooltip .. colorNeg .. " " .. physicalBonusNeg .. "|r";
        end
        if (percent > 1) then
            offhandDamageTooltip = offhandDamageTooltip .. colorPos .. " x" .. floor(percent * 100 + 0.5) .. "%|r";
        elseif (percent < 1) then
            offhandDamageTooltip = offhandDamageTooltip .. colorNeg .. " x" .. floor(percent * 100 + 0.5) .. "%|r";
        end
        statFrame.offhandDamage = offhandDamageTooltip;
        statFrame.offhandAttackSpeed = offhandSpeed;
        statFrame.offhandDps = offhandDamagePerSecond;
    else
        statFrame.offhandAttackSpeed = nil;
    end
    statFrame:Show();
end

function ExtraStats.stats:SetAttackSpeed(statFrame, unit)
    if (not unit) then
        unit = "player";
    end
    local speed, offhandSpeed = UnitAttackSpeed(unit);
    speed = format("%.2f", speed);
    if (offhandSpeed) then
        offhandSpeed = format("%.2f", offhandSpeed);
    end
    local text;
    if (offhandSpeed) then
        text = speed .. " / " .. offhandSpeed;
    else
        text = speed;
    end
    ExtraStats.stats:SetLabelAndText(statFrame, WEAPON_SPEED, text);

    statFrame.tooltip = HIGHLIGHT_FONT_COLOR_CODE .. format(PAPERDOLLFRAME_TOOLTIP_FORMAT, ATTACK_SPEED) .. " " .. text .. FONT_COLOR_CODE_CLOSE;
    statFrame.tooltip2 = format(CR_HASTE_RATING_TOOLTIP, GetCombatRating(CR_HASTE_MELEE), GetCombatRatingBonus(CR_HASTE_MELEE));

    statFrame:Show();
end

function ExtraStats.stats:SetAttackPower(statFrame, unit)
    if (not unit) then
        unit = "player";
    end
    statFrame.Label:SetText(format(STAT_FORMAT, ATTACK_POWER));
    local text = statFrame.Value;
    local base, posBuff, negBuff = UnitAttackPower(unit);

    PaperDollFormatStat(MELEE_ATTACK_POWER, base, posBuff, negBuff, statFrame, text);
    statFrame.tooltip2 = format(MELEE_ATTACK_POWER_TOOLTIP, max((base + posBuff + negBuff), 0) / ATTACK_POWER_MAGIC_NUMBER);
    statFrame:Show();
end

function ExtraStats.stats:SetRangedAttack(statFrame, unit)
    if (not unit) then
        unit = "player";
    elseif (unit == "pet") then
        return ;
    end

    local hasRelic = UnitHasRelicSlot(unit);
    local rangedAttackBase, rangedAttackMod = UnitRangedAttack(unit);
    statFrame.Label:SetText(format(STAT_FORMAT, COMBAT_RATING_NAME1));
    local text = statFrame.Value;

    -- If no ranged texture then set stats to n/a
    local rangedTexture = GetInventoryItemTexture("player", 18);
    if (rangedTexture and not hasRelic) then
        PaperDollFrame.noRanged = nil;
    else
        text:SetText(NOT_APPLICABLE);
        PaperDollFrame.noRanged = 1;
        statFrame.tooltip = nil;
    end
    if (not rangedTexture or hasRelic) then
        return ;
    end

    if (rangedAttackMod == 0) then
        text:SetText(rangedAttackBase);
        statFrame.tooltip = HIGHLIGHT_FONT_COLOR_CODE .. format(PAPERDOLLFRAME_TOOLTIP_FORMAT, COMBAT_RATING_NAME1) .. " " .. rangedAttackBase .. FONT_COLOR_CODE_CLOSE;
    else
        local color = RED_FONT_COLOR_CODE;
        if (rangedAttackMod > 0) then
            color = GREEN_FONT_COLOR_CODE;
            statFrame.tooltip = HIGHLIGHT_FONT_COLOR_CODE .. format(PAPERDOLLFRAME_TOOLTIP_FORMAT, COMBAT_RATING_NAME1) .. " " .. (rangedAttackBase + rangedAttackMod) .. " (" .. rangedAttackBase .. color .. " +" .. rangedAttackMod .. FONT_COLOR_CODE_CLOSE .. HIGHLIGHT_FONT_COLOR_CODE .. ")";
        else
            statFrame.tooltip = HIGHLIGHT_FONT_COLOR_CODE .. format(PAPERDOLLFRAME_TOOLTIP_FORMAT, COMBAT_RATING_NAME1) .. " " .. (rangedAttackBase + rangedAttackMod) .. " (" .. rangedAttackBase .. color .. " " .. rangedAttackMod .. FONT_COLOR_CODE_CLOSE .. HIGHLIGHT_FONT_COLOR_CODE .. ")";
        end
        text:SetText(color .. (rangedAttackBase + rangedAttackMod) .. FONT_COLOR_CODE_CLOSE);
    end
    local total = GetCombatRating(CR_WEAPON_SKILL) + GetCombatRating(CR_WEAPON_SKILL_RANGED);
    statFrame.tooltip2 = format(WEAPON_SKILL_RATING, total);
    if (total > 0) then
        statFrame.tooltip2 = statFrame.tooltip2 .. format(WEAPON_SKILL_RATING_BONUS, GetCombatRatingBonus(CR_WEAPON_SKILL) + GetCombatRatingBonus(CR_WEAPON_SKILL_RANGED));
    end
    statFrame:Show();
end

function ExtraStats.stats:SetRangedDamage(statFrame, unit)
    if (not unit) then
        unit = "player";
    elseif (unit == "pet") then
        return ;
    end

    statFrame.Label:SetText(format(STAT_FORMAT, DAMAGE));
    local text = statFrame.Value;

    -- If no ranged attack then set to n/a
    local hasRelic = UnitHasRelicSlot(unit);
    local rangedTexture = GetInventoryItemTexture("player", 18);
    if (rangedTexture and not hasRelic) then
        PaperDollFrame.noRanged = nil;
    else
        text:SetText(NOT_APPLICABLE);
        PaperDollFrame.noRanged = 1;
        statFrame.damage = nil;
        return ;
    end

    local rangedAttackSpeed, minDamage, maxDamage, physicalBonusPos, physicalBonusNeg, percent = UnitRangedDamage(unit);

    -- Round to the third decimal place (i.e. 99.9 percent)
    percent = math.floor(percent * 10 ^ 3 + 0.5) / 10 ^ 3
    local displayMin = max(floor(minDamage), 1);
    local displayMax = max(ceil(maxDamage), 1);

    local baseDamage;
    local fullDamage;
    local totalBonus;
    local damagePerSecond;
    local tooltip;

    if (HasWandEquipped()) then
        baseDamage = (minDamage + maxDamage) * 0.5;
        fullDamage = baseDamage * percent;
        totalBonus = 0;
        if (rangedAttackSpeed == 0) then
            damagePerSecond = 0;
        else
            damagePerSecond = (max(fullDamage, 1) / rangedAttackSpeed);
        end
        tooltip = max(floor(minDamage), 1) .. " - " .. max(ceil(maxDamage), 1);
    else
        minDamage = (minDamage / percent) - physicalBonusPos - physicalBonusNeg;
        maxDamage = (maxDamage / percent) - physicalBonusPos - physicalBonusNeg;

        baseDamage = (minDamage + maxDamage) * 0.5;
        fullDamage = (baseDamage + physicalBonusPos + physicalBonusNeg) * percent;
        totalBonus = (fullDamage - baseDamage);
        if (rangedAttackSpeed == 0) then
            damagePerSecond = 0;
        else
            damagePerSecond = (max(fullDamage, 1) / rangedAttackSpeed);
        end
        tooltip = max(floor(minDamage), 1) .. " - " .. max(ceil(maxDamage), 1);
    end

    if (totalBonus == 0) then
        if ((displayMin < 100) and (displayMax < 100)) then
            text:SetText(displayMin .. " - " .. displayMax);
        else
            text:SetText(displayMin .. "-" .. displayMax);
        end
    else
        local colorPos = "|cff20ff20";
        local colorNeg = "|cffff2020";
        local color;
        if (totalBonus > 0) then
            color = colorPos;
        else
            color = colorNeg;
        end
        if ((displayMin < 100) and (displayMax < 100)) then
            text:SetText(color .. displayMin .. " - " .. displayMax .. "|r");
        else
            text:SetText(color .. displayMin .. "-" .. displayMax .. "|r");
        end
        if (physicalBonusPos > 0) then
            tooltip = tooltip .. colorPos .. " +" .. physicalBonusPos .. "|r";
        end
        if (physicalBonusNeg < 0) then
            tooltip = tooltip .. colorNeg .. " " .. physicalBonusNeg .. "|r";
        end
        if (percent > 1) then
            tooltip = tooltip .. colorPos .. " x" .. floor(percent * 100 + 0.5) .. "%|r";
        elseif (percent < 1) then
            tooltip = tooltip .. colorNeg .. " x" .. floor(percent * 100 + 0.5) .. "%|r";
        end
        statFrame.tooltip = tooltip .. " " .. format(DPS_TEMPLATE, damagePerSecond);
    end
    statFrame.attackSpeed = rangedAttackSpeed;
    statFrame.damage = tooltip;
    statFrame.dps = damagePerSecond;
    statFrame:Show();
end

function ExtraStats.stats:SetRangedAttackSpeed(statFrame, unit)
    if (not unit) then
        unit = "player";
    elseif (unit == "pet") then
        return ;
    end
    local text;
    -- If no ranged attack then set to n/a
    if (PaperDollFrame.noRanged) then
        text = NOT_APPLICABLE;
        statFrame.tooltip = nil;
    else
        text = UnitRangedDamage(unit);
        text = format("%.2f", text);
        statFrame.tooltip = HIGHLIGHT_FONT_COLOR_CODE .. format(PAPERDOLLFRAME_TOOLTIP_FORMAT, ATTACK_SPEED) .. " " .. text .. FONT_COLOR_CODE_CLOSE;
    end
    ExtraStats.stats:SetLabelAndText(statFrame, WEAPON_SPEED, text);
    statFrame.tooltip2 = format(CR_HASTE_RATING_TOOLTIP, GetCombatRating(CR_HASTE_RANGED), GetCombatRatingBonus(CR_HASTE_RANGED));
    statFrame:Show();
end

function ExtraStats.stats:SetRangedAttackPower(statFrame, unit)
    if (not unit) then
        unit = "player";
    end

    statFrame.Label:SetText(format(STAT_FORMAT, ATTACK_POWER));
    local text = statFrame.Value;
    local base, posBuff, negBuff = UnitRangedAttackPower(unit);

    ExtraStats.stats:PaperDollFormatStat(RANGED_ATTACK_POWER, base, posBuff, negBuff, statFrame, text);
    local totalAP = base + posBuff + negBuff;
    statFrame.tooltip2 = format(RANGED_ATTACK_POWER_TOOLTIP, max((totalAP), 0) / ATTACK_POWER_MAGIC_NUMBER);
    local petAPBonus = ComputePetBonus("PET_BONUS_RAP_TO_AP", totalAP);
    if (petAPBonus > 0) then
        statFrame.tooltip2 = statFrame.tooltip2 .. "\n" .. format(PET_BONUS_TOOLTIP_RANGED_ATTACK_POWER, petAPBonus);
    end

    local petSpellDmgBonus = ComputePetBonus("PET_BONUS_RAP_TO_SPELLDMG", totalAP);
    if (petSpellDmgBonus > 0) then
        statFrame.tooltip2 = statFrame.tooltip2 .. "\n" .. format(PET_BONUS_TOOLTIP_SPELLDAMAGE, petSpellDmgBonus);
    end

    statFrame:Show();
end

function ExtraStats.stats:SetSpellBonusHealing(statFrame)
    statFrame.Label:SetText(format(STAT_FORMAT, BONUS_HEALING));
    local text = statFrame.Value;
    local bonusHealing = GetSpellBonusHealing();
    text:SetText(bonusHealing);
    statFrame.tooltip = HIGHLIGHT_FONT_COLOR_CODE .. BONUS_HEALING .. FONT_COLOR_CODE_CLOSE;
    statFrame.tooltip2 = format(BONUS_HEALING_TOOLTIP, bonusHealing);
    statFrame:Show();
end

function ExtraStats.stats:SetSpellBonusDamage(statFrame)
    statFrame.Label:SetText(format(STAT_FORMAT, BONUS_DAMAGE));
    local text = statFrame.Value;
    local holySchool = 2;
    -- Start at 2 to skip physical damage
    local minModifier = GetSpellBonusDamage(holySchool);
    statFrame.bonusDamage = {};
    statFrame.bonusDamage[holySchool] = minModifier;
    local bonusDamage;
    for i = (holySchool + 1), MAX_SPELL_SCHOOLS do
        bonusDamage = GetSpellBonusDamage(i);
        minModifier = min(minModifier, bonusDamage);
        statFrame.bonusDamage[i] = bonusDamage;
    end
    text:SetText(minModifier);
    statFrame.minModifier = minModifier;
    statFrame:Show();
end

function ExtraStats.stats:SetSpellCritChance(statFrame)
    statFrame.Label:SetText(format(STAT_FORMAT, SPELL_CRIT_CHANCE));
    local text = statFrame.Value;
    local holySchool = 2;
    -- Start at 2 to skip physical damage
    local minCrit = GetSpellCritChance(holySchool);
    statFrame.spellCrit = {};
    statFrame.spellCrit[holySchool] = minCrit;
    local spellCrit;
    for i = (holySchool + 1), MAX_SPELL_SCHOOLS do
        spellCrit = GetSpellCritChance(i);
        minCrit = min(minCrit, spellCrit);
        statFrame.spellCrit[i] = spellCrit;
    end
    -- Add agility contribution
    --minCrit = minCrit + GetSpellCritChanceFromIntellect();
    minCrit = format("%.2f%%", minCrit);
    text:SetText(minCrit);
    statFrame.minCrit = minCrit;
    statFrame:Show();
end

function ExtraStats.stats:SetMeleeCritChance(statFrame)
    statFrame.Label:SetText(format(STAT_FORMAT, MELEE_CRIT_CHANCE));
    local text = statFrame.Value;
    local critChance = GetCritChance();-- + GetCritChanceFromAgility();
    critChance = format("%.2f%%", critChance);
    text:SetText(critChance);
    statFrame.tooltip = HIGHLIGHT_FONT_COLOR_CODE .. format(PAPERDOLLFRAME_TOOLTIP_FORMAT, MELEE_CRIT_CHANCE) .. " " .. critChance .. FONT_COLOR_CODE_CLOSE;
    statFrame.tooltip2 = format(CR_CRIT_MELEE_TOOLTIP, GetCombatRating(CR_CRIT_MELEE), GetCombatRatingBonus(CR_CRIT_MELEE));
    statFrame:Show();
end

function ExtraStats.stats:SetRangedCritChance(statFrame)
    statFrame.Label:SetText(format(STAT_FORMAT, RANGED_CRIT_CHANCE));
    local text = statFrame.Value;
    local critChance = GetRangedCritChance();-- + GetCritChanceFromAgility();
    critChance = format("%.2f%%", critChance);
    text:SetText(critChance);
    statFrame.tooltip = HIGHLIGHT_FONT_COLOR_CODE .. format(PAPERDOLLFRAME_TOOLTIP_FORMAT, RANGED_CRIT_CHANCE) .. " " .. critChance .. FONT_COLOR_CODE_CLOSE;
    statFrame.tooltip2 = format(CR_CRIT_RANGED_TOOLTIP, GetCombatRating(CR_CRIT_RANGED), GetCombatRatingBonus(CR_CRIT_RANGED));
    statFrame:Show();
end

function ExtraStats.stats:SetSpellPenetration(statFrame)
    statFrame.Label:SetText(format(STAT_FORMAT, SPELL_PENETRATION));
    local text = statFrame.Value;
    text:SetText(GetSpellPenetration());
    statFrame.tooltip = HIGHLIGHT_FONT_COLOR_CODE .. format(PAPERDOLLFRAME_TOOLTIP_FORMAT, SPELL_PENETRATION) .. FONT_COLOR_CODE_CLOSE;
    statFrame.tooltip2 = SPELL_PENETRATION_TOOLTIP;
    statFrame:Show();
end

function ExtraStats.stats:SetSpellHaste(statFrame)
    statFrame.Label:SetText(format(STAT_FORMAT, SPELL_HASTE));
    local text = statFrame.Value;
    text:SetText(format("%.2f%%", GetCombatRatingBonus(CR_HASTE_SPELL)));
    statFrame.tooltip = HIGHLIGHT_FONT_COLOR_CODE .. SPELL_HASTE .. FONT_COLOR_CODE_CLOSE;
    statFrame.tooltip2 = format(SPELL_HASTE_TOOLTIP, GetCombatRatingBonus(CR_HASTE_SPELL));
    statFrame:Show();
end

function ExtraStats.stats:SetMeleeHaste(statFrame)
    local speed, offhandSpeed = UnitAttackSpeed("Player");
    speed = format("%.2f", speed);
    if (offhandSpeed) then
        offhandSpeed = format("%.2f", offhandSpeed);
    end
    local text;
    if (offhandSpeed) then
        text = speed .. " / " .. offhandSpeed;
    else
        text = speed;
    end
    ExtraStats.stats:SetLabelAndText(statFrame, SPELL_HASTE, format("%.2f%%", GetCombatRatingBonus(CR_HASTE_MELEE)));

    statFrame.tooltip = HIGHLIGHT_FONT_COLOR_CODE .. format(PAPERDOLLFRAME_TOOLTIP_FORMAT, ATTACK_SPEED) .. " " .. text .. FONT_COLOR_CODE_CLOSE;
    statFrame.tooltip2 = format(CR_HASTE_RATING_TOOLTIP, GetCombatRating(CR_HASTE_MELEE), GetCombatRatingBonus(CR_HASTE_MELEE));
    statFrame:Show();
end

function ExtraStats.stats:SetManaRegen(statFrame)
    statFrame.Label:SetText(format(STAT_FORMAT, MANA_REGEN));
    local text = statFrame.Value;
    if (not UnitHasMana("player")) then
        text:SetText(NOT_APPLICABLE);
        statFrame.tooltip = nil;
        return ;
    end

    local base, casting = GetManaRegen();
    -- All mana regen stats are displayed as mana/5 sec.
    base = floor(base * 5.0);
    casting = floor(casting * 5.0);
    text:SetText(base);
    statFrame.tooltip = HIGHLIGHT_FONT_COLOR_CODE .. MANA_REGEN .. FONT_COLOR_CODE_CLOSE;
    statFrame.tooltip2 = format(MANA_REGEN_TOOLTIP, base, casting);
    statFrame:Show();
end

function ExtraStats.stats:SetExpertise(statFrame, unit)
    if (not unit) then
        unit = "player";
    end
    local expertise, offhandExpertise = GetExpertise();
    local speed, offhandSpeed = UnitAttackSpeed(unit);
    local text;
    if (offhandSpeed) then
        text = expertise .. " / " .. offhandExpertise;
    else
        text = expertise;
    end
    ExtraStats.stats:SetLabelAndText(statFrame, STAT_EXPERTISE, text);

    statFrame.tooltip = HIGHLIGHT_FONT_COLOR_CODE .. format(PAPERDOLLFRAME_TOOLTIP_FORMAT, _G["COMBAT_RATING_NAME" .. CR_EXPERTISE]) .. " " .. text .. FONT_COLOR_CODE_CLOSE;

    local expertisePercent, offhandExpertisePercent = GetExpertisePercent();
    expertisePercent = format("%.2f", expertisePercent);
    if (offhandSpeed) then
        offhandExpertisePercent = format("%.2f", offhandExpertisePercent);
        text = expertisePercent .. "% / " .. offhandExpertisePercent .. "%";
    else
        text = expertisePercent .. "%";
    end
    statFrame.tooltip2 = format(CR_EXPERTISE_TOOLTIP, text, GetCombatRating(CR_EXPERTISE), GetCombatRatingBonus(CR_EXPERTISE));

    statFrame:Show();
end

function ExtraStats.stats:MeleeHitChance(statFrame, unit)
    local label = statFrame.Label;
    local text = statFrame.Value
    local ratingIndex = CR_HIT_MELEE;
    local statName = _G["COMBAT_RATING_NAME" .. ratingIndex];
    label:SetText(format(STAT_FORMAT, "Hit Chance"));
    local rating = GetCombatRating(ratingIndex);
    local ratingBonus = GetCombatRatingBonus(ratingIndex);
    text:SetText(format("%.2f", ExtraStats:GetHitRatingBonus()) .. "%");

    -- Set the tooltip text
    statFrame.tooltip = HIGHLIGHT_FONT_COLOR_CODE .. format(PAPERDOLLFRAME_TOOLTIP_FORMAT, statName) .. " " .. rating .. FONT_COLOR_CODE_CLOSE;
    if (ratingIndex == CR_HIT_MELEE) then
        statFrame.tooltip2 = format(CR_HIT_MELEE_TOOLTIP, UnitLevel("player"), ratingBonus, GetCombatRating(CR_ARMOR_PENETRATION), GetArmorPenetration());
    end

    statFrame:Show();
end

function ExtraStats.stats:SpellBonusDamage_OnEnter (self)
    GameTooltip:SetOwner(self, "ANCHOR_RIGHT");
    GameTooltip:SetText(HIGHLIGHT_FONT_COLOR_CODE .. format(PAPERDOLLFRAME_TOOLTIP_FORMAT, BONUS_DAMAGE) .. " " .. self.minModifier .. FONT_COLOR_CODE_CLOSE);
    for i = 2, MAX_SPELL_SCHOOLS do
        GameTooltip:AddDoubleLine(_G["DAMAGE_SCHOOL" .. i], self.bonusDamage[i], NORMAL_FONT_COLOR.r, NORMAL_FONT_COLOR.g, NORMAL_FONT_COLOR.b, NORMAL_FONT_COLOR.r, NORMAL_FONT_COLOR.g, NORMAL_FONT_COLOR.b);
        GameTooltip:AddTexture("Interface\\PaperDollInfoFrame\\SpellSchoolIcon" .. i);
    end

    local petStr, damage;
    if (self.bonusDamage[6] > self.bonusDamage[3]) then
        petStr = PET_BONUS_TOOLTIP_WARLOCK_SPELLDMG_SHADOW;
        damage = self.bonusDamage[6];
    else
        petStr = PET_BONUS_TOOLTIP_WARLOCK_SPELLDMG_FIRE;
        damage = self.bonusDamage[3];
    end

    local petBonusAP = ComputePetBonus("PET_BONUS_SPELLDMG_TO_AP", damage);
    local petBonusDmg = ComputePetBonus("PET_BONUS_SPELLDMG_TO_SPELLDMG", damage);
    if (petBonusAP > 0 or petBonusDmg > 0) then
        GameTooltip:AddLine("\n" .. format(petStr, petBonusAP, petBonusDmg), nil, nil, nil, 1);
    end
    GameTooltip:Show();
end

function ExtraStats.stats:SpellCritChance_OnEnter (self)
    GameTooltip:SetOwner(self, "ANCHOR_RIGHT");
    GameTooltip:SetText(HIGHLIGHT_FONT_COLOR_CODE .. format(PAPERDOLLFRAME_TOOLTIP_FORMAT, COMBAT_RATING_NAME11) .. " " .. GetCombatRating(11) .. FONT_COLOR_CODE_CLOSE);
    local spellCrit;
    for i = 2, MAX_SPELL_SCHOOLS do
        spellCrit = format("%.2f", self.spellCrit[i]);
        spellCrit = spellCrit .. "%";
        GameTooltip:AddDoubleLine(_G["DAMAGE_SCHOOL" .. i], spellCrit, NORMAL_FONT_COLOR.r, NORMAL_FONT_COLOR.g, NORMAL_FONT_COLOR.b, NORMAL_FONT_COLOR.r, NORMAL_FONT_COLOR.g, NORMAL_FONT_COLOR.b);
        GameTooltip:AddTexture("Interface\\PaperDollInfoFrame\\SpellSchoolIcon" .. i);
    end
    GameTooltip:Show();
end

function ExtraStats.stats:DamageFrame_OnEnter (self)
    -- Main hand weapon
    GameTooltip:SetOwner(self, "ANCHOR_RIGHT");
    if (self == PetDamageFrame) then
        GameTooltip:SetText(INVTYPE_WEAPONMAINHAND_PET, HIGHLIGHT_FONT_COLOR.r, HIGHLIGHT_FONT_COLOR.g, HIGHLIGHT_FONT_COLOR.b);
    else
        GameTooltip:SetText(INVTYPE_WEAPONMAINHAND, HIGHLIGHT_FONT_COLOR.r, HIGHLIGHT_FONT_COLOR.g, HIGHLIGHT_FONT_COLOR.b);
    end
    GameTooltip:AddDoubleLine(format(STAT_FORMAT, ATTACK_SPEED_SECONDS), format("%.2f", self.attackSpeed), NORMAL_FONT_COLOR.r, NORMAL_FONT_COLOR.g, NORMAL_FONT_COLOR.b, NORMAL_FONT_COLOR.r, NORMAL_FONT_COLOR.g, NORMAL_FONT_COLOR.b);
    GameTooltip:AddDoubleLine(format(STAT_FORMAT, DAMAGE), self.damage, NORMAL_FONT_COLOR.r, NORMAL_FONT_COLOR.g, NORMAL_FONT_COLOR.b, NORMAL_FONT_COLOR.r, NORMAL_FONT_COLOR.g, NORMAL_FONT_COLOR.b);
    GameTooltip:AddDoubleLine(format(STAT_FORMAT, DAMAGE_PER_SECOND), format("%.1f", self.dps), NORMAL_FONT_COLOR.r, NORMAL_FONT_COLOR.g, NORMAL_FONT_COLOR.b, NORMAL_FONT_COLOR.r, NORMAL_FONT_COLOR.g, NORMAL_FONT_COLOR.b);
    -- Check for offhand weapon
    if (self.offhandAttackSpeed) then
        GameTooltip:AddLine("\n");
        GameTooltip:AddLine(INVTYPE_WEAPONOFFHAND, HIGHLIGHT_FONT_COLOR.r, HIGHLIGHT_FONT_COLOR.g, HIGHLIGHT_FONT_COLOR.b);
        GameTooltip:AddDoubleLine(format(STAT_FORMAT, ATTACK_SPEED_SECONDS), format("%.2f", self.offhandAttackSpeed), NORMAL_FONT_COLOR.r, NORMAL_FONT_COLOR.g, NORMAL_FONT_COLOR.b, NORMAL_FONT_COLOR.r, NORMAL_FONT_COLOR.g, NORMAL_FONT_COLOR.b);
        GameTooltip:AddDoubleLine(format(STAT_FORMAT, DAMAGE), self.offhandDamage, NORMAL_FONT_COLOR.r, NORMAL_FONT_COLOR.g, NORMAL_FONT_COLOR.b, NORMAL_FONT_COLOR.r, NORMAL_FONT_COLOR.g, NORMAL_FONT_COLOR.b);
        GameTooltip:AddDoubleLine(format(STAT_FORMAT, DAMAGE_PER_SECOND), format("%.1f", self.offhandDps), NORMAL_FONT_COLOR.r, NORMAL_FONT_COLOR.g, NORMAL_FONT_COLOR.b, NORMAL_FONT_COLOR.r, NORMAL_FONT_COLOR.g, NORMAL_FONT_COLOR.b);
    end
    GameTooltip:Show();
end

function ExtraStats.stats:RangedDamageFrame_OnEnter (self)
    if (not self.damage) then
        return ;
    end
    GameTooltip:SetOwner(self, "ANCHOR_RIGHT");
    GameTooltip:SetText(INVTYPE_RANGED, HIGHLIGHT_FONT_COLOR.r, HIGHLIGHT_FONT_COLOR.g, HIGHLIGHT_FONT_COLOR.b);
    GameTooltip:AddDoubleLine(format(STAT_FORMAT, ATTACK_SPEED_SECONDS), format("%.2f", self.attackSpeed), NORMAL_FONT_COLOR.r, NORMAL_FONT_COLOR.g, NORMAL_FONT_COLOR.b, NORMAL_FONT_COLOR.r, NORMAL_FONT_COLOR.g, NORMAL_FONT_COLOR.b);
    GameTooltip:AddDoubleLine(format(STAT_FORMAT, DAMAGE), self.damage, NORMAL_FONT_COLOR.r, NORMAL_FONT_COLOR.g, NORMAL_FONT_COLOR.b, NORMAL_FONT_COLOR.r, NORMAL_FONT_COLOR.g, NORMAL_FONT_COLOR.b);
    GameTooltip:AddDoubleLine(format(STAT_FORMAT, DAMAGE_PER_SECOND), format("%.1f", self.dps), NORMAL_FONT_COLOR.r, NORMAL_FONT_COLOR.g, NORMAL_FONT_COLOR.b, NORMAL_FONT_COLOR.r, NORMAL_FONT_COLOR.g, NORMAL_FONT_COLOR.b);
    GameTooltip:Show();
end

function ExtraStats:UpdateStats()
    self.statsFramePool:ReleaseAll();
    local level = UnitLevel("player");
    local categoryYOffset = 0;
    local statYOffset = 0;
    local classIndex = ExtraStats:GetCurrentClass();
    local statFrame = self.statsFramePool:Acquire();
    local currentRole = GetTalentGroupRole(GetActiveTalentGroup())
    local lastAnchor;
    for catIndex = 1, #stats.categories do
        local catFrame = ExtraStats.window[stats.categories[catIndex].categoryFrame];
        catFrame:Hide()

        local showCat = true;

        if stats.categories[catIndex].showFunc ~= nil and not stats.categories[catIndex].showFunc("player") then
            showCat = false;
        end

        if stats.categories[catIndex].role ~= nil and stats.currentRole ~= stats.categories[catIndex].role then
            showCat = false;
        end

        if not ExtraStats.db.char.dynamic and not ExtraStats.db.char.categories[stats.categories[catIndex].id].enabled then
            showCat = false
        end

        local numStatInCat = 0;
        if showCat then
            for statIndex = 1, #stats.categories[catIndex].stats do
                local stat = stats.categories[catIndex].stats[statIndex];
                local showStat = true;

                --for _, stats in pairs(CLASS_STATS_ALL) do
                --    if stats == stat.stat then
                --        showStat = true
                --    end
                --end
                --
                --for _, stats in pairs(CLASS_STATS[classIndex]) do
                --    if stats == stat.stat then
                --        showStat = true
                --    end
                --end

                --if CLASS_ROLE_STATS[classIndex][currentRole] then
                --    for _, stats in pairs(CLASS_ROLE_STATS[classIndex][currentRole]) do
                --        if stats == stat.stat then
                --            showStat = true
                --        end
                --    end
                --end

                if (showStat and stat.showFunc) then
                    showStat = stat.showFunc();
                end

                if not ExtraStats.db.char.categories[stats.categories[catIndex].id].stats[string.lower(stat.stat)] then
                    showStat = false
                end

                if (showStat) then
                    statFrame.onEnterFunc = nil;
                    statFrame.UpdateTooltip = nil;
                    statFrame.tooltip = nil;
                    statFrame.tooltip2 = nil;
                    statFrame.tooltip3 = nil;

                    stat.updateFunc(statFrame, "player");

                    --if (not stat.hideAt or stat.hideAt ~= statFrame.numericValue) then
                    catFrame:Show()

                    if not lastAnchor then
                        catFrame:SetPoint("TOP", 0, 0);
                    end

                    if (numStatInCat == 0) then
                        if (lastAnchor) then
                            catFrame:SetPoint("TOP", lastAnchor, "BOTTOM", 0, categoryYOffset);
                        end
                        lastAnchor = catFrame;
                        statFrame:SetPoint("TOP", catFrame, "BOTTOM", 0, -2);
                    else
                        statFrame:SetPoint("TOP", lastAnchor, "BOTTOM", 0, statYOffset);
                    end
                    numStatInCat = numStatInCat + 1;
                    statFrame.Background:SetShown((numStatInCat % 2) == 0);
                    lastAnchor = statFrame;

                    statFrame = self.statsFramePool:Acquire();
                end
            end
        end
    end
end

function ExtraStats:GetHitRatingBonus()
    local hitModifier = GetHitModifier();

    local hit = 0
    local hitRating = 0
    local debuffs = {
        ["Faerie Fire"] = true,
        ["Misery"] = true,
    }

    for debuff in pairs(debuffs) do
        if AuraUtil.FindAuraByName(debuff, "target", "HARMFUL") then
            hit = 3
            break --Stop after 1 they dont stack
        end
    end

    hit = hit + (GetCombatRatingBonus(CR_HIT_SPELL) + hitModifier);
    hitRating = math.ceil((hit) * 26.23)

    return hit;
end

function ExtraStats:SendVersionCheck()
    if IsInGuild() then
        ExtraStats:SendCommMessage(stats.name .. "Ver", ExtraStats:Serialize(stats.version), "GUILD")
    end

    ExtraStats:SendCommMessage(stats.name .. "Ver", ExtraStats:Serialize(stats.version), "YELL")
end

function ExtraStats:VersionCheck(event, msg, channel, sender)
    local success, message = ExtraStats:Deserialize(msg);
    if not success then
        return
    end

    ExtraStats:debug("Version check from", channel, sender, message)

    local removeVersion = Semver:Parse(message);
    if not removeVersion then
        return
    end

    local localVersion = Semver:Parse(stats.version);
    if not localVersion then
        return
    end

    if localVersion < removeVersion and not stats.NewVersionExists then
        stats.NewVersionExists = true;
        ExtraStats:print("A new version of", stats.name, "has been detected, please visit curseforge.com to download the latest version, or use the twitch app to keep you addons updated")
    end

end
