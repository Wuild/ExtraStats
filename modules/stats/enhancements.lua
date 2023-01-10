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

local Module = {  }

function Module:Setup()
    local Category = ExtraStats:CreateCategory("enhancements", ExtraStats:translate("stats.enhancements"), {
        order = 999,
    })

    Category:Add(ExtraStats:translate("stats.resiliance"), Resilience)

end

do
    table.insert(ExtraStats.modules, Module)
end