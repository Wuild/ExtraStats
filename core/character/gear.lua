local tab = ExtraStats:CreateModule("character.gear")
local EquipmentSet = ExtraStats:GetModule("EquipmentSet")

tab.frame = nil

tab.pendingNewSet = false

ExtraStats_EQUIPMENTSET_BUTTON_HEIGHT = 38
MAX_EQUIPMENT_SETS_PER_PLAYER = 10
NUM_GEARSET_ICONS_SHOWN = 80
NUM_GEARSET_ICONS_PER_ROW = 10
NUM_GEARSET_ICON_ROWS = 8
GEARSET_ICON_ROW_HEIGHT = 36

local DEFAULT_ICON = 134400
local EQUIPMENT_SET_BUTTON_OFFSET_X = 4
local EQUIPMENT_SET_BUTTON_OFFSET_Y = -34
local EQUIPMENT_SET_TOP_MASK_HEIGHT = 32
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
local LoadSelectedSetDraft
local RefreshEquipmentSetPreview
local ClearEquipmentSetPreview

local nativeItemSlotButtons = {
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
local itemSlotButtons = {}
local editorSlotButtons = {}
local editorSlotByNativeButton = {}

local EDITOR_SLOT_BACKGROUND_TEXTURES = {
    [INVSLOT_HEAD] = "Interface\\PaperDoll\\UI-PaperDoll-Slot-Head",
    [INVSLOT_NECK] = "Interface\\PaperDoll\\UI-PaperDoll-Slot-Neck",
    [INVSLOT_SHOULDER] = "Interface\\PaperDoll\\UI-PaperDoll-Slot-Shoulder",
    [INVSLOT_BODY] = "Interface\\PaperDoll\\UI-PaperDoll-Slot-Shirt",
    [INVSLOT_CHEST] = "Interface\\PaperDoll\\UI-PaperDoll-Slot-Chest",
    [INVSLOT_WAIST] = "Interface\\PaperDoll\\UI-PaperDoll-Slot-Waist",
    [INVSLOT_LEGS] = "Interface\\PaperDoll\\UI-PaperDoll-Slot-Legs",
    [INVSLOT_FEET] = "Interface\\PaperDoll\\UI-PaperDoll-Slot-Feet",
    [INVSLOT_WRIST] = "Interface\\PaperDoll\\UI-PaperDoll-Slot-Wrists",
    [INVSLOT_HAND] = "Interface\\PaperDoll\\UI-PaperDoll-Slot-Hands",
    [INVSLOT_FINGER1] = "Interface\\PaperDoll\\UI-PaperDoll-Slot-Finger",
    [INVSLOT_FINGER2] = "Interface\\PaperDoll\\UI-PaperDoll-Slot-Finger",
    [INVSLOT_TRINKET1] = "Interface\\PaperDoll\\UI-PaperDoll-Slot-Trinket",
    [INVSLOT_TRINKET2] = "Interface\\PaperDoll\\UI-PaperDoll-Slot-Trinket",
    [INVSLOT_BACK] = "Interface\\PaperDoll\\UI-PaperDoll-Slot-Chest",
    [INVSLOT_MAINHAND] = "Interface\\PaperDoll\\UI-PaperDoll-Slot-MainHand",
    [INVSLOT_OFFHAND] = "Interface\\PaperDoll\\UI-PaperDoll-Slot-SecondaryHand",
    [INVSLOT_RANGED] = "Interface\\PaperDoll\\UI-PaperDoll-Slot-Ranged",
    [INVSLOT_TABARD] = "Interface\\PaperDoll\\UI-PaperDoll-Slot-Tabard",
}

local LEFT_EDITOR_SLOTS = {
    [INVSLOT_HEAD] = true, [INVSLOT_NECK] = true, [INVSLOT_SHOULDER] = true,
    [INVSLOT_BACK] = true, [INVSLOT_CHEST] = true, [INVSLOT_BODY] = true,
    [INVSLOT_TABARD] = true, [INVSLOT_WRIST] = true,
}
local BOTTOM_EDITOR_SLOTS = {
    [INVSLOT_MAINHAND] = true, [INVSLOT_OFFHAND] = true, [INVSLOT_RANGED] = true,
}

local MODEL_PREVIEW_SLOTS = {
    [INVSLOT_HEAD] = true,
    [INVSLOT_SHOULDER] = true,
    [INVSLOT_BODY] = true,
    [INVSLOT_BACK] = true,
    [INVSLOT_CHEST] = true,
    [INVSLOT_TABARD] = true,
    [INVSLOT_WRIST] = true,
    [INVSLOT_HAND] = true,
    [INVSLOT_WAIST] = true,
    [INVSLOT_LEGS] = true,
    [INVSLOT_FEET] = true,
    [INVSLOT_MAINHAND] = true,
    [INVSLOT_OFFHAND] = true,
    [INVSLOT_RANGED] = true,
}

local function SyncGearSetEditorSlotLayout()
    for _, nativeButton in ipairs(nativeItemSlotButtons) do
        local button = editorSlotByNativeButton[nativeButton]
        if button then
            button:SetSize(nativeButton:GetWidth(), nativeButton:GetHeight())
            button:SetFrameLevel(nativeButton:GetFrameLevel() + 12)
            button:ClearAllPoints()
            for pointIndex = 1, nativeButton:GetNumPoints() do
                local point, relativeTo, relativePoint, xOffset, yOffset = nativeButton:GetPoint(pointIndex)
                button:SetPoint(point, editorSlotByNativeButton[relativeTo] or relativeTo, relativePoint, xOffset, yOffset)
            end

            local nativeIcon = nativeButton.icon or nativeButton.Icon
                or (nativeButton.GetName and _G[(nativeButton:GetName() or "") .. "IconTexture"])
            if nativeIcon and button.icon then
                button.icon:ClearAllPoints()
                button.icon:SetSize(nativeIcon:GetWidth(), nativeIcon:GetHeight())
                local nativeIconX, nativeIconY = nativeIcon:GetCenter()
                local nativeButtonX, nativeButtonY = nativeButton:GetCenter()
                if nativeIconX and nativeIconY and nativeButtonX and nativeButtonY then
                    button.icon:SetPoint("CENTER", button, "CENTER", nativeIconX - nativeButtonX, nativeIconY - nativeButtonY)
                else
                    button.icon:SetAllPoints(button)
                end
                button.icon:SetTexCoord(nativeIcon:GetTexCoord())
            end
        end
    end
end

local function EnsureGearSetEditorSlotButtons()
    if #editorSlotButtons > 0 then
        return
    end

    for _, nativeButton in ipairs(nativeItemSlotButtons) do
        if nativeButton then
            local slotID = nativeButton:GetID()
            local buttonName = "ExtraStatsGearSetEditorSlot" .. tostring(slotID)
            local button = CreateFrame("Button", buttonName, PaperDollFrame)
            button:SetSize(nativeButton:GetWidth(), nativeButton:GetHeight())
            button:SetID(slotID)
            button.ExtraStatsGearSetEditorSlot = true
            button:SetFrameLevel(nativeButton:GetFrameLevel() + 12)
            button:RegisterForClicks("LeftButtonUp", "RightButtonUp")
            button:RegisterForDrag("LeftButton")

            local frameTemplate = LEFT_EDITOR_SLOTS[slotID] and "ExtraLeftItemSlotTemplate"
                or (BOTTOM_EDITOR_SLOTS[slotID] and "ExtraBottomItemSlotTemplate" or "ExtraRightItemSlotTemplate")
            button.frameTexture = button:CreateTexture("$parentFrame", "BACKGROUND", frameTemplate, -1)
            if slotID == INVSLOT_MAINHAND then
                button:CreateTexture(nil, "BACKGROUND", "ExtraBottomItemSlotLeftBorderTemplate")
            elseif slotID == INVSLOT_RANGED then
                button:CreateTexture(nil, "BACKGROUND", "ExtraBottomItemSlotRightBorderTemplate")
            end

            button.background = button:CreateTexture(nil, "BACKGROUND", nil, 0)
            button.background:SetAllPoints()
            local nativeNormal = nativeButton.GetNormalTexture and nativeButton:GetNormalTexture()
            local nativeNormalTexture = nativeNormal and nativeNormal.GetTexture and nativeNormal:GetTexture()
            if nativeNormalTexture then
                button.background:SetTexture(nativeNormalTexture)
                button.background:SetTexCoord(nativeNormal:GetTexCoord())
            else
                button.background:SetTexture(EDITOR_SLOT_BACKGROUND_TEXTURES[slotID])
            end

            button.icon = button:CreateTexture(nil, "ARTWORK")
            button.icon:SetPoint("TOPLEFT", 2, -2)
            button.icon:SetPoint("BOTTOMRIGHT", -2, 2)
            button.icon:SetTexCoord(0.07, 0.93, 0.07, 0.93)

            button:SetHighlightTexture("Interface\\Buttons\\ButtonHilight-Square", "ADD")
            button:Hide()
            editorSlotButtons[#editorSlotButtons + 1] = button
            editorSlotByNativeButton[nativeButton] = button
        end
    end

    -- Copy the paperdoll layout, replacing any slot-to-slot anchors with
    -- editor-to-editor anchors. The editor frames never remain anchored to a
    -- live inventory button.
    SyncGearSetEditorSlotLayout()
    itemSlotButtons = editorSlotButtons
end

function ExtraStats_GetGearSetEditorSlotButtons()
    return editorSlotButtons
end

local function SetNativeAndEditorSlotsForEditMode(editing)
    for _, button in ipairs(nativeItemSlotButtons) do
        if button then
            button:SetAlpha(editing and 0 or 1)
            button:EnableMouse(not editing)
        end
    end
    for _, button in ipairs(editorSlotButtons) do
        button:SetShown(editing == true)
    end
end

local ignoreEditToggleButtons = {}
local EM_ICON_FILENAMES = {}
local equipmentSetPreviewModel
local equipmentSetPreviewModelUnavailable = false
local previewRefreshRequestID = 0

local function IsModelAppearanceShown(queryFunction, cvarName)
    if type(queryFunction) == "function" then
        local ok, shown = pcall(queryFunction)
        if ok then
            return shown == true or shown == 1
        end
    end
    if GetCVarBool then
        local ok, shown = pcall(GetCVarBool, cvarName)
        if ok then
            return shown == true or shown == 1
        end
    end
    if GetCVar then
        local ok, value = pcall(GetCVar, cvarName)
        if ok and value ~= nil then
            return tostring(value) == "1"
        end
    end
    return true
end

local function ScheduleEquipmentSetPreviewRefresh()
    previewRefreshRequestID = previewRefreshRequestID + 1
    local requestID = previewRefreshRequestID
    C_Timer.After(0, function()
        if requestID == previewRefreshRequestID and tab.frame and tab.frame:IsShown() then
            RefreshEquipmentSetPreview()
        end
    end)
end

local function CopyTable(source)
    local copy = {}
    for key, value in pairs(source or {}) do
        copy[key] = value
    end
    return copy
end

local function GetSlotName(slotID)
    for _, slot in ipairs(EquipmentSet:SlotInfo()) do
        if slot.id == slotID then
            return slot.name
        end
    end
end

LoadSelectedSetDraft = function(setID)
    if not tab.frame then
        return
    end
    if not setID then
        tab.frame.editDraft = nil
        return
    end

    local items, itemLinks, ignoredSlots = EquipmentSet:GetEquipmentSetItems(setID)
    if not items then
        tab.frame.editDraft = nil
        return
    end
    tab.frame.editDraft = {
        setID = setID,
        items = CopyTable(items),
        itemLinks = CopyTable(itemLinks),
        ignoredSlots = CopyTable(ignoredSlots),
        dirty = false,
    }
end

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

local function PrepareDefaultNewSetSlots()
    EquipmentSet:SetIgnoredSlotsForSave({
        [INVSLOT_BODY] = true,
        [INVSLOT_TABARD] = true,
    })
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
        LoadSelectedSetDraft(nil)
        ApplyIgnoredSlotsForSet(nil)
        RefreshEquipmentSetPreview()
        return
    end

    local name = select(1, EquipmentSet:GetEquipmentSetInfo(setID))
    if not name then
        tab.frame.selectedSetID = nil
        tab.frame.selectedSetName = nil
        LoadSelectedSetDraft(nil)
        ApplyIgnoredSlotsForSet(nil)
        RefreshEquipmentSetPreview()
        return
    end

    tab.frame.selectedSetID = setID
    tab.frame.selectedSetName = name
    LoadSelectedSetDraft(setID)
    ApplyIgnoredSlotsForSet(setID)
    RefreshEquipmentSetPreview()
end

local function SelectCurrentlyEquippedSet()
    local setIDs = EquipmentSet:GetEquipmentSetIDsSorted()
    local activeSetID = EquipmentSet:GetCurrentEquipmentSetID()
    if activeSetID and EquipmentSet:GetEquipmentSetInfo(activeSetID) then
        SelectSetByID(activeSetID)
        return true
    end

    for _, setID in ipairs(setIDs) do
        local _, _, _, isEquipped = EquipmentSet:GetEquipmentSetInfo(setID)
        if isEquipped then
            SelectSetByID(setID)
            return true
        end
    end

    -- Entering the tab always enters edit mode. If none is currently equipped,
    -- begin by editing the first saved set instead of showing the live gear.
    SelectSetByID(setIDs[1])
    return setIDs[1] ~= nil
end

StaticPopupDialogs["CONFIRM_SAVE_EQUIPMENT_SET"] = {
    text = CONFIRM_SAVE_EQUIPMENT_SET,
    button1 = YES,
    button2 = NO,
    OnAccept = function(self)
        local setID = self.data
        if setID then
            local draft = tab.frame and tab.frame.editDraft
            if draft and draft.setID == setID then
                EquipmentSet:SaveEquipmentSetItems(setID, draft.items, draft.itemLinks, draft.ignoredSlots)
                draft.dirty = false
            else
                return
            end
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
    text = CONFIRM_OVERWRITE_EQUIPMENT_SET or ExtraStats:translate("gearsets.overwrite"),
    button1 = YES,
    button2 = NO,
    OnAccept = function(self)
        local setID = self.data
        if setID then
            local popup = ExtraStats_GearManagerDialogPopup
            local oldName = select(1, EquipmentSet:GetEquipmentSetInfo(setID))
            EquipmentSet:ModifyEquipmentSet(setID, popup.name, self.selectedIcon)
            if tab.pendingNewSet then
                PrepareDefaultNewSetSlots()
            end
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

StaticPopupDialogs["ExtraStats_CONFIRM_SHARED_BANK_ITEMS"] = {
    text = ExtraStats:translate("gearsets.bank_shared_prompt"),
    button1 = ExtraStats:translate("gearsets.bank_move_shared"),
    button2 = CANCEL,
    button3 = ExtraStats:translate("gearsets.bank_leave_shared"),
    OnAccept = function(self)
        local data = self.data
        if data then
            EquipmentSet:MoveEquipmentSetBank(data.setID, data.direction, true)
        end
    end,
    OnAlt = function(self)
        local data = self.data
        if data then
            EquipmentSet:MoveEquipmentSetBank(data.setID, data.direction, false)
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

function ExtraStats_RequestEquipmentSetBankMove(setID, direction)
    local setName = select(1, EquipmentSet:GetEquipmentSetInfo(setID))
    if not setName then
        return false
    end
    if not EquipmentSet:IsBankOpen() then
        UIErrorsFrame:AddMessage(ExtraStats:translate("gearsets.bank_open_required"), 1.0, 0.1, 0.1, 1.0)
        return false
    end

    local sharedCount = EquipmentSet:GetEquipmentSetBankSharedItemCount(setID, direction)
    if sharedCount > 0 then
        local dialog = StaticPopup_Show("ExtraStats_CONFIRM_SHARED_BANK_ITEMS", setName, sharedCount)
        if dialog then
            dialog.data = { setID = setID, direction = direction }
            return true
        end
        return false
    end
    return EquipmentSet:MoveEquipmentSetBank(setID, direction, true)
end

function ExtraStats_PaperDollEquipmentManagerPane_OnLoad(self)
    HookNativeGearSetButtonTooltips()
    HybridScrollFrame_OnLoad(self)
    EnsureEquipmentSetTopMask(self)
    self.update = ExtraStats_PaperDollEquipmentManagerPane_Update

    self:RegisterEvent("EQUIPMENT_SWAP_FINISHED")
    self:RegisterEvent("EQUIPMENT_SETS_CHANGED")
    self:RegisterEvent("PLAYER_EQUIPMENT_CHANGED")
    self:RegisterEvent("BAG_UPDATE")
    self:RegisterEvent("CVAR_UPDATE")

    ExtraStats:On("gear.update", function()
        if self and self:IsShown() then
            ExtraStats_PaperDollEquipmentManagerPane_Update()
            RefreshEquipmentSetPreview()
        end
    end)
    ExtraStats:On("gear.swap.finished", function(success, setID)
        if success and setID and tab.frame and self:IsShown() then
            SelectSetByID(setID)
            ExtraStats_PaperDollEquipmentManagerPane_Update()
            ScheduleEquipmentSetPreviewRefresh()
        end
    end)
end

function ExtraStats_PaperDollEquipmentManagerPane_OnShow(self)
    self.equipmentEditMode = true
    EnsureGearSetEditorSlotButtons()
    SyncGearSetEditorSlotLayout()
    SetNativeAndEditorSlotsForEditMode(true)
    HookItemSlotIgnoreEditing()
    EnsureEquipmentSetTopMask(self)
    EnsureEquipmentSetButtons(self)
    if self.selectedSetID and EquipmentSet:GetEquipmentSetInfo(self.selectedSetID) then
        SelectSetByID(self.selectedSetID)
    else
        SelectCurrentlyEquippedSet()
    end
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
    ClearEquipmentSetPreview()
    SetNativeAndEditorSlotsForEditMode(false)
    ExtraStats_PaperDollFrame_ClearIgnoredSlots()
    UpdateEquipmentEditModeVisuals()
    ExtraStats_GearManagerDialogPopup:Hide()
    StaticPopup_Hide("CONFIRM_SAVE_EQUIPMENT_SET")
    StaticPopup_Hide("CONFIRM_DELETE_EQUIPMENT_SET")
    StaticPopup_Hide("ExtraStats_CONFIRM_OVERWRITE_EQUIPMENT_SET")
    StaticPopup_Hide("ExtraStats_CONFIRM_SHARED_BANK_ITEMS")
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

    if (event == "CVAR_UPDATE" or event == "PLAYER_EQUIPMENT_CHANGED" or event == "BAG_UPDATE" or event == "EQUIPMENT_SETS_CHANGED") and self:IsShown() then
        RefreshEquipmentSetPreview()
        ScheduleEquipmentSetPreviewRefresh()
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
            if button:IsShown() and button.IsMouseOver and button:IsMouseOver() then
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
        if button == hoveredSetButton then
            hoveredSetButton = button
            button.HighlightBar:Show()
            if button.setID then
                if button.EditButton and button.EditButton.Dropdown then
                    button.EditButton.Dropdown.gearSetButton = button
                end
                button.DeleteButton:Show()
                button.EditButton:Show()
            else
                button.DeleteButton:Hide()
                button.EditButton:Hide()
            end
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

    local ids = EquipmentSet:GetEquipmentSetIDsSorted()
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
                button.icon:SetSize(26, 26)
                button.icon:ClearAllPoints()
                button.icon:SetPoint("LEFT", 5, 0)

                button.Check:SetShown(setEquipped == true)
                local selected = button.setID == tab.frame.selectedSetID
                button.SelectedBar:SetShown(selected)
                button.SelectedAccent:SetShown(selected)
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
                button.text:SetTextColor(NORMAL_FONT_COLOR.r, NORMAL_FONT_COLOR.g, NORMAL_FONT_COLOR.b)
                button.text:ClearAllPoints()
                button.text:SetPoint("LEFT", button.icon, "RIGHT", 6, 0)
                button.icon:SetTexture("Interface\\Buttons\\UI-PlusButton-Up")
                button.icon:SetSize(18, 18)
                button.icon:ClearAllPoints()
                button.icon:SetPoint("LEFT", 9, 0)
                button.Check:Hide()
                button.SelectedBar:Hide()
                button.SelectedAccent:Hide()
                if isEquipInProgress then
                    button:Disable()
                else
                    button:Enable()
                end
            end

            if button.setID then
                button.text:ClearAllPoints()
                button.text:SetPoint("TOPLEFT", 40, -4)
            end

            button.Background:SetShown((row % 2) == 0)

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
    local setItems = setID and EquipmentSet:GetEquipmentSetTooltipItems(setID) or {}
    local tooltipMissing = 0
    for _, item in ipairs(setItems) do
        if item.location == "missing" then
            tooltipMissing = tooltipMissing + 1
        end
    end
    numLost = tooltipMissing

    GameTooltip:SetOwner(button, "ANCHOR_RIGHT")
    GameTooltip:ClearLines()
    GameTooltip:SetText(setName, HIGHLIGHT_FONT_COLOR.r, HIGHLIGHT_FONT_COLOR.g, HIGHLIGHT_FONT_COLOR.b)
    if setID then
        if isEquipped then
            GameTooltip:AddLine(EQUIPPED or ExtraStats:translate("gearsets.equipped"), GREEN_FONT_COLOR.r, GREEN_FONT_COLOR.g, GREEN_FONT_COLOR.b)
        elseif (numLost or 0) > 0 then
            GameTooltip:AddLine(numLost == 1 and ExtraStats:translate("gearsets.missing_one") or ExtraStats:translate("gearsets.missing_many", numLost), RED_FONT_COLOR.r, RED_FONT_COLOR.g, RED_FONT_COLOR.b)
        else
            GameTooltip:AddLine(EQUIPSET_EQUIP or ExtraStats:translate("gearsets.equip"), NORMAL_FONT_COLOR.r, NORMAL_FONT_COLOR.g, NORMAL_FONT_COLOR.b)
        end

        if #setItems > 0 then
            GameTooltip:AddLine(" ")
            GameTooltip:AddLine(ExtraStats:translate("gearsets.items_header"), NORMAL_FONT_COLOR.r, NORMAL_FONT_COLOR.g, NORMAL_FONT_COLOR.b)
            for _, item in ipairs(setItems) do
                local location = ExtraStats:translate("gearsets.location_" .. item.location)
                if item.ignored then
                    location = ExtraStats:translate("gearsets.location_ignored", location)
                end
                local r, g, b = HIGHLIGHT_FONT_COLOR.r, HIGHLIGHT_FONT_COLOR.g, HIGHLIGHT_FONT_COLOR.b
                if item.location == "equipped" then
                    r, g, b = GREEN_FONT_COLOR.r, GREEN_FONT_COLOR.g, GREEN_FONT_COLOR.b
                elseif item.location == "missing" then
                    r, g, b = RED_FONT_COLOR.r, RED_FONT_COLOR.g, RED_FONT_COLOR.b
                end
                GameTooltip:AddDoubleLine(
                    item.slotLabel .. ": " .. (item.itemLink or item.itemName),
                    location,
                    HIGHLIGHT_FONT_COLOR.r, HIGHLIGHT_FONT_COLOR.g, HIGHLIGHT_FONT_COLOR.b,
                    r, g, b
                )
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
    ExtraStats_GearManagerDialogPopup:Show()
end

function ExtraStats_GearSetButton_OnDoubleClick(self, button)
    if button == "LeftButton" and self.setID then
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
            GameTooltip:SetText(ExtraStats:translate("gearsets.include_slot"))
            GameTooltip:AddLine(ExtraStats:translate("gearsets.include_slot_desc"), 1, 1, 1, true)
        else
            GameTooltip:SetText(ExtraStats:translate("gearsets.ignore_slot"))
            GameTooltip:AddLine(ExtraStats:translate("gearsets.ignore_slot_desc"), 1, 1, 1, true)
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

local function GetSlotIconTexture(button)
    if not button then
        return nil
    end
    return button.icon or button.Icon or (button.GetName and _G[(button:GetName() or "") .. "IconTexture"])
end

local function SetEditedSlotFromCursor(button)
    if not button or not GetCursorInfo then
        return false
    end

    local cursorType, itemID, itemLink = GetCursorInfo()
    if cursorType ~= "item" or (not itemID and not itemLink) then
        return false
    end

    local slotID = button:GetID()
    local link = itemLink or ("item:" .. tostring(itemID))
    if not ExtraStats_SetEditedEquipmentSetSlotItem(slotID, link) then
        return false
    end
    if ClearCursor then
        ClearCursor()
    end
    return true
end

local function EnsurePreviewSlotHooks(button)
    if not button or button.ExtraStatsGearSetPreviewHooked then
        return
    end

    local originalOnClick = button:GetScript("OnClick")
    button:SetScript("OnClick", function(self, ...)
        if ExtraStats_IsEquipmentSetEditMode() then
            SetEditedSlotFromCursor(self)
            return
        end
        if originalOnClick then
            return originalOnClick(self, ...)
        end
    end)

    local originalOnReceiveDrag = button:GetScript("OnReceiveDrag")
    button:SetScript("OnReceiveDrag", function(self, ...)
        if ExtraStats_IsEquipmentSetEditMode() then
            SetEditedSlotFromCursor(self)
            return
        end
        if originalOnReceiveDrag then
            return originalOnReceiveDrag(self, ...)
        end
    end)

    button:HookScript("OnEnter", function(self)
        if not ExtraStats_IsEquipmentSetEditMode() then
            return
        end
        local itemID = self.ExtraStatsPreviewItemID
        local itemLink = self.ExtraStatsPreviewItemLink
        local ignored = self.ExtraStatsPreviewIgnored == true
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:ClearLines()
        if itemLink or itemID then
            GameTooltip:SetHyperlink(itemLink or ("item:" .. tostring(itemID)))
        else
            local slotName = GetSlotName(self:GetID()) or EMPTY or "Empty"
            GameTooltip:SetText(slotName)
            GameTooltip:AddLine(ignored and IGNORED or EMPTY or "Empty", 0.65, 0.65, 0.65)
        end
        GameTooltip:Show()
    end)
    button:HookScript("OnLeave", function()
        GameTooltip:Hide()
    end)

    button.ExtraStatsGearSetPreviewHooked = true
end

local function GetEquipmentSetPreviewModel()
    if equipmentSetPreviewModel then
        return equipmentSetPreviewModel
    end
    if equipmentSetPreviewModelUnavailable then
        return CharacterModelFrame
    end
    if not CharacterModelFrame then
        return nil
    end

    local ok, model = pcall(CreateFrame, "DressUpModel", "ExtraStatsEquipmentSetPreviewModel", CharacterModelFrame)
    if ok and model and model.TryOn then
        model:SetAllPoints(CharacterModelFrame)
        model:SetFrameLevel(CharacterModelFrame:GetFrameLevel() + 1)
        model:EnableMouse(false)
        model:SetScript("OnUpdate", function(self)
            -- Mouse rotation is still handled by Blizzard's original
            -- CharacterModelFrame. Mirror its facing onto the visible preview
            -- model while the live model itself is cleared.
            if self:IsShown() and self.SetFacing and CharacterModelFrame and CharacterModelFrame.GetFacing then
                local facing = CharacterModelFrame:GetFacing()
                local nativeModelVisible = false
                if CharacterModelFrame.GetModelFileID then
                    local ok, modelFileID = pcall(CharacterModelFrame.GetModelFileID, CharacterModelFrame)
                    nativeModelVisible = ok and modelFileID ~= nil and modelFileID ~= 0
                elseif CharacterModelFrame.GetModel then
                    local ok, modelPath = pcall(CharacterModelFrame.GetModel, CharacterModelFrame)
                    nativeModelVisible = ok and modelPath ~= nil and modelPath ~= ""
                end
                if nativeModelVisible and CharacterModelFrame.ClearModel then
                    pcall(CharacterModelFrame.ClearModel, CharacterModelFrame)
                end
                if facing ~= nil then
                    self:SetFacing(facing)
                end
            end
        end)
        model:Hide()
        equipmentSetPreviewModel = model
        return model
    end

    if ok and model then
        model:Hide()
    end
    equipmentSetPreviewModelUnavailable = true

    -- Older clients expose the dress-up methods directly on the character
    -- model, so it remains a safe compatibility fallback.
    return CharacterModelFrame
end

local function RefreshPreviewModel(draft)
    local model = GetEquipmentSetPreviewModel()
    if not model or not model.SetUnit then
        return
    end

    if not draft then
        if equipmentSetPreviewModel then
            equipmentSetPreviewModel:Hide()
        end
        if model ~= CharacterModelFrame and CharacterModelFrame and CharacterModelFrame.SetUnit then
            pcall(CharacterModelFrame.SetUnit, CharacterModelFrame, "player")
        elseif model == CharacterModelFrame then
            pcall(model.SetUnit, model, "player")
        end
        if CharacterModelFrame and CharacterModelFrame.SetSheathed then
            pcall(CharacterModelFrame.SetSheathed, CharacterModelFrame, false)
        end
        return
    end

    -- The preview model is transparent, so clear the live unit model beneath
    -- it before showing the edited set. This prevents two characters rendering
    -- in the same paperdoll viewport.
    if model ~= CharacterModelFrame and CharacterModelFrame then
        if CharacterModelFrame.ClearModel then
            pcall(CharacterModelFrame.ClearModel, CharacterModelFrame)
        elseif CharacterModelFrame.SetUnit then
            pcall(CharacterModelFrame.SetUnit, CharacterModelFrame, nil)
        end
    end
    if equipmentSetPreviewModel then
        equipmentSetPreviewModel:Show()
    end
    pcall(model.SetUnit, model, "player")
    if model.Undress then
        pcall(model.Undress, model)
    end
    if not model.TryOn then
        return
    end

    local showHelm = IsModelAppearanceShown(ShowingHelm, "showHelm")
    local showCloak = IsModelAppearanceShown(ShowingCloak, "showCloak")
    local slots = EquipmentSet:SlotInfo()
    table.sort(slots, function(a, b)
        local function priority(slotID)
            if slotID == INVSLOT_BODY then return 1 end
            if slotID == INVSLOT_CHEST then return 2 end
            if slotID == INVSLOT_TABARD then return 3 end
            if slotID == INVSLOT_RANGED then return 20 end
            if slotID == INVSLOT_MAINHAND then return 21 end
            if slotID == INVSLOT_OFFHAND then return 22 end
            return 10
        end
        return priority(a.id) < priority(b.id)
    end)
    for _, slot in ipairs(slots) do
        local hiddenByAppearanceSetting = (slot.id == INVSLOT_HEAD and not showHelm)
            or (slot.id == INVSLOT_BACK and not showCloak)
        if MODEL_PREVIEW_SLOTS[slot.id] and not hiddenByAppearanceSetting then
            local ignored = draft.ignoredSlots[slot.id] == true
            local itemLink, itemID
            if ignored then
                itemLink = GetInventoryItemLink("player", slot.id)
                itemID = GetInventoryItemID("player", slot.id)
            else
                itemLink = draft.itemLinks[slot.name]
                itemID = draft.items[slot.name]
            end
            if itemLink or itemID then
                local item = itemLink or itemID
                local equipLoc = select(9, GetItemInfo(item))
                if (not equipLoc or equipLoc == "") and GetItemInfoInstant then
                    equipLoc = select(4, GetItemInfoInstant(item))
                end
                -- Relics occupy the ranged slot but have no model appearance.
                if equipLoc == "INVTYPE_RELIC" then
                    item = nil
                end
                if item and slot.id == INVSLOT_MAINHAND then
                    local ok = pcall(model.TryOn, model, item, "MAINHANDSLOT")
                    if not ok then
                        pcall(model.TryOn, model, item)
                    end
                elseif item and slot.id == INVSLOT_OFFHAND then
                    local ok = pcall(model.TryOn, model, item, "SECONDARYHANDSLOT")
                    if not ok then
                        pcall(model.TryOn, model, item)
                    end
                elseif item then
                    pcall(model.TryOn, model, item)
                end
            end
        end
    end
    if model.SetSheathed then
        pcall(model.SetSheathed, model, false)
    end
end

local function ApplyEquipmentSetPreviewToSlot(button, draft, unavailableSlots)
    if not button or not draft then
        return
    end
    EnsurePreviewSlotHooks(button)
    local slotID = button:GetID()
    local slotName = GetSlotName(slotID)
    local iconTexture = GetSlotIconTexture(button)
    if not slotName or not iconTexture then
        return
    end

    local itemLink = draft.itemLinks[slotName]
    local itemID = draft.items[slotName]
    if draft.ignoredSlots[slotID] then
        itemLink = GetInventoryItemLink("player", slotID)
        itemID = GetInventoryItemID("player", slotID)
    end

    -- The tooltip reads the same immutable preview values as the icon. It must
    -- never resolve through the live paperdoll slot while this draft is shown.
    button.ExtraStatsPreviewItemID = itemID
    button.ExtraStatsPreviewItemLink = itemLink
    button.ExtraStatsPreviewIgnored = draft.ignoredSlots[slotID] == true or nil

    local icon
    if itemLink or itemID then
        icon = select(10, GetItemInfo(itemLink or itemID))
    end
    if GetItemInfoInstant and (not icon or icon == 0) and (itemLink or itemID) then
        icon = select(5, GetItemInfoInstant(itemLink or itemID))
    end

    if itemLink or itemID then
        iconTexture:SetTexture(icon or "Interface\\Icons\\INV_Misc_QuestionMark")
    else
        iconTexture:SetTexture(nil)
    end
    if unavailableSlots and unavailableSlots[slotID] then
        iconTexture:SetVertexColor(1.0, 0.18, 0.18)
    else
        iconTexture:SetVertexColor(1.0, 1.0, 1.0)
    end
end

RefreshEquipmentSetPreview = function()
    if not tab.frame then
        return
    end

    local shown = tab.frame.equipmentEditMode == true
    local draft = shown and tab.frame.editDraft or nil
    local unavailableSlots = draft and EquipmentSet:GetUnavailableEquipmentSetSlots(draft.items, draft.itemLinks, draft.ignoredSlots) or {}
    tab.frame.previewUnavailableSlots = unavailableSlots
    for _, button in ipairs(itemSlotButtons) do
        if button then
            if draft then
                ApplyEquipmentSetPreviewToSlot(button, draft, unavailableSlots)
            else
                local iconTexture = GetSlotIconTexture(button)
                if iconTexture then
                    iconTexture:SetVertexColor(1.0, 1.0, 1.0)
                end
            end
        end
    end
    RefreshPreviewModel(draft)
    if ExtraStats_RefreshGearSlotVisuals then
        ExtraStats_RefreshGearSlotVisuals()
    end
    if ExtraStats_RefreshGearAlternatives then
        ExtraStats_RefreshGearAlternatives()
    end
end

ClearEquipmentSetPreview = function()
    if tab.frame then
        tab.frame.previewUnavailableSlots = nil
    end
    for _, button in ipairs(itemSlotButtons) do
        if button then
            local iconTexture = GetSlotIconTexture(button)
            if iconTexture then
                iconTexture:SetTexture(nil)
                iconTexture:SetVertexColor(1.0, 1.0, 1.0)
            end
            button.ExtraStatsPreviewItemID = nil
            button.ExtraStatsPreviewItemLink = nil
            button.ExtraStatsPreviewIgnored = nil
        end
    end
    RefreshPreviewModel(nil)
    if ExtraStats_RefreshGearSlotVisuals then
        ExtraStats_RefreshGearSlotVisuals()
    end
    if ExtraStats_RefreshGearAlternatives then
        ExtraStats_RefreshGearAlternatives()
    end
end

function ExtraStats_IsEquipmentSetEditMode()
    return tab.frame and tab.frame.equipmentEditMode == true and tab.frame.editDraft ~= nil
end

function ExtraStats_GetEditedEquipmentSetSlotItem(slotID)
    local draft = tab.frame and tab.frame.editDraft
    local slotName = GetSlotName(slotID)
    if not draft or not slotName then
        return nil, nil, false
    end
    return draft.items[slotName], draft.itemLinks[slotName], draft.ignoredSlots[slotID] == true
end

function ExtraStats_SetEditedEquipmentSetSlotItem(slotID, itemLink)
    local draft = tab.frame and tab.frame.editDraft
    local slotName = GetSlotName(slotID)
    if not draft or not slotName then
        return false
    end

    local changed, changedSlots, errorMessage = EquipmentSet:SimulateEquipmentSetSlotChange(
        draft.items,
        draft.itemLinks,
        draft.ignoredSlots,
        slotID,
        itemLink
    )
    if not changed then
        if errorMessage and UIErrorsFrame then
            UIErrorsFrame:AddMessage(errorMessage, 1.0, 0.1, 0.1, 1.0)
        end
        return false
    end
    draft.dirty = true

    for changedSlotID in pairs(changedSlots) do
        EquipmentSet:UnignoreSlotForSave(changedSlotID)
        SetIgnoredSlotVisual(changedSlotID, false)
    end
    RefreshEquipmentSetPreview()
    ExtraStats_PaperDollEquipmentManagerPane_Update()
    return true
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
        local draft = tab.frame.editDraft
        if draft and draft.setID == tab.frame.selectedSetID then
            draft.ignoredSlots[slotID] = ignored or nil
            draft.dirty = true
        end
    end

    SetIgnoredSlotVisual(slotID, ignored)
    RefreshEquipmentSetPreview()
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
    UpdateIgnoreEditToggle(button)
    UpdateIgnoredSlotOverlays()
end

ClearIgnoredSlotVisuals = function()
    for _, button in ipairs(itemSlotButtons) do
        if button and button.ignored then
            button.ignored = nil
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
        UIErrorsFrame:AddMessage(ExtraStats:translate("gearsets.reserved_name"), 1.0, 0.1, 0.1, 1.0)
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
    PrepareDefaultNewSetSlots()
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

    local updateFromEquippedInfo = UIDropDownMenu_CreateInfo()
    updateFromEquippedInfo.text = ExtraStats:translate("gearsets.update_from_equipped")
    updateFromEquippedInfo.notCheckable = true
    updateFromEquippedInfo.func = function()
        CloseDropDownMenus()
        if EquipmentSet:UpdateEquipmentSetFromCurrentItems(setID) then
            SelectSetByID(setID)
            ExtraStats_PaperDollEquipmentManagerPane_Update()
        end
    end
    UIDropDownMenu_AddButton(updateFromEquippedInfo, UIDROPDOWN_MENU_LEVEL)

    if EquipmentSet:CanMoveEquipmentSetBank(setID, "toBank") then
        local moveToBankInfo = UIDropDownMenu_CreateInfo()
        moveToBankInfo.text = ExtraStats:translate("gearsets.move_to_bank")
        moveToBankInfo.notCheckable = true
        moveToBankInfo.disabled = EquipmentSet:IsBankTransferActive()
        moveToBankInfo.func = function()
            CloseDropDownMenus()
            ExtraStats_RequestEquipmentSetBankMove(setID, "toBank")
        end
        UIDropDownMenu_AddButton(moveToBankInfo, UIDROPDOWN_MENU_LEVEL)
    end

    if EquipmentSet:CanMoveEquipmentSetBank(setID, "fromBank") then
        local moveFromBankInfo = UIDropDownMenu_CreateInfo()
        moveFromBankInfo.text = ExtraStats:translate("gearsets.move_from_bank")
        moveFromBankInfo.notCheckable = true
        moveFromBankInfo.disabled = EquipmentSet:IsBankTransferActive()
        moveFromBankInfo.func = function()
            CloseDropDownMenus()
            ExtraStats_RequestEquipmentSetBankMove(setID, "fromBank")
        end
        UIDropDownMenu_AddButton(moveFromBankInfo, UIDROPDOWN_MENU_LEVEL)
    end

    local mountSetID = EquipmentSet:GetMountEquipmentSet()
    local mountInfo = UIDropDownMenu_CreateInfo()
    mountInfo.text = ExtraStats:translate("gearsets.auto_mount")
    mountInfo.checked = mountSetID == setID
    mountInfo.func = function()
        EquipmentSet:AssignMountEquipmentSet(setID)
        ExtraStats_PaperDollEquipmentManagerPane_Update()
    end
    UIDropDownMenu_AddButton(mountInfo, UIDROPDOWN_MENU_LEVEL)

    if mountSetID == setID then
        local clearMountInfo = UIDropDownMenu_CreateInfo()
        clearMountInfo.text = ExtraStats:translate("gearsets.clear_mount")
        clearMountInfo.notCheckable = true
        clearMountInfo.func = function()
            EquipmentSet:UnassignMountEquipmentSet()
            ExtraStats_PaperDollEquipmentManagerPane_Update()
        end
        UIDropDownMenu_AddButton(clearMountInfo, UIDROPDOWN_MENU_LEVEL)
    end

    local pvpSetID = EquipmentSet:GetPvPEquipmentSet()
    local pvpInfo = UIDropDownMenu_CreateInfo()
    pvpInfo.text = ExtraStats:translate("gearsets.auto_pvp")
    pvpInfo.checked = pvpSetID == setID
    pvpInfo.func = function()
        EquipmentSet:AssignPvPEquipmentSet(setID)
        ExtraStats_PaperDollEquipmentManagerPane_Update()
    end
    UIDropDownMenu_AddButton(pvpInfo, UIDROPDOWN_MENU_LEVEL)

    if pvpSetID == setID then
        local clearPvPInfo = UIDropDownMenu_CreateInfo()
        clearPvPInfo.text = ExtraStats:translate("gearsets.clear_pvp")
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
            assignInfo.text = ExtraStats:translate("gearsets.auto_spec", specGroup, specName)
        else
            assignInfo.text = ExtraStats:translate("gearsets.auto_for", specLabel)
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
        clearInfo.text = ExtraStats:translate("gearsets.clear_spec")
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
        GearSetButton_SetSpecInfo(self, 0, ExtraStats:translate("gearsets.mount_set"))
        return
    end

    if GetPvPEquipmentSet() == self.setID then
        GearSetButton_SetSpecInfo(self, 0, ExtraStats:translate("gearsets.pvp_set"))
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
    EnsureGearSetEditorSlotButtons()
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
