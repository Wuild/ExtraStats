local name, stats = ...;

local Semver = LibStub("Semver");

local L = LibStub("AceLocale-3.0"):GetLocale("ExtraStats", true)

ExtraStats.stats = {}
ExtraStats.modules = {}

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

function ExtraStats:GetCurrentClass()
    local localizedClass, englishClass, classIndex = UnitClass("Player");
    return classIndex
end

local function CopyTable(orig)
    local orig_type = type(orig)
    local copy
    if orig_type == 'table' then
        copy = {}
        for orig_key, orig_value in next, orig, nil do
            copy[CopyTable(orig_key)] = CopyTable(orig_value)
        end
        setmetatable(copy, CopyTable(getmetatable(orig)))
    else
        -- number, string, boolean, etc
        copy = orig
    end
    return copy
end

local CategoryClass = {
    id = nil,
    name = nil,
    frame = nil,
    show = nil,
    order = 0,
    roles = {},
    classes = {},
    stats = {}
}

--- @param name string
--- @param value function|string
--- @param options {show, role, onEnter, onUpdate, roles, classes}
function CategoryClass:Add(name, value, options)
    local data = {
        name = name,
        value = value,
        roles = {},
        classes = {},
        show = function()
            return true
        end,
        onEnter = nil,
        onUpdate = nil
    }

    if options then
        for k, v in pairs(options) do
            data[k] = v
        end
    end

    table.insert(self.stats, data)
end

---@param id string
---@param name string
---@param options table {id, show, role, roles = {}, classes = {}}
--- @return CategoryClass
function ExtraStats:CreateCategory(id, text, options)
    local cat = CopyTable(CategoryClass) ---  @CategoryClass

    cat.id = id;
    cat.text = text;

    if options then
        for k, v in pairs(options) do
            cat[k] = v
        end
    end

    table.insert(ExtraStats.categories, cat)

    return cat
end

---@param id string
--- @return CategoryClass
function ExtraStats:GetCategory(id)
    return ExtraStats.categories[id]
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

local function compare(t, a, b)
    return t[a].order < t[b].order
end

local function spairs(t, order)
    -- collect the keys
    local keys = {}
    for k in pairs(t) do
        keys[#keys + 1] = k
    end

    -- if order function given, sort by it by passing the table and keys a, b,
    -- otherwise just sort the keys
    if order then
        table.sort(keys, function(a, b)
            return order(t, a, b)
        end)
    else
        table.sort(keys)
    end

    -- return the iterator function
    local i = 0
    return function()
        i = i + 1
        if keys[i] then
            return keys[i], t[keys[i]]
        end
    end
end

function ExtraStats:UpdateStatsDelayed()
    C_Timer.After(0.2, function()
        ExtraStats:UpdateStats()
    end)
end

function ExtraStats:UpdateStats()

    if not ExtraStats.window:IsVisible() then
        return
    end

    self.statsFramePool:ReleaseAll();
    self.categoryFramePool:ReleaseAll();
    local categoryYOffset = 0;
    local statYOffset = 0;
    local catFrame = self.categoryFramePool:Acquire();
    local statFrame = self.statsFramePool:Acquire();
    local lastAnchor;

    ExtraStats:debug("Update stats")

    --table.sort(ExtraStats.categories, function(a, b)
    --    return b.order < a.order
    --end)

    --for index, category in pairs(ExtraStats.categories) do
    --    --ExtraStats.window[index] = CreateFrame("Frame", "ExtraStatsCategory" .. index, ExtraStats.window.ScrollChild, "ExtraStatsFrameCategoryTemplate")
    --    ExtraStats.window[index]
    --    category.frame = ExtraStats.window[index];
    --end

    for catId, category in spairs(ExtraStats.categories, compare) do
        local showCat = true

        catFrame.Title:SetText(category.text)
        catFrame:Hide()

        if not ExtraStats.db.char.dynamic and not ExtraStats.db.char.categories[category.id].enabled then
            showCat = false
        end

        if ExtraStats.db.char.dynamic then
            local foundRole = false
            local foundClass = false

            if #category.classes > 0 then
                for _, class in pairs(category.classes) do
                    if class == CURRENT_CLASS then
                        foundClass = true
                    end
                end
            end

            if #category.roles > 0 then
                for _, role in pairs(category.roles) do
                    if role == CURRENT_ROLE then
                        foundRole = true
                    end
                end
            end

            if #category.classes > 0 and not foundClass then
                showCat = false
            end

            if #category.roles > 0 and not foundRole then
                showCat = false
            end
        end

        if showCat and category.show then
            showCat = category.show()
        end

        local numStatInCat = 0;
        if showCat then
            for index, stat in pairs(category.stats) do
                local showStat = stat.show();

                if ExtraStats.db.char.dynamic then
                    local foundRole = false
                    local foundClass = false

                    if #stat.classes > 0 then
                        for _, class in pairs(stat.classes) do
                            if class == CURRENT_CLASS then
                                foundClass = true
                                showStat = true
                            end
                            if not foundClass and class ~= CURRENT_CLASS then
                                showStat = false
                            end
                        end
                    end

                    if #stat.roles > 0 then
                        for _, role in pairs(stat.roles) do
                            if role == CURRENT_ROLE then
                                foundRole = true
                                showStat = true
                            end
                            if not foundRole and role ~= CURRENT_ROLE then
                                showStat = false
                            end
                        end
                    end
                end

                if (showStat) then
                    statFrame:Hide()
                    statFrame.onEnter = nil;
                    statFrame.onUpdate = nil;
                    statFrame.UpdateTooltip = nil;
                    statFrame.tooltip = nil;
                    statFrame.tooltip2 = nil;

                    catFrame:Show()
                    if not lastAnchor then
                        catFrame:SetPoint("TOPRIGHT", -30, 0);
                    end

                    if stat.value then
                        local data = stat.value()
                        statFrame.tooltip = data.tooltip
                        statFrame.tooltip2 = data.tooltip2

                        if data then
                            for k, v in pairs(data) do
                                statFrame[k] = v
                            end
                        end

                        ExtraStats:SetLabelAndText(statFrame, stat.name, data.value, data.isPercentage)

                        statFrame.onEnter = stat.onEnter;
                        statFrame.onUpdate = stat.onUpdate;
                    else
                        ExtraStats:SetLabelAndText(statFrame, stat.name, "")
                    end

                    if (numStatInCat == 0) then
                        if (lastAnchor) then
                            catFrame:SetPoint("TOP", lastAnchor, "BOTTOM", 0, categoryYOffset);
                        end
                        lastAnchor = catFrame;
                        statFrame:SetPoint("TOP", catFrame, "BOTTOM", 0, -2);
                    else
                        statFrame:SetPoint("TOP", lastAnchor, "BOTTOM", 0, statYOffset);
                    end

                    statFrame:Show()

                    numStatInCat = numStatInCat + 1;
                    statFrame.Background:SetShown((numStatInCat % 2) == 0);
                    lastAnchor = statFrame;

                    statFrame = self.statsFramePool:Acquire();
                end
            end
        end

        if (numStatInCat > 0) then
            catFrame = self.categoryFramePool:Acquire();
        end

    end
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

function ExtraStats:SendVersionCheck()
    --CURRENT_ROLE = GetTalentGroupRole(GetActiveTalentGroup())
    CURRENT_CLASS = ExtraStats:GetCurrentClass()

    if IsInGuild() then
        ExtraStats:SendCommMessage(stats.name .. "Ver", ExtraStats:Serialize(stats.version), "GUILD")
    end

    ExtraStats:SendCommMessage(stats.name .. "Ver", ExtraStats:Serialize(stats.version), "YELL")
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
