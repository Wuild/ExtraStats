local Plugin = {  }

table.insert(ExtraStats.plugins, Plugin)

function Plugin:Setup()
    if not TacoTip then
        return
    end

    local MyGearScore, MyAverageScore, r, g, b = 0, 0, 0, 0, 0
    MyGearScore, MyAverageScore = TT_GS:GetScore("player")
    r, g, b = TT_GS:GetQuality(MyGearScore)

    local Base = ExtraStats:GetCategory("base")
    Base:Add("GearScore", function()
        return {
            value = MyGearScore,
        }
    end, {
        show = function()
            return MyGearScore > 0
        end,
        onUpdate = function(self)
            if not self.lastUpdate or self.lastUpdate < GetTime() - 0.2 then
                self.lastUpdate = GetTime();
                self.Value:SetTextColor(r, g, b)
            end
        end
    })

    Base:Add("iLvl", function()
        return {
            value = MyAverageScore
        }
    end, {
        show = function()
            return MyAverageScore > 0
        end,
        onUpdate = function(self)
            if not self.lastUpdate or self.lastUpdate < GetTime() - 0.2 then
                self.lastUpdate = GetTime();
                self.Value:SetTextColor(r, g, b)
            end
        end
    })

end