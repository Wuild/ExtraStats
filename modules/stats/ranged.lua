local function RangedDamageFrame_OnEnter (self)
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

local function Damage()
    local textValue;
    -- If no ranged attack then set to n/a
    local hasRelic = UnitHasRelicSlot("player");
    local rangedTexture = GetInventoryItemTexture("player", 18);
    if (rangedTexture and not hasRelic) then
        PaperDollFrame.noRanged = nil;
    else
        PaperDollFrame.noRanged = 1;
        return ;
    end

    local rangedAttackSpeed, minDamage, maxDamage, physicalBonusPos, physicalBonusNeg, percent = UnitRangedDamage("player");

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
            textValue = displayMin .. " - " .. displayMax;
        else
            textValue = displayMin .. "-" .. displayMax;
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
            textValue = color .. displayMin .. " - " .. displayMax .. "|r";
        else
            textValue = color .. displayMin .. "-" .. displayMax .. "|r";
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
    end

    return {
        value = textValue,
        attackSpeed = rangedAttackSpeed,
        damage = tooltip,
        dps = damagePerSecond,
        onEnter = RangedDamageFrame_OnEnter
    }

end

local function RangedAttackSpeed()
    local text = UnitRangedDamage("player");
    return {
        value = format("%.2f", text),
        tooltip = HIGHLIGHT_FONT_COLOR_CODE .. format(PAPERDOLLFRAME_TOOLTIP_FORMAT, ATTACK_SPEED) .. " " .. text .. FONT_COLOR_CODE_CLOSE,
        tooltip2 = format(CR_HASTE_RATING_TOOLTIP, GetCombatRating(CR_HASTE_RANGED), GetCombatRatingBonus(CR_HASTE_RANGED))
    }
end

local function RangedAttackPower()
    local tooltip, tooltip2, value
    local base, posBuff, negBuff = UnitRangedAttackPower("player");

    value, tooltip = ExtraStats:FormatStat(RANGED_ATTACK_POWER, base, posBuff, negBuff);

    local totalAP = base + posBuff + negBuff;
    tooltip2 = format(RANGED_ATTACK_POWER_TOOLTIP, max((totalAP), 0) / ATTACK_POWER_MAGIC_NUMBER);
    return {
        value = value,
        tooltip = tooltip,
        tooltip2 = tooltip2
    }
end

local function CriticalChance()
    local critChance = GetRangedCritChance();

    return {
        value = format("%.2f%%", critChance),
        tooltip = HIGHLIGHT_FONT_COLOR_CODE .. format(PAPERDOLLFRAME_TOOLTIP_FORMAT, RANGED_CRIT_CHANCE) .. " " .. critChance .. FONT_COLOR_CODE_CLOSE,
        tooltip2 = format(CR_CRIT_RANGED_TOOLTIP, GetCombatRating(CR_CRIT_RANGED), GetCombatRatingBonus(CR_CRIT_RANGED))
    }
end

local function HitChance()
    local ratingIndex = CR_HIT_RANGED;
    local statName = _G["COMBAT_RATING_NAME" .. ratingIndex];
    local hitModifier = GetHitModifier();

    local rangedHit = math.floor((GetCombatRatingBonus(CR_HIT_RANGED) + hitModifier) * 100) / 100;

    return {
        value = format("%.2f%%", rangedHit),
        tooltip = HIGHLIGHT_FONT_COLOR_CODE .. format(PAPERDOLLFRAME_TOOLTIP_FORMAT, statName) .. " " .. rangedHit .. FONT_COLOR_CODE_CLOSE,
        tooltip2 = format(CR_HIT_RANGED_TOOLTIP, UnitLevel("player"), rangedHit, GetCombatRating(CR_ARMOR_PENETRATION), GetArmorPenetration())
    }
end

local function Haste()
    local speed = GetCombatRating(CR_HASTE_RANGED);
    speed = format("%.2f", speed);

    return {
        value = format("%.2f%%", GetRangedHaste()),
        tooltip = HIGHLIGHT_FONT_COLOR_CODE .. format(PAPERDOLLFRAME_TOOLTIP_FORMAT, ATTACK_SPEED) .. " " .. speed .. FONT_COLOR_CODE_CLOSE,
        tooltip2 = format(CR_HASTE_RATING_TOOLTIP, GetCombatRating(CR_HASTE_RANGED), GetCombatRatingBonus(CR_HASTE_RANGED))
    }
end

local Module = ExtraStats.modules:NewModule("ranged")

function Module:OnEnable()
    local stats = ExtraStats:LoadModule("character.stats")

    local Category = stats:CreateCategory("ranged", ExtraStats:translate("stats.ranged"), {
        order = 2,
        classes = { INDEX_CLASS_HUNTER },
        show = function()
            if ExtraStats.db.char.dynamic then
                return CURRENT_CLASS == INDEX_CLASS_HUNTER;
            end

            return true
        end
    })

    Category:Add(ExtraStats:translate("stats.damage"), Damage)
    Category:Add(ExtraStats:translate("stats.speed"), RangedAttackSpeed)
    Category:Add(ExtraStats:translate("stats.power"), RangedAttackPower)
    Category:Add(ExtraStats:translate("stats.hit_chance"), HitChance)
    Category:Add(ExtraStats:translate("stats.crit_chance"), CriticalChance)
    Category:Add(ExtraStats:translate("stats.haste_rating"), Haste)
end