local name, stats = ...;

local Semver = LibStub("Semver");

local L = LibStub("AceLocale-3.0"):GetLocale("ExtraStats", true)

local events = {};

function ExtraStats:print(...)
    print(ExtraStats:Colorize("<" .. name .. ">", "cyan"), ...)
end

function ExtraStats:debug(...)
    if (ExtraStats.db.global.debug.enabled) then
        print(ExtraStats:Colorize("<" .. stats.name .. " - " .. (stats.debug[stats.DEBUG_DEFAULT]) .. ">", "blue"), ...)
    end
end

function ExtraStats:Colorize(str, color)
    local c = '';
    if color == 'red' then
        c = '|cffff0000';
    elseif color == 'gray' then
        c = '|cFFCFCFCF';
    elseif color == 'purple' then
        c = '|cFFB900FF';
    elseif color == 'blue' then
        c = '|cB900FFFF';
    elseif color == 'yellow' then
        c = '|cFFFFB900';
    elseif color == 'green' then
        c = "|cFF00FF00";
    elseif color == 'white' then
        c = "|cffffffff"
    elseif color == 'cyan' then
        c = "|cff00FFFF"
    end
    return c .. str .. "|r"
end

function ExtraStats:On(event, callback)
    if not events[event] then
        events[event] = {}
    end

    events[event][ExtraStats:tablelength(events[event]) + 1] = callback;
end

function ExtraStats:Trigger(event, ...)
    if events[event] then
        for key = 1, ExtraStats:tablelength(events[event]) do
            events[event][key](...);
        end
    end
end

function ExtraStats:tablelength(T)
    local count = 0
    if T then
        for _ in pairs(T) do
            count = count + 1
        end
    end
    return count
end

function ExtraStats:GetCurrentClass()
    local localizedClass, englishClass, classIndex = UnitClass("Player");
    return classIndex
end

function ExtraStats:translate(key, ...)
    local arg = { ... };

    if L[key] == nil then
        return key
    end

    for i, v in ipairs(arg) do
        arg[i] = tostring(v);
    end
    return string.format(L[key], unpack(arg))
end

function ExtraStats:FormatStat(name, base, posBuff, negBuff)
    local value;
    local effective = max(0, base + posBuff + negBuff);
    local text = HIGHLIGHT_FONT_COLOR_CODE .. format(PAPERDOLLFRAME_TOOLTIP_FORMAT, name) .. " " .. effective;
    if ((posBuff == 0) and (negBuff == 0)) then
        text = text .. FONT_COLOR_CODE_CLOSE;
        value = effective;
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
            value = RED_FONT_COLOR_CODE .. effective .. FONT_COLOR_CODE_CLOSE;
        else
            value = GREEN_FONT_COLOR_CODE .. effective .. FONT_COLOR_CODE_CLOSE;
        end
    end

    return value, text;
end

function ExtraStats:SetLabelAndText(statFrame, label, text)

    local name = label;

    if type(label) == "function" then
        name = label()
    end

    statFrame.Label:SetText(format(STAT_FORMAT, name));
    statFrame.Value:SetText(text);
end

local updateTimer

function ExtraStats:UpdateStatsDelayed()
    ExtraStats:CancelTimer(updateTimer)
    updateTimer = ExtraStats:ScheduleTimer("UpdateStats", 0.5)
end

function ExtraStats:UpdateStats()
    ExtraStats:Trigger("character.stats")
end

function ExtraStats:GetHitRatingBonus()
    local hitModifier = GetHitModifier();

    local hit = 0
    local hitRating = 0
    local debuffs = {
        ["Faerie Fire"] = true,
        ["Misery"] = true,
    }

    for debuff in pairs(debuffs) do
        if AuraUtil.FindAuraByName(debuff, "target", "HARMFUL") then
            hit = 3
            break --Stop after 1 they dont stack
        end
    end

    --hit = (GetCombatRatingBonus(CR_HIT_MELEE) + hitModifier);
    --hitRating = math.ceil((GetCombatRatingBonus(CR_HIT_MELEE) + hitModifier - 5) * 32.78)

    hit = hit + (GetCombatRatingBonus(CR_HIT_SPELL) + hitModifier);
    hitRating = math.ceil((hit) * 26.23)

    return hit;
end

function ExtraStats:GetTalentGroup(index)
    local name, texture, pointsSpent, fileName = GetTalentTabInfo(index)
    return pointsSpent
end

function ExtraStats:CheckTalents()
    local points = 0;
    local group = 0;

    local groupPoints = 0;

    groupPoints = ExtraStats:GetTalentGroup(1)

    if groupPoints > points then
        points = groupPoints;
        group = 1
    end

    groupPoints = ExtraStats:GetTalentGroup(2)

    if groupPoints > points then
        points = groupPoints;
        group = 2
    end

    groupPoints = ExtraStats:GetTalentGroup(3)

    if groupPoints > points then
        points = groupPoints;
        group = 3
    end

    return group, points

end

function ExtraStats:UpdateRole()

    local group, points = ExtraStats:CheckTalents()
    --local role = GetTalentGroupRole(GetActiveTalentGroup());

    if points > 0 then
        CURRENT_ROLE = CLASS_TALENTS_ROLE[CURRENT_CLASS][group]
    end
end

local lastSent

function ExtraStats:SendVersionCheck()
    --CURRENT_ROLE = GetTalentGroupRole(GetActiveTalentGroup())
    --CURRENT_CLASS = ExtraStats:GetCurrentClass()

    if not lastSent or lastSent < GetTime() - 1 then
        lastSent = GetTime();

        if IsInGuild() then
            ExtraStats:SendCommMessage(stats.name .. "Ver", ExtraStats:Serialize(stats.version), "GUILD")
        end

        ExtraStats:SendCommMessage(stats.name .. "Ver", ExtraStats:Serialize(stats.version), "YELL")
    end
end

function ExtraStats:VersionCheck(event, msg, channel, sender)
    local success, message = ExtraStats:Deserialize(msg);
    if not success then
        return
    end

    ExtraStats:debug("Version check from", channel, sender, message)

    local removeVersion = Semver:Parse(message);
    if not removeVersion then
        return
    end

    local localVersion = Semver:Parse(stats.version);
    if not localVersion then
        return
    end

    if localVersion < removeVersion and not stats.NewVersionExists then
        stats.NewVersionExists = true;
        ExtraStats:print("A new version of", stats.name, "has been detected, please visit curseforge.com to download the latest version, or use the twitch app to keep you addons updated")
    end

end
