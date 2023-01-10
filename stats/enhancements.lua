local function Resilience()
    local resilienceRating = BreakUpLargeNumbers(GetCombatRating(COMBAT_RATING_RESILIENCE_PLAYER_DAMAGE_TAKEN));
    local ratingBonus = GetCombatRatingBonus(COMBAT_RATING_RESILIENCE_PLAYER_DAMAGE_TAKEN);
    local damageReduction = ratingBonus + GetCombatRatingBonus(COMBAT_RATING_RESILIENCE_PLAYER_DAMAGE_TAKEN);

    return {
        value = resilienceRating,
        tooltip = HIGHLIGHT_FONT_COLOR_CODE .. format(PAPERDOLLFRAME_TOOLTIP_FORMAT, STAT_RESILIENCE) .. " " .. damageReduction .. FONT_COLOR_CODE_CLOSE,
        tooltip2 = format(RESILIENCE_TOOLTIP, ratingBonus, damageReduction, damageReduction)
    }
end

local function Expertise()
    local expertise, offhandExpertise = GetExpertise();
    local speed, offhandSpeed = UnitAttackSpeed("player");
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

local Module = {  }

function Module:Setup()
    local Category = ExtraStats:CreateCategory("enhancements", ExtraStats:translate("stats.enhancements"), {
        order = 999,
    })

    Category:Add(ExtraStats:translate("stats.resiliance"), Resilience)
    Category:Add(ExtraStats:translate("stats.expertise"), Expertise)
end

do
    table.insert(ExtraStats.modules, Module)
end