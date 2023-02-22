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

local Module = ExtraStats.modules:NewModule("enhancements")

function Module:OnEnable()
    local stats = ExtraStats:LoadModule("character.stats")

    local Category = stats:CreateCategory("enhancements", ExtraStats:translate("stats.enhancements"), {
        order = 999,
    })

    Category:Add(ExtraStats:translate("stats.resilience"), Resilience)
end

do
    table.insert(ExtraStats.modules, Module)
end