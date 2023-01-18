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

LEGENDARY_FONT_COLOR_CODE = "|cffff8000"
EPIC_FONT_COLOR_CODE = "|cffa335ee"
RARE_FONT_COLOR_CODE = "|cff0070dd"
RARE_FONT_COLOR_CODE = "|cff0070dd"
COMMON_FONT_COLOR_CODE = "|cffffffff"

local function MoveSpeed()
    local _, runSpeed, flightSpeed, swimSpeed = GetUnitSpeed("player")
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

local Module = {  }

function Module:Setup()
    local stats = ExtraStats:LoadModule("character.stats")

    local Category = stats:CreateCategory("base", ExtraStats:translate("stats.base"), {
        order = -999
    })

    Category:Add(ExtraStats:translate("stats.health"), Health)
    Category:Add(function()
        local powerType, powerToken = UnitPowerType("player");
        return ExtraStats:translate("stats." .. string.lower(powerToken))
    end, Power)
    Category:Add(ExtraStats:translate("stats.movespeed"), MoveSpeed, {
        onUpdate = function(self)
            if not self.lastUpdate or self.lastUpdate < GetTime() - 0.2 then
                self.lastUpdate = GetTime();
                self.Value:SetText(MoveSpeed().value)
            end
        end
    })
end

do
    table.insert(ExtraStats.modules, Module)
end