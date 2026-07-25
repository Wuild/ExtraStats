local Module = ExtraStats.modules:NewModule("Tbc")
local Stats = ExtraStats:LoadModule("character.stats")

SPELL_HIT_TOOLTIP_TXT = ExtraStats:translate("spell_hit.from_gear");
SPELL_HIT_TOOLTIP_2_TXT = ExtraStats:translate("spell_hit.total");
SPELL_HIT_SUBTOOLTIP_TXT = ExtraStats:translate("spell_hit.heading");
ARCANE_SPELL_HIT_TXT = ExtraStats:translate("spell_hit.arcane");
FIRE_SPELL_HIT_TXT = ExtraStats:translate("spell_hit.fire");
FROST_SPELL_HIT_TXT = ExtraStats:translate("spell_hit.frost");
NATURE_SPELL_HIT_TXT = ExtraStats:translate("spell_hit.nature");
SHADOW_SPELL_HIT_TXT = ExtraStats:translate("spell_hit.shadow");
DESTRUCTION_SPELL_HIT_TXT = ExtraStats:translate("spell_hit.destruction");
AFFLICTION_SPELL_HIT_TXT = ExtraStats:translate("spell_hit.affliction");
LIGHTNING_TXT = ExtraStats:translate("tooltip.lightning");

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

LEGENDARY_FONT_COLOR_CODE = "|cffff8000"
EPIC_FONT_COLOR_CODE = "|cffa335ee"
RARE_FONT_COLOR_CODE = "|cff0070dd"
RARE_FONT_COLOR_CODE = "|cff0070dd"
COMMON_FONT_COLOR_CODE = "|cffffffff"

local RESILIENCE_DAMAGE_REDUCTION_MULTIPLIER = RESILIENCE_CRIT_CHANCE_TO_DAMAGE_REDUCTION_MULTIPLIER or 2.2
local RESILIENCE_CONSTANT_DAMAGE_REDUCTION_MULTIPLIER = RESILIENCE_CRIT_CHANCE_TO_CONSTANT_DAMAGE_REDUCTION_MULTIPLIER or 2.0
local CR_CRIT_TAKEN_MELEE_RATING = CR_CRIT_TAKEN_MELEE or 15
local CR_CRIT_TAKEN_RANGED_RATING = CR_CRIT_TAKEN_RANGED or 16
local CR_CRIT_TAKEN_SPELL_RATING = CR_CRIT_TAKEN_SPELL or 17
local CR_HIT_MELEE_RATING = CR_HIT_MELEE or 6
local CR_HIT_RANGED_RATING = CR_HIT_RANGED or 7
local CR_HIT_SPELL_RATING = CR_HIT_SPELL or 8
local CR_CRIT_MELEE_RATING = CR_CRIT_MELEE or 9
local CR_CRIT_RANGED_RATING = CR_CRIT_RANGED or 10
local CR_CRIT_SPELL_RATING = CR_CRIT_SPELL or 11
local CR_DODGE_RATING = CR_DODGE or 3
local CR_PARRY_RATING = CR_PARRY or 4
local CR_BLOCK_RATING = CR_BLOCK or 5
local CR_EXPERTISE_RATING = CR_EXPERTISE or 24
local CR_HASTE_MELEE_RATING = CR_HASTE_MELEE or 18
local CR_HASTE_SPELL_RATING = CR_HASTE_SPELL or 20
local EXPERTISE_LABEL = STAT_EXPERTISE or _G["COMBAT_RATING_NAME" .. CR_EXPERTISE_RATING] or ExtraStats:translate("stats.expertise")
local MELEE_HASTE_LABEL = _G["COMBAT_RATING_NAME" .. CR_HASTE_MELEE_RATING] or STAT_HASTE or ExtraStats:translate("stats.haste_rating")
local SPELL_HASTE_LABEL = _G["COMBAT_RATING_NAME" .. CR_HASTE_SPELL_RATING] or STAT_HASTE or ExtraStats:translate("stats.haste_rating")
local RATING_LABEL = RATING_COLON or STAT_RATING or ExtraStats:translate("tooltip.rating")
-- TBC level 70:
-- 3.9423 expertise rating = 1 expertise point ("skill")
-- 1 expertise point = 0.25% dodge/parry reduction
local EXPERTISE_RATING_PER_POINT = 3.9423

local EnchantMp5 = {
    [2381] = 10, -- Enchant Chest - Greater Mana Restoration
    [2565] = 4, -- Enchant Bracer - Mana Regeneration
    [2624] = 4, -- Minor Mana Oil
    [2625] = 8, -- Lesser Mana Oil
    [2629] = 12, -- Brilliant Mana Oil
    [2656] = 4, -- Enchant Boots - Vitality
    [2677] = 14, -- Superior Mana Oil
    [2679] = 6, -- Enchant Bracer - Restore Mana Prime
    [2715] = 4, -- Resilience of the Scourge
    [2980] = 4, -- Greater Inscription of Faith
    [2992] = 5, -- Inscription of the Oracle
    [2993] = 6, -- Greater Inscription of the Oracle
    [3001] = 7, -- Glyph of Renewal
    [3150] = 6, -- Enchant Chest - Restore Mana Prime
    [3244] = 7, -- Enchant Boots - Greater Vitality
    [3298] = 19, -- Exceptional Mana Oil
}

local GemMp5 = {
    [23106] = 2, -- Dazzling Deep Peridot
    [23109] = 2, -- Royal Shadow Draenite
    [23121] = 3, -- Lustrous Azure Moonstone
    [24037] = 4, -- Lustrous Star of Elune
    [24057] = 2, -- Royal Nightseye
    [24065] = 2, -- Dazzling Talasite
    [28465] = 2, -- Lustrous Zircon
    [30550] = 2, -- Sundered Chrysoprase
    [30560] = 2, -- Rune Covered Chrysoprase
    [30589] = 2, -- Dazzling Chrysoprase
    [30594] = 2, -- Effulgent Chrysoprase
    [30603] = 2, -- Royal Tanzanite
    [30606] = 2, -- Lambent Chrysoprase
    [31864] = 1, -- Infused Shadow Draenite
    [31865] = 2, -- Infused Nightseye
    [32202] = 5, -- Lustrous Empyrean Sapphire
    [32214] = 3, -- Infused Shadowsong Amethyst
    [32216] = 3, -- Royal Shadowsong Amethyst
    [32225] = 3, -- Dazzling Seaspray Emerald
}

local Mp5SetItems = {
    AUGURS_REGALIA = {
        items = { [19609] = true, [19828] = true, [19829] = true, [19830] = true, [19956] = true },
        pieces = 2,
        mp5 = 4,
        classId = INDEX_CLASS_SHAMAN,
    },
    BLOODSOUL_EMBRACE = {
        items = { [19690] = true, [19691] = true, [19692] = true },
        pieces = 3,
        mp5 = 12,
    },
    FEL_IRON_CHAIN = {
        items = { [23490] = true, [23491] = true, [23493] = true, [23494] = true },
        pieces = 4,
        mp5 = 8,
    },
    FREETHINKERS_ARMOR = {
        items = { [19588] = true, [19825] = true, [19826] = true, [19827] = true, [19952] = true },
        pieces = 2,
        mp5 = 4,
        classId = INDEX_CLASS_PALADIN,
    },
    GREEN_DRAGON_MAIL_2 = {
        items = { [15045] = true, [15046] = true, [20296] = true },
        pieces = 2,
        mp5 = 3,
    },
    GREEN_DRAGON_MAIL_3 = {
        items = { [15045] = true, [15046] = true, [20296] = true },
        pieces = 3,
        mp5 = 20,
    },
    HARUSPEXS_GARB = {
        items = { [19613] = true, [19838] = true, [19839] = true, [19840] = true, [19955] = true },
        pieces = 2,
        mp5 = 4,
        classId = INDEX_CLASS_DRUID,
    },
    STORMRAGE_RAIMENT = {
        items = { [16897] = true, [16898] = true, [16899] = true, [16900] = true, [16901] = true, [16902] = true, [16903] = true, [16904] = true },
        pieces = 3,
        mp5 = 20,
        classId = INDEX_CLASS_DRUID,
    },
    VESTMENTS_OF_TRANSCENDENCE = {
        items = { [16919] = true, [16920] = true, [16921] = true, [16922] = true, [16923] = true, [16924] = true, [16925] = true, [16926] = true },
        pieces = 3,
        mp5 = 20,
        classId = INDEX_CLASS_PRIEST,
    },
    WINDHAWK_ARMOR = {
        items = { [29522] = true, [29523] = true, [29524] = true },
        pieces = 3,
        mp5 = 8,
    },
}

local Mp5CastingModifierSetItems = {
    PRIMAL_MOONCLOTH = {
        items = { [21873] = true, [21874] = true, [21875] = true },
        pieces = 3,
        modifier = 0.05,
    },
}

local function BuildHitTooltipDetails(totalHit, fromRating, fromModifier, ratingValue, fromTalents)
    return table.concat({
        format("%s %d", RATING_LABEL, ratingValue or 0),
        ExtraStats:translate("tooltip.from_rating", fromRating or 0),
        ExtraStats:translate("tooltip.other_bonuses", fromModifier or 0),
        ExtraStats:translate("tooltip.talent_bonuses", fromTalents or 0),
        ExtraStats:translate("tooltip.total_hit", totalHit or 0),
    }, "\n")
end

local function BuildCritTooltipDetails(totalCrit, ratingId)
    local ratingValue = (GetCombatRating and ratingId and GetCombatRating(ratingId)) or 0
    local fromRating = (GetCombatRatingBonus and ratingId and GetCombatRatingBonus(ratingId)) or 0
    return table.concat({
        format("%s %d", RATING_LABEL, ratingValue),
        ExtraStats:translate("tooltip.from_rating", fromRating),
        ExtraStats:translate("tooltip.total_crit", totalCrit or 0),
    }, "\n")
end

local function BuildAvoidanceTooltipDetails(label, chance, ratingId)
    local ratingValue = (GetCombatRating and ratingId and GetCombatRating(ratingId)) or 0
    local fromRating = (GetCombatRatingBonus and ratingId and GetCombatRatingBonus(ratingId)) or 0
    return table.concat({
        format("%s: %.2F%%", label or ExtraStats:translate("tooltip.chance"), chance or 0),
        format("%s %d", RATING_LABEL, ratingValue),
        ExtraStats:translate("tooltip.from_rating", fromRating),
    }, "\n")
end

local function BuildHasteTooltipDetails(hastePercent, hasteRating, kindLabel)
    local speedMultiplier = 1 + ((hastePercent or 0) / 100)
    local timeFactor = 100 / (100 + (hastePercent or 0))
    return table.concat({
        format("%s %d", RATING_LABEL, hasteRating or 0),
        ExtraStats:translate("tooltip.speed_increase", hastePercent or 0),
        ExtraStats:translate("tooltip.speed_multiplier", kindLabel or ExtraStats:translate("tooltip.cast_attack"), speedMultiplier),
        ExtraStats:translate("tooltip.time_multiplier", timeFactor),
    }, "\n")
end

local function ComputeAvoidanceTotals(unit)
    local playerLevel = UnitLevel(unit)
    local skillRank, skillModifier = UnitDefense(unit)
    local defense = max(0, skillRank + skillModifier)

    local dodge = GetDodgeChance() or 0
    local parry = GetParryChance() or 0
    local block = GetBlockChance() or 0

    local function GetMobMiss(enemyLevel)
        local enemyWeaponSkill = enemyLevel * 5
        return max(0, 5 + ((defense - enemyWeaponSkill) * 0.04))
    end

    local missVsNpc = GetMobMiss(playerLevel)
    local missVsBoss = GetMobMiss(playerLevel + 3)

    return {
        playerLevel = playerLevel,
        defense = defense,

        dodge = dodge,
        parry = parry,
        block = block,

        missVsNpc = missVsNpc,
        missVsBoss = missVsBoss,

        totalVsNpc = dodge + parry + block + missVsNpc,
        totalVsBoss = dodge + parry + block + missVsBoss,
    }
end

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

local function GetAppropriateDamage(unit, category)
    if category == PLAYERSTAT_MELEE_COMBAT then
        return UnitDamage(unit);
    elseif category == PLAYERSTAT_RANGED_COMBAT then
        local _, minDamage, maxDamage, bonusPos, bonusNeg, percent = UnitRangedDamage(unit);
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

local function GetItemLinkEnchantAndGems(itemLink)
    if not itemLink then
        return nil, nil, nil, nil
    end

    local _, enchant, gem1, gem2, gem3 = itemLink:match("item:(%d+):(%d*):(%d*):(%d*):(%d*)")

    return tonumber(enchant), tonumber(gem1), tonumber(gem2), tonumber(gem3)
end

local function IsSetBonusActive(setData, unitClassId)
    if setData.classId and setData.classId ~= unitClassId then
        return false
    end

    local equippedPieces = 0
    for slotId = 1, 17 do
        local itemId = GetInventoryItemID("player", slotId)
        if itemId and setData.items[itemId] then
            equippedPieces = equippedPieces + 1
        end
    end

    return equippedPieces >= setData.pieces
end

local function GetMP5FromSetBonuses(unit)
    local unitClassId = select(3, UnitClass(unit))
    local mp5 = 0

    for _, setData in pairs(Mp5SetItems) do
        if IsSetBonusActive(setData, unitClassId) then
            mp5 = mp5 + setData.mp5
        end
    end

    return mp5
end

local function GetMP5CastingModifierFromSetBonuses(unit)
    local unitClassId = select(3, UnitClass(unit))
    local modifier = 0

    for _, setData in pairs(Mp5CastingModifierSetItems) do
        if IsSetBonusActive(setData, unitClassId) then
            modifier = modifier + setData.modifier
        end
    end

    return modifier
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

            local enchant, gem1, gem2, gem3 = GetItemLinkEnchantAndGems(itemLink)
            mp5 = mp5 + (EnchantMp5[enchant] or 0)
            mp5 = mp5 + (GemMp5[gem1] or 0)
            mp5 = mp5 + (GemMp5[gem2] or 0)
            mp5 = mp5 + (GemMp5[gem3] or 0)
        end
    end

    local tempMHEnchantId = select(4, GetWeaponEnchantInfo());
    mp5 = mp5 + (EnchantMp5[tempMHEnchantId] or 0)
    mp5 = mp5 + GetMP5FromSetBonuses(unit)

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

local function IsKnownSpell(spellId)
    if C_SpellBook and C_SpellBook.IsSpellKnown then
        return C_SpellBook.IsSpellKnown(spellId)
    end

    if IsSpellKnown then
        return IsSpellKnown(spellId)
    end

    return false
end

local function GetActiveTalentSpell(talentSpells)
    for rank = #talentSpells, 1, -1 do
        if IsKnownSpell(talentSpells[rank]) then
            return rank
        end
    end

    return 0
end

local function GetActiveTalentRank(talentSpells, treeIndex, talentName)
    local rank = GetActiveTalentSpell(talentSpells)
    if rank > 0 then
        return rank
    end

    if GetNumTalents and GetTalentInfo and treeIndex and talentName then
        local numTalents = GetNumTalents(treeIndex) or 0
        for talentIndex = 1, numTalents do
            local name, _, _, _, talentRank = GetTalentInfo(treeIndex, talentIndex)
            if name == talentName then
                return talentRank or 0
            end
        end
    end

    return 0
end

local function GetMP5ModifierFromTalents(unit)
    local unitClassId = select(3, UnitClass(unit))
    local spellRank = 0

    if unitClassId == INDEX_CLASS_PRIEST then
        spellRank = GetActiveTalentRank({ 14521, 14776, 14777 }, 1, "Meditation")
    elseif unitClassId == INDEX_CLASS_MAGE then
        spellRank = GetActiveTalentRank({ 14521, 18463, 18464 }, 1, "Arcane Meditation")
    elseif unitClassId == INDEX_CLASS_DRUID then
        spellRank = GetActiveTalentRank({ 17106, 17107, 17108 }, 3, "Intensity")
    end

    return spellRank * 0.1
end

local function GetTbcSpellHitFromTalents(unit, apiSpellHitModifier)
    local unitClassId = select(3, UnitClass(unit))
    local apiHasGenericSpellHit = (apiSpellHitModifier or 0) > 0
    local allSpellHit = 0
    local hitBySchool = {}

    if unitClassId == INDEX_CLASS_MAGE then
        local arcaneFocus = GetActiveTalentRank({ 11222, 12839, 12840, 12841, 12842 }, 1, "Arcane Focus") * 2
        local elementalPrecision = GetActiveTalentRank({ 29438, 29439, 29440 }, 3, "Elemental Precision")

        hitBySchool.arcane = arcaneFocus
        hitBySchool.fire = elementalPrecision
        hitBySchool.frost = elementalPrecision
    elseif unitClassId == INDEX_CLASS_PRIEST then
        hitBySchool.shadow = GetActiveTalentRank({ 15260, 15327, 15328, 15329, 15330 }, 3, "Shadow Focus") * 2
    elseif unitClassId == INDEX_CLASS_SHAMAN then
        local elementalPrecision = GetActiveTalentRank({ 30672, 30673, 30674 }, 1, "Elemental Precision") * 2

        hitBySchool.fire = elementalPrecision
        hitBySchool.frost = elementalPrecision
        hitBySchool.nature = elementalPrecision

        if not apiHasGenericSpellHit then
            allSpellHit = GetActiveTalentRank({ 16180, 16196, 16198 }, 3, "Nature's Guidance")
        end
    elseif unitClassId == INDEX_CLASS_PALADIN then
        if not apiHasGenericSpellHit then
            allSpellHit = GetActiveTalentRank({ 20189, 20192, 20193 }, 2, "Precision")
        end
    elseif unitClassId == INDEX_CLASS_WARLOCK then
        hitBySchool.affliction = GetActiveTalentRank({ 18174, 18175, 18176, 18177, 18178 }, 1, "Suppression") * 2
    elseif unitClassId == INDEX_CLASS_DRUID then
        if not apiHasGenericSpellHit then
            allSpellHit = GetActiveTalentRank({ 33592, 33596 }, 1, "Balance of Power") * 2
        end
    end

    return allSpellHit, hitBySchool
end

local function CharacterManaRegenFrame_OnEnter(self)
    GameTooltip:SetOwner(self, "ANCHOR_RIGHT");
    local title = MANA_REGEN;
    if type(MANA_REGEN_TOOLTIP) == "string" then
        local ok, formatted = pcall(format, MANA_REGEN_TOOLTIP, self.mp5NotCastingValue or 0, self.mp5CastingValue or 0)
        if ok and formatted then
            title = formatted
        end
    end
    GameTooltip:SetText(title, HIGHLIGHT_FONT_COLOR.r, HIGHLIGHT_FONT_COLOR.g, HIGHLIGHT_FONT_COLOR.b);
    GameTooltip:AddDoubleLine(MANA_REGEN .. " (" .. ExtraStats:translate("tooltip.from_gear") .. "):", self.mp5FromGear);
    GameTooltip:AddDoubleLine(MANA_REGEN .. " (" .. ExtraStats:translate("tooltip.while_casting") .. "):", self.mp5Casting);
    GameTooltip:AddDoubleLine(MANA_REGEN .. " (" .. ExtraStats:translate("tooltip.while_not_casting") .. "):", self.mp5NotCasting);
    GameTooltip:Show();
end

local function SpellHitChanceFrame_OnEnter(self)
    GameTooltip:SetOwner(self, "ANCHOR_RIGHT");
    GameTooltip:SetText(format(STAT_HIT_CHANCE .. ": %.2F%%", self.hitChance), HIGHLIGHT_FONT_COLOR.r, HIGHLIGHT_FONT_COLOR.g, HIGHLIGHT_FONT_COLOR.b);
    GameTooltip:AddLine(" ");
    GameTooltip:AddDoubleLine(ExtraStats:translate("tooltip.from_rating_label"), format("%.2F%%", self.hitFromRating or 0), NORMAL_FONT_COLOR.r, NORMAL_FONT_COLOR.g, NORMAL_FONT_COLOR.b, HIGHLIGHT_FONT_COLOR.r, HIGHLIGHT_FONT_COLOR.g, HIGHLIGHT_FONT_COLOR.b);
    GameTooltip:AddDoubleLine(ExtraStats:translate("tooltip.other_bonuses_label"), format("%.2F%%", self.hitFromModifier or 0), NORMAL_FONT_COLOR.r, NORMAL_FONT_COLOR.g, NORMAL_FONT_COLOR.b, HIGHLIGHT_FONT_COLOR.r, HIGHLIGHT_FONT_COLOR.g, HIGHLIGHT_FONT_COLOR.b);
    GameTooltip:AddDoubleLine(ExtraStats:translate("tooltip.talent_bonuses_label"), format("%.2F%%", self.hitFromTalents or 0), NORMAL_FONT_COLOR.r, NORMAL_FONT_COLOR.g, NORMAL_FONT_COLOR.b, HIGHLIGHT_FONT_COLOR.r, HIGHLIGHT_FONT_COLOR.g, HIGHLIGHT_FONT_COLOR.b);
    GameTooltip:AddDoubleLine(RATING_LABEL, tostring(self.hitRating or 0), NORMAL_FONT_COLOR.r, NORMAL_FONT_COLOR.g, NORMAL_FONT_COLOR.b, HIGHLIGHT_FONT_COLOR.r, HIGHLIGHT_FONT_COLOR.g, HIGHLIGHT_FONT_COLOR.b);

    if self.spellHitSchools and #self.spellHitSchools > 0 then
        GameTooltip:AddLine(" ");
        GameTooltip:AddLine(SPELL_HIT_SUBTOOLTIP_TXT);

        for _, school in ipairs(self.spellHitSchools) do
            GameTooltip:AddDoubleLine(SYMBOL_TAB .. school.label, format("%.2F%%", school.hit), NORMAL_FONT_COLOR.r, NORMAL_FONT_COLOR.g, NORMAL_FONT_COLOR.b, HIGHLIGHT_FONT_COLOR.r, HIGHLIGHT_FONT_COLOR.g, HIGHLIGHT_FONT_COLOR.b);
        end
    end

    GameTooltip:Show();
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
    base = {
        Health = function(unit)
            local health = UnitHealthMax(unit);
            local healthText = BreakUpLargeNumbers(health);
            local currentHealth = UnitHealth(unit) or 0

            return {
                value = healthText,
                tooltip = HIGHLIGHT_FONT_COLOR_CODE .. format(PAPERDOLLFRAME_TOOLTIP_FORMAT, HEALTH) .. " " .. healthText .. FONT_COLOR_CODE_CLOSE,
                tooltip2 = format("%s\n%s", STAT_HEALTH_TOOLTIP or "", ExtraStats:translate("tooltip.current", currentHealth, health))
            }
        end,
        Power = function(unit)
            local _, powerToken = UnitPowerType(unit);
            local powerType = UnitPowerType(unit) or 0
            local power = UnitPowerMax(unit, powerType) or 0;
            local currentPower = UnitPower(unit, powerType) or 0
            local powerText = BreakUpLargeNumbers(power);

            if powerToken then
                return {
                    value = powerText,
                    tooltip = HIGHLIGHT_FONT_COLOR_CODE .. format(PAPERDOLLFRAME_TOOLTIP_FORMAT, ExtraStats:translate("stats." .. string.lower(powerToken))) .. " " .. powerText .. FONT_COLOR_CODE_CLOSE,
                    tooltip2 = format("%s\n%s", _G["STAT_" .. powerToken .. "_TOOLTIP"] or "", ExtraStats:translate("tooltip.current", currentPower, power))
                }
            else
                return {
                    value = powerText,
                    tooltip = HIGHLIGHT_FONT_COLOR_CODE .. format(PAPERDOLLFRAME_TOOLTIP_FORMAT, MANA) .. " " .. powerText .. FONT_COLOR_CODE_CLOSE,
                    tooltip2 = ExtraStats:translate("tooltip.current", currentPower, power)
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
            local apBonus = max((base + posBuff + negBuff), 0) / (ATTACK_POWER_MAGIC_NUMBER or 14)
            local apTooltip = MELEE_ATTACK_POWER_TOOLTIP or ExtraStats:translate("tooltip.melee_damage")
            return {
                value = valueText,
                tooltip = tooltipText,
                tooltip2 = format(apTooltip, apBonus)
            }

        end,
        AttackSpeed = function(unit)
            local speed, offhandSpeed = UnitAttackSpeed(unit);
            local displaySpeed = format("%.2F", speed);
            local tooltip2 = {
                ExtraStats:translate("tooltip.main_hand_speed", speed or 0),
                ExtraStats:translate("tooltip.main_hand_swings", (speed and speed > 0) and (60 / speed) or 0),
            }
            if (offhandSpeed) then
                offhandSpeed = format("%.2F", offhandSpeed);
                local offNum = tonumber(offhandSpeed) or 0
                table.insert(tooltip2, ExtraStats:translate("tooltip.off_hand_speed", offNum))
                table.insert(tooltip2, ExtraStats:translate("tooltip.off_hand_swings", (offNum > 0) and (60 / offNum) or 0))
            end
            if (offhandSpeed) then
                displaySpeed = displaySpeed .. " / " .. offhandSpeed;
            else
                displaySpeed = displaySpeed;
            end

            return {
                value = displaySpeed,
                tooltip = format(PAPERDOLLFRAME_TOOLTIP_FORMAT, ATTACK_SPEED) .. " " .. displaySpeed,
                tooltip2 = table.concat(tooltip2, "\n")
            }
        end,
        CritChance = function()
            local crit = GetCritChance() or 0
            local critChance = format("%.2f%%", crit);

            return {
                value = critChance,
                tooltip = HIGHLIGHT_FONT_COLOR_CODE .. format(PAPERDOLLFRAME_TOOLTIP_FORMAT, MELEE_CRIT_CHANCE) .. " " .. critChance .. FONT_COLOR_CODE_CLOSE,
                tooltip2 = format(CR_CRIT_MELEE_TOOLTIP or ExtraStats:translate("tooltip.crit_from_rating"), GetCombatRating(CR_CRIT_MELEE_RATING) or 0, GetCombatRatingBonus(CR_CRIT_MELEE_RATING) or 0)
                        .. "\n" .. BuildCritTooltipDetails(crit, CR_CRIT_MELEE_RATING)
            }
        end,
        HitChance = function()
            local hitFromRating = GetCombatRatingBonus(CR_HIT_MELEE_RATING) or 0
            local hitFromModifier = GetHitModifier() or 0
            local hitRating = GetCombatRating(CR_HIT_MELEE_RATING) or 0
            local hitChance = hitFromRating + hitFromModifier

            return {
                value = format("%.2F%%", hitChance),
                tooltip = STAT_HIT_CHANCE .. ": " .. format("%.2F%%", hitChance),
                tooltip2 = BuildHitTooltipDetails(hitChance, hitFromRating, hitFromModifier, hitRating)
            }
        end,
        Expertise = function()
            local expertiseRating = (GetCombatRating and GetCombatRating(CR_EXPERTISE_RATING)) or 0
            local tooltip2 = format("%s %d", RATING_LABEL, expertiseRating)
            local ratingExpertiseRaw = (expertiseRating or 0) / EXPERTISE_RATING_PER_POINT -- expertise points
            local ratingExpertise = math.floor(ratingExpertiseRaw) -- floor only, never round up
            local mhExpertiseRaw = 0
            local ohExpertiseRaw = 0

            -- Prefer percent-derived totals because some clients quantize GetExpertise() to whole points.
            if GetExpertisePercent then
                local mhPercent, ohPercent = GetExpertisePercent()
                mhExpertiseRaw = (mhPercent or 0) / 0.25
                ohExpertiseRaw = (ohPercent or mhPercent or 0) / 0.25
            elseif GetExpertise then
                local mh, oh = GetExpertise()
                mhExpertiseRaw = mh or mhExpertiseRaw
                ohExpertiseRaw = oh or mh or mhExpertiseRaw
            end

            local mhBonusExpertise = max(0, mhExpertiseRaw - ratingExpertise)
            local ohBonusExpertise = max(0, ohExpertiseRaw - ratingExpertise)
            mhExpertiseRaw = ratingExpertise + mhBonusExpertise
            ohExpertiseRaw = ratingExpertise + ohBonusExpertise

            tooltip2 = tooltip2
                    .. "\n" .. ExtraStats:translate("tooltip.expertise_from_rating", ratingExpertise)
                    .. "\n" .. ExtraStats:translate("tooltip.expertise_from_bonuses", mhBonusExpertise)

            if math.abs(ohBonusExpertise - mhBonusExpertise) > 0.005 then
                tooltip2 = tooltip2 .. "\n" .. ExtraStats:translate("tooltip.expertise_from_bonuses_oh", ohBonusExpertise)
            end

            do
                local mainhandPercent = mhExpertiseRaw * 0.25
                local offhandPercent = ohExpertiseRaw * 0.25
                if math.abs(mainhandPercent - offhandPercent) > 0.005 then
                    tooltip2 = tooltip2
                            .. "\n" .. ExtraStats:translate("tooltip.reduces_dodge_mh", mainhandPercent)
                            .. "\n" .. ExtraStats:translate("tooltip.reduces_parry_oh", offhandPercent)
                else
                    tooltip2 = tooltip2
                            .. "\n" .. ExtraStats:translate("tooltip.reduces_dodge", mainhandPercent)
                            .. "\n" .. ExtraStats:translate("tooltip.reduces_parry", mainhandPercent)
                end
            end

            local mhDisplay = mhExpertiseRaw or 0
            local ohDisplay = ohExpertiseRaw or mhDisplay

            local expertiseValue = format("%.2F", mhDisplay)
            if math.abs(ohDisplay - mhDisplay) > 0.005 then
                expertiseValue = format("%.2F / %.2F", mhDisplay, ohDisplay)
            end

            return {
                value = expertiseValue,
                tooltip = EXPERTISE_LABEL .. ": " .. expertiseValue,
                tooltip2 = tooltip2
            }
        end,
        Haste = function()
            local hastePercent = GetCombatRatingBonus(CR_HASTE_MELEE_RATING) or 0
            local hasteRating = GetCombatRating(CR_HASTE_MELEE_RATING) or 0

            return {
                value = format("%.2F%%", hastePercent),
                tooltip = MELEE_HASTE_LABEL .. ": " .. format("%.2F%%", hastePercent),
                tooltip2 = BuildHasteTooltipDetails(hastePercent, hasteRating, ExtraStats:translate("tooltip.attack"))
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
            local rangedApTooltip = RANGED_ATTACK_POWER_TOOLTIP or ExtraStats:translate("tooltip.ranged_damage")

            return {
                value = valueText,
                tooltip = tooltipText,
                tooltip2 = format(rangedApTooltip, valueNum / (ATTACK_POWER_MAGIC_NUMBER or 14))
            }
        end,
        AttackSpeed = function(unit)
            if not IsRangedWeapon() then
                return {
                    value = NOT_APPLICABLE
                }
            end

            local attackSpeed = select(1, UnitRangedDamage(unit));
            local displaySpeed = format("%.2F", attackSpeed);
            local shotsPerMinute = (attackSpeed and attackSpeed > 0) and (60 / attackSpeed) or 0

            return {
                value = displaySpeed,
                tooltip = format(PAPERDOLLFRAME_TOOLTIP_FORMAT, ATTACK_SPEED) .. " " .. displaySpeed,
                tooltip2 = ExtraStats:translate("tooltip.ranged_speed", attackSpeed or 0, shotsPerMinute)
            }
        end,
        CritChance = function()
            if not IsRangedWeapon() then
                return {
                    value = NOT_APPLICABLE
                }
            end

            local critChance = GetRangedCritChance();

            return {
                value = format("%.2F%%", critChance),
                tooltip = format(PAPERDOLLFRAME_TOOLTIP_FORMAT, STAT_CRITICAL_STRIKE) .. " " .. format("%.2F%%", critChance),
                tooltip2 = BuildCritTooltipDetails(critChance or 0, CR_CRIT_RANGED_RATING)
            }
        end,
        HitChance = function()
            if not IsRangedWeapon() then
                return {
                    value = NOT_APPLICABLE
                }
            end

            local hitFromRating = GetCombatRatingBonus(CR_HIT_RANGED_RATING) or 0
            local hitFromModifier = GetHitModifier() or 0
            local hitRating = GetCombatRating(CR_HIT_RANGED_RATING) or 0
            local hitChance = hitFromRating + hitFromModifier

            return {
                value = format("%.2F%%", hitChance),
                tooltip = format(PAPERDOLLFRAME_TOOLTIP_FORMAT, STAT_HIT_CHANCE) .. " " .. format("%.2F%%", hitChance),
                tooltip2 = BuildHitTooltipDetails(hitChance, hitFromRating, hitFromModifier, hitRating),
            }
        end
    },

    spell = {
        Damage = function()
            local MAX_SPELL_SCHOOLS = 7;
            local holySchool = 2;

            local maxSpellDmg = GetSpellBonusDamage(holySchool);
            for i = holySchool, MAX_SPELL_SCHOOLS do
                local bonusDamage = GetSpellBonusDamage(i);
                maxSpellDmg = max(maxSpellDmg, bonusDamage);
            end

            return {
                value = BreakUpLargeNumbers(maxSpellDmg),
                tooltip = STAT_SPELLPOWER .. ": " .. BreakUpLargeNumbers(maxSpellDmg),
                tooltip2 = ExtraStats:translate("tooltip.highest_damage_school"),
                onEnter = SpellDamageFrame_OnEnter
            }

        end,
        Healing = function()
            local healing = GetSpellBonusHealing();

            return {
                value = BreakUpLargeNumbers(healing),
                tooltip = STAT_SPELLHEALING .. " " .. healing,
                tooltip2 = STAT_SPELLHEALING_TOOLTIP .. "\n" .. ExtraStats:translate("tooltip.bonus_healing", healing or 0)
            }

        end,
        Regen = function(unit)
            if not UnitHasMana(unit) then
                return {
                    value = NOT_APPLICABLE
                }
            end

            local base, casting = GetManaRegen();
            base = base or 0;
            casting = casting or 0;
            local mp5FromGear = GetMP5FromGear(unit);
            local mp5ModifierCasting = GetMP5ModifierFromTalents(unit);
            mp5ModifierCasting = mp5ModifierCasting + GetMP5CastingModifierFromSetBonuses(unit)

            local mp5FromAuras, mp5CombatModifier = GetMP5FromAuras();
            if mp5CombatModifier > 0 then
                mp5ModifierCasting = mp5ModifierCasting + mp5CombatModifier;
            end

            -- All mana regen stats are displayed as mana/5 sec.
            local regenWhenNotCasting = (base * 5.0) + mp5FromGear + mp5FromAuras;
            local castingFromSpirit = casting * 5.0;
            local castingFromKnownModifiers = 0;

            if mp5ModifierCasting > 0 then
                castingFromKnownModifiers = base * mp5ModifierCasting * 5.0;
            end

            casting = mp5FromGear + mp5FromAuras + max(castingFromSpirit, castingFromKnownModifiers);

            local regenWhenNotCastingText = BreakUpLargeNumbers(regenWhenNotCasting);
            local castingText = BreakUpLargeNumbers(casting);

            return {
                value = regenWhenNotCastingText,
                tooltip = HIGHLIGHT_FONT_COLOR_CODE .. MANA_REGEN .. FONT_COLOR_CODE_CLOSE,
                mp5FromGear = BreakUpLargeNumbers(mp5FromGear),
                mp5Casting = castingText,
                mp5NotCasting = regenWhenNotCastingText,
                mp5CastingValue = floor(casting),
                mp5NotCastingValue = floor(regenWhenNotCasting),
                tooltip2 = format(MANA_REGEN_TOOLTIP or ExtraStats:translate("stats.regen"), floor(regenWhenNotCasting), floor(casting)),
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
            local unitClassId = select(3, UnitClass(unit));
            local lightningCrit = unitClassId == SHAMAN_CLASS_ID and natureCrit or nil;

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
                tooltip = STAT_CRITICAL_STRIKE .. ": " .. format("%.2F%%", maxSpellCrit),
                tooltip2 = BuildCritTooltipDetails(maxSpellCrit, CR_CRIT_SPELL_RATING),
                onEnter = CharacterSpellCritFrame_OnEnter
            }

        end,
        HitChance = function(unit)
            local hitFromRating = GetCombatRatingBonus(CR_HIT_SPELL_RATING) or 0
            local hitFromModifier = GetSpellHitModifier() or 0
            local hitRating = GetCombatRating(CR_HIT_SPELL_RATING) or 0
            local unitClassId = select(3, UnitClass(unit));
            local allTalentHit, hitBySchool = GetTbcSpellHitFromTalents(unit, hitFromModifier)
            local hitChance = hitFromRating + hitFromModifier + allTalentHit
            local highestHitChance = hitChance
            local spellHitSchools = {}

            if unitClassId == INDEX_CLASS_MAGE then
                table.insert(spellHitSchools, { label = ARCANE_SPELL_HIT_TXT, hit = hitChance + (hitBySchool.arcane or 0) })
                table.insert(spellHitSchools, { label = FIRE_SPELL_HIT_TXT, hit = hitChance + (hitBySchool.fire or 0) })
                table.insert(spellHitSchools, { label = FROST_SPELL_HIT_TXT, hit = hitChance + (hitBySchool.frost or 0) })
            elseif unitClassId == INDEX_CLASS_PRIEST then
                table.insert(spellHitSchools, { label = SHADOW_SPELL_HIT_TXT, hit = hitChance + (hitBySchool.shadow or 0) })
            elseif unitClassId == INDEX_CLASS_SHAMAN then
                table.insert(spellHitSchools, { label = FIRE_SPELL_HIT_TXT, hit = hitChance + (hitBySchool.fire or 0) })
                table.insert(spellHitSchools, { label = FROST_SPELL_HIT_TXT, hit = hitChance + (hitBySchool.frost or 0) })
                table.insert(spellHitSchools, { label = NATURE_SPELL_HIT_TXT, hit = hitChance + (hitBySchool.nature or 0) })
            elseif unitClassId == INDEX_CLASS_WARLOCK then
                table.insert(spellHitSchools, { label = AFFLICTION_SPELL_HIT_TXT, hit = hitChance + (hitBySchool.affliction or 0) })
                table.insert(spellHitSchools, { label = DESTRUCTION_SPELL_HIT_TXT, hit = hitChance })
            end

            for _, school in ipairs(spellHitSchools) do
                highestHitChance = max(highestHitChance, school.hit)
            end
            local highestTalentHit = highestHitChance - hitFromRating - hitFromModifier

            return {
                value = format("%.2F%%", highestHitChance),
                hitChance = highestHitChance,
                hitFromRating = hitFromRating,
                hitFromModifier = hitFromModifier,
                hitFromTalents = highestTalentHit,
                hitRating = hitRating,
                unitClassId = unitClassId,
                spellHitSchools = spellHitSchools,
                tooltip = STAT_HIT_CHANCE .. ": " .. format("%.2F%%", highestHitChance),
                tooltip2 = BuildHitTooltipDetails(highestHitChance, hitFromRating, hitFromModifier, hitRating, highestTalentHit),
                onEnter = SpellHitChanceFrame_OnEnter
            }
        end,
        Haste = function()
            local hastePercent = (GetHaste and GetHaste()) or GetCombatRatingBonus(CR_HASTE_SPELL_RATING) or 0
            local hasteRating = GetCombatRating(CR_HASTE_SPELL_RATING) or 0

            return {
                value = format("%.2F%%", hastePercent),
                tooltip = SPELL_HASTE_LABEL .. ": " .. format("%.2F%%", hastePercent),
                tooltip2 = BuildHasteTooltipDetails(hastePercent, hasteRating, ExtraStats:translate("tooltip.cast"))
            }
        end
    },

    defense = {
        Armor = function(unit)
            local base, effectiveArmor, armor, posBuff, negBuff = UnitArmor(unit);

            if (unit ~= "player") then
                -- Replicate old UI behavior
                base = effectiveArmor;
                armor = effectiveArmor;
                posBuff = 0;
                negBuff = 0;
            end

            local level = UnitLevel(unit);
            local valueNum = max(0, base + posBuff + negBuff);

            local armorReduction = 0;

            if level and level > 0 then
                local denominator;

                if level < 60 then
                    denominator = (85 * level) + effectiveArmor + 400;
                else
                    denominator = (467.5 * level) + effectiveArmor - 22167.5;
                end

                if denominator > 0 then
                    armorReduction = (effectiveArmor / denominator) * 100;
                end
                armorReduction = min(75, max(0, armorReduction));
            end

            local _, tooltipText = FormatStat(ARMOR, base, posBuff, negBuff);

            return {
                value = valueNum,
                tooltip = tooltipText,
                tooltip2 = format(ARMOR_TOOLTIP, level, armorReduction);
            };
        end,
        Defense = function(unit)
            local skillRank, skillModifier = UnitDefense(unit)
            local playerLevel = UnitLevel(unit)

            local posBuff = 0
            local negBuff = 0

            if skillModifier > 0 then
                posBuff = skillModifier
            elseif skillModifier < 0 then
                negBuff = skillModifier
            end

            local valueNum = max(0, skillRank + posBuff + negBuff)
            local _, defenseText = FormatStat(DEFENSE_COLON, skillRank, posBuff, negBuff)

            local npcLevel = playerLevel
            local bossLevel = playerLevel + 3

            local baseDefense = playerLevel * 5
            local npcWeaponskill = npcLevel * 5
            local bossWeaponskill = bossLevel * 5

            local dodgeChance = GetDodgeChance() or 0
            local parryChance = GetParryChance() or 0
            local blockChance = GetBlockChance() or 0

            local resilienceCritReduction = GetCombatRatingBonus(CR_CRIT_TAKEN_MELEE_RATING) or 0

            if resilienceCritReduction <= 0 then
                resilienceCritReduction = GetCombatRatingBonus(CR_CRIT_TAKEN_RANGED_RATING) or 0
            end

            if resilienceCritReduction <= 0 then
                resilienceCritReduction = GetCombatRatingBonus(CR_CRIT_TAKEN_SPELL_RATING) or 0
            end

            local defenseEffectVsNpc = math.max(0, valueNum - npcWeaponskill) * 0.04
            local defenseEffectVsBoss = math.max(0, valueNum - bossWeaponskill) * 0.04
            local totalDefenseVsNpc = defenseEffectVsNpc + resilienceCritReduction
            local totalDefenseVsBoss = defenseEffectVsBoss + resilienceCritReduction

            local missChanceVsNpc =
            5 + (math.max(0, valueNum - npcWeaponskill) * 0.04)

            local missChanceVsBoss =
            5 + (math.max(0, valueNum - bossWeaponskill) * 0.04)

            -- Total avoidance
            local totalAvoidanceVsNpc =
            dodgeChance +
                    parryChance +
                    blockChance +
                    missChanceVsNpc

            local totalAvoidanceVsBoss =
            dodgeChance +
                    parryChance +
                    blockChance +
                    missChanceVsBoss

            local tooltip = ExtraStats:translate("tooltip.defense_desc")
            tooltip = tooltip .. " \n";
            tooltip = tooltip .. ExtraStats:translate("tooltip.effect_vs") .. " \n";

            tooltip = tooltip ..
                    format(
                            SYMBOL_TAB .. "%s",
                            ExtraStats:translate("tooltip.level_npc", playerLevel, defenseEffectVsNpc)
                    ) .. "\n";

            tooltip = tooltip ..
                    format(
                            SYMBOL_TAB .. "%s",
                            ExtraStats:translate("tooltip.level_npc_boss", playerLevel + 3, defenseEffectVsBoss)
                    ) .. "\n";

            tooltip = tooltip .. " \n";
            tooltip = tooltip .. ExtraStats:translate("tooltip.total_defense") .. " \n";

            tooltip = tooltip ..
                    format(
                            SYMBOL_TAB .. "%s",
                            ExtraStats:translate("tooltip.level_npc", playerLevel, totalDefenseVsNpc)
                    ) .. "\n";

            tooltip = tooltip ..
                    format(
                            SYMBOL_TAB .. "%s",
                            ExtraStats:translate("tooltip.level_npc_boss", playerLevel + 3, totalDefenseVsBoss)
                    ) .. "\n";

            tooltip = tooltip .. " \n";
            tooltip = tooltip .. ExtraStats:translate("tooltip.total_avoidance") .. " \n";

            tooltip = tooltip ..
                    format(
                            SYMBOL_TAB .. "%s",
                            ExtraStats:translate("tooltip.level_npc", playerLevel, totalAvoidanceVsNpc)
                    ) .. "\n";

            tooltip = tooltip ..
                    format(
                            SYMBOL_TAB .. "%s",
                            ExtraStats:translate("tooltip.level_npc_boss", playerLevel + 3, totalAvoidanceVsBoss)
                    ) .. "\n";

            return {
                value = valueNum,
                tooltip = defenseText,
                tooltip2 = tooltip
            }
        end,
        Avoidance = function(unit)
            local data = ComputeAvoidanceTotals(unit)
            local level = data.playerLevel or UnitLevel(unit)
            local tooltip = table.concat({
                ExtraStats:translate("tooltip.avoidance_vs_level", level, data.totalVsNpc),
                ExtraStats:translate("tooltip.avoidance_vs_level", level + 3, data.totalVsBoss),
                " ",
                ExtraStats:translate("tooltip.dodge", data.dodge),
                ExtraStats:translate("tooltip.parry", data.parry),
                ExtraStats:translate("tooltip.block", data.block),
                ExtraStats:translate("tooltip.mob_miss", level, data.missVsNpc),
                ExtraStats:translate("tooltip.mob_miss", level + 3, data.missVsBoss),
            }, "\n")

            return {
                value = format("%.2F%%", data.totalVsBoss),
                tooltip = format(PAPERDOLLFRAME_TOOLTIP_FORMAT, ExtraStats:translate("stats.avoidance")) .. " " .. format("%.2F%%", data.totalVsBoss),
                tooltip2 = tooltip
            }
        end,
        Dodge = function()
            local chance = GetDodgeChance();

            return {
                value = string.format("%.2F", chance) .. "%",
                tooltip = format(PAPERDOLLFRAME_TOOLTIP_FORMAT, DODGE_CHANCE) .. " " .. string.format("%.2F", chance) .. "%",
                tooltip2 = BuildAvoidanceTooltipDetails(DODGE_CHANCE, chance, CR_DODGE_RATING)
            }
        end,
        Parry = function()
            local chance = GetParryChance();

            return {
                value = string.format("%.2F", chance) .. "%",
                tooltip = format(PAPERDOLLFRAME_TOOLTIP_FORMAT, PARRY_CHANCE) .. " " .. string.format("%.2F", chance) .. "%",
                tooltip2 = BuildAvoidanceTooltipDetails(PARRY_CHANCE, chance, CR_PARRY_RATING)
            }
        end,
        Block = function()
            local blockChance = GetBlockChance();
            local blockValue = GetShieldBlock();
            local tooltip = BLOCK_CHANCE .. ": " .. string.format("%.2F", blockChance) .. "%\n";
            tooltip = tooltip .. ITEM_MOD_BLOCK_VALUE_SHORT .. ": " .. blockValue
            tooltip = tooltip
                    .. "\n" .. format("%s %d", RATING_LABEL, (GetCombatRating and GetCombatRating(CR_BLOCK_RATING)) or 0)
                    .. "\n" .. ExtraStats:translate("tooltip.from_rating", (GetCombatRatingBonus and GetCombatRatingBonus(CR_BLOCK_RATING)) or 0)

            return {
                value = string.format("%.2F", blockChance) .. "%",
                tooltip = HIGHLIGHT_FONT_COLOR_CODE .. format(PAPERDOLLFRAME_TOOLTIP_FORMAT, BLOCK_CHANCE) .. " " .. string.format("%.02f", blockChance) .. "%" .. FONT_COLOR_CODE_CLOSE,
                tooltip2 = tooltip
            }
        end,
        Resilience = function()
            local melee = GetCombatRating(CR_CRIT_TAKEN_MELEE_RATING);
            local ranged = GetCombatRating(CR_CRIT_TAKEN_RANGED_RATING);
            local spell = GetCombatRating(CR_CRIT_TAKEN_SPELL_RATING);

            -- TBC resilience is effectively one stat; some clients/APIs may return 0 for ranged/spell buckets.
            -- Prefer melee bucket as authoritative, then fall back to any non-zero bucket.
            local resilienceRating = melee;
            local ratingIndex = CR_CRIT_TAKEN_MELEE_RATING;
            if resilienceRating <= 0 and ranged > 0 then
                resilienceRating = ranged;
                ratingIndex = CR_CRIT_TAKEN_RANGED_RATING;
            end
            if resilienceRating <= 0 and spell > 0 then
                resilienceRating = spell;
                ratingIndex = CR_CRIT_TAKEN_SPELL_RATING;
            end

            local resilienceBonus = GetCombatRatingBonus(ratingIndex);
            local maxRatingBonus = GetMaxCombatRatingBonus and GetMaxCombatRatingBonus(ratingIndex) or (resilienceBonus * RESILIENCE_DAMAGE_REDUCTION_MULTIPLIER);

            return {
                value = resilienceRating,
                tooltip = HIGHLIGHT_FONT_COLOR_CODE .. format(PAPERDOLLFRAME_TOOLTIP_FORMAT, STAT_RESILIENCE) .. " " .. resilienceRating .. FONT_COLOR_CODE_CLOSE,
                tooltip2 = format(RESILIENCE_TOOLTIP or ExtraStats:translate("tooltip.resilience"), resilienceBonus or 0, min((resilienceBonus or 0) * RESILIENCE_DAMAGE_REDUCTION_MULTIPLIER, maxRatingBonus or 0), (resilienceBonus or 0) * RESILIENCE_CONSTANT_DAMAGE_REDUCTION_MULTIPLIER)
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
        local _, powerToken = UnitPowerType("player");
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
            local _, classFileName = UnitClass(unit);
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
    Category:Add(MELEE_ATTACK_POWER, self.stats.melee.AttackPower)
    Category:Add(WEAPON_SPEED, self.stats.melee.AttackSpeed)
    Category:Add(STAT_CRITICAL_STRIKE, self.stats.melee.CritChance)
    Category:Add(STAT_HIT_CHANCE, self.stats.melee.HitChance)
    Category:Add(MELEE_HASTE_LABEL, self.stats.melee.Haste)
    Category:Add(EXPERTISE_LABEL, self.stats.melee.Expertise)
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
    Category:Add(RANGED_ATTACK_POWER, self.stats.ranged.AttackPower)
    Category:Add(WEAPON_SPEED, self.stats.ranged.AttackSpeed)
    Category:Add(STAT_CRITICAL_STRIKE, self.stats.ranged.CritChance)
    Category:Add(STAT_HIT_CHANCE, self.stats.ranged.HitChance)
end

function Module:Spell()
    local Category = Stats:CreateCategory("spell", PLAYERSTAT_SPELL_COMBAT, {
        order = 3,
        classes = { INDEX_CLASS_MAGE, INDEX_CLASS_PRIEST, INDEX_CLASS_SHAMAN, INDEX_CLASS_DRUID, INDEX_CLASS_PALADIN, INDEX_CLASS_WARLOCK },
    })

    Category:Add(STAT_SPELLPOWER, self.stats.spell.Damage)
    Category:Add(STAT_SPELLHEALING, self.stats.spell.Healing)
    Category:Add(MANA_REGEN, self.stats.spell.Regen)
    Category:Add(STAT_CRITICAL_STRIKE, self.stats.spell.CritChance)
    Category:Add(STAT_HIT_CHANCE, self.stats.spell.HitChance)
    Category:Add(SPELL_HASTE_LABEL, self.stats.spell.Haste)
end

function Module:Defense()
    local Category = Stats:CreateCategory("defenses", PLAYERSTAT_DEFENSES, {
        order = 20,
        roles = { CLASS_ROLE_TANK },
    })
    Category:Add(STAT_ARMOR, self.stats.defense.Armor)
    Category:Add(DEFENSE, self.stats.defense.Defense)
    Category:Add("Avoidance", self.stats.defense.Avoidance)
    Category:Add(STAT_DODGE, self.stats.defense.Dodge)
    Category:Add(STAT_PARRY, self.stats.defense.Parry)
    Category:Add(STAT_BLOCK, self.stats.defense.Block)
    Category:Add(STAT_RESILIENCE, self.stats.defense.Resilience)
end

function Module:OnEnable()
    Module:Base();
    Module:Attributes();
    Module:Melee();
    Module:Ranged();
    Module:Spell();
    Module:Defense();
end
