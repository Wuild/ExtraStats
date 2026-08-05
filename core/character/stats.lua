local name, addon = ...;

local tab = ExtraStats:CreateModule("character.stats")

local categoryFramePool
local statsFramePool

tab.frame = nil

local categories = {}
local lastUpdate;

local function EnsureCategoryOrder()
    local order = ExtraStats.db.char.categoryOrder
    if not order then
        order = {}
        ExtraStats.db.char.categoryOrder = order
    end

    if ExtraStats:tablelength(order) == 0 then
        local sorted = {}
        for _, category in pairs(categories) do
            table.insert(sorted, category)
        end
        table.sort(sorted, function(a, b)
            return a.order < b.order
        end)
        for index, category in ipairs(sorted) do
            order[category.id] = index
        end
        return order
    end

    local maxOrder = 0
    for _, value in pairs(order) do
        if type(value) == "number" and value > maxOrder then
            maxOrder = value
        end
    end

    for _, category in pairs(categories) do
        if type(order[category.id]) ~= "number" then
            maxOrder = maxOrder + 1
            order[category.id] = maxOrder
        end
    end

    return order
end

local function GetOrderedCategories()
    local order = EnsureCategoryOrder()
    local ordered = {}
    for _, category in pairs(categories) do
        table.insert(ordered, category)
    end
    table.sort(ordered, function(a, b)
        return order[a.id] < order[b.id]
    end)
    return ordered, order
end

function tab:init()
    local frame = CreateFrame("ScrollFrame", "CharacterStatsPane", PaperDollFrame, "CharacterStatsPaneScrollViewTemplate")
    frame.ScrollChild = CreateFrame("Frame", nil, frame)
    frame.ScrollChild:SetSize(215, 1)

    frame:SetScrollChild(frame.ScrollChild)

    categoryFramePool = CreateFramePool("FRAME", frame.ScrollChild, "ExtraStatsFrameCategoryTemplate")
    statsFramePool = CreateFramePool("FRAME", frame.ScrollChild, "ExtraStatsCharacterStatFrameTemplate")


    tab.frame = frame

    frame:SetScript("OnShow", tab.show)
    frame:SetScript("OnHide", tab.hide)

    ExtraStats:On("character.stats", tab.update)
end

function tab:IsVisible()
    return tab.frame and tab.frame:IsVisible()
end

function tab:show()
    ExtraStats:debug("stats tab is open")
    ExtraStats:Trigger("stats.tab.show", tab.frame)
    tab:update(true)
end

function tab:hide()
    ExtraStats:Trigger("stats.tab.hide", tab.frame)
end

function tab:MoveCategory(categoryId, direction)
    local ordered, order = GetOrderedCategories()
    local index = nil
    for i, category in ipairs(ordered) do
        if category.id == categoryId then
            index = i
            break
        end
    end
    if not index then
        return
    end

    local swapIndex = index + direction
    if swapIndex < 1 or swapIndex > #ordered then
        return
    end

    local current = ordered[index]
    local other = ordered[swapIndex]
    local currentOrder = order[current.id]
    order[current.id] = order[other.id]
    order[other.id] = currentOrder

    tab:update(true)
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
    ExtraStats:Trigger("stats.category.stat.added", self, data)
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
    ExtraStats:Trigger("stats.category.created", cat)

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

function tab:GetCategories()
    return categories
end

local lastUpdate;

local function GetRoleModeText()
    if not ExtraStats.db or not ExtraStats.db.char or not ExtraStats.db.char.dynamic then
        return "Role: Off"
    end

    local preset = ExtraStats.db.char.rolePreset or "AUTO"
    local role = ExtraStats:GetActiveRole()
    local roleName = roleLabels[role] or tostring(role or "Unknown")

    if preset == "AUTO" then
        return "Role: Auto (" .. roleName .. ")"
    end
    return "Role: Preset (" .. roleName .. ")"
end


local function GetFirstCategoryOffsetY()
    return 0
end

function tab:update(force)
    if not tab:IsVisible() then
        return
    end

    if not force and not ExtraStats.statsDirty then
        return
    end

    -- role icons are rendered near the nameplate in core/window.lua

    ExtraStats.statsDirty = false
    local dirtyCategories = ExtraStats.statsDirtyCategories
    local allDirty = dirtyCategories == nil
    ExtraStats.statsDirtyCategories = nil
    ExtraStats.statsCache = ExtraStats.statsCache or {}

    ExtraStats:debug("Updating stats")
    ExtraStats:Trigger("stats.update.start")

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

    local orderedCategories = GetOrderedCategories()
    local positions = {}
    for index, category in ipairs(orderedCategories) do
        positions[category.id] = index
    end

    local activeRole = ExtraStats:GetActiveRole()
    local roleCategoryVisibility = nil
    local roleStatVisibility = nil
    if ExtraStats.db.char.dynamic then
        roleCategoryVisibility = ExtraStats:GetRoleCategoryVisibility(activeRole)
        roleStatVisibility = ExtraStats.db.char.roleStatVisibility and ExtraStats.db.char.roleStatVisibility[activeRole]
    end
    for _, category in ipairs(orderedCategories) do
        local categoryDirty = allDirty or (dirtyCategories and dirtyCategories[category.id])
        local catCache = ExtraStats.statsCache[category.id]
        if categoryDirty or not catCache then
            catCache = { stats = {} }
            ExtraStats.statsCache[category.id] = catCache
        end
        local showCat = true

        catFrame.Title:SetText(category.text)
        catFrame:Hide()
        catFrame.categoryId = category.id
        local collapsed = ExtraStats.db.char.categoryCollapsed and ExtraStats.db.char.categoryCollapsed[category.id]
        catFrame.expanded = not collapsed
        catFrame.CollapseButton:SetNormalTexture(collapsed and "Interface\\Buttons\\UI-PlusButton-Up" or "Interface\\Buttons\\UI-MinusButton-Up")
        catFrame.CollapseButton:SetPushedTexture(collapsed and "Interface\\Buttons\\UI-PlusButton-Down" or "Interface\\Buttons\\UI-MinusButton-Down")
        catFrame.CollapseButton:SetScript("OnClick", function(self)
            local parent = self:GetParent()
            ExtraStats.db.char.categoryCollapsed = ExtraStats.db.char.categoryCollapsed or {}
            ExtraStats.db.char.categoryCollapsed[parent.categoryId] = parent.expanded
            tab:update(true)
        end)
        catFrame:SetScript("OnMouseDown", function(self, button)
            if button ~= "LeftButton" then
                return
            end
            ExtraStats.db.char.categoryCollapsed = ExtraStats.db.char.categoryCollapsed or {}
            ExtraStats.db.char.categoryCollapsed[self.categoryId] = self.expanded
            tab:update(true)
        end)

        catFrame.UpButton:SetScript("OnClick", function()
            tab:MoveCategory(category.id, -1)
        end)
        catFrame.DownButton:SetScript("OnClick", function()
            tab:MoveCategory(category.id, 1)
        end)
        local position = positions[category.id] or 1
        catFrame.UpButton:SetEnabled(position > 1)
        catFrame.DownButton:SetEnabled(position < #orderedCategories)

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
                    if role == activeRole then
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

            if showCat and roleCategoryVisibility and roleCategoryVisibility[category.id] ~= nil then
                showCat = roleCategoryVisibility[category.id]
            end
        end

        if showCat and category.show then
            showCat = category.show()
        end

        local numStatInCat = 0;
        local categoryRoleStatVisibility = roleStatVisibility and roleStatVisibility[category.id]
        if showCat then
            if not catFrame.expanded then
                catFrame:Show()
                if not lastAnchor then
                    catFrame:SetPoint("TOPLEFT", 4, GetFirstCategoryOffsetY());
                else
                    catFrame:SetPoint("TOP", lastAnchor, "BOTTOM", 0, ExtraStats.categoryYOffset);
                end
                lastAnchor = catFrame
                catFrame = categoryFramePool:Acquire();
            else
            for index, stat in ipairs(category.stats) do
                local statKey = stat.name
                if type(statKey) ~= "string" then
                    statKey = tostring(index)
                end
                local showStat = stat.show();

                if showStat and categoryRoleStatVisibility and categoryRoleStatVisibility[statKey] ~= nil then
                    showStat = categoryRoleStatVisibility[statKey]
                end

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
                            if role == activeRole then
                                foundRole = true
                                showStat = true
                            end
                            if not foundRole and role ~= activeRole then
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
                        catFrame:SetPoint("TOPLEFT", 4, GetFirstCategoryOffsetY());
                    end

                    if stat.value then
                        local data

                        if not categoryDirty then
                            data = catCache.stats[statKey]
                        end

                        if not data then
                            if type(stat.value) == "table" then
                                data = stat.value;
                            else
                                data = stat.value("player")
                            end
                            if data then
                                catCache.stats[statKey] = data
                            end
                        end

                        if data then
                            statFrame.tooltip = data.tooltip
                            statFrame.tooltip2 = data.tooltip2

                            for k, v in pairs(data) do
                                statFrame[k] = v
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
                        statFrame:SetPoint("TOP", catFrame, "BOTTOM", 0, 0);
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
        end

        if (numStatInCat > 0) then
            catFrame = categoryFramePool:Acquire();
        end
    end
    local contentHeight = 1
    if lastAnchor and tab.frame.ScrollChild.GetTop and lastAnchor.GetBottom then
        local top = tab.frame.ScrollChild:GetTop()
        local bottom = lastAnchor:GetBottom()
        if top and bottom then
            contentHeight = math.max(1, top - bottom + 8)
        end
    end
    tab.frame.ScrollChild:SetHeight(contentHeight)
    ExtraStats:Trigger("stats.update.end")
end
