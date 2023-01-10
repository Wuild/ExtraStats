local Plugin = {  }

table.insert(ExtraStats.plugins, Plugin)

local function GetRGBAAsBytes(r, g, b, a)
    return Round(r * 255), Round(g * 255), Round(b * 255), Round((a or 1) * 255);
end

function Plugin:Setup()
    if not TacoTip then
        return
    end

    local Base = ExtraStats:GetCategory("base")
    Base:Add("GearScore", function()
        local MyGearScore, MyAverageScore, r, g, b = 0, 0, 0, 0, 0
        MyGearScore, MyAverageScore = TT_GS:GetScore("player")
        r, g, b = TT_GS:GetQuality(MyGearScore)
        return {
            value = "|c" .. string.format("ff%.2x%.2x%.2x", GetRGBAAsBytes(r, g, b, 1)) .. MyGearScore .. FONT_COLOR_CODE_CLOSE,
        }
    end, {
        show = function()
            local MyGearScore, MyAverageScore = TT_GS:GetScore("player")
            return MyGearScore > 0
        end
    })

    Base:Add("iLvl", function()
        local MyGearScore, MyAverageScore, r, g, b = 0, 0, 0, 0, 0
        MyGearScore, MyAverageScore = TT_GS:GetScore("player")
        r, g, b = TT_GS:GetQuality(MyGearScore)
        return {
            value = "|c" .. string.format("ff%.2x%.2x%.2x", GetRGBAAsBytes(r, g, b, 1)) .. MyAverageScore .. FONT_COLOR_CODE_CLOSE,
        }
    end, {
        show = function()
            local MyGearScore, MyAverageScore = TT_GS:GetScore("player")
            return MyAverageScore > 0
        end
    })

end