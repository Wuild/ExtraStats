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
    if type(event) ~= "string" or type(callback) ~= "function" then
        return
    end

    if not events[event] then
        events[event] = {}
    end

    local listeners = events[event]
    for i = 1, #listeners do
        if listeners[i] == callback then
            return
        end
    end

    listeners[#listeners + 1] = callback
end

function ExtraStats:RegisterPlugin(plugin)
    if not plugin or type(plugin) ~= "table" then
        return nil
    end
    if not plugin.name or plugin.name == "" then
        return nil
    end

    ExtraStats.plugins = ExtraStats.plugins or {}
    ExtraStats.pluginsByName = ExtraStats.pluginsByName or {}
    if ExtraStats.pluginsByName[plugin.name] then
        return ExtraStats.pluginsByName[plugin.name]
    end

    table.insert(ExtraStats.plugins, plugin)
    ExtraStats.pluginsByName[plugin.name] = plugin
    return plugin
end

function ExtraStats:MarkStatsDirty(categories)
    ExtraStats.statsDirty = true
    if not categories or categories == true or categories == "all" then
        ExtraStats.statsDirtyCategories = nil
        return
    end

    if type(categories) == "string" then
        categories = { categories }
    end

    ExtraStats.statsDirtyCategories = ExtraStats.statsDirtyCategories or {}
    for k, v in pairs(categories) do
        local category = v
        if type(k) == "string" and v == true then
            category = k
        end
        if type(category) == "string" then
            ExtraStats.statsDirtyCategories[category] = true
        end
    end
end

function ExtraStats:Trigger(event, ...)
    local listeners = events[event]
    if listeners then
        for i = 1, #listeners do
            listeners[i](...)
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

function ExtraStats:GetActiveRole()
    if ExtraStats.db and ExtraStats.db.char and ExtraStats.db.char.dynamic then
        local preset = ExtraStats.db.char.rolePreset
        if preset and preset ~= "AUTO" then
            return preset
        end
    end
    return CURRENT_ROLE
end

function ExtraStats:GetRoleCategoryVisibility(role)
    if ExtraStats.db and ExtraStats.db.char then
        local visibility = ExtraStats.db.char.roleCategoryVisibility
        if visibility and role and visibility[role] then
            return visibility[role]
        end
    end
    return nil
end

function ExtraStats:GetRoleStatVisibility(role, categoryId)
    if ExtraStats.db and ExtraStats.db.char and role and categoryId then
        local visibility = ExtraStats.db.char.roleStatVisibility
        if visibility and visibility[role] and visibility[role][categoryId] then
            return visibility[role][categoryId]
        end
    end
    return nil
end

function ExtraStats:translate(key, ...)
    local arg = { ... };

    if L[key] == nil then
        return key
    end

    if #arg == 0 then
        return L[key]
    end

    for i, v in ipairs(arg) do
        if type(v) ~= "number" and type(v) ~= "string" then
            arg[i] = tostring(v);
        end
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
    ExtraStats:MarkStatsDirty()
    ExtraStats:CancelTimer(updateTimer)
    updateTimer = ExtraStats:ScheduleTimer("UpdateStats", 0.5)
end

function ExtraStats:UpdateStats()
    ExtraStats:MarkStatsDirty()
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

function ExtraStats:GetTalentTabInfoCompat(tabIndex, group)
    if not GetTalentTabInfo then
        return nil, nil, 0
    end

    if group == nil and GetActiveTalentGroup then
        local ok, activeGroup = pcall(GetActiveTalentGroup)
        if ok then
            group = activeGroup
        end
    end

    local ok, a, b, c, d, e
    if group ~= nil then
        ok, a, b, c, d, e = pcall(GetTalentTabInfo, tabIndex, false, false, group)
    end
    if not ok then
        ok, a, b, c, d, e = pcall(GetTalentTabInfo, tabIndex)
    end
    if not ok then
        return nil, nil, 0
    end

    -- Classic's older signature starts with name, icon, pointsSpent.
    -- Newer clients start with id, name, description, icon, pointsSpent.
    local usesClassicSignature = tonumber(c) ~= nil
    local tabName = usesClassicSignature and a or b
    local icon = usesClassicSignature and b or d
    local points = usesClassicSignature and c or e
    return tabName, icon, tonumber(points) or 0
end

function ExtraStats:GetTalentGroup(index)
    local _, _, pointsSpent = ExtraStats:GetTalentTabInfoCompat(index)
    return pointsSpent
end

local function GetPrimaryTalentTreeIndex()
    local numTabs = GetNumTalentTabs and GetNumTalentTabs() or 0
    if numTabs == 0 then
        return nil
    end

    local bestTab = nil
    local bestPoints = -1
    for i = 1, numTabs do
        local _, _, points = ExtraStats:GetTalentTabInfoCompat(i)
        if points > bestPoints then
            bestPoints = points
            bestTab = i
        end
    end

    if bestPoints <= 0 then
        return nil
    end
    return bestTab
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
    local classIndex = CURRENT_CLASS or ExtraStats:GetCurrentClass()
    if not classIndex or not CLASS_TALENTS_ROLE[classIndex] then
        return
    end

    if GetTalentGroupRole and GetActiveTalentGroup then
        local okGroup, group = pcall(GetActiveTalentGroup)
        local okRole, role
        if okGroup and group then
            okRole, role = pcall(GetTalentGroupRole, group)
        end
        if okRole and (role == CLASS_ROLE_DAMAGER or role == CLASS_ROLE_HEALER or role == CLASS_ROLE_TANK) then
            CURRENT_ROLE = role
            return
        end
    end

    local primaryTab = GetPrimaryTalentTreeIndex()
    if not primaryTab then
        return
    end

    CURRENT_ROLE = CLASS_TALENTS_ROLE[classIndex][primaryTab] or CURRENT_ROLE
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
        ExtraStats:print(ExtraStats:translate("message.new_version", stats.name))
    end

end
