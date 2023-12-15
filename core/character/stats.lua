local name, addon = ...;

local tab = ExtraStats:CreateModule("character.stats")

local categoryFramePool
local statsFramePool

tab.frame = nil

local categories = {}
local lastUpdate;

function tab:init()
    local frame = CreateFrame("ScrollFrame", "CharacterStatsPane", PaperDollFrame, "CharacterStatsPaneScrollViewTemplate")
    frame.ScrollChild = CreateFrame("Frame", nil, frame)
    frame.ScrollChild:SetSize(242, 160)

    frame:SetScrollChild(frame.ScrollChild)

    categoryFramePool = CreateFramePool("FRAME", frame.ScrollChild, "ExtraStatsFrameCategoryTemplate")
    statsFramePool = CreateFramePool("FRAME", frame.ScrollChild, "ExtraStatsCharacterStatFrameTemplate")

    tab.frame = frame

    frame:SetScript("OnShow", tab.show)

    ExtraStats:On("character.stats", tab.update)
end

function tab:IsVisible()
    return tab.frame and tab.frame:IsVisible()
end

function tab:show()
    ExtraStats:debug("stats tab is open")
    tab:update()
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
function tab:CreateCategory(id, text, options)
    local cat = CopyTable(CategoryClass) ---  @CategoryClass

    cat.id = id;
    cat.text = text;

    if options then
        for k, v in pairs(options) do
            cat[k] = v
        end
    end

    table.insert(categories, cat)

    return cat
end

---@param id string
--- @return CategoryClass
function tab:GetCategory(id)
    for catId, category in pairs(categories) do
        if category.id == id then
            return categories[catId]
        end
    end

    return false
end

local lastUpdate;

function tab:update()
    if not tab:IsVisible() then
        return
    end

    ExtraStats:debug("Updating stats")

    for name, module in ExtraStats.modules:IterateModules() do
        if module.Update then
            module:Update();
        end
    end

    statsFramePool:ReleaseAll();
    categoryFramePool:ReleaseAll();

    local catFrame = categoryFramePool:Acquire();
    local statFrame = statsFramePool:Acquire();
    local lastAnchor;

    for catId, category in spairs(categories, compare) do
        local showCat = true

        catFrame.Title:SetText(category.text)
        catFrame:Hide()

        ExtraStats:Trigger("category:build", catFrame)

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
                    --statFrame.onEnter = nil;
                    statFrame.onUpdate = nil;
                    statFrame.UpdateTooltip = nil;
                    statFrame.tooltip = nil;
                    statFrame.tooltip2 = nil;

                    catFrame:Show()
                    if not lastAnchor then
                        catFrame:SetPoint("TOPLEFT", 8, 0);
                    end

                    if stat.value then
                        local data

                        if type(stat.value) == "table" then
                            data = stat.value;
                        else
                            data = stat.value("player")
                        end

                        if data then

                            statFrame.tooltip = data.tooltip
                            statFrame.tooltip2 = data.tooltip2

                            if data then
                                for k, v in pairs(data) do
                                    statFrame[k] = v
                                end
                            end

                            ExtraStats:SetLabelAndText(statFrame, stat.name, data.value, data.isPercentage)

                            statFrame.onEnter = data.onEnter;
                            statFrame.onUpdate = data.onUpdate;

                        end
                    else
                        ExtraStats:SetLabelAndText(statFrame, stat.name, "")
                    end

                    if (numStatInCat == 0) then
                        if (lastAnchor) then
                            catFrame:SetPoint("TOP", lastAnchor, "BOTTOM", 0, ExtraStats.categoryYOffset);
                        end
                        lastAnchor = catFrame;
                        statFrame:SetPoint("TOP", catFrame, "BOTTOM", 0, -2);
                    else
                        statFrame:SetPoint("TOP", lastAnchor, "BOTTOM", 0, ExtraStats.statYOffset);
                    end

                    statFrame:Show()

                    numStatInCat = numStatInCat + 1;
                    statFrame.Background:SetShown((numStatInCat % 2) == 0);
                    lastAnchor = statFrame;

                    ExtraStats:Trigger("stat:build", statFrame)

                    statFrame = statsFramePool:Acquire();
                end
            end
        end

        if (numStatInCat > 0) then
            catFrame = categoryFramePool:Acquire();
        end
    end
end