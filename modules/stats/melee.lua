local function DamageFrame_OnEnter (self)
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

local function Damage()
    local textValue;
    local speed, offhandSpeed = UnitAttackSpeed("player");

    local minDamage;
    local maxDamage;
    local minOffHandDamage;
    local maxOffHandDamage;
    local physicalBonusPos;
    local physicalBonusNeg;
    local percent;
    minDamage, maxDamage, minOffHandDamage, maxOffHandDamage, physicalBonusPos, physicalBonusNeg, percent = UnitDamage("player");
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
            textValue = displayMin .. " - " .. displayMax;
        else
            textValue = displayMin .. "-" .. displayMax;
        end
    else

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

    local offhandBaseDamage, offhandFullDamage, offhandDamagePerSecond, offhandDamageTooltip

    -- If there's an offhand speed then add the offhand info to the tooltip
    if (offhandSpeed) then
        minOffHandDamage = (minOffHandDamage / percent) - physicalBonusPos - physicalBonusNeg;
        maxOffHandDamage = (maxOffHandDamage / percent) - physicalBonusPos - physicalBonusNeg;

        offhandBaseDamage = (minOffHandDamage + maxOffHandDamage) * 0.5;
        offhandFullDamage = (offhandBaseDamage + physicalBonusPos + physicalBonusNeg) * percent;
        offhandDamagePerSecond = (max(offhandFullDamage, 1) / offhandSpeed);
        offhandDamageTooltip = max(floor(minOffHandDamage), 1) .. " - " .. max(ceil(maxOffHandDamage), 1);
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
    end

    return {
        value = textValue,

        damage = damageTooltip,
        attackSpeed = speed,
        dps = damagePerSecond,

        offhandDamage = offhandDamageTooltip,
        offhandAttackSpeed = offhandSpeed,
        offhandDps = offhandDamagePerSecond,
        onEnter = DamageFrame_OnEnter
    }
end

local function AttackSpeed()
    local speed, offhandSpeed = UnitAttackSpeed("player");
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

    return {
        value = text,
        tooltip = HIGHLIGHT_FONT_COLOR_CODE .. format(PAPERDOLLFRAME_TOOLTIP_FORMAT, ATTACK_SPEED) .. " " .. text .. FONT_COLOR_CODE_CLOSE,
        tooltip2 = format(CR_HASTE_RATING_TOOLTIP, GetCombatRating(CR_HASTE_MELEE), GetCombatRatingBonus(CR_HASTE_MELEE))
    }

end

local function AttackPower()

    local base, posBuff, negBuff = UnitAttackPower("player");

    local value, tooltip = ExtraStats:FormatStat(MELEE_ATTACK_POWER, base, posBuff, negBuff);

    return {
        value = value,
        tooltip = tooltip,
        tooltip2 = format(MELEE_ATTACK_POWER_TOOLTIP, max((base + posBuff + negBuff), 0) / ATTACK_POWER_MAGIC_NUMBER)
    }
end

local function HitChance()
    local ratingIndex = CR_HIT_MELEE;
    local statName = _G["COMBAT_RATING_NAME" .. ratingIndex];
    local rating = GetCombatRating(ratingIndex);
    local ratingBonus = GetCombatRatingBonus(ratingIndex);

    local hitChance = format("%.2f%%", ExtraStats:GetHitRatingBonus())

    return {
        value = hitChance,
        tooltip = HIGHLIGHT_FONT_COLOR_CODE .. format(PAPERDOLLFRAME_TOOLTIP_FORMAT, statName) .. " " .. rating .. FONT_COLOR_CODE_CLOSE,
        tooltip2 = format(CR_HIT_MELEE_TOOLTIP, UnitLevel("player"), ratingBonus, GetCombatRating(CR_ARMOR_PENETRATION), GetArmorPenetration())
    }
end

local function CriticalChance()
    local critChance = format("%.2f%%", GetCritChance());

    return {
        value = critChance,
        tooltip = HIGHLIGHT_FONT_COLOR_CODE .. format(PAPERDOLLFRAME_TOOLTIP_FORMAT, MELEE_CRIT_CHANCE) .. " " .. critChance .. FONT_COLOR_CODE_CLOSE,
        tooltip2 = format(CR_CRIT_MELEE_TOOLTIP, GetCombatRating(CR_CRIT_MELEE), GetCombatRatingBonus(CR_CRIT_MELEE))
    }
end

local function Haste()
    local speed, offhandSpeed = UnitAttackSpeed("player");
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

    return {
        value = format("%.2f%%", GetCombatRatingBonus(CR_HASTE_MELEE)),
        tooltip = HIGHLIGHT_FONT_COLOR_CODE .. format(PAPERDOLLFRAME_TOOLTIP_FORMAT, ATTACK_SPEED) .. " " .. text .. FONT_COLOR_CODE_CLOSE,
        tooltip2 = format(CR_HASTE_RATING_TOOLTIP, GetCombatRating(CR_HASTE_MELEE), GetCombatRatingBonus(CR_HASTE_MELEE))
    }
end

local function Expertise()
    local expertise, offhandExpertise = GetExpertise();
    local speed, offhandSpeed = UnitAttackSpeed("player");
    local text;
    local value;
    if (offhandSpeed) then
        value = expertise .. " / " .. offhandExpertise;
    else
        value = expertise;
    end

    local expertisePercent, offhandExpertisePercent = GetExpertisePercent();
    expertisePercent = format("%.2f", expertisePercent);
    if (offhandSpeed) then
        offhandExpertisePercent = format("%.2f", offhandExpertisePercent);
        text = expertisePercent .. "% / " .. offhandExpertisePercent .. "%";
    else
        text = expertisePercent .. "%";
    end

    return {
        value = value,
        tooltip = HIGHLIGHT_FONT_COLOR_CODE .. format(PAPERDOLLFRAME_TOOLTIP_FORMAT, _G["COMBAT_RATING_NAME" .. CR_EXPERTISE]) .. " " .. text .. FONT_COLOR_CODE_CLOSE,
        tooltip2 = format(CR_EXPERTISE_TOOLTIP, text, GetCombatRating(CR_EXPERTISE), GetCombatRatingBonus(CR_EXPERTISE))
    }
end

local Module = {  }

function Module:Setup()

    local stats = ExtraStats:LoadModule("character.stats")

    local Category = stats:CreateCategory("melee", ExtraStats:translate("stats.melee"), {
        order = 1,
        classes = {
            INDEX_CLASS_WARRIOR,
            INDEX_CLASS_ROGUE,
            INDEX_CLASS_DEATH_KNIGHT,
            INDEX_CLASS_SHAMAN,
            INDEX_CLASS_DRUID,
            INDEX_CLASS_PALADIN
        },
        show = function()
            if ExtraStats.db.char.dynamic then
                local group = ExtraStats:CheckTalents()
                if CURRENT_CLASS == INDEX_CLASS_DRUID then
                    if group == 1 or group == 3 then
                        return false
                    end
                end

                if CURRENT_CLASS == INDEX_CLASS_SHAMAN then
                    if group ~= 2 then
                        return false
                    end
                end
            end
            return true
        end
    })

    Category:Add(ExtraStats:translate("stats.damage"), Damage)
    Category:Add(ExtraStats:translate("stats.speed"), AttackSpeed)
    Category:Add(ExtraStats:translate("stats.power"), AttackPower)
    Category:Add(ExtraStats:translate("stats.hit_chance"), HitChance)
    Category:Add(ExtraStats:translate("stats.crit_chance"), CriticalChance)
    Category:Add(ExtraStats:translate("stats.haste_rating"), Haste)
    Category:Add(ExtraStats:translate("stats.expertise"), Expertise)
end

do
    table.insert(ExtraStats.modules, Module)
end