local Module = ExtraStats.modules:NewModule("Vanilla")
local Stats = ExtraStats:LoadModule("character.stats")
local L = LibStub("AceLocale-3.0"):GetLocale("ExtraStats", true)

LEGENDARY_FONT_COLOR_CODE = "|cffff8000"
EPIC_FONT_COLOR_CODE = "|cffa335ee"
RARE_FONT_COLOR_CODE = "|cff0070dd"
RARE_FONT_COLOR_CODE = "|cff0070dd"
COMMON_FONT_COLOR_CODE = "|cffffffff"

NUM_RESISTANCE_TYPES = 5;
NUM_STATS = 5;
NUM_SHOPPING_TOOLTIPS = 2;
MAX_SPELL_SCHOOLS = 7;

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
CR_HIT_TAKEN_MELEE = 12;
CR_HIT_TAKEN_RANGED = 13;
CR_HIT_TAKEN_SPELL = 14;
CR_CRIT_TAKEN_MELEE = 15;
CR_CRIT_TAKEN_RANGED = 16;
CR_CRIT_TAKEN_SPELL = 17;
CR_HASTE_MELEE = 18;
CR_HASTE_RANGED = 19;
CR_HASTE_SPELL = 20;
CR_WEAPON_SKILL_MAINHAND = 21;
CR_WEAPON_SKILL_OFFHAND = 22;
CR_WEAPON_SKILL_RANGED = 23;
CR_EXPERTISE = 24;
CR_ARMOR_PENETRATION = 25;

ATTACK_POWER_MAGIC_NUMBER = 14;
BLOCK_PER_STRENGTH = 0.5;
HEALTH_PER_STAMINA = 10;
ARMOR_PER_AGILITY = 2;
MANA_PER_INTELLECT = 15;
MANA_REGEN_PER_SPIRIT = 0.2;
DODGE_PARRY_BLOCK_PERCENT_PER_DEFENSE = 0.04;
RESILIENCE_CRIT_CHANCE_TO_DAMAGE_REDUCTION_MULTIPLIER = 2.2;
RESILIENCE_CRIT_CHANCE_TO_CONSTANT_DAMAGE_REDUCTION_MULTIPLIER = 2.0;

--Pet scaling:
HUNTER_PET_BONUS = {};
HUNTER_PET_BONUS["PET_BONUS_RAP_TO_AP"] = 0.22;
HUNTER_PET_BONUS["PET_BONUS_RAP_TO_SPELLDMG"] = 0.1287;
HUNTER_PET_BONUS["PET_BONUS_STAM"] = 0.3;
HUNTER_PET_BONUS["PET_BONUS_RES"] = 0.4;
HUNTER_PET_BONUS["PET_BONUS_ARMOR"] = 0.35;
HUNTER_PET_BONUS["PET_BONUS_SPELLDMG_TO_SPELLDMG"] = 0.0;
HUNTER_PET_BONUS["PET_BONUS_SPELLDMG_TO_AP"] = 0.0;
HUNTER_PET_BONUS["PET_BONUS_INT"] = 0.0;

WARLOCK_PET_BONUS = {};
WARLOCK_PET_BONUS["PET_BONUS_RAP_TO_AP"] = 0.0;
WARLOCK_PET_BONUS["PET_BONUS_RAP_TO_SPELLDMG"] = 0.0;
WARLOCK_PET_BONUS["PET_BONUS_STAM"] = 0.3;
WARLOCK_PET_BONUS["PET_BONUS_RES"] = 0.4;
WARLOCK_PET_BONUS["PET_BONUS_ARMOR"] = 0.35;
WARLOCK_PET_BONUS["PET_BONUS_SPELLDMG_TO_SPELLDMG"] = 0.15;
WARLOCK_PET_BONUS["PET_BONUS_SPELLDMG_TO_AP"] = 0.57;
WARLOCK_PET_BONUS["PET_BONUS_INT"] = 0.3;

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
    return {
        value = textValue,
        tooltip = tooltip,
        tooltip2 = tooltip2,
    }
end

local function MeleeDamageFrame_OnEnter (self)
    -- Main hand weapon
    GameTooltip:SetOwner(self, "ANCHOR_RIGHT");
    if (self == PetDamageFrame) then
        GameTooltip:SetText(INVTYPE_WEAPONMAINHAND_PET, HIGHLIGHT_FONT_COLOR.r, HIGHLIGHT_FONT_COLOR.g, HIGHLIGHT_FONT_COLOR.b);
    else
        GameTooltip:SetText(INVTYPE_WEAPONMAINHAND, HIGHLIGHT_FONT_COLOR.r, HIGHLIGHT_FONT_COLOR.g, HIGHLIGHT_FONT_COLOR.b);
    end
    GameTooltip:AddDoubleLine(ATTACK_SPEED_COLON, format("%.2f", self.attackSpeed), NORMAL_FONT_COLOR.r, NORMAL_FONT_COLOR.g, NORMAL_FONT_COLOR.b, NORMAL_FONT_COLOR.r, NORMAL_FONT_COLOR.g, NORMAL_FONT_COLOR.b);
    GameTooltip:AddDoubleLine(DAMAGE_COLON, self.damage, NORMAL_FONT_COLOR.r, NORMAL_FONT_COLOR.g, NORMAL_FONT_COLOR.b, NORMAL_FONT_COLOR.r, NORMAL_FONT_COLOR.g, NORMAL_FONT_COLOR.b);
    GameTooltip:AddDoubleLine(DAMAGE_PER_SECOND, format("%.1f", self.dps), NORMAL_FONT_COLOR.r, NORMAL_FONT_COLOR.g, NORMAL_FONT_COLOR.b, NORMAL_FONT_COLOR.r, NORMAL_FONT_COLOR.g, NORMAL_FONT_COLOR.b);
    -- Check for offhand weapon
    if (self.offhandAttackSpeed) then
        GameTooltip:AddLine("\n");
        GameTooltip:AddLine(INVTYPE_WEAPONOFFHAND, HIGHLIGHT_FONT_COLOR.r, HIGHLIGHT_FONT_COLOR.g, HIGHLIGHT_FONT_COLOR.b);
        GameTooltip:AddDoubleLine(ATTACK_SPEED_COLON, format("%.2f", self.offhandAttackSpeed), NORMAL_FONT_COLOR.r, NORMAL_FONT_COLOR.g, NORMAL_FONT_COLOR.b, NORMAL_FONT_COLOR.r, NORMAL_FONT_COLOR.g, NORMAL_FONT_COLOR.b);
        GameTooltip:AddDoubleLine(DAMAGE_COLON, self.offhandDamage, NORMAL_FONT_COLOR.r, NORMAL_FONT_COLOR.g, NORMAL_FONT_COLOR.b, NORMAL_FONT_COLOR.r, NORMAL_FONT_COLOR.g, NORMAL_FONT_COLOR.b);
        GameTooltip:AddDoubleLine(DAMAGE_PER_SECOND, format("%.1f", self.offhandDps), NORMAL_FONT_COLOR.r, NORMAL_FONT_COLOR.g, NORMAL_FONT_COLOR.b, NORMAL_FONT_COLOR.r, NORMAL_FONT_COLOR.g, NORMAL_FONT_COLOR.b);
    end
    GameTooltip:Show();
end
local function RangedDamageFrame_OnEnter (self)
    if (not self.damage) then
        return ;
    end
    GameTooltip:SetOwner(self, "ANCHOR_RIGHT");
    GameTooltip:SetText(INVTYPE_RANGED, HIGHLIGHT_FONT_COLOR.r, HIGHLIGHT_FONT_COLOR.g, HIGHLIGHT_FONT_COLOR.b);
    GameTooltip:AddDoubleLine(ATTACK_SPEED_COLON, format("%.2f", self.attackSpeed), NORMAL_FONT_COLOR.r, NORMAL_FONT_COLOR.g, NORMAL_FONT_COLOR.b, NORMAL_FONT_COLOR.r, NORMAL_FONT_COLOR.g, NORMAL_FONT_COLOR.b);
    GameTooltip:AddDoubleLine(DAMAGE_COLON, self.damage, NORMAL_FONT_COLOR.r, NORMAL_FONT_COLOR.g, NORMAL_FONT_COLOR.b, NORMAL_FONT_COLOR.r, NORMAL_FONT_COLOR.g, NORMAL_FONT_COLOR.b);
    GameTooltip:AddDoubleLine(DAMAGE_PER_SECOND, format("%.1f", self.dps), NORMAL_FONT_COLOR.r, NORMAL_FONT_COLOR.g, NORMAL_FONT_COLOR.b, NORMAL_FONT_COLOR.r, NORMAL_FONT_COLOR.g, NORMAL_FONT_COLOR.b);
    GameTooltip:Show();
end
local function SpellBonusDamage_OnEnter (self)
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
local function SpellCritChance_OnEnter (self)
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

local function GetTalentSpellHitBonus()
    local _, _, classId = UnitClass("player")
    local bonus = 0

    if classId == INDEX_CLASS_PRIEST then
        local _, _, _, _, points, _, _, _ = GetTalentInfo(3, 3)
        bonus = points -- 0-3% from Shadow Focus
    end

    if classId == INDEX_CLASS_MAGE then
        local _, _, _, _, points, _, _, _ = GetTalentInfo(3, 17)
        bonus = points * 1 -- 0-3% from Elemental Precision
    end

    if classId == INDEX_CLASS_SHAMAN then
        local _, _, _, _, points, _, _, _ = GetTalentInfo(1, 16)
        bonus = points -- 0-3% from Elemental Precision
    end

    if classId == INDEX_CLASS_DRUID then
        local _, _, _, _, points, _, _, _ = GetTalentInfo(1, 13)
        bonus = points * 2 -- 0-4% from Balance of Power
    end

    if classId == INDEX_CLASS_WARLOCK then
        local _, _, _, _, points, _, _, _ = GetTalentInfo(1, 5)
        bonus = points -- 0-3% from Suppression
    end

    return bonus
end

local function GetBuffSpellHitBonus()
    local buffHit = 0;
    for i = 1, 40 do
        local _, _, _, _, _, _, _, _, _, spellId, _ = UnitAura("player", i, "HELPFUL");
        if spellId == nil then
            break ;
        end

        if spellId == 28878 or spellId == 6562 then
            buffHit = buffHit + 1; -- 1% from Heroic Presence
            break ;
        end
    end
    return buffHit
end

local DODGE_PARRY_BLOCK_PERCENT_PER_DEFENSE = 0.04;

local function GetDodgeBlockParryChanceFromDefense()
    local base, modifier = UnitDefense("player");
    --local defensePercent = DODGE_PARRY_BLOCK_PERCENT_PER_DEFENSE * modifier;
    local defensePercent = DODGE_PARRY_BLOCK_PERCENT_PER_DEFENSE * ((base + modifier) - (UnitLevel("player") * 5));
    defensePercent = max(defensePercent, 0);
    return defensePercent;
end

local function PaperDollFrame_GetArmorReduction(armor, attackerLevel)
    return C_PaperDollInfo.GetArmorEffectiveness(armor, attackerLevel) * 100;
end

local function ComputePetBonus(stat, value)
    local temp, unitClass = UnitClass("player");
    unitClass = strupper(unitClass);
    if (unitClass == "WARLOCK") then
        if (WARLOCK_PET_BONUS[stat]) then
            return value * WARLOCK_PET_BONUS[stat];
        else
            return 0;
        end
    elseif (unitClass == "HUNTER") then
        if (HUNTER_PET_BONUS[stat]) then
            return value * HUNTER_PET_BONUS[stat];
        else
            return 0;
        end
    end

    return 0;
end

Module.stats = {
    base = {
        Health = function(unit)
            local health = UnitHealthMax(unit);
            local healthText = BreakUpLargeNumbers(health);

            return {
                value = healthText,
                tooltip = HIGHLIGHT_FONT_COLOR_CODE .. format(PAPERDOLLFRAME_TOOLTIP_FORMAT, HEALTH) .. " " .. healthText .. FONT_COLOR_CODE_CLOSE,
                tooltip1 = STAT_HEALTH_TOOLTIP
            }
        end,
        Power = function(unit)
            local powerType, powerToken = UnitPowerType(unit);
            local power = UnitPowerMax(unit) or 0;
            local powerText = BreakUpLargeNumbers(power);

            if powerToken then
                return {
                    value = powerText,
                    tooltip = HIGHLIGHT_FONT_COLOR_CODE .. format(PAPERDOLLFRAME_TOOLTIP_FORMAT, ExtraStats:translate("stats." .. string.lower(powerToken))) .. " " .. powerText .. FONT_COLOR_CODE_CLOSE,
                    tooltip1 = _G["STAT_" .. powerToken .. "_TOOLTIP"]
                }
            else
                return {
                    value = powerText,
                }
            end
        end,
        Speed = function(unit)
            local _, runSpeed, flightSpeed, swimSpeed = GetUnitSpeed(unit)
            local currentSpeed

            if IsFlying() then
                currentSpeed = flightSpeed
            elseif IsSwimming() then
                currentSpeed = swimSpeed
            else
                currentSpeed = runSpeed
            end

            currentSpeed = currentSpeed / 7 * 100

            local buff = currentSpeed - 100;

            local value;

            local color = COMMON_FONT_COLOR_CODE;

            if buff >= 320 then
                color = LEGENDARY_FONT_COLOR_CODE;
            end
            if buff < 320 then
                color = EPIC_FONT_COLOR_CODE
            end
            if buff < 190 then
                color = RARE_FONT_COLOR_CODE
            end

            if buff == 0 then
                color = COMMON_FONT_COLOR_CODE
            end

            if buff < 0 then
                color = RED_FONT_COLOR_CODE
            end

            value = color .. format("%.2f%%", currentSpeed) .. FONT_COLOR_CODE_CLOSE

            return {
                value = value,
                tooltip = ExtraStats:translate("stats.tooltip.movementspeed"),
                tooltip2 = ExtraStats:translate("stats.tooltip.movementspeed_description")
            }
        end
    },
    melee = {
        Damage = function(unit)
            local textValue;
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
                onEnter = MeleeDamageFrame_OnEnter
            }
        end,
        AttackPower = function(unit)
            local base, posBuff, negBuff = UnitAttackPower(unit);

            local value, tooltip = ExtraStats:FormatStat(MELEE_ATTACK_POWER, base, posBuff, negBuff);

            return {
                value = value,
                tooltip = tooltip,
                tooltip2 = format(MELEE_ATTACK_POWER_TOOLTIP, max((base + posBuff + negBuff), 0) / ATTACK_POWER_MAGIC_NUMBER)
            }
        end,
        Speed = function(unit)
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

            return {
                value = text,
                tooltip = HIGHLIGHT_FONT_COLOR_CODE .. format(PAPERDOLLFRAME_TOOLTIP_FORMAT, ATTACK_SPEED) .. " " .. text .. FONT_COLOR_CODE_CLOSE,
                tooltip2 = format(CR_HASTE_RATING_TOOLTIP, GetCombatRating(CR_HASTE_MELEE), GetCombatRatingBonus(CR_HASTE_MELEE))
            }
        end,
        HitChance = function(unit)
            local ratingIndex = CR_HIT_MELEE;
            local statName = _G["COMBAT_RATING_NAME" .. ratingIndex];
            local rating = GetCombatRating(ratingIndex);
            local ratingBonus = GetCombatRatingBonus(ratingIndex);

            local a = ExtraStats:GetHitRatingBonus()

            local hitChance = format("%.2f%%", a)

            return {
                value = hitChance,
                tooltip = HIGHLIGHT_FONT_COLOR_CODE .. format(PAPERDOLLFRAME_TOOLTIP_FORMAT, statName) .. " " .. rating .. FONT_COLOR_CODE_CLOSE,
                tooltip2 = format(CR_HIT_MELEE_TOOLTIP, UnitLevel(unit), a, GetCombatRating(CR_ARMOR_PENETRATION), GetArmorPenetration())
            }
        end,
        CritChance = function(unit)
            local critChance = format("%.2f%%", GetCritChance());

            return {
                value = critChance,
                tooltip = HIGHLIGHT_FONT_COLOR_CODE .. format(PAPERDOLLFRAME_TOOLTIP_FORMAT, MELEE_CRIT_CHANCE) .. " " .. critChance .. FONT_COLOR_CODE_CLOSE,
                tooltip2 = format(CR_CRIT_MELEE_TOOLTIP, GetCombatRating(CR_CRIT_MELEE), GetCombatRatingBonus(CR_CRIT_MELEE))
            }
        end,
        Haste = function(unit)
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

            return {
                value = format("%.2f%%", GetCombatRatingBonus(CR_HASTE_MELEE)),
                tooltip = HIGHLIGHT_FONT_COLOR_CODE .. format(PAPERDOLLFRAME_TOOLTIP_FORMAT, ATTACK_SPEED) .. " " .. text .. FONT_COLOR_CODE_CLOSE,
                tooltip2 = format(CR_HASTE_RATING_TOOLTIP, GetCombatRating(CR_HASTE_MELEE), GetCombatRatingBonus(CR_HASTE_MELEE))
            }
        end,
        Expertise = function(unit)
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

            local expertisePercent, offhandExpertisePercent = GetExpertisePercent();
            expertisePercent = format("%.2f", expertisePercent);
            if (offhandSpeed) then
                offhandExpertisePercent = format("%.2f", offhandExpertisePercent);
                text = expertisePercent .. "% / " .. offhandExpertisePercent .. "%";
            else
                text = expertisePercent .. "%";
            end

            return {
                value = expertise,
                tooltip = HIGHLIGHT_FONT_COLOR_CODE .. format(PAPERDOLLFRAME_TOOLTIP_FORMAT, _G["COMBAT_RATING_NAME" .. CR_EXPERTISE]) .. " " .. text .. FONT_COLOR_CODE_CLOSE,
                tooltip2 = format(CR_EXPERTISE_TOOLTIP, text, GetCombatRating(CR_EXPERTISE), GetCombatRatingBonus(CR_EXPERTISE))
            }
        end
    },
    ranged = {
        Damage = function(unit)
            local textValue;
            -- If no ranged attack then set to n/a
            local hasRelic = UnitHasRelicSlot(unit);
            local rangedTexture = GetInventoryItemTexture(unit, 18);
            if (rangedTexture and not hasRelic) then
                PaperDollFrame.noRanged = nil;
            else
                PaperDollFrame.noRanged = 1;
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

        end,
        Speed = function(unit)
            local text = UnitRangedDamage(unit);
            return {
                value = format("%.2f", text),
                tooltip = HIGHLIGHT_FONT_COLOR_CODE .. format(PAPERDOLLFRAME_TOOLTIP_FORMAT, ATTACK_SPEED) .. " " .. text .. FONT_COLOR_CODE_CLOSE,
                tooltip2 = format(CR_HASTE_RATING_TOOLTIP, GetCombatRating(CR_HASTE_RANGED), GetCombatRatingBonus(CR_HASTE_RANGED))
            }
        end,
        AttackPower = function(unit)
            local tooltip, tooltip2, value
            local base, posBuff, negBuff = UnitRangedAttackPower(unit);

            value, tooltip = ExtraStats:FormatStat(RANGED_ATTACK_POWER, base, posBuff, negBuff);

            local totalAP = base + posBuff + negBuff;
            tooltip2 = format(RANGED_ATTACK_POWER_TOOLTIP, max((totalAP), 0) / ATTACK_POWER_MAGIC_NUMBER);
            return {
                value = value,
                tooltip = tooltip,
                tooltip2 = tooltip2
            }
        end,
        CritChance = function(unit)
            local critChance = GetRangedCritChance();

            return {
                value = format("%.2f%%", critChance),
                tooltip = HIGHLIGHT_FONT_COLOR_CODE .. format(PAPERDOLLFRAME_TOOLTIP_FORMAT, RANGED_CRIT_CHANCE) .. " " .. critChance .. FONT_COLOR_CODE_CLOSE,
                tooltip2 = format(CR_CRIT_RANGED_TOOLTIP, GetCombatRating(CR_CRIT_RANGED), GetCombatRatingBonus(CR_CRIT_RANGED))
            }
        end,
        HitChance = function(unit)
            local ratingIndex = CR_HIT_RANGED;
            local statName = _G["COMBAT_RATING_NAME" .. ratingIndex];
            local hitModifier = GetHitModifier();

            local rangedHit = math.floor((GetCombatRatingBonus(CR_HIT_RANGED) + hitModifier) * 100) / 100;

            return {
                value = format("%.2f%%", rangedHit),
                tooltip = HIGHLIGHT_FONT_COLOR_CODE .. format(PAPERDOLLFRAME_TOOLTIP_FORMAT, statName) .. " " .. rangedHit .. FONT_COLOR_CODE_CLOSE,
                tooltip2 = format(CR_HIT_RANGED_TOOLTIP, UnitLevel(unit), rangedHit, GetCombatRating(CR_ARMOR_PENETRATION), GetArmorPenetration())
            }
        end,
        Haste = function(unit)
            local speed = GetCombatRating(CR_HASTE_RANGED);
            speed = format("%.2f", speed);

            return {
                value = format("%.2f%%", GetRangedHaste()),
                tooltip = HIGHLIGHT_FONT_COLOR_CODE .. format(PAPERDOLLFRAME_TOOLTIP_FORMAT, ATTACK_SPEED) .. " " .. speed .. FONT_COLOR_CODE_CLOSE,
                tooltip2 = format(CR_HASTE_RATING_TOOLTIP, GetCombatRating(CR_HASTE_RANGED), GetCombatRatingBonus(CR_HASTE_RANGED))
            }
        end
    },
    spell = {
        Damage = function(unit)
            local holySchool = 2;
            -- Start at 2 to skip physical damage
            local minModifier = GetSpellBonusDamage(holySchool);

            local data = {
                onEnter = SpellBonusDamage_OnEnter,
            }

            data.bonusDamage = {};
            data.bonusDamage[holySchool] = minModifier;

            local bonusDamage
            for i = (holySchool + 1), MAX_SPELL_SCHOOLS do
                bonusDamage = GetSpellBonusDamage(i);
                minModifier = min(minModifier, bonusDamage);
                data.bonusDamage[i] = bonusDamage;
            end
            data.minModifier = minModifier
            data.value = minModifier;

            return data
        end,
        Healing = function(unit)
            local bonusHealing = GetSpellBonusHealing();
            return {
                value = bonusHealing,
                tooltip = HIGHLIGHT_FONT_COLOR_CODE .. BONUS_HEALING .. FONT_COLOR_CODE_CLOSE,
                tooltip2 = format(BONUS_HEALING_TOOLTIP, bonusHealing)
            }
        end,
        CritChance = function(unit)
            local holySchool = 2;
            local minCrit = GetSpellCritChance(holySchool);
            local data = {
                onEnter = SpellCritChance_OnEnter
            }

            data.spellCrit = {};
            data.spellCrit[holySchool] = minCrit;
            local spellCrit;
            for i = (holySchool + 1), MAX_SPELL_SCHOOLS do
                spellCrit = GetSpellCritChance(i);
                minCrit = min(minCrit, spellCrit);
                data.spellCrit[i] = spellCrit;
            end

            minCrit = format("%.2f%%", minCrit);

            data.value = minCrit
            data.minCrit = minCrit

            return data
        end,
        HitChance = function(unit)
            local ratingIndex = CR_HIT_SPELL;
            local statName = _G["COMBAT_RATING_NAME" .. ratingIndex];
            local spellPenetration = GetSpellPenetration();

            local rating = GetCombatRating(ratingIndex);
            local ratingBonus = GetCombatRatingBonus(ratingIndex) + GetTalentSpellHitBonus() + GetBuffSpellHitBonus();

            local hitChance = format("%.2f%%", ratingBonus)

            return {
                value = hitChance,
                tooltip = HIGHLIGHT_FONT_COLOR_CODE .. format(PAPERDOLLFRAME_TOOLTIP_FORMAT, statName) .. " " .. rating .. FONT_COLOR_CODE_CLOSE;
                tooltip2 = format(CR_HIT_SPELL_TOOLTIP, UnitLevel(unit), ratingBonus, spellPenetration, spellPenetration)
            }
        end,
        Penetration = function(unit)
            return {
                value = GetSpellPenetration(),
                tooltip = HIGHLIGHT_FONT_COLOR_CODE .. format(PAPERDOLLFRAME_TOOLTIP_FORMAT, SPELL_PENETRATION) .. FONT_COLOR_CODE_CLOSE,
                tooltip2 = SPELL_PENETRATION_TOOLTIP
            }
        end,
        Haste = function(unit)
            return {
                value = format("%.2f%%", GetCombatRatingBonus(CR_HASTE_SPELL)),
                tooltip = HIGHLIGHT_FONT_COLOR_CODE .. SPELL_HASTE .. FONT_COLOR_CODE_CLOSE,
                tooltip2 = format(SPELL_HASTE_TOOLTIP, GetCombatRatingBonus(CR_HASTE_SPELL))
            }
        end,
        Regen = function(unit)
            local base, casting = GetManaRegen();
            -- All mana regen stats are displayed as mana/5 sec.
            base = floor(base * 5.0);
            casting = floor(casting * 5.0);

            return {
                value = format("%s / %s", casting, base),
                tooltip = HIGHLIGHT_FONT_COLOR_CODE .. MANA_REGEN .. FONT_COLOR_CODE_CLOSE,
                tooltip2 = format(MANA_REGEN_TOOLTIP, base, casting)
            }
        end
    },
    defense = {
        Armor = function(unit)
            local value, tooltip, tooltip2;
            local base, effectiveArmor, armor, posBuff, negBuff = UnitArmor(unit);

            value, tooltip = ExtraStats:FormatStat(ARMOR, base, posBuff, negBuff);

            local armorReduction = PaperDollFrame_GetArmorReduction(effectiveArmor, UnitLevel(unit));
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
        end,
        Defense = function(unit)
            local value, tooltip, tooltip2;
            local base, modifier = UnitDefense(unit);
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
        end,
        Dodge = function(unit)
            local chance = GetDodgeChance();
            local tooltip = HIGHLIGHT_FONT_COLOR_CODE .. format(PAPERDOLLFRAME_TOOLTIP_FORMAT, DODGE_CHANCE) .. " " .. string.format("%.02f", chance) .. "%" .. FONT_COLOR_CODE_CLOSE;
            local tooltip2 = format(CR_DODGE_TOOLTIP, GetCombatRating(CR_DODGE), GetCombatRatingBonus(CR_DODGE));

            return {
                value = format("%.2f%%", chance),
                tooltip = tooltip,
                tooltip2 = tooltip2
            }
        end,
        Block = function(unit)
            local chance = GetBlockChance();
            local tooltip = HIGHLIGHT_FONT_COLOR_CODE .. format(PAPERDOLLFRAME_TOOLTIP_FORMAT, BLOCK_CHANCE) .. " " .. string.format("%.02f", chance) .. "%" .. FONT_COLOR_CODE_CLOSE;
            local tooltip2 = format(CR_BLOCK_TOOLTIP, GetCombatRating(CR_BLOCK), GetCombatRatingBonus(CR_BLOCK), GetShieldBlock());

            return {
                value = format("%.2f%%", chance),
                tooltip = tooltip,
                tooltip2 = tooltip2
            }
        end,
        Parry = function(unit)
            local chance = GetParryChance();
            local tooltip = HIGHLIGHT_FONT_COLOR_CODE .. format(PAPERDOLLFRAME_TOOLTIP_FORMAT, PARRY_CHANCE) .. " " .. string.format("%.02f", chance) .. "%" .. FONT_COLOR_CODE_CLOSE;
            local tooltip2 = format(CR_PARRY_TOOLTIP, GetCombatRating(CR_PARRY), GetCombatRatingBonus(CR_PARRY));

            return {
                value = format("%.2f%%", chance),
                tooltip = tooltip,
                tooltip2 = tooltip2
            }
        end,
        Resilience = function(unit)
            local melee = GetCombatRating(CR_CRIT_TAKEN_MELEE);
            local ranged = GetCombatRating(CR_CRIT_TAKEN_RANGED);
            local spell = GetCombatRating(CR_CRIT_TAKEN_SPELL);

            local minResilience = min(melee, ranged);
            minResilience = min(minResilience, spell);

            local lowestRating = CR_CRIT_TAKEN_MELEE;
            if (melee == minResilience) then
                lowestRating = CR_CRIT_TAKEN_MELEE;
            elseif (ranged == minResilience) then
                lowestRating = CR_CRIT_TAKEN_RANGED;
            else
                lowestRating = CR_CRIT_TAKEN_SPELL;
            end

            local maxRatingBonus = GetMaxCombatRatingBonus(lowestRating);
            local lowestRatingBonus = GetCombatRatingBonus(lowestRating);

            return {
                value = minResilience,
                tooltip = HIGHLIGHT_FONT_COLOR_CODE .. format(PAPERDOLLFRAME_TOOLTIP_FORMAT, STAT_RESILIENCE) .. " " .. minResilience .. FONT_COLOR_CODE_CLOSE,
                tooltip2 = format(RESILIENCE_TOOLTIP, lowestRatingBonus, min(lowestRatingBonus * RESILIENCE_CRIT_CHANCE_TO_DAMAGE_REDUCTION_MULTIPLIER, maxRatingBonus), lowestRatingBonus * RESILIENCE_CRIT_CHANCE_TO_CONSTANT_DAMAGE_REDUCTION_MULTIPLIER)
            }
        end
    }
}

function Module:Base()
    local Category = Stats:CreateCategory("base", UnitName("player"), {
        order = -999
    })

    Category:Add(ExtraStats:translate("stats.health"), Module.stats.base.Health)
    Category:Add(function()
        local powerType, powerToken = UnitPowerType("player");
        return ExtraStats:translate("stats." .. string.lower(powerToken))
    end, Module.stats.base.Power)
    Category:Add(ExtraStats:translate("stats.movespeed"), Module.stats.base.Speed, {
        onUpdate = function(self)
            if not self.lastUpdate or self.lastUpdate < GetTime() - 0.2 then
                self.lastUpdate = GetTime();
                self.Value:SetText(MoveSpeed().value)
            end
        end
    })
end
function Module:Attributes()
    local Category = Stats:CreateCategory("attributes", PLAYERSTAT_BASE_STATS, {
        order = 0,
    })

    local statIndexTable = {
        "STRENGTH",
        "AGILITY",
        "STAMINA",
        "INTELLECT",
        "SPIRIT",
    }

    for i = 1, NUM_STATS, 1 do
        Category:Add(_G["SPELL_STAT" .. i .. "_NAME"], function(unit)
            local stat;
            local effectiveStat;
            local posBuff;
            local negBuff;
            local tooltip, tooltip2, frameText;
            stat, effectiveStat, posBuff, negBuff = UnitStat(unit, i);

            local tooltipText = HIGHLIGHT_FONT_COLOR_CODE .. _G["SPELL_STAT" .. i .. "_NAME"] .. " ";
            local temp, classFileName = UnitClass(unit);
            local classStatText = _G[strupper(classFileName) .. "_" .. statIndexTable[i] .. "_" .. "TOOLTIP"];
            -- If can't find one use the default
            if (not classStatText) then
                classStatText = _G["DEFAULT" .. "_" .. statIndexTable[i] .. "_" .. "TOOLTIP"];
            end

            if ((posBuff == 0) and (negBuff == 0)) then
                --text:SetText(effectiveStat);
                frameText = effectiveStat;
                tooltip = tooltipText .. effectiveStat .. FONT_COLOR_CODE_CLOSE;
                tooltip2 = classStatText;
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
                tooltip2 = classStatText;

                -- If there are any negative buffs then show the main number in red even if there are
                -- positive buffs. Otherwise show in green.
                if (negBuff < 0) then
                    frameText = RED_FONT_COLOR_CODE .. effectiveStat .. FONT_COLOR_CODE_CLOSE;
                else
                    frameText = GREEN_FONT_COLOR_CODE .. effectiveStat .. FONT_COLOR_CODE_CLOSE;
                end
            end

            return {
                value = frameText,
                tooltip = tooltip,
                tooltip2 = tooltip2
            }
        end)
    end
end

function Module:Melee()
    local Category = Stats:CreateCategory("melee", PLAYERSTAT_MELEE_COMBAT, {
        order = 1,
    })

    Category:Add(DAMAGE, self.stats.melee.Damage)
    Category:Add(STAT_ATTACK_POWER, self.stats.melee.AttackPower)
    Category:Add(WEAPON_SPEED, self.stats.melee.Speed)
    Category:Add(STAT_CRITICAL_STRIKE, self.stats.melee.CritChance)
    Category:Add(STAT_HIT_CHANCE, self.stats.melee.HitChance)
    Category:Add(STAT_HASTE, self.stats.melee.Haste)
    Category:Add(STAT_EXPERTISE, self.stats.melee.Expertise)
end

function Module:Ranged()
    local Category = Stats:CreateCategory("ranged", PLAYERSTAT_RANGED_COMBAT, {
        order = 2,
        show = function()
            if ExtraStats.db.char.dynamic then
                return CURRENT_CLASS == INDEX_CLASS_HUNTER;
            end

            return true
        end
    })

    Category:Add(DAMAGE, self.stats.ranged.Damage)
    Category:Add(STAT_ATTACK_POWER, self.stats.ranged.AttackPower)
    Category:Add(WEAPON_SPEED, self.stats.ranged.Speed)
    Category:Add(STAT_CRITICAL_STRIKE, self.stats.ranged.CritChance)
    Category:Add(STAT_HIT_CHANCE, self.stats.ranged.HitChance)
    Category:Add(STAT_HASTE, self.stats.ranged.Haste)
end

function Module:Spell()
    local Category = Stats:CreateCategory("spell", PLAYERSTAT_SPELL_COMBAT, {
        order = 3,
        classes = { INDEX_CLASS_MAGE, INDEX_CLASS_PRIEST, INDEX_CLASS_SHAMAN, INDEX_CLASS_DRUID, INDEX_CLASS_PALADIN },
        roles = { CLASS_ROLE_DAMAGER, CLASS_ROLE_HEALER },
    })

    Category:Add(STAT_SPELLPOWER, self.stats.spell.Damage)
    Category:Add(STAT_SPELLHEALING, self.stats.spell.Healing)
    Category:Add(MANA_REGEN, self.stats.spell.Regen)
    Category:Add(STAT_CRITICAL_STRIKE, self.stats.spell.CritChance)
    Category:Add(STAT_HIT_CHANCE, self.stats.spell.HitChance)
end

function Module:Defense()
    local Category = Stats:CreateCategory("defenses", PLAYERSTAT_DEFENSES, {
        order = 20,
        roles = { CLASS_ROLE_TANK },
    })
    Category:Add(STAT_ARMOR, self.stats.defense.Armor)
    Category:Add(DEFENSE, self.stats.defense.Defense)
    Category:Add(STAT_DODGE, self.stats.defense.Dodge)
    Category:Add(STAT_PARRY, self.stats.defense.Parry)
    Category:Add(STAT_BLOCK, self.stats.defense.Block)
    Category:Add(STAT_RESILIENCE, self.stats.defense.Resilience)
end

function Module:OnEnable()
    Module:Base()
    Module:Attributes();
    Module:Melee();
    Module:Ranged();
    Module:Defense();

end