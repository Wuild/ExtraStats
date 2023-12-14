local Module = ExtraStats.modules:NewModule("Vanilla")
local Stats = ExtraStats:LoadModule("character.stats")

SPELL_HIT_TOOLTIP_TXT = "Spell Hit chance from gear: %d%%";
SPELL_HIT_TOOLTIP_2_TXT = "Spell Hit chance (Gear and Talents): %d%%";
SPELL_HIT_SUBTOOLTIP_TXT = "Spell Hit chance (Gear + Talents):";
ARCANE_SPELL_HIT_TXT = "Arcane Spell Hit";
FIRE_SPELL_HIT_TXT = "Fire Spell Hit";
FROST_SPELL_HIT_TXT = "Frost Spell Hit";
DESTRUCTION_SPELL_HIT_TXT = "Destruction Spell Hit";
AFFLICTION_SPELL_HIT_TXT = "Affliction Spell Hit";
LIGHTNING_TXT = "Lightning";

local SYMBOL_TAB = "    ";

local AuraIdToMp5 = {
    -- BOW
    [19742] = 10,
    [19850] = 15,
    [19852] = 20,
    [19853] = 25,
    [19854] = 30,
    [25290] = 33,
    -- GBOW
    [25894] = 30,
    [25918] = 33,
    -- Mana Spring Totem
    [5675] = 10,
    [10495] = 15,
    [10496] = 20,
    [10497] = 25,
    -- Mageblood potion
    [24363] = 12,
    --Nightfin Soup
    [18194] = 8
}
local CombatManaRegenSpellIdToModifier = {
    -- Mage Armor
    [6117] = 0.3,
    [22782] = 0.3,
    [22783] = 0.3
};

local function FormatStat(name, base, posBuff, negBuff)
    local effective = max(0, base + posBuff + negBuff);
    local text = HIGHLIGHT_FONT_COLOR_CODE .. name .. " " .. effective;
    if ((posBuff == 0) and (negBuff == 0)) then
        text = text .. FONT_COLOR_CODE_CLOSE;
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
            effective = RED_FONT_COLOR_CODE .. effective .. FONT_COLOR_CODE_CLOSE;
        elseif (posBuff > 0) then
            effective = GREEN_FONT_COLOR_CODE .. effective .. FONT_COLOR_CODE_CLOSE;
        end
    end

    return effective, text;
end

local function GetSkill(unit, skill)
    local numSkills = GetNumSkillLines();
    local skillIndex = 0;
    local currentHeader = nil;
    local playerLevel = UnitLevel(unit);

    for i = 1, numSkills do
        local skillName = select(1, GetSkillLineInfo(i));
        local isHeader = select(2, GetSkillLineInfo(i));

        if isHeader ~= nil and isHeader then
            currentHeader = skillName;
        else
            if (skillName == skill) then
                skillIndex = i;
                break ;
            end
        end
    end

    local skillRank, skillModifier;
    if (skillIndex > 0) then
        skillRank = select(4, GetSkillLineInfo(skillIndex));
        skillModifier = select(6, GetSkillLineInfo(skillIndex));
    else
        -- Use this as a backup, just in case something goes wrong
        skillRank, skillModifier = UnitDefense(unit); --Not working properly
    end

    return skillRank, skillModifier, playerLevel;
end

local function GetAppropriateDamage(unit, category)
    if category == PLAYERSTAT_MELEE_COMBAT then
        return UnitDamage(unit);
    elseif category == PLAYERSTAT_RANGED_COMBAT then
        local attackTime, minDamage, maxDamage, bonusPos, bonusNeg, percent = UnitRangedDamage(unit);
        return minDamage, maxDamage, nil, nil, bonusPos, bonusNeg, percent;
    end
end

local function GetAppropriateAttackSpeed(unit, category)
    if category == PLAYERSTAT_MELEE_COMBAT then
        return UnitAttackSpeed(unit);
    elseif category == PLAYERSTAT_RANGED_COMBAT then
        local attackSpeed = select(1, UnitRangedDamage(unit))
        return attackSpeed, nil;
    end
end

local function DamageFrame_OnEnter (self)
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

local function SpellDamageFrame_OnEnter(self)

    self.holyDmg = GetSpellBonusDamage(2);
    self.fireDmg = GetSpellBonusDamage(3);
    self.natureDmg = GetSpellBonusDamage(4);
    self.frostDmg = GetSpellBonusDamage(5);
    self.shadowDmg = GetSpellBonusDamage(6);
    self.arcaneDmg = GetSpellBonusDamage(7);

    GameTooltip:SetOwner(self, "ANCHOR_RIGHT");
    GameTooltip:SetText(STAT_SPELLPOWER, HIGHLIGHT_FONT_COLOR.r, HIGHLIGHT_FONT_COLOR.g, HIGHLIGHT_FONT_COLOR.b);
    GameTooltip:AddDoubleLine(STAT_SPELLPOWER_TOOLTIP);
    GameTooltip:AddLine(" "); -- Blank line.
    GameTooltip:AddDoubleLine(SPELL_SCHOOL1_CAP .. " " .. DAMAGE .. ": ", format("%.2F", self.holyDmg), NORMAL_FONT_COLOR.r, NORMAL_FONT_COLOR.g, NORMAL_FONT_COLOR.b, HIGHLIGHT_FONT_COLOR.r, HIGHLIGHT_FONT_COLOR.g, HIGHLIGHT_FONT_COLOR.b);
    GameTooltip:AddDoubleLine(SPELL_SCHOOL2_CAP .. " " .. DAMAGE .. ": ", format("%.2F", self.fireDmg), NORMAL_FONT_COLOR.r, NORMAL_FONT_COLOR.g, NORMAL_FONT_COLOR.b, HIGHLIGHT_FONT_COLOR.r, HIGHLIGHT_FONT_COLOR.g, HIGHLIGHT_FONT_COLOR.b);
    GameTooltip:AddDoubleLine(SPELL_SCHOOL4_CAP .. " " .. DAMAGE .. ": ", format("%.2F", self.frostDmg), NORMAL_FONT_COLOR.r, NORMAL_FONT_COLOR.g, NORMAL_FONT_COLOR.b, HIGHLIGHT_FONT_COLOR.r, HIGHLIGHT_FONT_COLOR.g, HIGHLIGHT_FONT_COLOR.b);
    GameTooltip:AddDoubleLine(SPELL_SCHOOL6_CAP .. " " .. DAMAGE .. ": ", format("%.2F", self.arcaneDmg), NORMAL_FONT_COLOR.r, NORMAL_FONT_COLOR.g, NORMAL_FONT_COLOR.b, HIGHLIGHT_FONT_COLOR.r, HIGHLIGHT_FONT_COLOR.g, HIGHLIGHT_FONT_COLOR.b);
    GameTooltip:AddDoubleLine(SPELL_SCHOOL5_CAP .. " " .. DAMAGE .. ": ", format("%.2F", self.shadowDmg), NORMAL_FONT_COLOR.r, NORMAL_FONT_COLOR.g, NORMAL_FONT_COLOR.b, HIGHLIGHT_FONT_COLOR.r, HIGHLIGHT_FONT_COLOR.g, HIGHLIGHT_FONT_COLOR.b);
    GameTooltip:AddDoubleLine(SPELL_SCHOOL3_CAP .. " " .. DAMAGE .. ": ", format("%.2F", self.natureDmg), NORMAL_FONT_COLOR.r, NORMAL_FONT_COLOR.g, NORMAL_FONT_COLOR.b, HIGHLIGHT_FONT_COLOR.r, HIGHLIGHT_FONT_COLOR.g, HIGHLIGHT_FONT_COLOR.b);

    GameTooltip:Show();
end

local function GetMP5ModifierFromTalents(unit)
    local unitClassId = select(3, UnitClass(unit));
    local spellRank = 0;

    if unitClassId == INDEX_CLASS_PRIEST then
        -- Meditation
        spellRank = select(5, GetTalentInfo(1, 8));
    elseif unitClassId == INDEX_CLASS_MAGE then
        -- Arcane Meditation
        spellRank = select(5, GetTalentInfo(1, 12));
    elseif unitClassId == INDEX_CLASS_DRUID then
        -- Reflection
        spellRank = select(5, GetTalentInfo(3, 6));
    end

    local modifier = spellRank * 0.05;

    return modifier;
end

local function HasEnchant(unit, slotId, enchantId)
    local itemLink = GetInventoryItemLink(unit, slotId);
    if itemLink then
        local itemId, enchant = itemLink:match("item:(%d+):(%d*)");
        if enchant then
            if tonumber(enchant) == enchantId then
                return true;
            end
        end
    end

    return false;
end

local function GetMP5FromGear(unit)
    local mp5 = 0;
    for i = 1, 18 do
        local itemLink = GetInventoryItemLink(unit, i);
        if itemLink then
            local stats = GetItemStats(itemLink);
            if stats then
                -- For some reason this returns (mp5 - 1) so I have to add 1 to the result
                local statMP5 = stats["ITEM_MOD_POWER_REGEN0_SHORT"];
                if (statMP5) then
                    mp5 = mp5 + statMP5 + 1;
                end
            end
        end
    end

    if (HasEnchant(unit, INVSLOT_WRIST, 2565)) then
        -- Mana Regen
        mp5 = mp5 + 4;
    end

    if (HasEnchant(unit, INVSLOT_SHOULDER, 2715)) then
        -- Resilience of the Scourge
        mp5 = mp5 + 5;
    end

    local tempMHEnchantId = select(4, GetWeaponEnchantInfo());
    if (tempMHEnchantId == 2629) then
        -- Brilliant Mana Oil
        mp5 = mp5 + 12;
    end

    return mp5;
end

local function IsBoWSpellId(spellId)

    if (spellId == 19742 or spellId == 19850 or spellId == 19852 or spellId == 19853 or spellId == 19854 or spellId == 25290 or spellId == 25894 or spellId == 25918) then
        return true;
    end

    return false;
end

local function GetPaladinImprovedBoWModifier()
    -- Improved Blessing of Wisdom
    local spellRank = select(5, GetTalentInfo(1, 10));

    return spellRank * 0.1;
end

local function GetMP5FromAuras()
    local mp5FromAuras = 0;
    local mp5CombatModifier = 0;

    for i = 0, 40 do
        --local name = select(1, UnitAura("player", i, "HELPFUL", "PLAYER"));
        local spellId = select(10, UnitAura("player", i, "HELPFUL", "PLAYER"));
        if spellId then
            if AuraIdToMp5[spellId] then
                local auraMp5 = AuraIdToMp5[spellId];

                local unitClassId = select(3, UnitClass("player"));
                if (unitClassId == INDEX_CLASS_PALADIN and IsBoWSpellId(spellId)) then
                    local improvedBoWModifier = GetPaladinImprovedBoWModifier();

                    if (improvedBoWModifier > 0) then
                        auraMp5 = auraMp5 + auraMp5 * improvedBoWModifier;
                    end
                end

                mp5FromAuras = mp5FromAuras + auraMp5;
            elseif CombatManaRegenSpellIdToModifier[spellId] then
                mp5CombatModifier = mp5CombatModifier + CombatManaRegenSpellIdToModifier[spellId];
            end
            --print(name.." "..spellId);
        end
    end
    return mp5FromAuras, mp5CombatModifier;
end

local function CharacterManaRegenFrame_OnEnter(self)
    GameTooltip:SetOwner(self, "ANCHOR_RIGHT");
    GameTooltip:SetText(MANA_REGEN_TOOLTIP, HIGHLIGHT_FONT_COLOR.r, HIGHLIGHT_FONT_COLOR.g, HIGHLIGHT_FONT_COLOR.b);
    GameTooltip:AddDoubleLine(MANA_REGEN .. " (From Gear):", self.mp5FromGear);
    GameTooltip:AddDoubleLine(MANA_REGEN .. " (While Casting):", self.mp5Casting);
    GameTooltip:AddDoubleLine(MANA_REGEN .. " (While Not Casting):", self.mp5NotCasting);
    GameTooltip:Show();
end

local function GetMageSpellHitFromTalents()
    local arcaneHit = 0;
    local frostFireHit = 0;

    -- Arcane Focus
    local spellRank = select(5, GetTalentInfo(1, 2));
    arcaneHit = spellRank * 2; -- 2% for each point

    -- Elemental Precision
    spellRank = select(5, GetTalentInfo(3, 3));
    frostFireHit = spellRank * 2; -- 2% for each point

    return arcaneHit, frostFireHit;
end

local function GetWarlockSpellHitFromTalents()
    local afflictionHit = 0;

    -- Suppression
    local spellRank = select(5, GetTalentInfo(1, 1));
    afflictionHit = spellRank * 2; -- 2% for each point

    return afflictionHit;
end

local function SpellHitChanceFrame_OnEnter(self)
    GameTooltip:SetOwner(self, "ANCHOR_RIGHT");
    GameTooltip:SetText(format(STAT_HIT_CHANCE .. ": %.2F%%", self.hitChance), HIGHLIGHT_FONT_COLOR.r, HIGHLIGHT_FONT_COLOR.g, HIGHLIGHT_FONT_COLOR.b);

    if self.unitClassId == INDEX_CLASS_MAGE then
        GameTooltip:AddLine(" "); -- Blank line.
        GameTooltip:AddLine(SPELL_HIT_SUBTOOLTIP_TXT);
        GameTooltip:AddDoubleLine(SYMBOL_TAB .. ARCANE_SPELL_HIT_TXT, (self.arcaneHit + self.hitChance) .. "%");
        GameTooltip:AddDoubleLine(SYMBOL_TAB .. FIRE_SPELL_HIT_TXT, (self.fireHit + self.hitChance) .. "%");
        GameTooltip:AddDoubleLine(SYMBOL_TAB .. FROST_SPELL_HIT_TXT, (self.frostHit + self.hitChance) .. "%");
    elseif self.unitClassId == INDEX_CLASS_WARLOCK then
        GameTooltip:AddLine(" "); -- Blank line.
        GameTooltip:AddLine(SPELL_HIT_SUBTOOLTIP_TXT);
        GameTooltip:AddDoubleLine(SYMBOL_TAB .. DESTRUCTION_SPELL_HIT_TXT, self.hitChance .. "%");
        GameTooltip:AddDoubleLine(SYMBOL_TAB .. AFFLICTION_SPELL_HIT_TXT, (self.afflictionHit + self.hitChance) .. "%");
    elseif self.unitClassId == SHAMAN_CLASS_ID then
        GameTooltip:SetText(format(SPELL_HIT_TOOLTIP_2_TXT, self.hitChance), HIGHLIGHT_FONT_COLOR.r, HIGHLIGHT_FONT_COLOR.g, HIGHLIGHT_FONT_COLOR.b);
    end
    GameTooltip:Show();
end

local function GetMageCritStatsFromTalents()
    local arcaneInstabilityCrit = 0;
    local criticalMassCrit = 0;

    -- Arcane Instability (1, 2, 3)%
    local arcaneInstabilityTable = { 1, 2, 3 };
    local spellRank = select(5, GetTalentInfo(1, 15));
    if (spellRank > 0) and (spellRank <= 3) then
        arcaneInstabilityCrit = arcaneInstabilityTable[spellRank];
    end

    -- Critical Mass (2, 4, 6)%
    local criticalMassTable = { 2, 4, 6 };
    spellRank = select(5, GetTalentInfo(2, 13));
    if (spellRank > 0) and (spellRank <= 3) then
        criticalMassCrit = criticalMassTable[spellRank];
    end

    return arcaneInstabilityCrit, criticalMassCrit;
end

local function GetPriestCritStatsFromTalents()

    local holySpecializationCrit = 0;
    local forceOfWillCrit = 0;

    local critTable = { 1, 2, 3, 4, 5 };
    -- Holy Specialization (1, 2, 3, 4, 5)%
    local spellRank = select(5, GetTalentInfo(2, 3));
    if (spellRank > 0) and (spellRank <= 5) then
        holySpecializationCrit = critTable[spellRank];
    end

    -- Force of Will (1, 2, 3, 4, 5)%
    spellRank = select(5, GetTalentInfo(1, 14));
    if (spellRank > 0) and (spellRank <= 5) then
        forceOfWillCrit = critTable[spellRank];
    end

    local critCombined = holySpecializationCrit + forceOfWillCrit;
    return critCombined;
end

local function GetHolyCritFromBenediction(unit)
    local benedictionCrit = 0;
    local itemId = GetInventoryItemID(unit, INVSLOT_MAINHAND);

    if itemId == 18608 then
        benedictionCrit = 2;
    end

    return benedictionCrit;
end

local function GetWarlockCritStatsFromTalents()
    -- the spell rank is equal to the value
    local devastationCrit = select(5, GetTalentInfo(3, 7));

    return devastationCrit;
end

local function GetShamanCallOfThunderCrit()
    local bonusCrit = 0;
    local talentTable = { 1, 2, 3, 4, 6 };

    -- Call of Thunder (Lightning)
    local spellRank = select(5, GetTalentInfo(1, 8));

    if (spellRank > 0) and (spellRank <= 5) then
        bonusCrit = talentTable[spellRank];
    end

    return bonusCrit;
end

local function GetShamanTidalMasteryCrit()
    -- Tidal Mastery (Nature/Lightning)
    local spellRank = select(5, GetTalentInfo(3, 11));
    return spellRank;
end

local function CharacterSpellCritFrame_OnEnter(self)
    GameTooltip:SetOwner(self, "ANCHOR_RIGHT");
    GameTooltip:SetText(STAT_CRITICAL_STRIKE, HIGHLIGHT_FONT_COLOR.r, HIGHLIGHT_FONT_COLOR.g, HIGHLIGHT_FONT_COLOR.b);
    GameTooltip:AddLine(" "); -- Blank line.
    GameTooltip:AddDoubleLine(SPELL_SCHOOL1_CAP .. " " .. CRIT_ABBR .. ": ", format("%.2F", self.holyCrit) .. "%", NORMAL_FONT_COLOR.r, NORMAL_FONT_COLOR.g, NORMAL_FONT_COLOR.b, HIGHLIGHT_FONT_COLOR.r, HIGHLIGHT_FONT_COLOR.g, HIGHLIGHT_FONT_COLOR.b);
    GameTooltip:AddDoubleLine(SPELL_SCHOOL2_CAP .. " " .. CRIT_ABBR .. ": ", format("%.2F", self.fireCrit) .. "%", NORMAL_FONT_COLOR.r, NORMAL_FONT_COLOR.g, NORMAL_FONT_COLOR.b, HIGHLIGHT_FONT_COLOR.r, HIGHLIGHT_FONT_COLOR.g, HIGHLIGHT_FONT_COLOR.b);
    GameTooltip:AddDoubleLine(SPELL_SCHOOL4_CAP .. " " .. CRIT_ABBR .. ": ", format("%.2F", self.frostCrit) .. "%", NORMAL_FONT_COLOR.r, NORMAL_FONT_COLOR.g, NORMAL_FONT_COLOR.b, HIGHLIGHT_FONT_COLOR.r, HIGHLIGHT_FONT_COLOR.g, HIGHLIGHT_FONT_COLOR.b);
    GameTooltip:AddDoubleLine(SPELL_SCHOOL6_CAP .. " " .. CRIT_ABBR .. ": ", format("%.2F", self.arcaneCrit) .. "%", NORMAL_FONT_COLOR.r, NORMAL_FONT_COLOR.g, NORMAL_FONT_COLOR.b, HIGHLIGHT_FONT_COLOR.r, HIGHLIGHT_FONT_COLOR.g, HIGHLIGHT_FONT_COLOR.b);
    GameTooltip:AddDoubleLine(SPELL_SCHOOL5_CAP .. " " .. CRIT_ABBR .. ": ", format("%.2F", self.shadowCrit) .. "%", NORMAL_FONT_COLOR.r, NORMAL_FONT_COLOR.g, NORMAL_FONT_COLOR.b, HIGHLIGHT_FONT_COLOR.r, HIGHLIGHT_FONT_COLOR.g, HIGHLIGHT_FONT_COLOR.b);
    GameTooltip:AddDoubleLine(SPELL_SCHOOL3_CAP .. " " .. CRIT_ABBR .. ": ", format("%.2F", self.natureCrit) .. "%", NORMAL_FONT_COLOR.r, NORMAL_FONT_COLOR.g, NORMAL_FONT_COLOR.b, HIGHLIGHT_FONT_COLOR.r, HIGHLIGHT_FONT_COLOR.g, HIGHLIGHT_FONT_COLOR.b);

    if self.unitClassId == SHAMAN_CLASS_ID then
        GameTooltip:AddDoubleLine(LIGHTNING_TXT .. " " .. CRIT_ABBR .. ": ", format("%.2F", self.lightningCrit) .. "%", NORMAL_FONT_COLOR.r, NORMAL_FONT_COLOR.g, NORMAL_FONT_COLOR.b, HIGHLIGHT_FONT_COLOR.r, HIGHLIGHT_FONT_COLOR.g, HIGHLIGHT_FONT_COLOR.b);
    end

    GameTooltip:Show();
end

Module.stats = {
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
        end,
        AttackPower = function(unit)
            local base, posBuff, negBuff = UnitAttackPower(unit);
            local valueText, tooltipText = FormatStat(MELEE_ATTACK_POWER, base, posBuff, negBuff);
            local valueNum = max(0, base + posBuff + negBuff);

            return {
                value = valueText,
                tooltip = tooltipText,
                tooltip2 = format(MELEE_ATTACK_POWER_TOOLTIP, max((base + posBuff + negBuff), 0) / ATTACK_POWER_MAGIC_NUMBER)
            }

        end,
        AttackSpeed = function(unit)
            local speed, offhandSpeed = UnitAttackSpeed(unit);
            local displaySpeed = format("%.2F", speed);
            if (offhandSpeed) then
                offhandSpeed = format("%.2F", offhandSpeed);
            end
            if (offhandSpeed) then
                displaySpeed = displaySpeed .. " / " .. offhandSpeed;
            else
                displaySpeed = displaySpeed;
            end

            return {
                value = displaySpeed,
                tooltip = format(PAPERDOLLFRAME_TOOLTIP_FORMAT, ATTACK_SPEED) .. " " .. displaySpeed
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
        HitChance = function()
            local hitChance = GetHitModifier();
            if not hitChance then
                hitChance = 0;
            end

            return {
                value = format("%.2F%%", hitChance),
                tooltip = STAT_HIT_CHANCE .. ": " .. format("%.2F%%", hitChance)
            }
        end
    },

    ranged = {
        Damage = function(unit)

            if not IsRangedWeapon() then
                return {
                    value = NOT_APPLICABLE
                }
            end

            local textValue;
            local speed, offhandSpeed = GetAppropriateAttackSpeed(unit, PLAYERSTAT_RANGED_COMBAT);

            local minDamage;
            local maxDamage;
            local minOffHandDamage;
            local maxOffHandDamage;
            local physicalBonusPos;
            local physicalBonusNeg;
            local percent;
            minDamage, maxDamage, minOffHandDamage, maxOffHandDamage, physicalBonusPos, physicalBonusNeg, percent = GetAppropriateDamage("player", PLAYERSTAT_RANGED_COMBAT);
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
        end,
        AttackPower = function(unit)
            if not IsRangedWeapon() then
                return {
                    value = NOT_APPLICABLE
                }
            end

            if HasWandEquipped() then
                return {
                    value = NOT_APPLICABLE
                }
            end

            local base, posBuff, negBuff = UnitRangedAttackPower(unit);

            local valueText, tooltipText = FormatStat(RANGED_ATTACK_POWER, base, posBuff, negBuff);
            local valueNum = max(0, base + posBuff + negBuff);

            return {
                value = valueText,
                tooltip = tooltipText,
                tooltip2 = format(RANGED_ATTACK_POWER_TOOLTIP, valueNum / ATTACK_POWER_MAGIC_NUMBER)
            }
        end,
        AttackSpeed = function(unit)
            if not IsRangedWeapon() then
                return {
                    value = NOT_APPLICABLE
                }
            end

            local attackSpeed, minDamage, maxDamage, bonusPos, bonusNeg, percent = UnitRangedDamage(unit);
            local displaySpeed = format("%.2F", attackSpeed);

            return {
                value = displaySpeed,
                tooltip = format(PAPERDOLLFRAME_TOOLTIP_FORMAT, ATTACK_SPEED) .. " " .. displaySpeed
            }
        end,
        CritChance = function(unit)
            if not IsRangedWeapon() then
                return {
                    value = NOT_APPLICABLE
                }
            end

            local critChance = GetRangedCritChance();

            return {
                value = format("%.2F%%", critChance),
                tooltip = format(PAPERDOLLFRAME_TOOLTIP_FORMAT, STAT_CRITICAL_STRIKE) .. " " .. format("%.2F%%", critChance)
            }
        end,
        HitChance = function(unit)
            if not IsRangedWeapon() then
                return {
                    value = NOT_APPLICABLE
                }
            end

            local hitChance = GetHitModifier();

            return {
                value = format("%.2F%%", hitChance),
                tooltip = format(PAPERDOLLFRAME_TOOLTIP_FORMAT, STAT_HIT_CHANCE) .. " " .. format("%.2F%%", hitChance),
            }
        end
    },

    spell = {
        Damage = function(unit)
            local MAX_SPELL_SCHOOLS = 7;
            local holySchool = 2;

            local maxSpellDmg = GetSpellBonusDamage(holySchool);
            for i = holySchool, MAX_SPELL_SCHOOLS do
                local bonusDamage = GetSpellBonusDamage(i);
                maxSpellDmg = max(maxSpellDmg, bonusDamage);
            end

            return {
                value = BreakUpLargeNumbers(maxSpellDmg),
                onEnter = SpellDamageFrame_OnEnter
            }

        end,
        Healing = function(unit)
            local healing = GetSpellBonusHealing();

            return {
                value = BreakUpLargeNumbers(healing),
                tooltip = STAT_SPELLHEALING .. " " .. healing,
                tooltip2 = STAT_SPELLHEALING_TOOLTIP
            }

        end,
        Regen = function(unit)
            if not UnitHasMana(unit) then
                return {
                    value = NOT_APPLICABLE
                }
            end

            local base, casting = GetManaRegen();
            local mp5FromGear = GetMP5FromGear(unit);
            local mp5ModifierCasting = GetMP5ModifierFromTalents(unit);

            local mp5FromAuras, mp5CombatModifier = GetMP5FromAuras();
            if mp5CombatModifier > 0 then
                mp5ModifierCasting = mp5ModifierCasting + mp5CombatModifier;
            end

            -- All mana regen stats are displayed as mana/5 sec.
            local regenWhenNotCasting = (base * 5.0) + mp5FromGear + mp5FromAuras;
            casting = mp5FromGear + mp5FromAuras; -- if GetManaRegen() gets fixed ever, this should be changed

            if mp5ModifierCasting > 0 then
                casting = casting + base * mp5ModifierCasting * 5.0;
            end

            local regenWhenNotCastingText = BreakUpLargeNumbers(regenWhenNotCasting);
            local castingText = BreakUpLargeNumbers(casting);

            return {
                value = regenWhenNotCastingText,
                tooltip = HIGHLIGHT_FONT_COLOR_CODE .. MANA_REGEN .. FONT_COLOR_CODE_CLOSE,
                mp5FromGear = BreakUpLargeNumbers(mp5FromGear),
                mp5Casting = castingText,
                mp5NotCasting = regenWhenNotCastingText,
                tooltip2 = format(MANA_REGEN_TOOLTIP, base, casting),
                onEnter = CharacterManaRegenFrame_OnEnter
            }

        end,
        CritChance = function(unit)
            local MAX_SPELL_SCHOOLS = 7;
            local holySchool = 2;

            -- Start at 2 to skip physical damage
            local maxSpellCrit = GetSpellCritChance(holySchool);
            for i = holySchool, MAX_SPELL_SCHOOLS do
                local bonusCrit = GetSpellCritChance(i);
                maxSpellCrit = max(maxSpellCrit, bonusCrit);
            end

            local holyCrit = GetSpellCritChance(2);
            local fireCrit = GetSpellCritChance(3);
            local natureCrit = GetSpellCritChance(4);
            local frostCrit = GetSpellCritChance(5);
            local shadowCrit = GetSpellCritChance(6);
            local arcaneCrit = GetSpellCritChance(7);
            local lightningCrit;

            local unitClassId = select(3, UnitClass(unit));

            if (unitClassId == INDEX_CLASS_MAGE) then
                local arcaneInstabilityCrit, criticalMassCrit = GetMageCritStatsFromTalents();
                if (arcaneInstabilityCrit > 0) then
                    -- increases the crit of all spell schools
                    holyCrit = holyCrit + arcaneInstabilityCrit;
                    fireCrit = fireCrit + arcaneInstabilityCrit;
                    natureCrit = natureCrit + arcaneInstabilityCrit;
                    frostCrit = frostCrit + arcaneInstabilityCrit;
                    shadowCrit = shadowCrit + arcaneInstabilityCrit;
                    arcaneCrit = arcaneCrit + arcaneInstabilityCrit;
                    -- set the new maximum
                    maxSpellCrit = maxSpellCrit + arcaneInstabilityCrit;
                end
                if (criticalMassCrit > 0) then
                    fireCrit = fireCrit + criticalMassCrit;
                    -- set the new maximum
                    maxSpellCrit = max(maxSpellCrit, fireCrit);
                end
            elseif (unitClassId == INDEX_CLASS_PRIEST) then
                local priestHolyCrit = GetPriestCritStatsFromTalents();
                priestHolyCrit = priestHolyCrit + GetHolyCritFromBenediction(unit);

                if (priestHolyCrit > 0) then
                    holyCrit = holyCrit + priestHolyCrit;
                    -- set the new maximum
                    maxSpellCrit = max(maxSpellCrit, holyCrit);
                end
            elseif (unitClassId == INDEX_CLASS_WARLOCK) then
                local destructionCrit = GetWarlockCritStatsFromTalents();
                if (destructionCrit > 0) then
                    shadowCrit = shadowCrit + destructionCrit;
                    fireCrit = fireCrit + destructionCrit;
                    local tmpMax = max(shadowCrit, fireCrit);
                    -- set the new maximum
                    maxSpellCrit = max(maxSpellCrit, tmpMax);
                end
            elseif (unitClassId == SHAMAN_CLASS_ID) then
                lightningCrit = natureCrit;

                local callOfThunderCrit = GetShamanCallOfThunderCrit();
                if callOfThunderCrit > 0 then
                    lightningCrit = lightningCrit + callOfThunderCrit;
                end

                local tidalMastery = GetShamanTidalMasteryCrit();
                if tidalMastery > 0 then
                    lightningCrit = lightningCrit + tidalMastery;
                    natureCrit = natureCrit + tidalMastery;
                end

                local tmpMax = max(lightningCrit, natureCrit);
                -- set the new maximum
                maxSpellCrit = max(maxSpellCrit, tmpMax);
            end

            return {
                value = format("%.2F%%", maxSpellCrit),
                unitClassId = unitClassId,
                holyCrit = holyCrit,
                fireCrit = fireCrit,
                natureCrit = natureCrit,
                frostCrit = frostCrit,
                shadowCrit = shadowCrit,
                arcaneCrit = arcaneCrit,
                lightningCrit = lightningCrit,
                onEnter = CharacterSpellCritFrame_OnEnter
            }

        end,
        HitChance = function(unit)
            local hitChance = GetSpellHitModifier();

            if not hitChance then
                hitChance = 0;
            end

            if hitChance > 0 then
                hitChance = hitChance / 7;  -- dirty fix because the api is changed with the SOM update
            end

            local unitClassId = select(3, UnitClass(unit));
            if unitClassId == INDEX_CLASS_MAGE then
                local arcaneHit, frostFireHit = GetMageSpellHitFromTalents();
                statFrame.arcaneHit = arcaneHit;
                statFrame.frostHit = frostFireHit;
                statFrame.fireHit = frostFireHit;
            elseif unitClassId == INDEX_CLASS_WARLOCK then
                statFrame.afflictionHit = GetWarlockSpellHitFromTalents();
            end

            return {
                value = format("%.2F%%", hitChance),
                hitChance = hitChance,
                unitClassId = unitClassId,
                onEnter = SpellHitChanceFrame_OnEnter
            }
        end
    },

    defense = {
        Armor = function(unit)
            local base, effectiveArmor, armor, posBuff, negBuff = UnitArmor(unit);
            if (unit ~= "player") then
                --[[ In 1.12.0, UnitArmor didn't report positive / negative buffs for units that weren't the active player.
                     This hack replicates that behavior for the UI. ]]
                base = effectiveArmor;
                armor = effectiveArmor;
                posBuff = 0;
                negBuff = 0;
            end

            local playerLevel = UnitLevel(unit);
            local armorReduction = effectiveArmor / ((85 * playerLevel) + 400);
            armorReduction = 100 * (armorReduction / (armorReduction + 1));

            local valueText, tooltipText = FormatStat(ARMOR, base, posBuff, negBuff);
            local valueNum = max(0, base + posBuff + negBuff);

            return {
                value = valueNum,
                tooltip = tooltipText,
                tooltip2 = format(ARMOR_TOOLTIP, playerLevel, armorReduction);
            };
        end,
        Defense = function(unit)
            local skillRank, skillModifier, playerLevel = GetSkill(unit, DEFENSE);

            local posBuff = 0;
            local negBuff = 0;
            if (skillModifier > 0) then
                posBuff = skillModifier;
            elseif (skillModifier < 0) then
                negBuff = skillModifier;
            end
            local valueText, defenseText = FormatStat(DEFENSE_COLON, skillRank, posBuff, negBuff);
            local valueNum = max(0, skillRank + posBuff + negBuff);

            local npcWeaponskill = playerLevel * 5; -- same level as player
            local bossWeaponskill = playerLevel * 5; -- level 63

            local tooltip = "Increases chance to Dodge, Block and Parry.\nDecreases chance to be hit and critically hit."
            tooltip = tooltip .. " \n";
            tooltip = tooltip .. "Effect vs. \n";
            tooltip = tooltip .. format(SYMBOL_TAB .. "Level " .. playerLevel .. " NPC: %.2F%%", math.max(0, skillRank + skillModifier - npcWeaponskill) * 0.04) .. "\n";
            tooltip = tooltip .. format(SYMBOL_TAB .. "Level " .. (playerLevel + 3) .. " NPC/Boss: %.2F%%", math.max(0, skillRank + skillModifier - bossWeaponskill) * 0.04) .. "\n";

            return {
                value = valueNum,
                tooltip = defenseText,
                tooltip2 = tooltip
            }
        end,
        Dodge = function(unit)
            local chance = GetDodgeChance();

            return {
                value = string.format("%.2F", chance) .. "%",
                tooltip = format(PAPERDOLLFRAME_TOOLTIP_FORMAT, DODGE_CHANCE) .. " " .. string.format("%.2F", chance) .. "%"
            }
        end,
        Parry = function(unit)
            local chance = GetParryChance();

            return {
                value = string.format("%.2F", chance) .. "%",
                tooltip = format(PAPERDOLLFRAME_TOOLTIP_FORMAT, PARRY_CHANCE) .. " " .. string.format("%.2F", chance) .. "%"
            }
        end,
        Block = function(unit)
            local blockChance = GetBlockChance();
            local blockValue = GetShieldBlock();
            local tooltip = BLOCK_CHANCE .. ": " .. string.format("%.2F", blockChance) .. "%\n";
            tooltip = tooltip .. ITEM_MOD_BLOCK_VALUE_SHORT .. ": " .. blockValue

            return {
                value = string.format("%.2F", blockChance) .. "%",
                tooltip = HIGHLIGHT_FONT_COLOR_CODE .. format(PAPERDOLLFRAME_TOOLTIP_FORMAT, BLOCK_CHANCE) .. " " .. string.format("%.02f", blockChance) .. "%" .. FONT_COLOR_CODE_CLOSE,
                tooltip2 = tooltip
            }
        end
    }
}

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
        roles = { CLASS_ROLE_TANK },
    })

    Category:Add(DAMAGE, self.stats.melee.Damage)
    Category:Add(STAT_ATTACK_POWER, self.stats.melee.AttackPower)
    Category:Add(WEAPON_SPEED, self.stats.melee.AttackSpeed)
    Category:Add(STAT_CRITICAL_STRIKE, self.stats.melee.CritChance)
    Category:Add(STAT_HIT_CHANCE, self.stats.melee.HitChance)
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
    Category:Add(WEAPON_SPEED, self.stats.ranged.AttackSpeed)
    Category:Add(STAT_CRITICAL_STRIKE, self.stats.ranged.CritChance)
    Category:Add(STAT_HIT_CHANCE, self.stats.ranged.HitChance)
end

function Module:Spell()
    local Category = Stats:CreateCategory("spell", PLAYERSTAT_SPELL_COMBAT, {
        order = 3,
        classes = { INDEX_CLASS_MAGE, INDEX_CLASS_PRIEST, INDEX_CLASS_SHAMAN, INDEX_CLASS_DRUID, INDEX_CLASS_PALADIN },
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
end

function Module:OnEnable()
    Module:Attributes();
    Module:Melee();
    Module:Ranged();
    Module:Spell();
    Module:Defense();
end