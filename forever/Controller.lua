-- Navigation for the addon layout; never change the shared sidebar registry.
local addonName = ...
local _, _, _, interface = GetBuildInfo()
if interface < 16000 or interface >= 17000 then return end
local Controller = {}
ExtraStatsForeverController = Controller

local function Visible(frame)
    return frame and frame:IsShown()
end
local function Jump(source, direction, target)
    if source then SmartNavigation_AddJumpNavigationOverride(source, direction, target) end
end

function Controller:Tabs()
    return { PaperDollSidebarTab1, PaperDollSidebarTab2, PaperDollSidebarTab3, ExtraStatsForeverStats.button }
end

function Controller:FirstContent()
    local ui = ExtraStatsForeverStats
    if ExtraStatsForeverOptions and ExtraStatsForeverOptions.frame and ExtraStatsForeverOptions.frame:IsShown() then
        return ExtraStatsForeverOptions.selector
    end
    if PaperDollFrame.EquipmentManagerPane:IsShown() then
        local gear = PaperDollFrame.EquipmentManagerPane
        return gear.ScrollBox:GetFrames()[1] or gear.NewSet
    elseif CharacterStatsPanePetScrollBox:IsShown() then
        return CharacterStatsPanePetScrollBox.ScrollBox:GetFrames()[1] or PaperDollSidebarTab3
    end
    return ui.navigationRows and ui.navigationRows[1] or PaperDollSidebarTab1
end

function Controller:GearLayout()
    local gear = PaperDollFrame.EquipmentManagerPane
    -- Forever's gamepad transition still anchors to the obsolete InsetRight.
    -- Keep all three actions below the list in both input modes.
    gear.ScrollBox:ClearAllPoints()
    gear.ScrollBox:SetPoint("TOPLEFT", gear, "TOPLEFT", 5, -8)
    gear.ScrollBox:SetPoint("BOTTOMRIGHT", gear, "BOTTOMRIGHT", -20, 105)
    gear.ScrollBar:ClearAllPoints()
    gear.ScrollBar:SetPoint("TOPLEFT", gear.ScrollBox, "TOPRIGHT", -5, -12)
    gear.ScrollBar:SetPoint("BOTTOMLEFT", gear.ScrollBox, "BOTTOMRIGHT", -5, 0)
    gear.NewSet:Show()
    gear.EquipSet:Show()
    gear.SaveSet:Show()
end

function Controller:Refresh()
    if not SmartNavigation or not SMART_NAV_INPUT_DIRECTION then return end
    if ExtraStatsForeverOptions and ExtraStatsForeverOptions.frame and ExtraStatsForeverOptions.frame:IsShown() then
        ExtraStatsForeverOptions:UpdateNavigation()
        return
    end
    local D = SMART_NAV_INPUT_DIRECTION
    local ui, gear = ExtraStatsForeverStats, PaperDollFrame.EquipmentManagerPane
    local tabs, visibleTabs = self:Tabs(), {}
    SmartNavigation_ClearIgnoreStatus(PaperDollSidebarTabs)
    for _, tab in ipairs(tabs) do
        SmartNavigation_ClearIgnoreStatus(tab)
        if Visible(tab) then table.insert(visibleTabs, tab) end
    end
    -- SetUpTabs appends and ignores buttons; supply our private ordered list and
    -- leave the native PAPERDOLL_SIDEBARS/SidebarTabs.Tabs tables untouched.
    local indicators = PaperDollFrame.TabIndicators
    indicators.tabs = tabs
    indicators:UpdateTabVisibility()
    local selected = (ExtraStatsForeverOptions and ExtraStatsForeverOptions.frame and ExtraStatsForeverOptions.frame:IsShown() and ui.button)
        or (gear:IsShown() and PaperDollSidebarTab2)
        or (CharacterStatsPanePetScrollBox:IsShown() and PaperDollSidebarTab3) or PaperDollSidebarTab1
    for index, tab in ipairs(visibleTabs) do
        if tab == selected then indicators:SetCurrentIndex(index) end
        Jump(tab, D.LEFT, visibleTabs[index - 1] or CharacterHandsSlot)
        Jump(tab, D.RIGHT, visibleTabs[index + 1] or ui.button)
        Jump(tab, D.DOWN, function() return self:FirstContent() end)
    end
    indicators:UpdateTabIndicators()
    for index, row in ipairs(ui.navigationRows or {}) do
        Jump(row, D.UP, ui.navigationRows[index - 1] or PaperDollSidebarTab1)
        Jump(row, D.DOWN, ui.navigationRows[index + 1])
        Jump(row, D.LEFT, CharacterHandsSlot)
    end
    local gearRows = gear.ScrollBox:GetFrames()
    for index, row in ipairs(gearRows) do
        Jump(row, D.UP, row.setID == (gear.equipmentSetIDs or {})[1] and PaperDollSidebarTab2 or nil)
        Jump(row, D.DOWN, function()
            -- Allow native scrolling until the actual final set, not just the
            -- final currently instantiated row, is reached.
            local ids = gear.equipmentSetIDs or {}
            if row.setID == ids[#ids] then return gear.NewSet end
        end)
    end
    for _, button in ipairs({ gear.NewSet, gear.EquipSet, gear.SaveSet }) do
        SmartNavigation_ClearIgnoreStatus(button)
        SmartNavigation_MarkFrameFocusable(button)
        Jump(button, D.LEFT, CharacterTrinket1Slot)
    end
    Jump(gear.NewSet, D.UP, function() local rows=gear.ScrollBox:GetFrames(); return rows[#rows] or PaperDollSidebarTab2 end)
    Jump(gear.NewSet, D.DOWN, gear.EquipSet)
    Jump(gear.EquipSet, D.UP, gear.NewSet)
    Jump(gear.SaveSet, D.UP, gear.NewSet)
    Jump(gear.EquipSet, D.RIGHT, gear.SaveSet)
    Jump(gear.SaveSet, D.LEFT, gear.EquipSet)
    for _, slot in ipairs(PaperDollItemsFrame.EquipmentSlots or {}) do
        -- Keep native equipment-to-equipment navigation; only change the entry
        -- route from the right column into the current content pane.
        if slot == CharacterHandsSlot then Jump(slot, D.RIGHT, function() return self:FirstContent() end) end
    end
    Jump(CharacterHeadSlot, D.UP, ui.roleIcons.TANK)
    Jump(ui.roleIcons.TANK, D.RIGHT, ui.roleIcons.HEALER)
    Jump(ui.roleIcons.HEALER, D.LEFT, ui.roleIcons.TANK)
    Jump(ui.roleIcons.HEALER, D.RIGHT, ui.roleIcons.DAMAGER)
    Jump(ui.roleIcons.DAMAGER, D.LEFT, ui.roleIcons.HEALER)
    for _, button in pairs(ui.roleIcons) do Jump(button, D.DOWN, CharacterHeadSlot) end
    Jump(CharacterWristSlot, D.DOWN, CharacterMainHandSlot)
    Jump(ui.button, D.LEFT, visibleTabs[#visibleTabs-1])
    Jump(ui.button, D.DOWN, function() return self:FirstContent() end)
    local resistances = ExtraStatsForeverResistances.rows
    Jump(CharacterHandsSlot, D.LEFT, resistances[1])
    for index, row in ipairs(resistances) do
        Jump(row, D.UP, resistances[index-1] or ui.roleIcons.DAMAGER)
        Jump(row, D.DOWN, resistances[index+1] or CharacterMainHandSlot)
        Jump(row, D.RIGHT, CharacterHandsSlot)
        Jump(row, D.LEFT, CharacterHeadSlot)
    end
    SmartNavigation_MarkFrameIgnored(ui.scrollBar)
    SmartNavigation:RefreshButtonGroups(CharacterFrame)
    if ExtraStatsForeverOptions then ExtraStatsForeverOptions:UpdateNavigation() end
end

function Controller:QueueRefresh()
    if self.pending then return end
    self.pending = true
    C_Timer.After(0, function() self.pending=nil; self:Refresh() end)
end

local events = CreateFrame("Frame")
events:RegisterEvent("ADDON_LOADED")
events:SetScript("OnEvent", function(self, _, name)
    if name ~= addonName then return end
    self:UnregisterEvent("ADDON_LOADED")
    if not SmartNavigation then return end
    local gear = PaperDollFrame.EquipmentManagerPane
    hooksecurefunc(gear, "InitializeGamepad", function() Controller:GearLayout(); Controller:QueueRefresh() end)
    hooksecurefunc(gear, "UninitializeGamepad", function() Controller:GearLayout(); Controller:QueueRefresh() end)
    hooksecurefunc(CharacterFrame, "SetupGamepad", function() Controller:QueueRefresh() end)
    hooksecurefunc(ExtraStatsForeverStats, "Refresh", function() Controller:QueueRefresh() end)
    hooksecurefunc("PaperDollFrame_UpdateSidebarTabs", function() Controller:QueueRefresh() end)
    hooksecurefunc("PaperDollEquipmentManagerPane_Update", function() Controller:QueueRefresh() end)
    gear:HookScript("OnShow", function() Controller:GearLayout(); Controller:QueueRefresh() end)
    for _, tab in ipairs(Controller:Tabs()) do
        tab:HookScript("OnClick", function()
            Controller:Refresh()
            if InputUtil.IsGamepadUIEnabled() and SmartNavigation:GetActiveFrame() == CharacterFrame then
                CharacterFrame:SwapToRightSide()
                SmartNavigation:SelectButton(Controller:FirstContent())
            end
        end)
    end
    -- Native gear-tab handler assumes a nonempty set list. New Set is the
    -- correct landing target when no sets exist.
    PaperDollSidebarTab2:SetScript("OnClick", function(button) PaperDollFrame_SetSidebar(button, 2) end)
    Controller:GearLayout()
    Controller:QueueRefresh()
end)
