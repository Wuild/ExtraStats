local Module = ExtraStats.modules:NewModule("base")
local Stats = ExtraStats:LoadModule("character.stats")

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

local function PlayerMissChances(playerHit, totalWeaponSkill)
    local hitChance = playerHit;
    local missChanceVsNPC = 5; -- Level 60 npcs with 300 def
    local missChanceVsBoss = 9;
    local missChanceVsPlayer = 5; -- Level 60 player def is 300 base

    if totalWeaponSkill then
        local bossDefense = 315; -- level 63
        local playerBossDeltaSkill = bossDefense - totalWeaponSkill;

        if (playerBossDeltaSkill > 10) then
            if (hitChance >= 1) then
                hitChance = hitChance - 1;
            end

            missChanceVsBoss = 5 + (playerBossDeltaSkill * 0.2);
        else
            missChanceVsBoss = 5 + (playerBossDeltaSkill * 0.1);
        end
    end

    local dwMissChanceVsNpc = math.max(0, (missChanceVsNPC * 0.8 + 20) - playerHit);
    local dwMissChanceVsBoss = math.max(0, (missChanceVsBoss * 0.8 + 20) - hitChance);
    local dwMissChanceVsPlayer = math.max(0, (missChanceVsPlayer * 0.8 + 20) - playerHit);

    missChanceVsNPC = math.max(0, missChanceVsNPC - playerHit);
    missChanceVsBoss = math.max(0, missChanceVsBoss - hitChance);
    missChanceVsPlayer = math.max(0, missChanceVsPlayer - playerHit);

    return missChanceVsNPC, missChanceVsBoss, missChanceVsPlayer, dwMissChanceVsNpc, dwMissChanceVsBoss, dwMissChanceVsPlayer;
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

local SYMBOL_TAB = "    ";

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

function Module:Melee()
    local Category = Stats:CreateCategory("melee", PLAYERSTAT_MELEE_COMBAT, {
        order = 20,
        roles = { CLASS_ROLE_TANK },
    })

    Category:Add(DAMAGE, self.stats.melee.Damage)
    Category:Add(STAT_ATTACK_POWER, self.stats.melee.AttackPower)
    Category:Add(WEAPON_SPEED, self.stats.melee.AttackSpeed)
    Category:Add(STAT_CRITICAL_STRIKE, self.stats.melee.CritChance)
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
    Module:Melee();
    Module:Defense();
end