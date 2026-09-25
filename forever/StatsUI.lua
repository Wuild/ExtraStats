-- Addon-owned stats view inside the native character pane; shared Blizzard data stays untouched.
local addonName = ...
local _, _, _, interface = GetBuildInfo()
if interface < 16000 or interface >= 17000 then return end
local UI = {}
ExtraStatsForeverStats = UI
local ids = { "base", "attributes", "melee", "ranged", "spell", "defenses" }
local roles = { "OFF", "AUTO", "TANK", "HEALER", "DAMAGER" }
local roleNames = { OFF = "Off", AUTO = "Auto", TANK = "Tank", HEALER = "Healer", DAMAGER = "Damage" }
local casters = { MAGE=true, PRIEST=true, WARLOCK=true, SHAMAN=true, DRUID=true, PALADIN=true }

-- Same tree-to-role defaults as the original ExtraStats addon.
local treeRoles = {
    WARRIOR = { "DAMAGER", "DAMAGER", "TANK" },
    PALADIN = { "HEALER", "TANK", "DAMAGER" },
    PRIEST = { "HEALER", "HEALER", "DAMAGER" },
    SHAMAN = { "DAMAGER", "DAMAGER", "HEALER" },
    DRUID = { "DAMAGER", "TANK", "HEALER" },
}

function UI:GetTalentRole()
    self.autoTreeIndex = nil
    if not C_ClassTalents or not C_Traits then return end
    local configID = C_ClassTalents.GetActiveConfigID()
    if not configID then return end
    local config = C_Traits.GetConfigInfo(configID)
    if not config or not config.treeIDs then return end
    local _, class = UnitClass("player")
    for _, treeID in ipairs(config.treeIDs) do
        local displays = C_Traits.GetGroupDisplayInfoByTreeID(treeID)
        if displays and #displays > 0 then
            -- Sort a private copy; never mutate an API-owned array.
            local ordered, groupIDs, points = {}, {}, {}
            for _, display in ipairs(displays) do table.insert(ordered, display) end
            table.sort(ordered, function(a, b) return a.orderIndex < b.orderIndex end)
            for _, display in ipairs(ordered) do table.insert(groupIDs, display.groupID) end
            for _, group in ipairs(C_Traits.GetGroupCurrencyInfo(configID, groupIDs) or {}) do
                local currency = group.currencyInfos and group.currencyInfos[1]
                points[group.traitNodeGroupID] = currency and currency.spent or 0
            end
            local best, highest = nil, 0
            for index, display in ipairs(ordered) do
                local spent = points[display.groupID] or 0
                if not (issecretvalue and issecretvalue(spent)) and spent > highest then
                    best, highest = index, spent
                end
            end
            self.autoTreeIndex = best
            self.autoTreeName = best and ordered[best].displayName or nil
            return best and treeRoles[class] and treeRoles[class][best] or "DAMAGER"
        end
    end
end

function UI:GetRole()
    local preset = self.settings.rolePreset
    if preset ~= "AUTO" then return preset end
    local talentRole = self:GetTalentRole()
    if talentRole then return talentRole end
    local role = UnitGroupRolesAssigned("player")
    if role == "TANK" or role == "HEALER" or role == "DAMAGER" then return role end
    local spec = C_SpecializationInfo.GetSpecialization()
    if spec then
        role = select(5, C_SpecializationInfo.GetSpecializationInfo(spec))
        if role == "TANK" or role == "HEALER" or role == "DAMAGER" then return role end
    end
    return "DAMAGER"
end

function UI:GetProfile()
    local role = self:GetRole()
    self.settings.profiles[role] = self.settings.profiles[role] or { categories = {}, stats = {} }
    return self.settings.profiles[role], role
end

function UI:GetCategoryVisibility(id)
    local profile, role = self:GetProfile()
    local className, class = UnitClass("player")
    local shown, reason = true, "Included in the default layout."
    if role == "OFF" then
        reason = "All roles selected: every category is included."
    elseif id == "spell" then
        shown = casters[class] == true
        reason = shown and ("Included for " .. className .. " spell abilities, including tank builds.")
            or ("Hidden by default for " .. className .. ": this class does not use spell stats.")
    elseif id == "defenses" then
        shown = role == "TANK"
        reason = shown and "Included for the Tank role." or "Hidden by default outside the Tank role."
    elseif id == "ranged" then
        shown = class == "HUNTER" or IsRangedWeapon()
        reason = shown and "Included for Hunters or an equipped ranged weapon (including wands)."
            or "Hidden by default: no ranged weapon equipped."
    end
    if profile.categories[id] ~= nil then
        shown = profile.categories[id]
        reason = (shown and "Shown" or "Hidden") .. " by your saved override for this role."
    end
    return shown, reason
end

function UI:IsCategoryShown(id)
    return (self:GetCategoryVisibility(id))
end

function UI:GetOrder()
    if self.settings.orderCustom then return self.settings.order end
    local role = self:GetRole()
    local _, class = UnitClass("player")
    if role == "TANK" and class == "PALADIN" then return { "base", "defenses", "spell", "melee", "ranged", "attributes" } end
    if role == "TANK" then return { "base", "defenses", "melee", "ranged", "spell", "attributes" } end
    if role == "HEALER" then return { "base", "spell", "ranged", "melee", "defenses", "attributes" } end
    if class == "HUNTER" then return { "base", "ranged", "melee", "spell", "defenses", "attributes" } end
    self:GetTalentRole()
    local caster = class == "MAGE" or class == "PRIEST" or class == "WARLOCK"
        or ((class == "DRUID" or class == "SHAMAN") and self.autoTreeIndex == 1)
    if caster then return { "base", "spell", "ranged", "melee", "defenses", "attributes" } end
    return { "base", "melee", "ranged", "spell", "defenses", "attributes" }
end

function UI:Move(id, direction)
    local order = { unpack(self:GetOrder()) }
    for index, value in ipairs(order) do
        if value == id then
            local other = index + direction
            if other >= 1 and other <= #order then
                order[index], order[other] = order[other], order[index]
                self.settings.order, self.settings.orderCustom = order, true
                self:Refresh()
            end
            return
        end
    end
end

function UI:GetPowerName()
    local _, token = UnitPowerType("player")
    return (token and _G[token]) or POWER or "Power", token
end

local function MovementSpeedIsRestricted()
    local _, run, flight, swim = GetUnitSpeed("player")
    if issecretvalue then
        return issecretvalue(run) or issecretvalue(flight) or issecretvalue(swim)
            or issecretvalue(IsSwimming("player")) or issecretvalue(IsFlying("player"))
            or issecretvalue(IsFalling("player"))
    end
    return false
end

function UI:UpdateMovementSpeed(row)
    if MovementSpeedIsRestricted() then
        -- A percentage requires arithmetic, which is forbidden on secret speeds.
        row.Label:SetText(string.format(STAT_FORMAT or "%s:", STAT_MOVEMENT_SPEED))
        row.Value:SetText("--")
        row.speed, row.runSpeed, row.flightSpeed, row.swimSpeed = nil, nil, nil, nil
        row.tooltip = STAT_MOVEMENT_SPEED
        row.tooltip2 = "Movement speed is unavailable while protected by the game."
        row.onEnterFunc, row.UpdateTooltip = nil, nil
        return
    end
    ExtraStatsForeverData.stats.MOVESPEED.updateFunc(row, "player")
    local nativeTooltip = row.onEnterFunc
    if nativeTooltip then
        local function OnEnter(frame)
            -- Recheck on hover: combat can start after this row was rendered.
            local restricted = MovementSpeedIsRestricted()
            if restricted then
                self:UpdateMovementSpeed(frame)
                PaperDollStatTooltip(frame)
            elseif issecretvalue and (issecretvalue(GetCombatRating(CR_SPEED))
                or issecretvalue(GetCombatRatingBonus(CR_SPEED))) then
                frame.tooltip, frame.tooltip2 = STAT_MOVEMENT_SPEED, nil
                PaperDollStatTooltip(frame)
            else
                nativeTooltip(frame)
            end
            frame.UpdateTooltip = OnEnter
        end
        row.onEnterFunc = OnEnter
    end
end

function UI:Refresh()
    if self.drag then return end -- Keep row identities stable until the drop.
    local focusedStat
    if SmartNavigation and InputUtil.IsGamepadUIEnabled() then
        local current = SmartNavigation:GetCurrentButton()
        if current and current.extraStatsStatRow then focusedStat = current.statName end
    end
    self.labels.POWER = self:GetPowerName()
    local role = self:GetRole()
    for choice, button in pairs(self.roleIcons or {}) do
        button.Icon:SetDesaturated(choice ~= role)
        button.Icon:SetAlpha(choice == role and 1 or 0.45)
    end
    if not self.ready or not self.scroll:IsVisible() then return end
    -- Never call the native UpdateStats or change its elementData/provider.
    local view = { elementData = {} }
    for _, category in ipairs(ExtraStatsForeverData.categories) do
        table.insert(view.elementData, { isHeader = true, name = category.categoryName })
        for _, stat in ipairs(category.stats) do
            if not stat.showFunc or stat.showFunc() then
                table.insert(view.elementData, { name = stat.stat, hideAt = stat.hideAt })
            end
        end
    end
    self:Apply(view)
    for _, frame in ipairs(self.rows) do frame:Hide() end
    for _, frame in ipairs(self.headers) do frame:Hide() end
    self.headerPositions = {}
    self.navigationRows = {}
    local y, rowIndex, headerIndex = 0, 0, 0
    for _, entry in ipairs(view.elementData) do
        local frame
        local display = true
        if entry.isHeader then
            headerIndex = headerIndex + 1
            frame = self.headers[headerIndex]
            if not frame then
                frame = CreateFrame("Frame", nil, self.body, "ExtraStatsForeverCategoryTemplate")
                frame:SetHeight(29)
                -- Keep header controls clear of the overlaid scrollbar.
                frame.Title:SetPoint("RIGHT", frame, "RIGHT", -36, 0)
                function frame:GetElementData() return self.elementData end
                self.headers[headerIndex] = frame
            end
            table.insert(self.headerPositions, { id = entry.extraStatsCategory, y = y })
            frame.elementData = entry
            frame.Title:SetText(entry.name)
        else
            rowIndex = rowIndex + 1
            frame = self.rows[rowIndex]
            if not frame then
                frame = CreateFrame("Frame", nil, self.body, "ExtraStatsForeverStatRowTemplate")
                frame:EnableMouse(true)
                if SmartNavigation_MarkFrameFocusable then
                    SmartNavigation_MarkFrameFocusable(frame)
                    SmartNavigation_MarkFrameBlockingSmartNavClick(frame)
                end
                frame:SetScript("OnEnter", function(row)
                    row.Hover:Show()
                    CharacterStatFrameMixin.OnEnter(row)
                end)
                frame:SetScript("OnLeave", function(row) row.Hover:Hide(); GameTooltip:Hide() end)
                frame.extraStatsStatRow = true
                -- Controller FocusEnter does not reliably run mouse OnEnter on
                -- these plain Frames. Use the explicit smart-nav lifecycle too.
                frame.OnSmartNavSelect = function(row)
                    row.Hover:Show()
                    CharacterStatFrameMixin.OnEnter(row)
                end
                frame.OnSmartNavDeselect = function(row)
                    row.Hover:Hide()
                    if GameTooltip:IsOwned(row) then GameTooltip:Hide() end
                end
                self.rows[rowIndex] = frame
            end
            frame.tooltip, frame.tooltip2, frame.tooltip3, frame.tooltip4 = nil, nil, nil, nil
            frame.onEnterFunc, frame.UpdateTooltip = nil, nil
            frame.unit = "player"
            frame.statName = entry.name
            frame.Label:SetText(self.labels[entry.name])
            -- Health/power values may be secret: pass directly to the font string.
            if entry.name == "HEALTH" then
                frame.tooltip = HEALTH
                frame.tooltip2 = STAT_HEALTH_TOOLTIP
                frame.Value:SetText(UnitHealth("player"))
            elseif entry.name == "POWER" then
                local name, token = self:GetPowerName()
                frame.Label:SetText(string.format(STAT_FORMAT or "%s:", name))
                frame.tooltip = name
                frame.tooltip2 = token and _G["STAT_" .. token .. "_TOOLTIP"] or nil
                frame.Value:SetText(UnitPower("player"))
            elseif entry.name == "MOVESPEED" then
                self:UpdateMovementSpeed(frame)
            else
                local value = ExtraStatsForeverData.stats[entry.name].updateFunc(frame, "player")
                if entry.hideAt ~= nil and not (issecretvalue and issecretvalue(value)) then
                    display = value ~= entry.hideAt
                end
            end
            frame.Background:SetShown(entry.statIndex % 2 == 0)
        end
        if display then
        table.insert(self.navigationRows, entry.isHeader and frame.CollapseButton or frame)
        frame:ClearAllPoints()
        frame:SetPoint("TOPLEFT", self.body, "TOPLEFT", 0, -y)
        frame:SetPoint("RIGHT", self.body, "RIGHT", 0, 0)
        frame:Show()
        y = y + (entry.isHeader and 29 or 21)
        else
            frame:Hide()
        end
    end
    self.body:SetHeight(math.max(1, y))
    self.contentHeight = math.max(1, y)
    self:UpdateScrollMetrics()
    self:DecorateHeaders()
    if focusedStat then
        local target
        for _, row in ipairs(self.rows) do
            if row:IsShown() and row.statName == focusedStat then target = row; break end
        end
        -- Rows are recycled/reordered on refresh. Keep focus on the same stat
        -- and reopen its freshly rebuilt tooltip instead of a different value.
        SmartNavigation:SelectButton(target or self.navigationRows[1], true)
    end
end

-- ScrollFrame ranges can be secret even though every row is addon-owned.
-- Keep public layout dimensions and offsets instead of querying engine ranges.
local function IsPublicNumber(value)
    return not (issecretvalue and issecretvalue(value)) and type(value) == "number"
end

function UI:SetScrollOffset(offset)
    if not IsPublicNumber(offset) then return end
    self.scrollOffset = math.max(0, math.min(offset, self.scrollRange or 0))
    self.setNativeVerticalScroll(self.scroll, self.scrollOffset)
    if not self.syncingScrollBar then
        self.syncingScrollBar = true
        local range = self.scrollRange or 0
        self.scrollBar:SetScrollPercentage(range > 0 and self.scrollOffset / range or 0, true)
        self.syncingScrollBar = false
    end
end

-- Drop before a visible category (or at the end), retaining hidden categories.
function UI:DropCategory(id, before)
    if id == before then return end
    local order, found = {}, false
    for _, value in ipairs(self:GetOrder()) do
        if value == id then found = true else table.insert(order, value) end
    end
    if not found then return end
    local position = #order + 1
    if before then
        for index, value in ipairs(order) do
            if value == before then position = index; break end
        end
    end
    table.insert(order, position, id)
    self.settings.order, self.settings.orderCustom = order, true
end

function UI:UpdateCategoryDrag(elapsed)
    local drag = self.drag
    if not drag then return end
    local x, y = GetCursorPosition()
    local scale, left, top = self.scroll:GetEffectiveScale(), self.scroll:GetLeft(), self.scroll:GetTop()
    local width, height = self.scroll:GetWidth(), self.viewportHeight
    drag.valid = false
    self.dragGhost:Hide()
    local geometry = { x, y, scale, left, top, width, height }
    for index = 1, 7 do
        if not IsPublicNumber(geometry[index]) then self.dropLine:Hide(); return end
    end
    if not height or not left or not top or not scale or scale <= 0 then self.dropLine:Hide(); return end
    x, y = x / scale - left, top - y / scale
    if x < 0 or x > width or y < 0 or y > height then self.dropLine:Hide(); return end
    self.dragGhost:ClearAllPoints()
    self.dragGhost:SetPoint("TOPLEFT", self.scroll, "TOPLEFT", math.min(x + 12, math.max(0, width - 180)), -math.max(0, math.min(y + 16, height - 44)))
    self.dragGhost:Show()
    if elapsed and elapsed > 0 then
        local direction = y < 24 and -1 or (y > height - 24 and 1 or 0)
        if direction ~= 0 then self:SetScrollOffset((self.scrollOffset or 0) + direction * 180 * elapsed) end
    end
    local contentY = y + (self.scrollOffset or 0)
    local before, lineY = nil, self.contentHeight or 0
    for _, header in ipairs(self.headerPositions or {}) do
        if contentY < header.y + 14.5 then before, lineY = header.id, header.y; break end
    end
    drag.valid, drag.before = true, before
    self.dropLine:ClearAllPoints()
    self.dropLine:SetPoint("TOPLEFT", self.body, "TOPLEFT", 0, -lineY)
    self.dropLine:SetPoint("TOPRIGHT", self.body, "TOPRIGHT", -16, -lineY)
    self.dropLine:Show()
end

function UI:StartCategoryDrag(frame)
    if self.drag then return end
    self.drag = { frame = frame, id = frame.elementData.extraStatsCategory }
    frame:SetAlpha(0.25)
    if GameTooltip then GameTooltip:Hide() end
    if not self.dragGhost then
        local ghost = CreateFrame("Frame", nil, self.scroll:GetParent(), "BackdropTemplate")
        self.dragGhost = ghost
        ghost:SetSize(180, 44)
        ghost:SetFrameStrata("TOOLTIP")
        ghost:EnableMouse(false)
        ghost:SetBackdrop({bgFile="Interface\\Buttons\\WHITE8X8", edgeFile="Interface\\Buttons\\WHITE8X8", edgeSize=1})
        ghost:SetBackdropColor(0.08, 0.065, 0.03, 0.98)
        ghost:SetBackdropBorderColor(1, 0.78, 0.25, 1)
        ghost.Label = ghost:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        ghost.Label:SetPoint("TOPLEFT", 10, -7)
        ghost.Label:SetWidth(160)
        ghost.Label:SetJustifyH("LEFT")
        local hint = ghost:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        hint:SetPoint("BOTTOMLEFT", 10, 7)
        hint:SetText("Release to place category")
    end
    self.dragGhost.Label:SetText(self.categories[self.drag.id].categoryName)
    if not self.dropLine then
        self.dropLine = self.body:CreateTexture(nil, "OVERLAY")
        self.dropLine:SetColorTexture(1, 0.78, 0.25, 1)
        self.dropLine:SetHeight(4)
    end
    self.scroll:SetScript("OnUpdate", function(_, elapsed) self:UpdateCategoryDrag(elapsed) end)
    self:UpdateCategoryDrag(0)
end

function UI:FinishCategoryDrag(commit)
    local drag = self.drag
    if not drag then return end
    if commit then self:UpdateCategoryDrag(0) end
    self.drag = nil
    self.scroll:SetScript("OnUpdate", nil)
    self.dropLine:Hide()
    self.dragGhost:Hide()
    drag.frame:SetAlpha(1)
    if commit and drag.valid then self:DropCategory(drag.id, drag.before) end
    self:QueueRefresh()
end

function UI:UpdateScrollMetrics()
    local height = self.scroll:GetHeight()
    if IsPublicNumber(height) and height > 0 then self.viewportHeight = height end
    if not self.viewportHeight then return end
    local content = self.contentHeight or 1
    self.scrollRange = math.max(0, content - self.viewportHeight)
    self.scrollBar:SetVisibleExtentPercentage(math.min(1, self.viewportHeight / content))
    self.scrollBar:SetPanExtentPercentage(self.scrollRange > 0 and math.min(1, 30 / self.scrollRange) or 0)
    self:SetScrollOffset(self.scrollOffset or 0)
end

-- Frequent resource changes only touch font strings, preserving the layout and
-- any active category drag. Secret health/power values pass through unchanged.
function UI:QueueResourceRefresh()
    if self.resourceRefreshQueued then return end
    self.resourceRefreshQueued = true
    C_Timer.After(0, function()
        self.resourceRefreshQueued = nil
        if not self.ready or not self.scroll:IsVisible() then return end
        for _, row in ipairs(self.rows) do
            if row.statName == "HEALTH" then
                row.Value:SetText(UnitHealth("player"))
            elseif row.statName == "POWER" then
                row.Value:SetText(UnitPower("player"))
            end
        end
    end)
end

function UI:QueueRefresh()
    if self.refreshQueued then return end
    self.refreshQueued = true
    C_Timer.After(0, function()
        self.refreshQueued = nil
        self:Refresh()
    end)
end

function UI:Apply(pane)
    -- Reorder rendered groups, never PAPERDOLL_STATCATEGORIES: Blizzard indexes
    -- attributes by category 2 when constructing primary-stat tooltips.
    local groups, current = {}, nil
    for _, entry in ipairs(pane.elementData) do
        if entry.isHeader then
            current = self.byName[entry.name]
            if current then
                entry.extraStatsCategory = current
                groups[current] = { entry }
            end
        elseif current then
            table.insert(groups[current], entry)
        end
    end
    local result = {}
    local profile = self:GetProfile()
    for _, id in ipairs(self:GetOrder()) do
        local group = groups[id]
        if group and self:IsCategoryShown(id) then
            table.insert(result, group[1])
            if not self.settings.collapsed[id] then
                for index = 2, #group do
                    local entry = group[index]
                    if profile.stats[entry.name] ~= false then
                        table.insert(result, entry)
                    end
                end
            end
        end
    end
    local stripe = 0
    for _, entry in ipairs(result) do
        if entry.isHeader then stripe = 0 else stripe = stripe + 1; entry.statIndex = stripe end
    end
    pane.elementData = result
end

function UI:DecorateHeaders()
    for _, frame in ipairs(self.headers) do
        local data = frame:GetElementData()
        local id = data and data.extraStatsCategory
        if id then
            if not frame.ExtraStatsControls then
                frame.ExtraStatsControls = {
                    collapse = frame.CollapseButton,
                }
                frame.CollapseButton:SetScript("OnClick", function()
                    local category = frame.elementData.extraStatsCategory
                    self.settings.collapsed[category] = not self.settings.collapsed[category]
                    self:Refresh()
                end)
                frame:RegisterForDrag("LeftButton")
                frame:SetScript("OnDragStart", function() self:StartCategoryDrag(frame) end)
                frame:SetScript("OnDragStop", function() self:FinishCategoryDrag(true) end)
                frame:SetScript("OnHide", function()
                    if self.drag and self.drag.frame == frame then self:FinishCategoryDrag(false) end
                end)
                frame:EnableMouse(true)
            end
            local controls = frame.ExtraStatsControls
            local texture = self.settings.collapsed[id] and "Plus" or "Minus"
            controls.collapse:SetNormalTexture("Interface\\Buttons\\UI-" .. texture .. "Button-Up")
            controls.collapse:SetPushedTexture("Interface\\Buttons\\UI-" .. texture .. "Button-Down")
        end
    end
end

function UI:OpenMenu(owner)
    self.labels.POWER = self:GetPowerName()
    MenuUtil.CreateContextMenu(owner, function(_, menu)
        menu:CreateTitle("ExtraStats")
        for _, role in ipairs(roles) do
            local choice = role
            menu:CreateRadio("Role: " .. roleNames[choice], function()
                return self.settings.rolePreset == choice
            end, function() self.settings.rolePreset = choice; self:Refresh() end)
        end
        menu:CreateDivider()
        menu:CreateTitle("Categories and stats (current role)")
        local profile = self:GetProfile()
        for _, id in ipairs(ids) do
            local categoryId = id
            local category = self.categories[id]
            local submenu = menu:CreateButton(category.categoryName)
            submenu:CreateCheckbox("Show category", function() return self:IsCategoryShown(categoryId) end, function()
                profile.categories[categoryId] = not self:IsCategoryShown(categoryId)
                self:Refresh()
            end)
            submenu:CreateButton("Move category up", function() self:Move(categoryId, -1) end)
            submenu:CreateButton("Move category down", function() self:Move(categoryId, 1) end)
            for _, stat in ipairs(category.stats) do
                local key = stat.stat
                submenu:CreateCheckbox(self.labels[key] or key, function() return profile.stats[key] ~= false end, function()
                    profile.stats[key] = profile.stats[key] == false
                    self:Refresh()
                end)
            end
        end
        menu:CreateDivider()
        menu:CreateButton("Use role-based category order", function()
            self.settings.orderCustom = false
            self:Refresh()
        end)
        menu:CreateButton("Reset stats layout and filters", function()
            self.settings.order = { unpack(ids) }
            self.settings.orderCustom = false
            self.settings.collapsed = {}
            self.settings.profiles = {}
            self.settings.rolePreset = "AUTO"
            self:Refresh()
        end)
        menu:CreateDivider()
        local appearance = menu:CreateButton("Paper-doll background")
        for _, option in ipairs({ { "DARK", "Dark" }, { "LIGHT", "Light" } }) do
            local mode, label = option[1], option[2]
            appearance:CreateRadio(label, function()
                return ExtraStatsForeverData.GetBackgroundMode() == mode
            end, function() ExtraStatsForeverData.SetBackgroundMode(mode) end)
        end
    end)
end

function UI:Initialize()
    ExtraStatsForeverSettings = ExtraStatsForeverSettings or {}
    ExtraStatsForeverSettings.stats = ExtraStatsForeverSettings.stats or {}
    self.settings = ExtraStatsForeverSettings.stats
    self.settings.order = self.settings.order or { unpack(ids) }
    -- Earlier versions saved the default order even when never customized.
    if self.settings.orderCustom == nil then
        self.settings.orderCustom = false
        for index, id in ipairs(ids) do
            if self.settings.order[index] ~= id then self.settings.orderCustom = true; break end
        end
    end
    self.settings.collapsed = self.settings.collapsed or {}
    self.settings.profiles = self.settings.profiles or {}
    self.settings.rolePreset = self.settings.rolePreset or "AUTO"
    self.categories, self.byName, self.labels = {}, {}, {}
    local labels = {
        HEALTH=HEALTH, POWER=POWER, MOVESPEED=STAT_MOVEMENT_SPEED, HASTE=STAT_HASTE,
        STRENGTH=SPELL_STAT1_NAME, AGILITY=SPELL_STAT2_NAME, STAMINA=SPELL_STAT3_NAME,
        INTELLECT=SPELL_STAT4_NAME, SPIRIT=SPELL_STAT5_NAME,
        MAINHAND_DAMAGE=INVTYPE_WEAPONMAINHAND, OFFHAND_DAMAGE=INVTYPE_WEAPONOFFHAND,
        RANGED_DAMAGE=DAMAGE, ATTACK_AP=MELEE_ATTACK_POWER, RANGED_ATTACK_AP=RANGED_ATTACK_POWER,
        ATTACK_ATTACKSPEED=WEAPON_SPEED, EXPERTISE=STAT_EXPERTISE, ARMORPEN=STAT_ARMOR_PENETRATION,
        SPELLPOWER=STAT_SPELLPOWER, SPELLHEALING=STAT_SPELLHEALING, MANAREGEN=MANA_REGEN,
        SPELLPENETRATION=SPELL_PENETRATION, ARMOR=STAT_ARMOR, DEFENSE=DEFENSE,
        DODGE=STAT_DODGE, PARRY=STAT_PARRY, BLOCK=STAT_BLOCK,
    }
    for index, id in ipairs(ids) do
        local category = ExtraStatsForeverData.categories[index]
        self.categories[id] = category
        self.byName[category.categoryName] = id
        for _, stat in ipairs(category.stats) do
            local key = stat.stat
            self.labels[key] = labels[key] or (key:match("_CRIT$") and STAT_CRITICAL_STRIKE)
                or (key:match("_HIT$") and STAT_HIT_CHANCE) or key:gsub("_", " "):lower()
        end
    end
    local pane = CharacterStatsPaneScrollBox
    -- Keep the model controls together, directly above the weapon row.
    local viewControls = CharacterModelScene.ControlFrame
    viewControls:ClearAllPoints()
    viewControls:SetPoint("BOTTOM", CharacterSecondaryHandSlot, "TOP", 0, 12)
    self.roleIcons = {}
    local roleAtlases = {
        TANK = "UI-LFG-RoleIcon-Tank",
        HEALER = "UI-LFG-RoleIcon-Healer",
        DAMAGER = "UI-LFG-RoleIcon-DPS",
    }
    for index, role in ipairs({ "TANK", "HEALER", "DAMAGER" }) do
        local choice = role
        local button = CreateFrame("Button", nil, PaperDollItemsFrame)
        button:SetSize(30, 30)
        button:SetPoint("TOP", CharacterModelScene, "TOP", (index - 2) * 30, -10)
        button:SetFrameLevel(PaperDollItemsFrame:GetFrameLevel() + 20)
        button.Icon = button:CreateTexture(nil, "ARTWORK")
        button.Icon:SetAllPoints()
        button.Icon:SetAtlas(roleAtlases[choice])
        button:SetHighlightTexture("Interface\\Buttons\\UI-Common-MouseHilight", "ADD")
        button:RegisterForClicks("LeftButtonUp", "RightButtonUp")
        button:SetScript("OnClick", function(owner, mouseButton)
            if mouseButton == "RightButton" then ExtraStatsForeverOptions:Toggle(); return end
            self.settings.rolePreset = choice
            self:Refresh()
        end)
        button:SetScript("OnEnter", function(owner)
            GameTooltip:SetOwner(owner, "ANCHOR_RIGHT")
            GameTooltip:SetText(roleNames[choice])
            GameTooltip:AddLine("Left-click to select. Right-click for Auto and filters.", 1, 1, 1, true)
            GameTooltip:Show()
        end)
        button:SetScript("OnLeave", function() GameTooltip:Hide() end)
        self.roleIcons[choice] = button
    end
    self.button = CreateFrame("Button", nil, PaperDollSidebarTabs, "SquareIconButtonTemplate")
    self.button:SetSize(28, 28)
    self.button:SetPoint("RIGHT", CharacterFrameRightPaneHostStoneBg, "RIGHT", -8, 0)
    self.button:SetFrameLevel(PaperDollSidebarTabs:GetFrameLevel() + 20)
    self.button:SetAtlas("GM-icon-settings")
    self.button.tooltipText = "ExtraStats settings"
    self.button:SetScript("OnClick", function() ExtraStatsForeverOptions:Toggle() end)
    -- Only visibility changes on Blizzard frames; all data and rows are ours.
    pane.ScrollBox:Hide()
    pane.ScrollBar:Hide()
    -- This unkeyed native divider is anchored to the hidden ScrollBox, but is
    -- owned by the pane itself. Leave the surrounding frame border intact.
    for _, region in ipairs({ pane:GetRegions() }) do
        if region:IsObjectType("Texture") and region:GetAtlas() == "UI-Character-Info-ScrollLine" then
            region:Hide()
        end
    end
    self.scroll = CreateFrame("ScrollFrame", "ExtraStatsForeverStatsScroll", pane)
    -- SmartNavigation reads these methods for both focus-follow and right-stick
    -- scrolling. Expose our public layout model only on this addon-owned frame.
    self.setNativeVerticalScroll = self.scroll.SetVerticalScroll
    self.scroll.GetVerticalScrollRange = function() return self.scrollRange or 0 end
    self.scroll.GetVerticalScroll = function() return self.scrollOffset or 0 end
    self.scroll.SetVerticalScroll = function(_, offset) self:SetScrollOffset(offset) end
    self.scroll:SetPoint("TOPLEFT", pane, "TOPLEFT", 8, -8)
    self.scroll:SetPoint("BOTTOMRIGHT", pane, "BOTTOMRIGHT", -8, 10)
    self.body = CreateFrame("Frame", nil, self.scroll)
    self.body:SetSize(190, 1)
    self.scroll:SetScrollChild(self.body)
    self.scroll:EnableMouseWheel(true)
    self.scrollBar = CreateFrame("EventFrame", "ExtraStatsForeverStatsScrollBar", self.scroll, "MinimalScrollBar")
    self.scrollBar:SetPoint("TOPRIGHT", self.scroll, "TOPRIGHT", -3, -3)
    self.scrollBar:SetPoint("BOTTOMRIGHT", self.scroll, "BOTTOMRIGHT", -3, 3)
    self.scrollBar:SetFrameLevel(self.scroll:GetFrameLevel() + 20)
    self.scrollBar:RegisterCallback(BaseScrollBoxEvents.OnScroll, function(_, percentage)
        if self.syncingScrollBar or not IsPublicNumber(percentage) then return end
        self.syncingScrollBar = true
        self:SetScrollOffset(percentage * (self.scrollRange or 0))
        self.syncingScrollBar = false
    end, self)
    self.scroll:SetScript("OnMouseWheel", function(_, delta)
        if IsPublicNumber(delta) then self:SetScrollOffset((self.scrollOffset or 0) - delta * 30) end
    end)
    self.rows, self.headers = {}, {}
    self.scroll:SetScript("OnSizeChanged", function(scroll, width)
        if IsPublicNumber(width) then self.body:SetWidth(width) end
        self:UpdateScrollMetrics()
    end)
    self.scroll:SetScript("OnShow", function() self:QueueRefresh() end)
    -- Post-hook schedules work after Blizzard's caller has finished securely.
    hooksecurefunc("PaperDollFrame_UpdateStats", function() self:QueueRefresh() end)
    self.ready = true
    self:QueueRefresh()
end

local events = CreateFrame("Frame")
events:RegisterEvent("ADDON_LOADED")
events:SetScript("OnEvent", function(self, event, name)
    if event == "ADDON_LOADED" then
        if name ~= addonName then return end
        self:UnregisterEvent(event)
        UI:Initialize()
        self:RegisterEvent("PLAYER_ROLES_ASSIGNED")
        self:RegisterEvent("TRAIT_CONFIG_UPDATED")
        self:RegisterEvent("PLAYER_TALENT_UPDATE")
        self:RegisterEvent("PLAYER_EQUIPMENT_CHANGED")
        self:RegisterEvent("PLAYER_ENTERING_WORLD")
        self:RegisterEvent("ACTIVE_TALENT_GROUP_CHANGED")
        self:RegisterUnitEvent("PLAYER_SPECIALIZATION_CHANGED", "player")
        self:RegisterUnitEvent("UNIT_DISPLAYPOWER", "player")
        -- Listen directly: the native paper doll refresh does not cover current
        -- resources, and our view must not depend on its hidden stat renderer.
        for _, eventName in ipairs({ "UNIT_HEALTH", "UNIT_POWER_UPDATE", "UNIT_POWER_FREQUENT" }) do
            self:RegisterUnitEvent(eventName, "player")
        end
        for _, eventName in ipairs({
            "UNIT_MAXHEALTH", "UNIT_MAXPOWER", "UNIT_STATS", "UNIT_AURA",
            "UNIT_DAMAGE", "UNIT_ATTACK", "UNIT_ATTACK_POWER", "UNIT_ATTACK_SPEED",
            "UNIT_RANGEDDAMAGE", "UNIT_RANGED_ATTACK_POWER", "UNIT_SPELL_HASTE",
            "UNIT_RESISTANCES", "UNIT_LEVEL",
        }) do
            self:RegisterUnitEvent(eventName, "player")
        end
        for _, eventName in ipairs({
            "COMBAT_RATING_UPDATE", "SPELL_POWER_CHANGED", "PLAYER_DAMAGE_DONE_MODS",
            "SKILL_LINES_CHANGED", "SPEED_UPDATE", "PLAYER_REGEN_DISABLED", "PLAYER_REGEN_ENABLED",
        }) do
            self:RegisterEvent(eventName)
        end
    elseif UI.ready then
        if event == "UNIT_HEALTH" or event == "UNIT_POWER_UPDATE" or event == "UNIT_POWER_FREQUENT" then
            UI:QueueResourceRefresh()
        else
            UI:QueueRefresh()
        end
    end
end)
