local tab = ExtraStats:CreateModule("character.gear")
local EquipmentSet = ExtraStats:GetModule("EquipmentSet")

tab.frame = nil

tab.pendingNewSet = false

ExtraStats_EQUIPMENTSET_BUTTON_HEIGHT = 44
MAX_EQUIPMENT_SETS_PER_PLAYER = 10
NUM_GEARSET_ICONS_SHOWN = 80
NUM_GEARSET_ICONS_PER_ROW = 10
NUM_GEARSET_ICON_ROWS = 8
GEARSET_ICON_ROW_HEIGHT = 36

local STRIPE_COLOR = { r = 0.9, g = 0.9, b = 1 }
local DEFAULT_ICON = 134400
local EQUIPMENT_SET_BUTTON_OFFSET_X = 2
local EQUIPMENT_SET_BUTTON_OFFSET_Y = -24
local EQUIPMENT_SET_TOP_MASK_HEIGHT = 24
local ShowGearSetTooltip
local HideGearSetTooltip
local HookNativeGearSetButtonTooltips
local EnsureGearSetButtonTooltipScripts
local EnsureEquipmentSetButtons
local EnsureEquipmentSetTopMask
local IsFrameUnderCursor
local GetGearSetButtonFromMouseFocus
local ToggleIgnoredSlotForSave
local UpdateIgnoredSlotOverlays
local UpdateEquipmentEditModeVisuals
local HookItemSlotIgnoreEditing
local RestoreItemSlotIgnoreEditing
local SetIgnoredSlotVisual
local ClearIgnoredSlotVisuals

local itemSlotButtons = {
    CharacterHeadSlot,
    CharacterNeckSlot,
    CharacterShoulderSlot,
    CharacterShirtSlot,
    CharacterChestSlot,
    CharacterWaistSlot,
    CharacterLegsSlot,
    CharacterFeetSlot,
    CharacterWristSlot,
    CharacterHandsSlot,
    CharacterFinger0Slot,
    CharacterFinger1Slot,
    CharacterTrinket0Slot,
    CharacterTrinket1Slot,
    CharacterBackSlot,
    CharacterMainHandSlot,
    CharacterSecondaryHandSlot,
    CharacterRangedSlot,
    CharacterTabardSlot,
}

local ignoreEditToggleButtons = {}
local EM_ICON_FILENAMES = {}

local function BuildEquipMacroBody(setName)
    local safeName = tostring(setName):gsub('"', "'")
    return "/stats equip \"" .. safeName .. "\""
end

local function BuildMacroName(setName)
    local name = "ES " .. tostring(setName or "")
    if #name > 16 then
        name = string.sub(name, 1, 16)
    end
    return name
end

local function IterateMacros()
    local numGlobal, numCharacter = GetNumMacros()
    local total = numGlobal + numCharacter
    local data = {}

    for i = 1, total do
        local name, icon, body = GetMacroInfo(i)
        if name then
            data[#data + 1] = { id = i, name = name, icon = icon, body = body }
        end
    end

    return data
end

local function FindEquipMacrosBySetName(setName)
    local body = BuildEquipMacroBody(setName)
    local matches = {}

    for _, macro in ipairs(IterateMacros()) do
        if macro.body == body then
            matches[#matches + 1] = macro
        end
    end

    return matches
end

local function EnsureEquipMacro(setName, iconTexture)
    local matches = FindEquipMacrosBySetName(setName)
    local body = BuildEquipMacroBody(setName)
    local icon = iconTexture or DEFAULT_ICON
    if #matches > 0 then
        local macro = matches[1]
        EditMacro(macro.id, BuildMacroName(setName), icon, body)
        return macro.id
    end

    local numGlobal, numCharacter = GetNumMacros()
    if numCharacter < MAX_CHARACTER_MACROS then
        return CreateMacro(BuildMacroName(setName), icon, body, true)
    end
    if numGlobal < MAX_ACCOUNT_MACROS then
        return CreateMacro(BuildMacroName(setName), icon, body, false)
    end
    return nil
end

local function RenameEquipMacros(oldName, newName, iconTexture)
    if not oldName or not newName or oldName == newName then
        return
    end

    local macros = FindEquipMacrosBySetName(oldName)
    local body = BuildEquipMacroBody(newName)
    local icon = iconTexture or DEFAULT_ICON

    for _, macro in ipairs(macros) do
        EditMacro(macro.id, BuildMacroName(newName), icon, body)
    end
end

local function UpdateEquipMacros(setName, iconTexture)
    if not setName then
        return
    end

    local macros = FindEquipMacrosBySetName(setName)
    local body = BuildEquipMacroBody(setName)
    local icon = iconTexture or DEFAULT_ICON

    for _, macro in ipairs(macros) do
        EditMacro(macro.id, BuildMacroName(setName), icon, body)
    end
end

local function DeleteEquipMacros(setName)
    local macros = FindEquipMacrosBySetName(setName)
    table.sort(macros, function(a, b)
        return a.id > b.id
    end)

    for _, macro in ipairs(macros) do
        DeleteMacro(macro.id)
    end
end

local function GetSetIDsSorted()
    local ids = EquipmentSet:GetEquipmentSetIDs()
    table.sort(ids, function(a, b)
        local aName = select(1, EquipmentSet:GetEquipmentSetInfo(a)) or ""
        local bName = select(1, EquipmentSet:GetEquipmentSetInfo(b)) or ""
        return aName < bName
    end)
    return ids
end

local function IgnoreDefaultNewSetSlots()
    ExtraStats_PaperDollFrame_IgnoreSlot(INVSLOT_BODY)
    ExtraStats_PaperDollFrame_IgnoreSlot(INVSLOT_TABARD)
end

local function ApplyIgnoredSlotsForSet(setID)
    ClearIgnoredSlotVisuals()

    if not setID then
        EquipmentSet:ClearIgnoredSlotsForSave()
        UpdateIgnoredSlotOverlays()
        return
    end

    local ignored = EquipmentSet:GetIgnoredSlots(setID)
    EquipmentSet:SetIgnoredSlotsForSave(ignored)
    for slotID, isIgnored in pairs(ignored) do
        if isIgnored then
            SetIgnoredSlotVisual(slotID, true)
        end
    end
    UpdateIgnoredSlotOverlays()
end

local function SelectSetByID(setID)
    if not setID then
        tab.frame.selectedSetID = nil
        tab.frame.selectedSetName = nil
        ApplyIgnoredSlotsForSet(nil)
        return
    end

    local name = select(1, EquipmentSet:GetEquipmentSetInfo(setID))
    if not name then
        tab.frame.selectedSetID = nil
        tab.frame.selectedSetName = nil
        ApplyIgnoredSlotsForSet(nil)
        return
    end

    tab.frame.selectedSetID = setID
    tab.frame.selectedSetName = name
    ApplyIgnoredSlotsForSet(setID)
end

local function SelectCurrentlyEquippedSet()
    for _, setID in ipairs(GetSetIDsSorted()) do
        local _, _, _, isEquipped = EquipmentSet:GetEquipmentSetInfo(setID)
        if isEquipped then
            SelectSetByID(setID)
            return true
        end
    end

    SelectSetByID(nil)
    return false
end

StaticPopupDialogs["CONFIRM_SAVE_EQUIPMENT_SET"] = {
    text = CONFIRM_SAVE_EQUIPMENT_SET,
    button1 = YES,
    button2 = NO,
    OnAccept = function(self)
        local setID = self.data
        if setID then
            EquipmentSet:SaveEquipmentSet(setID)
            local setName, setIcon = EquipmentSet:GetEquipmentSetInfo(setID)
            UpdateEquipMacros(setName, setIcon)
            ExtraStats_PaperDollEquipmentManagerPane_Update()
        end
    end,
    OnHide = function(self)
        self.data = nil
    end,
    hideOnEscape = 1,
    timeout = 0,
    exclusive = 1,
    whileDead = 1,
}

StaticPopupDialogs["CONFIRM_DELETE_EQUIPMENT_SET"] = {
    text = CONFIRM_DELETE_EQUIPMENT_SET,
    button1 = YES,
    button2 = NO,
    OnAccept = function(self)
        local setID = self.data
        if setID then
            local setName = select(1, EquipmentSet:GetEquipmentSetInfo(setID))
            local selectedName = tab.frame and tab.frame.selectedSetName
            EquipmentSet:DeleteEquipmentSet(setID)
            DeleteEquipMacros(setName)
            if selectedName == setName then
                SelectSetByID(nil)
            elseif selectedName then
                local selectedID = EquipmentSet:GetEquipmentSetID(selectedName)
                SelectSetByID(selectedID)
            end
            ExtraStats_PaperDollEquipmentManagerPane_Update()
        end
    end,
    OnHide = function(self)
        self.data = nil
    end,
    hideOnEscape = 1,
    timeout = 0,
    exclusive = 1,
    whileDead = 1,
}

StaticPopupDialogs["ExtraStats_CONFIRM_OVERWRITE_EQUIPMENT_SET"] = {
    text = CONFIRM_OVERWRITE_EQUIPMENT_SET or "Overwrite equipment set %s?",
    button1 = YES,
    button2 = NO,
    OnAccept = function(self)
        local setID = self.data
        if setID then
            local popup = ExtraStats_GearManagerDialogPopup
            local oldName = select(1, EquipmentSet:GetEquipmentSetInfo(setID))
            EquipmentSet:ModifyEquipmentSet(setID, popup.name, self.selectedIcon)
            EquipmentSet:SaveEquipmentSet(setID)
            RenameEquipMacros(oldName, popup.name, self.selectedIcon)
            UpdateEquipMacros(popup.name, self.selectedIcon)
            SelectSetByID(setID)
            popup:Hide()
            ExtraStats_PaperDollEquipmentManagerPane_Update()
        end
    end,
    OnHide = function(self)
        self.data = nil
        self.selectedIcon = nil
    end,
    hideOnEscape = 1,
    timeout = 0,
    exclusive = 1,
    whileDead = 1,
}

function ExtraStats_PaperDollEquipmentManagerPane_OnLoad(self)
    HookNativeGearSetButtonTooltips()
    HybridScrollFrame_OnLoad(self)
    EnsureEquipmentSetTopMask(self)
    self.update = ExtraStats_PaperDollEquipmentManagerPane_Update

    self:RegisterEvent("EQUIPMENT_SWAP_FINISHED")
    self:RegisterEvent("EQUIPMENT_SETS_CHANGED")
    self:RegisterEvent("PLAYER_EQUIPMENT_CHANGED")
    self:RegisterEvent("BAG_UPDATE")

    ExtraStats:On("gear.update", function()
        if self and self:IsShown() then
            ExtraStats_PaperDollEquipmentManagerPane_Update()
        end
    end)
    ExtraStats:On("gear.swap.finished", function(success, setID)
        if success and setID and tab.frame and self:IsShown() then
            SelectSetByID(setID)
            ExtraStats_PaperDollEquipmentManagerPane_Update()
        end
    end)
end

function ExtraStats_PaperDollEquipmentManagerPane_OnShow(self)
    self.equipmentEditMode = true
    HookItemSlotIgnoreEditing()
    EnsureEquipmentSetTopMask(self)
    EnsureEquipmentSetButtons(self)
    SelectCurrentlyEquippedSet()
    UpdateEquipmentEditModeVisuals()
    ExtraStats_PaperDollEquipmentManagerPane_Update()
    C_Timer.After(0, function()
        if self and self:IsShown() then
            EnsureEquipmentSetButtons(self)
            ExtraStats_PaperDollEquipmentManagerPane_Update()
        end
    end)
    ExtraStats:Trigger("gear.tab.show", self)
end

function ExtraStats_PaperDollEquipmentManagerPane_OnHide(self)
    self.equipmentEditMode = nil
    RestoreItemSlotIgnoreEditing()
    ExtraStats_PaperDollFrame_ClearIgnoredSlots()
    UpdateEquipmentEditModeVisuals()
    ExtraStats_GearManagerDialogPopup:Hide()
    StaticPopup_Hide("CONFIRM_SAVE_EQUIPMENT_SET")
    StaticPopup_Hide("CONFIRM_DELETE_EQUIPMENT_SET")
    StaticPopup_Hide("ExtraStats_CONFIRM_OVERWRITE_EQUIPMENT_SET")
    ExtraStats:Trigger("gear.tab.hide", self)
end

function ExtraStats_PaperDollEquipmentManagerPane_OnEvent(self, event, ...)
    if event == "EQUIPMENT_SWAP_FINISHED" then
        local completed, setID = ...
        if completed and setID and self:IsShown() then
            PlaySound(SOUNDKIT.PUT_DOWN_SMALL_CHAIN)
            SelectSetByID(setID)
        end
    end

    if self:IsShown() then
        self.queuedUpdate = true
    end
end

function ExtraStats_PaperDollEquipmentManagerPane_OnUpdate(self)
    if self.queuedUpdate then
        ExtraStats_PaperDollEquipmentManagerPane_Update()
        self.queuedUpdate = false
    end

    local now = GetTime()
    if self.lastHoverUpdate and (now - self.lastHoverUpdate) < 0.1 then
        return
    end
    self.lastHoverUpdate = now

    local isEquipInProgress = EquipmentSet:IsEquipmentSwapActive()
    if isEquipInProgress then
        HideGearSetTooltip(self.hoveredSetButton)
        self.hoveredSetButton = nil
        for i = 1, #(self.buttons or {}) do
            local button = self.buttons[i]
            button.DeleteButton:Hide()
            button.EditButton:Hide()
            button.HighlightBar:Hide()
        end
        return
    end

    local hoveredSetButton = GetGearSetButtonFromMouseFocus(self)
    if not hoveredSetButton then
        for i = 1, #(self.buttons or {}) do
            local button = self.buttons[i]
            if button:IsShown() and button.name and button.IsMouseOver and button:IsMouseOver() then
                hoveredSetButton = button
                break
            end
            if button.DeleteButton and button.DeleteButton:IsShown() and button.DeleteButton.IsMouseOver and button.DeleteButton:IsMouseOver() then
                hoveredSetButton = button
                break
            end
            if button.EditButton and button.EditButton:IsShown() and button.EditButton.IsMouseOver and button.EditButton:IsMouseOver() then
                hoveredSetButton = button
                break
            end
        end
    end

    for i = 1, #(self.buttons or {}) do
        local button = self.buttons[i]
        if button == hoveredSetButton and button.name then
            hoveredSetButton = button
            if button.EditButton and button.EditButton.Dropdown then
                button.EditButton.Dropdown.gearSetButton = button
            end
            button.DeleteButton:Show()
            button.EditButton:Show()
            button.HighlightBar:Show()
        else
            button.DeleteButton:Hide()
            button.EditButton:Hide()
            button.HighlightBar:Hide()
        end
    end

    if hoveredSetButton ~= self.hoveredSetButton then
        HideGearSetTooltip(self.hoveredSetButton)
        self.hoveredSetButton = hoveredSetButton
    end

    if hoveredSetButton and hoveredSetButton.name and GameTooltip.extraStatsGearSetButton ~= hoveredSetButton and not IsFrameUnderCursor(hoveredSetButton.DeleteButton) and not IsFrameUnderCursor(hoveredSetButton.EditButton) then
        ShowGearSetTooltip(hoveredSetButton)
    end
end

function ExtraStats_PaperDollEquipmentManagerPaneEquipSet_OnClick(index)
    local setID = index
    if type(setID) ~= "number" then
        setID = tab.frame.selectedSetID
    end

    if not setID then
        return
    end

    PlaySound(SOUNDKIT.IG_CHARACTER_INFO_TAB)
    EquipmentSet:UseEquipmentSet(setID)
end

function ExtraStats_PaperDollEquipmentManagerPaneSaveSet_OnClick()
    local setID = tab.frame.selectedSetID
    if not setID then
        return
    end

    local setName = tab.frame.selectedSetName or ""
    local dialog = StaticPopup_Show("CONFIRM_SAVE_EQUIPMENT_SET", setName)
    if dialog then
        dialog.data = setID
    end
end

EnsureGearSetButtonTooltipScripts = function(button)
    if not button then
        return
    end

    local parent = button:GetParent()
    if parent and parent.GetFrameLevel and button.SetFrameLevel then
        button:SetFrameLevel((parent:GetFrameLevel() or 0) + 2)
    end
    if button.SetHitRectInsets then
        button:SetHitRectInsets(0, 0, 0, 0)
    end
    button:EnableMouse(true)
    button:SetScript("OnEnter", function(self)
        ShowGearSetTooltip(self)
    end)
    button:SetScript("OnLeave", function(self)
        HideGearSetTooltip(self)
    end)
end

EnsureEquipmentSetButtons = function(frame)
    if not frame then
        return
    end

    local frameHeight = frame.GetHeight and frame:GetHeight() or 0
    if frameHeight <= math.abs(EQUIPMENT_SET_BUTTON_OFFSET_Y) then
        return
    end

    if not frame.extraStatsGearSetButtonsInitialized then
        frame.buttons = nil
        HybridScrollFrame_CreateButtons(frame, "ExtraGearSetButtonTemplate", EQUIPMENT_SET_BUTTON_OFFSET_X, EQUIPMENT_SET_BUTTON_OFFSET_Y)
        frame.extraStatsGearSetButtonsInitialized = frame.buttons and #frame.buttons > 0
    elseif not frame.buttons or #frame.buttons == 0 then
        frame.extraStatsGearSetButtonsInitialized = nil
        HybridScrollFrame_CreateButtons(frame, "ExtraGearSetButtonTemplate", EQUIPMENT_SET_BUTTON_OFFSET_X, EQUIPMENT_SET_BUTTON_OFFSET_Y)
        frame.extraStatsGearSetButtonsInitialized = frame.buttons and #frame.buttons > 0
    end

    local activeScrollChild = frame.GetScrollChild and frame:GetScrollChild()
    if activeScrollChild then
        frame.scrollChild = activeScrollChild
        frame.ScrollChild = activeScrollChild
    end

    for _, button in ipairs(frame.buttons or {}) do
        if button.EditButton and button.EditButton.Dropdown then
            button.EditButton.Dropdown.gearSetButton = button
        end
        EnsureGearSetButtonTooltipScripts(button)
    end
end

EnsureEquipmentSetTopMask = function(frame)
    if not frame then
        return
    end

    if not frame.ExtraStatsTopMask then
        local mask = CreateFrame("Frame", nil, frame)
        mask:SetPoint("TOPLEFT", frame, "TOPLEFT", 0, 0)
        mask:SetPoint("TOPRIGHT", frame, "TOPRIGHT", 0, 0)
        mask:SetHeight(EQUIPMENT_SET_TOP_MASK_HEIGHT)
        mask:EnableMouse(false)

        local texture = mask:CreateTexture(nil, "BACKGROUND")
        texture:SetAllPoints()
        if texture.SetColorTexture then
            texture:SetColorTexture(0, 0, 0, 0.72)
        else
            texture:SetTexture(0, 0, 0, 0.72)
        end
        mask.Texture = texture
        frame.ExtraStatsTopMask = mask
    end

    local baseFrameLevel = frame.GetFrameLevel and frame:GetFrameLevel() or 0
    frame.ExtraStatsTopMask:SetFrameLevel(baseFrameLevel + 3)
    if frame.EquipSet and frame.EquipSet.SetFrameLevel then
        frame.EquipSet:SetFrameLevel(baseFrameLevel + 4)
    end
    if frame.SaveSet and frame.SaveSet.SetFrameLevel then
        frame.SaveSet:SetFrameLevel(baseFrameLevel + 4)
    end
end

IsFrameUnderCursor = function(frame)
    if not frame or not frame.GetRect or not frame:IsShown() then
        return false
    end

    if frame.IsMouseOver and frame:IsMouseOver() then
        return true
    end

    local left, bottom, width, height = frame:GetRect()
    if not left or not bottom or not width or not height then
        return false
    end

    local cursorX, cursorY = GetCursorPosition()
    local scale = frame:GetEffectiveScale() or UIParent:GetEffectiveScale() or 1
    cursorX = cursorX / scale
    cursorY = cursorY / scale

    return cursorX >= left and cursorX <= (left + width) and cursorY >= bottom and cursorY <= (bottom + height)
end

GetGearSetButtonFromMouseFocus = function(frame)
    if not frame then
        return nil
    end

    local mouseFocuses = {}
    if GetMouseFoci then
        mouseFocuses = { GetMouseFoci() }
    elseif GetMouseFocus then
        mouseFocuses = { GetMouseFocus() }
    end

    for _, focus in ipairs(mouseFocuses) do
        local depth = 0
        while focus and depth < 8 do
            for i = 1, #(frame.buttons or {}) do
                local button = frame.buttons[i]
                if focus == button or focus == button.DeleteButton or focus == button.EditButton then
                    return button
                end
            end
            focus = focus.GetParent and focus:GetParent()
            depth = depth + 1
        end
    end

    return nil
end

function ExtraStats_PaperDollEquipmentManagerPane_Update()
    if not tab.frame then
        return
    end

    EnsureEquipmentSetButtons(tab.frame)

    local selectedSetID = tab.frame.selectedSetID
    if selectedSetID and not EquipmentSet:GetEquipmentSetInfo(selectedSetID) then
        SelectSetByID(nil)
        selectedSetID = nil
    end

    local isEquipInProgress = EquipmentSet:IsEquipmentSwapActive()
    local selectedSetName, _, _, isEquipped = EquipmentSet:GetEquipmentSetInfo(selectedSetID or 0)
    if selectedSetID and selectedSetName and not isEquipInProgress then
        ExtraStatsPaperDollEquipmentManagerPaneSaveSet:Enable()
        if isEquipped then
            ExtraStatsPaperDollEquipmentManagerPaneEquipSet:Disable()
        else
            ExtraStatsPaperDollEquipmentManagerPaneEquipSet:Enable()
        end
    else
        ExtraStatsPaperDollEquipmentManagerPaneSaveSet:Disable()
        ExtraStatsPaperDollEquipmentManagerPaneEquipSet:Disable()
    end

    local ids = GetSetIDsSorted()
    local numSets = #ids
    local numRows = numSets
    if numSets < MAX_EQUIPMENT_SETS_PER_PLAYER then
        numRows = numRows + 1
    end

    HybridScrollFrame_Update(tab.frame, numRows * ExtraStats_EQUIPMENTSET_BUTTON_HEIGHT + math.abs(EQUIPMENT_SET_BUTTON_OFFSET_Y), tab.frame:GetHeight())

    local scrollOffset = HybridScrollFrame_GetOffset(tab.frame)
    local buttons = tab.frame.buttons or {}

    for i = 1, #buttons do
        local row = i + scrollOffset
        local button = buttons[i]
        if row <= numRows then
            EnsureGearSetButtonTooltipScripts(button)
            button:Show()
            button.setID = nil

            if row <= numSets then
                local setID = ids[row]
                local name, icon, _, setEquipped, numLost = EquipmentSet:GetEquipmentSetInfo(setID)

                button.name = name
                button.iconTexture = icon
                button.setID = setID
                button.text:SetText(name)
                if (numLost or 0) > 0 then
                    button.text:SetTextColor(RED_FONT_COLOR.r, RED_FONT_COLOR.g, RED_FONT_COLOR.b)
                else
                    button.text:SetTextColor(NORMAL_FONT_COLOR.r, NORMAL_FONT_COLOR.g, NORMAL_FONT_COLOR.b)
                end

                button.icon:SetTexture(icon or "Interface\\Icons\\INV_Misc_QuestionMark")
                button.icon:SetSize(36, 36)
                button.icon:SetPoint("LEFT", 4, 0)

                button.Check:SetShown(setEquipped == true)
                button.SelectedBar:SetShown(button.setID == tab.frame.selectedSetID)
                if isEquipInProgress then
                    button:Disable()
                    button.DeleteButton:Hide()
                    button.EditButton:Hide()
                else
                    button:Enable()
                end
            else
                button.name = nil
                button.iconTexture = nil
                button.text:SetText(PAPERDOLL_NEWEQUIPMENTSET)
                button.text:SetTextColor(GREEN_FONT_COLOR.r, GREEN_FONT_COLOR.g, GREEN_FONT_COLOR.b)
                button.text:ClearAllPoints()
                button.text:SetPoint("LEFT", button.icon, "RIGHT", 4, 0)
                button.icon:SetTexture("Interface\\PaperDollInfoFrame\\Character-Plus")
                button.icon:SetSize(30, 30)
                button.icon:SetPoint("LEFT", 7, 0)
                button.Check:Hide()
                button.SelectedBar:Hide()
                if isEquipInProgress then
                    button:Disable()
                else
                    button:Enable()
                end
            end

            if button.setID then
                button.text:ClearAllPoints()
                button.text:SetPoint("TOPLEFT", 44, -5)
            end

            button.BgTop:Hide()
            button.BgBottom:Hide()
            button.BgMiddle:Hide()
            button.BgMiddle:SetPoint("TOP")
            button.BgMiddle:SetPoint("BOTTOM")

            if row % 2 == 0 then
                button.Stripe:SetColorTexture(STRIPE_COLOR.r, STRIPE_COLOR.g, STRIPE_COLOR.b)
                button.Stripe:SetAlpha(0.1)
                button.Stripe:Show()
            else
                button.Stripe:Hide()
            end

            GearSetButton_UpdateSpecInfo(button)
        else
            button:Hide()
        end
    end
end

function ExtraStats_GetEquipmentSetInfoByName(arg)
    return EquipmentSet:GetEquipmentSetInfoByName(arg)
end

ShowGearSetTooltip = function(button)
    if not button then
        return
    end

    local setName = button.name
    if (not setName or setName == "") and button.setID then
        setName = select(1, EquipmentSet:GetEquipmentSetInfo(button.setID))
    end
    if not setName or setName == "" then
        return
    end

    local setID = button.setID or EquipmentSet:GetEquipmentSetID(setName)
    local _, _, _, isEquipped, numLost = EquipmentSet:GetEquipmentSetInfo(setID or 0)

    GameTooltip:SetOwner(button, "ANCHOR_RIGHT")
    GameTooltip:ClearLines()
    GameTooltip:SetText(setName, HIGHLIGHT_FONT_COLOR.r, HIGHLIGHT_FONT_COLOR.g, HIGHLIGHT_FONT_COLOR.b)
    if setID then
        if isEquipped then
            GameTooltip:AddLine(EQUIPPED or "Equipped", GREEN_FONT_COLOR.r, GREEN_FONT_COLOR.g, GREEN_FONT_COLOR.b)
        elseif (numLost or 0) > 0 then
            GameTooltip:AddLine((numLost == 1 and "1 missing item" or tostring(numLost) .. " missing items"), RED_FONT_COLOR.r, RED_FONT_COLOR.g, RED_FONT_COLOR.b)
        else
            GameTooltip:AddLine(EQUIPSET_EQUIP or "Equip Set", NORMAL_FONT_COLOR.r, NORMAL_FONT_COLOR.g, NORMAL_FONT_COLOR.b)
        end

        local missingItems = EquipmentSet:GetMissingEquipmentSetItems(setID)
        if #missingItems > 0 then
            GameTooltip:AddLine(" ")
            GameTooltip:AddLine("Missing items:", RED_FONT_COLOR.r, RED_FONT_COLOR.g, RED_FONT_COLOR.b)
            for _, item in ipairs(missingItems) do
                GameTooltip:AddLine(item.slotLabel .. " -> " .. item.itemName, HIGHLIGHT_FONT_COLOR.r, HIGHLIGHT_FONT_COLOR.g, HIGHLIGHT_FONT_COLOR.b)
            end
        end
    end
    GameTooltip.extraStatsGearSetButton = button
    GameTooltip:Show()
end

HideGearSetTooltip = function(button)
    if GameTooltip.extraStatsGearSetButton == button then
        GameTooltip.extraStatsGearSetButton = nil
        GameTooltip:Hide()
    end
end

function ExtraStats_GearSetButton_OnEnter(self)
    ShowGearSetTooltip(self)
end

function ExtraStats_GearSetButton_OnLeave(self)
    HideGearSetTooltip(self)
end

HookNativeGearSetButtonTooltips = function()
    if tab.nativeGearSetTooltipHooksApplied then
        return
    end

    local hooked = false
    if type(GearSetButton_OnEnter) == "function" and type(hooksecurefunc) == "function" then
        hooksecurefunc("GearSetButton_OnEnter", function(button)
            ShowGearSetTooltip(button)
        end)
        hooked = true
    end

    if type(GearSetButton_OnLeave) == "function" and type(hooksecurefunc) == "function" then
        hooksecurefunc("GearSetButton_OnLeave", function(button)
            HideGearSetTooltip(button)
        end)
        hooked = true
    end

    tab.nativeGearSetTooltipHooksApplied = hooked
end

function ExtraStats_GearSetButton_OnClick(self, button)
    if button == "RightButton" and self.setID and self.EditButton and self.EditButton.Dropdown then
        ExtraStats_GearManagerDialogPopup:Hide()
        PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON)
        SelectSetByID(self.setID)
        ExtraStats_PaperDollEquipmentManagerPane_Update()

        if self.EditButton.Dropdown.gearSetButton ~= self then
            HideDropDownMenu(1)
            self.EditButton.Dropdown.gearSetButton = self
        end

        ToggleDropDownMenu(1, nil, self.EditButton.Dropdown, self, 0, 0)
        return
    end

    if self.setID then
        ExtraStats_GearManagerDialogPopup:Hide()
        PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON)
        SelectSetByID(self.setID)
        ExtraStats_PaperDollEquipmentManagerPane_Update()
        return
    end

    tab.pendingNewSet = true
    SelectSetByID(nil)
    EquipmentSet:ClearIgnoredSlotsForSave()
    IgnoreDefaultNewSetSlots()
    ExtraStats_GearManagerDialogPopup:Show()
end

function ExtraStats_GearSetButton_OnDoubleClick(self)
    if self.setID then
        ExtraStats_PaperDollEquipmentManagerPaneEquipSet_OnClick(self.setID)
    end
end

function ExtraStats_GearSetButton_OnDragStart(self)
    if not self.setID or not self.name then
        return
    end

    if InCombatLockdown() then
        UIErrorsFrame:AddMessage(ERR_CLIENT_LOCKED_OUT, 1.0, 0.1, 0.1, 1.0)
        return
    end

    local macroID = EnsureEquipMacro(self.name, self.iconTexture)
    if macroID then
        PickupMacro(macroID)
    else
        UIErrorsFrame:AddMessage(ERR_MACRO_LIMIT, 1.0, 0.1, 0.1, 1.0)
    end
end

local function EnsureIgnoredSlotOverlay(button)
    if not button then
        return
    end

    if button.ExtraStatsIgnoredOverlay then
        button.ExtraStatsIgnoredOverlay:Hide()
    end

    if button.ignoreTexture then
        return
    end

    local overlay = button:CreateTexture(nil, "OVERLAY")
    overlay:SetTexture("Interface\\PaperDollInfoFrame\\UI-GearManager-LeaveItem-Transparent")
    overlay:SetSize(40, 40)
    overlay:SetPoint("CENTER", button, "CENTER", 0, 0)
    overlay:Hide()

    button.ignoreTexture = overlay
end

local function UpdateIgnoreEditToggle(button)
    local toggle = button and ignoreEditToggleButtons[button]
    if not toggle then
        return
    end

    local ignored = button.ignored == true
    toggle:SetNormalTexture(ignored
        and "Interface\\Buttons\\UI-PlusButton-Up"
        or "Interface\\Buttons\\UI-MinusButton-Up")
end

local function EnsureIgnoreEditToggle(button)
    if not button or ignoreEditToggleButtons[button] then
        return
    end

    local toggle = CreateFrame("Button", nil, button)
    toggle:SetSize(18, 18)
    toggle:SetPoint("TOPRIGHT", button, "TOPRIGHT", 1, 1)
    toggle:SetFrameLevel(button:GetFrameLevel() + 10)
    toggle:RegisterForClicks("LeftButtonUp")

    toggle:SetHighlightTexture("Interface\\Buttons\\UI-PlusButton-Hilight", "ADD")
    toggle:SetScript("OnClick", function(self)
        ToggleIgnoredSlotForSave(self.slotID)
    end)
    toggle:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        if self.slotButton.ignored then
            GameTooltip:SetText("Include this slot")
            GameTooltip:AddLine("The equipped item will be saved with this equipment set.", 1, 1, 1, true)
        else
            GameTooltip:SetText("Ignore this slot")
            GameTooltip:AddLine("Changes to this slot will not be saved with this equipment set.", 1, 1, 1, true)
        end
        GameTooltip:Show()
    end)
    toggle:SetScript("OnLeave", function()
        GameTooltip:Hide()
    end)
    toggle:Hide()

    toggle.slotID = button:GetID()
    toggle.slotButton = button
    ignoreEditToggleButtons[button] = toggle
    UpdateIgnoreEditToggle(button)
end

UpdateEquipmentEditModeVisuals = function()
    local shown = tab.frame and tab.frame.equipmentEditMode == true
    for _, button in ipairs(itemSlotButtons) do
        if button then
            EnsureIgnoreEditToggle(button)
            UpdateIgnoreEditToggle(button)
            ignoreEditToggleButtons[button]:SetShown(shown == true)
        end
    end
end

UpdateIgnoredSlotOverlays = function()
    local shown = tab.frame and tab.frame.equipmentEditMode == true
    for _, button in ipairs(itemSlotButtons) do
        if button then
            EnsureIgnoredSlotOverlay(button)
            if button.ignoreTexture then
                button.ignoreTexture:SetShown(shown == true and button.ignored == true)
            end
        end
    end
end

local function IsIgnoringSlotsEditable()
    return tab.frame and tab.frame.equipmentEditMode == true
end

ToggleIgnoredSlotForSave = function(slotID)
    if not IsIgnoringSlotsEditable() or not slotID then
        return false
    end

    local ignored = not EquipmentSet:IsSlotIgnoredForSave(slotID)
    if ignored then
        EquipmentSet:IgnoreSlotForSave(slotID)
    else
        EquipmentSet:UnignoreSlotForSave(slotID)
    end

    if tab.frame.selectedSetID then
        EquipmentSet:SetEquipmentSetSlotIgnored(tab.frame.selectedSetID, slotID, ignored)
    end

    SetIgnoredSlotVisual(slotID, ignored)
    return true
end

HookItemSlotIgnoreEditing = function()
    for _, button in ipairs(itemSlotButtons) do
        if button then
            EnsureIgnoredSlotOverlay(button)
            EnsureIgnoreEditToggle(button)
            ignoreEditToggleButtons[button]:SetShown(IsIgnoringSlotsEditable())
        end
    end
end

RestoreItemSlotIgnoreEditing = function()
    for _, button in ipairs(itemSlotButtons) do
        if button and ignoreEditToggleButtons[button] then
            ignoreEditToggleButtons[button]:Hide()
        end
    end
end

SetIgnoredSlotVisual = function(slot, ignored)
    local button = itemSlotButtons[slot]
    if not button then
        return
    end

    button.ignored = ignored == true or nil
    PaperDollItemSlotButton_Update(button)
    UpdateIgnoreEditToggle(button)
    UpdateIgnoredSlotOverlays()
end

ClearIgnoredSlotVisuals = function()
    for _, button in ipairs(itemSlotButtons) do
        if button and button.ignored then
            button.ignored = nil
            PaperDollItemSlotButton_Update(button)
            UpdateIgnoreEditToggle(button)
        end
    end
    UpdateIgnoredSlotOverlays()
end

function ExtraStats_PaperDollFrame_ClearIgnoredSlots()
    EquipmentSet:ClearIgnoredSlotsForSave()
    ClearIgnoredSlotVisuals()
end

function ExtraStats_PaperDollFrame_IgnoreSlot(slot)
    EquipmentSet:IgnoreSlotForSave(slot)
    SetIgnoredSlotVisual(slot, true)
end

function ExtraStats_PaperDollFrame_IgnoreSlotsForSet(setID)
    ApplyIgnoredSlotsForSet(setID)
end

function ExtraStats_GearSetDeleteButton_OnClick(self)
    if not self:GetParent().setID then
        return
    end

    local dialog = StaticPopup_Show("CONFIRM_DELETE_EQUIPMENT_SET", self:GetParent().name)
    if dialog then
        dialog.data = self:GetParent().setID
    end
end

local function RebuildIconList()
    wipe(EM_ICON_FILENAMES)
    EM_ICON_FILENAMES[1] = DEFAULT_ICON

    local seen = {}
    seen[DEFAULT_ICON] = true

    for slot = INVSLOT_FIRST_EQUIPPED, INVSLOT_LAST_EQUIPPED do
        local texture = GetInventoryItemTexture("player", slot)
        if texture and not seen[texture] then
            seen[texture] = true
            EM_ICON_FILENAMES[#EM_ICON_FILENAMES + 1] = texture
        end
    end

    GetMacroItemIcons(EM_ICON_FILENAMES)
    GetMacroIcons(EM_ICON_FILENAMES)
end

function ExtraStats_GetEquipmentSetIconInfo(index)
    return EM_ICON_FILENAMES[index]
end

function ExtraStats_RefreshEquipmentSetIconInfo()
    RebuildIconList()
end

function ExtraStats_GearManagerDialogPopup_Update()
    RebuildIconList()

    local popup = ExtraStats_GearManagerDialogPopup
    local offset = FauxScrollFrame_GetOffset(ExtraStats_GearManagerDialogPopupScrollFrame) or 0

    for i = 1, NUM_GEARSET_ICONS_SHOWN do
        local button = popup.buttons[i]
        local index = (offset * NUM_GEARSET_ICONS_PER_ROW) + i
        if index <= #EM_ICON_FILENAMES then
            local texture = ExtraStats_GetEquipmentSetIconInfo(index)
            button.icon:SetTexture(texture)
            button:Show()
            button:SetChecked(index == popup.selectedIcon)
        else
            button.icon:SetTexture(nil)
            button:Hide()
        end
    end

    FauxScrollFrame_Update(ExtraStats_GearManagerDialogPopupScrollFrame, ceil(#EM_ICON_FILENAMES / NUM_GEARSET_ICONS_PER_ROW), NUM_GEARSET_ICON_ROWS, GEARSET_ICON_ROW_HEIGHT)
end

function ExtraStats_RecalculateGearManagerDialogPopup(setName, iconTexture)
    local popup = ExtraStats_GearManagerDialogPopup
    ExtraStats_GearManagerDialogPopupEditBox:SetText(setName or "")
    if iconTexture then
        popup.selectedTexture = iconTexture
        popup.selectedIcon = nil
        RebuildIconList()
        for i = 1, #EM_ICON_FILENAMES do
            if EM_ICON_FILENAMES[i] == iconTexture then
                popup.selectedIcon = i
                break
            end
        end
    end

    if not popup.selectedIcon then
        popup.selectedIcon = 1
    end

    FauxScrollFrame_OnVerticalScroll(ExtraStats_GearManagerDialogPopupScrollFrame, 0, GEARSET_ICON_ROW_HEIGHT, nil)
    ExtraStats_GearManagerDialogPopup_Update()
    ExtraStats_GearManagerDialogPopupOkay_Update()
end

function ExtraStats_GearManagerDialogPopup_OnLoad(self)
    self.buttons = {}

    local button = CreateFrame("CheckButton", "ExtraStats_GearManagerDialogPopupButton1", self, "ExtraGearSetPopupButtonTemplate")
    button:SetPoint("TOPLEFT", 24, -85)
    button:SetID(1)
    self.buttons[1] = button

    for i = 2, NUM_GEARSET_ICONS_SHOWN do
        button = CreateFrame("CheckButton", "ExtraStats_GearManagerDialogPopupButton" .. i, self, "ExtraGearSetPopupButtonTemplate")
        button:SetID(i)

        local lastPos = (i - 1) / NUM_GEARSET_ICONS_PER_ROW
        if lastPos == math.floor(lastPos) then
            button:SetPoint("TOPLEFT", self.buttons[i - NUM_GEARSET_ICONS_PER_ROW], "BOTTOMLEFT", 0, -8)
        else
            button:SetPoint("TOPLEFT", self.buttons[i - 1], "TOPRIGHT", 10, 0)
        end

        self.buttons[i] = button
    end
end

function ExtraStats_GearManagerDialogPopup_OnShow(self)
    PlaySound(SOUNDKIT.IG_CHARACTER_INFO_OPEN)

    if not self.isEdit then
        self.origName = nil
        self.name = nil
    end

    ExtraStats_RecalculateGearManagerDialogPopup(self.name, self.selectedTexture)

    ExtraStatsPaperDollEquipmentManagerPaneSaveSet:Disable()
    ExtraStatsPaperDollEquipmentManagerPaneEquipSet:Disable()
end

function ExtraStats_GearManagerDialogPopup_OnHide(self)
    self.name = nil
    self.origName = nil
    self.isEdit = false
    self.selectedTexture = nil
    self.selectedIcon = nil
    ExtraStats_GearManagerDialogPopupEditBox:SetText("")

    tab.pendingNewSet = false
    ExtraStats_PaperDollEquipmentManagerPane_Update()
end

function ExtraStats_GearManagerDialogPopupOkay_Update()
    local popup = ExtraStats_GearManagerDialogPopup
    if popup.selectedIcon and popup.name and popup.name ~= "" then
        ExtraStats_GearManagerDialogPopupOkay:Enable()
    else
        ExtraStats_GearManagerDialogPopupOkay:Disable()
    end
end

function ExtraStats_GearManagerDialogPopupOkay_OnClick()
    local popup = ExtraStats_GearManagerDialogPopup
    local name = popup.name
    local icon = ExtraStats_GetEquipmentSetIconInfo(popup.selectedIcon) or DEFAULT_ICON
    if not name or name == "" then
        return
    end

    if name == "TEMP_SET" then
        UIErrorsFrame:AddMessage("Name TEMP_SET is reserved.", 1.0, 0.1, 0.1, 1.0)
        return
    end

    if popup.isEdit then
        local setID = EquipmentSet:GetEquipmentSetID(popup.origName)
        if not setID then
            popup:Hide()
            return
        end

        local existing = EquipmentSet:GetEquipmentSetID(name)
        if existing and existing ~= setID then
            UIErrorsFrame:AddMessage(EQUIPMENT_SETS_CANT_RENAME, 1.0, 0.1, 0.1, 1.0)
            return
        end

        local oldName = select(1, EquipmentSet:GetEquipmentSetInfo(setID))
        EquipmentSet:ModifyEquipmentSet(setID, name, icon)
        RenameEquipMacros(oldName, name, icon)
        UpdateEquipMacros(name, icon)
        SelectSetByID(setID)
        popup:Hide()
        return
    end

    local existing = EquipmentSet:GetEquipmentSetID(name)
    if existing then
        local dialog = StaticPopup_Show("ExtraStats_CONFIRM_OVERWRITE_EQUIPMENT_SET", name)
        if dialog then
            dialog.data = existing
            dialog.selectedIcon = icon
        end
        return
    end

    if EquipmentSet:GetNumEquipmentSets() >= MAX_EQUIPMENT_SETS_PER_PLAYER then
        UIErrorsFrame:AddMessage(EQUIPMENT_SETS_TOO_MANY, 1.0, 0.1, 0.1, 1.0)
        return
    end

    local setID = EquipmentSet:CreateEquipmentSet(name)
    EquipmentSet:ModifyEquipmentSet(setID, name, icon)
    EquipmentSet:SaveEquipmentSet(setID)
    UpdateEquipMacros(name, icon)
    SelectSetByID(setID)
    popup:Hide()
end

function ExtraStats_GearManagerDialogPopupCancel_OnClick()
    ExtraStats_GearManagerDialogPopup:Hide()
end

function ExtraStats_GearSetPopupButton_OnClick(self)
    local popup = ExtraStats_GearManagerDialogPopup
    local offset = FauxScrollFrame_GetOffset(ExtraStats_GearManagerDialogPopupScrollFrame) or 0
    popup.selectedIcon = (offset * NUM_GEARSET_ICONS_PER_ROW) + self:GetID()
    popup.selectedTexture = nil
    ExtraStats_GearManagerDialogPopup_Update()
    ExtraStats_GearManagerDialogPopupOkay_Update()
end

function GearSetEditButton_OnLoad(self)
    self.Dropdown = GearSetEditButtonDropDown
    UIDropDownMenu_Initialize(self.Dropdown, nil, "MENU")
    self.Dropdown.gearSetButton = self:GetParent()
    UIDropDownMenu_SetInitializeFunction(self.Dropdown, GearSetEditButtonDropDown_Initialize)
end

function GetPrimaryTalentTree(spec)
    return select(3, EquipmentSet:GetSpecGroupInfo(spec))
end

function GearSetEditButtonDropDown_Initialize(dropdownFrame)
    local gearSetButton = dropdownFrame.gearSetButton or GearSetEditButtonDropDown.gearSetButton
    local setID = gearSetButton and gearSetButton.setID

    local info = UIDropDownMenu_CreateInfo()
    info.text = EQUIPMENT_SET_EDIT
    info.notCheckable = true
    info.func = function()
        local popup = ExtraStats_GearManagerDialogPopup
        popup.isEdit = true
        popup.origName = gearSetButton.name
        popup.name = gearSetButton.name
        popup.selectedTexture = gearSetButton.iconTexture
        popup:Show()
    end
    UIDropDownMenu_AddButton(info, UIDROPDOWN_MENU_LEVEL)

    if not setID then
        return
    end

    local mountSetID = EquipmentSet:GetMountEquipmentSet()
    local mountInfo = UIDropDownMenu_CreateInfo()
    mountInfo.text = "Auto equip while mounted"
    mountInfo.checked = mountSetID == setID
    mountInfo.func = function()
        EquipmentSet:AssignMountEquipmentSet(setID)
        ExtraStats_PaperDollEquipmentManagerPane_Update()
    end
    UIDropDownMenu_AddButton(mountInfo, UIDROPDOWN_MENU_LEVEL)

    if mountSetID == setID then
        local clearMountInfo = UIDropDownMenu_CreateInfo()
        clearMountInfo.text = "Clear mounted auto equip"
        clearMountInfo.notCheckable = true
        clearMountInfo.func = function()
            EquipmentSet:UnassignMountEquipmentSet()
            ExtraStats_PaperDollEquipmentManagerPane_Update()
        end
        UIDropDownMenu_AddButton(clearMountInfo, UIDROPDOWN_MENU_LEVEL)
    end

    local pvpSetID = EquipmentSet:GetPvPEquipmentSet()
    local pvpInfo = UIDropDownMenu_CreateInfo()
    pvpInfo.text = "Auto equip in PVP instances"
    pvpInfo.checked = pvpSetID == setID
    pvpInfo.func = function()
        EquipmentSet:AssignPvPEquipmentSet(setID)
        ExtraStats_PaperDollEquipmentManagerPane_Update()
    end
    UIDropDownMenu_AddButton(pvpInfo, UIDROPDOWN_MENU_LEVEL)

    if pvpSetID == setID then
        local clearPvPInfo = UIDropDownMenu_CreateInfo()
        clearPvPInfo.text = "Clear PVP auto equip"
        clearPvPInfo.notCheckable = true
        clearPvPInfo.func = function()
            EquipmentSet:UnassignPvPEquipmentSet()
            ExtraStats_PaperDollEquipmentManagerPane_Update()
        end
        UIDropDownMenu_AddButton(clearPvPInfo, UIDROPDOWN_MENU_LEVEL)
    end

    local assignedSpec = EquipmentSet:GetEquipmentSetAssignedSpec(setID)
    local specCount = EquipmentSet:GetSpecGroupCount()

    for specGroup = 1, specCount do
        local specLabel, _, _, specName = EquipmentSet:GetSpecGroupInfo(specGroup)
        local assignInfo = UIDropDownMenu_CreateInfo()
        if specName and specName ~= "" then
            assignInfo.text = string.format("Auto equip for Spec %d (%s)", specGroup, specName)
        else
            assignInfo.text = string.format("Auto equip for %s", specLabel)
        end
        assignInfo.checked = assignedSpec == specGroup
        assignInfo.func = function()
            EquipmentSet:AssignSpecToEquipmentSet(setID, specGroup)
            ExtraStats_PaperDollEquipmentManagerPane_Update()
        end
        UIDropDownMenu_AddButton(assignInfo, UIDROPDOWN_MENU_LEVEL)
    end

    if assignedSpec then
        local clearInfo = UIDropDownMenu_CreateInfo()
        clearInfo.text = "Clear auto equip spec"
        clearInfo.notCheckable = true
        clearInfo.func = function()
            EquipmentSet:UnassignSpecFromEquipmentSet(setID)
            ExtraStats_PaperDollEquipmentManagerPane_Update()
        end
        UIDropDownMenu_AddButton(clearInfo, UIDROPDOWN_MENU_LEVEL)
    end
end

function AssignSpecToEquipmentSet(setID, specID)
    EquipmentSet:AssignSpecToEquipmentSet(setID, specID)
end

function GetEquipmentSetAssignedSpec(setID)
    return EquipmentSet:GetEquipmentSetAssignedSpec(setID)
end

function UnassignEquipmentSetSpec(setID)
    EquipmentSet:UnassignSpecFromEquipmentSet(setID)
end

function GetEquipmentSetForSpec(specID)
    return EquipmentSet:GetEquipmentSetForSpec(specID)
end

function AssignMountEquipmentSet(setID)
    EquipmentSet:AssignMountEquipmentSet(setID)
end

function GetMountEquipmentSet()
    return EquipmentSet:GetMountEquipmentSet()
end

function UnassignMountEquipmentSet()
    EquipmentSet:UnassignMountEquipmentSet()
end

function AssignPvPEquipmentSet(setID)
    EquipmentSet:AssignPvPEquipmentSet(setID)
end

function GetPvPEquipmentSet()
    return EquipmentSet:GetPvPEquipmentSet()
end

function UnassignPvPEquipmentSet()
    EquipmentSet:UnassignPvPEquipmentSet()
end

function GearSetButton_SetSpecInfo(self, specID, specName)
    if specName and specName ~= "" then
        self.specID = specID
        self.SpecText:SetText(specName)
        self.SpecText:Show()
    else
        self.specID = nil
        self.SpecText:Hide()
    end

    self.SpecIcon:Hide()
    self.SpecRing:Hide()
end

function GearSetButton_UpdateSpecInfo(self)
    if not self.setID then
        GearSetButton_SetSpecInfo(self, nil)
        return
    end

    if GetMountEquipmentSet() == self.setID then
        GearSetButton_SetSpecInfo(self, 0, "Mount set")
        return
    end

    if GetPvPEquipmentSet() == self.setID then
        GearSetButton_SetSpecInfo(self, 0, "PVP set")
        return
    end

    local specGroup = GetEquipmentSetAssignedSpec(self.setID)
    if not specGroup then
        GearSetButton_SetSpecInfo(self, nil)
        return
    end

    local _, _, specID, specName = EquipmentSet:GetSpecGroupInfo(specGroup)
    GearSetButton_SetSpecInfo(self, specID, specName)
end

function tab:init()
    HookNativeGearSetButtonTooltips()
    local frame = CreateFrame("ScrollFrame", "ExtraStatsPaperDollEquipmentManagerPane", PaperDollFrame, "ExtraStatsPaperDollEquipmentManagerPaneTemplate")
    tab.DialogPopup = CreateFrame("Frame", "ExtraStats_GearManagerDialogPopup", frame, "ExtraGearManagerDialogPopupTemplate")
    tab.frame = frame
    HookItemSlotIgnoreEditing()
end

function tab:IsVisible()
end

function tab:show()
end

function tab:hide()
end
