ExtraStats.stats.spell = {}

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

local function SpellBonusDamage()
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
end

local function SpellBonusHealing()
    local bonusHealing = GetSpellBonusHealing();
    return {
        value = bonusHealing,
        tooltip = HIGHLIGHT_FONT_COLOR_CODE .. BONUS_HEALING .. FONT_COLOR_CODE_CLOSE,
        tooltip2 = format(BONUS_HEALING_TOOLTIP, bonusHealing)
    }
end

local function SpellCritChance()
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
end

local function SpellPenetration()
    return {
        value = GetSpellPenetration(),
        tooltip = HIGHLIGHT_FONT_COLOR_CODE .. format(PAPERDOLLFRAME_TOOLTIP_FORMAT, SPELL_PENETRATION) .. FONT_COLOR_CODE_CLOSE,
        tooltip2 = SPELL_PENETRATION_TOOLTIP
    }
end

local function SpellHaste()
    return {
        value = format("%.2f%%", GetCombatRatingBonus(CR_HASTE_SPELL)),
        tooltip = HIGHLIGHT_FONT_COLOR_CODE .. SPELL_HASTE .. FONT_COLOR_CODE_CLOSE,
        tooltip2 = format(SPELL_HASTE_TOOLTIP, GetCombatRatingBonus(CR_HASTE_SPELL))
    }
end

local function ManaRegen()
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

local function HitChance()
    local ratingIndex = CR_HIT_SPELL;
    local statName = _G["COMBAT_RATING_NAME" .. ratingIndex];
    local rating = GetCombatRating(ratingIndex);
    local ratingBonus = GetCombatRatingBonus(ratingIndex);

    local hitChance = format("%.2f%%", ExtraStats:GetHitRatingBonus())

    return {
        value = hitChance,
        tooltip = HIGHLIGHT_FONT_COLOR_CODE .. format(PAPERDOLLFRAME_TOOLTIP_FORMAT, statName) .. " " .. rating .. FONT_COLOR_CODE_CLOSE,
        tooltip2 = format(CR_HIT_RANGED_TOOLTIP, UnitLevel("player"), ratingBonus, GetCombatRating(CR_ARMOR_PENETRATION), GetArmorPenetration())
    }
end

local Module = {  }

function Module:Setup()
    local Category = ExtraStats:CreateCategory("spell", ExtraStats:translate("stats.spell"), {
        order = 3,
        classes = { INDEX_CLASS_MAGE, INDEX_CLASS_PRIEST, INDEX_CLASS_SHAMAN, INDEX_CLASS_DRUID, INDEX_CLASS_PALADIN },
        roles = { CLASS_ROLE_DAMAGER, CLASS_ROLE_HEALER },
    })

    Category:Add(ExtraStats:translate("stats.bonus_damage"), SpellBonusDamage)
    Category:Add(ExtraStats:translate("stats.bonus_healing"), SpellBonusHealing)
    Category:Add(ExtraStats:translate("stats.hit_chance"), HitChance)
    Category:Add(ExtraStats:translate("stats.crit_chance"), SpellCritChance)
    Category:Add(ExtraStats:translate("stats.penetration"), SpellPenetration)
    Category:Add(ExtraStats:translate("stats.haste_rating"), SpellHaste)
    Category:Add(ExtraStats:translate("stats.regen"), ManaRegen)
end

do
    table.insert(ExtraStats.modules, Module)
end