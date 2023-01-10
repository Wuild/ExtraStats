local function Health()
    local health = UnitHealthMax("player");
    local healthText = BreakUpLargeNumbers(health);

    return {
        value = healthText,
        tooltip = HIGHLIGHT_FONT_COLOR_CODE .. format(PAPERDOLLFRAME_TOOLTIP_FORMAT, HEALTH) .. " " .. healthText .. FONT_COLOR_CODE_CLOSE,
        tooltip1 = STAT_HEALTH_TOOLTIP
    }

end

local function Power()
    local powerType, powerToken = UnitPowerType("player");
    local power = UnitPowerMax("player") or 0;
    local powerText = BreakUpLargeNumbers(power);

    return {
        value = powerText,
        tooltip = HIGHLIGHT_FONT_COLOR_CODE .. format(PAPERDOLLFRAME_TOOLTIP_FORMAT, ExtraStats:translate("stats." .. string.lower(powerToken))) .. " " .. powerText .. FONT_COLOR_CODE_CLOSE,
        tooltip1 = _G["STAT_" .. powerToken .. "_TOOLTIP"]
    }
end

local Module = {  }

function Module:Setup()
    local Category = ExtraStats:CreateCategory("base", ExtraStats:translate("stats.base"), {
        order = -999
    })

    Category:Add(ExtraStats:translate("stats.health"), Health)
    Category:Add(function()
        local powerType, powerToken = UnitPowerType("player");
        return ExtraStats:translate("stats." .. string.lower(powerToken))
    end, Power)
end

do
    table.insert(ExtraStats.modules, Module)
end