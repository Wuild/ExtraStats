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

local function ApplyIgnoredSlotsForSet(setID)
    ExtraStats_PaperDollFrame_ClearIgnoredSlots()

    if not setID then
        return
    end

    local ignored = EquipmentSet:GetIgnoredSlots(setID)
    for slotID, isIgnored in pairs(ignored) do
        if isIgnored then
            ExtraStats_PaperDollFrame_IgnoreSlot(slotID)
        end
    end
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
    HybridScrollFrame_OnLoad(self)
    self.update = ExtraStats_PaperDollEquipmentManagerPane_Update
    HybridScrollFrame_CreateButtons(self, "ExtraGearSetButtonTemplate", 2, -(self.EquipSet:GetHeight() + 4))

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
        if success and setID and tab.frame then
            SelectSetByID(setID)
            if self:IsShown() then
                ExtraStats_PaperDollEquipmentManagerPane_Update()
            end
        end
    end)
end

function ExtraStats_PaperDollEquipmentManagerPane_OnShow(self)
    ExtraStats_PaperDollEquipmentManagerPane_Update()
    ExtraStats:Trigger("gear.tab.show", self)
end

function ExtraStats_PaperDollEquipmentManagerPane_OnHide(self)
    ExtraStats_PaperDollFrame_ClearIgnoredSlots()
    ExtraStats_GearManagerDialogPopup:Hide()
    StaticPopup_Hide("CONFIRM_SAVE_EQUIPMENT_SET")
    StaticPopup_Hide("CONFIRM_DELETE_EQUIPMENT_SET")
    StaticPopup_Hide("ExtraStats_CONFIRM_OVERWRITE_EQUIPMENT_SET")
    ExtraStats:Trigger("gear.tab.hide", self)
end

function ExtraStats_PaperDollEquipmentManagerPane_OnEvent(self, event, ...)
    if event == "EQUIPMENT_SWAP_FINISHED" then
        local completed, setID = ...
        if completed and setID then
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
    for i = 1, #self.buttons do
        local button = self.buttons[i]
        if button:IsShown() and button:IsMouseOver() and button.name and not isEquipInProgress then
            button.DeleteButton:Show()
            button.EditButton:Show()
            button.HighlightBar:Show()
        else
            button.DeleteButton:Hide()
            button.EditButton:Hide()
            button.HighlightBar:Hide()
        end
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

function ExtraStats_PaperDollEquipmentManagerPane_Update()
    if not tab.frame then
        return
    end

    local selectedSetID = tab.frame.selectedSetID
    if selectedSetID and not EquipmentSet:GetEquipmentSetInfo(selectedSetID) then
        SelectSetByID(nil)
        selectedSetID = nil
    end

    local isEquipInProgress = EquipmentSet:IsEquipmentSwapActive()
    local selectedSetName, _, _, isEquipped = EquipmentSet:GetEquipmentSetInfo(selectedSetID or 0)
    if selectedSetID and selectedSetName and not isEquipInProgress then
        PaperDollEquipmentManagerPaneSaveSet:Enable()
        if isEquipped then
            PaperDollEquipmentManagerPaneEquipSet:Disable()
        else
            PaperDollEquipmentManagerPaneEquipSet:Enable()
        end
    else
        PaperDollEquipmentManagerPaneSaveSet:Disable()
        PaperDollEquipmentManagerPaneEquipSet:Disable()
    end

    local ids = GetSetIDsSorted()
    local numSets = #ids
    local numRows = numSets
    if numSets < MAX_EQUIPMENT_SETS_PER_PLAYER then
        numRows = numRows + 1
    end

    HybridScrollFrame_Update(tab.frame, numRows * ExtraStats_EQUIPMENTSET_BUTTON_HEIGHT + PaperDollEquipmentManagerPaneEquipSet:GetHeight() + 20, tab.frame:GetHeight())

    local scrollOffset = HybridScrollFrame_GetOffset(tab.frame)
    local buttons = tab.frame.buttons

    for i = 1, #buttons do
        local row = i + scrollOffset
        local button = buttons[i]
        if row <= numRows then
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

function ExtraStats_GearSetButton_OnEnter(self)
    if self.name and self.name ~= "" then
        GameTooltip_SetDefaultAnchor(GameTooltip, self)
        GameTooltip:SetEquipmentSet(self.name)
    end
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
    ExtraStats_PaperDollFrame_IgnoreSlot(4)
    ExtraStats_PaperDollFrame_IgnoreSlot(19)
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

function ExtraStats_PaperDollFrame_ClearIgnoredSlots()
    EquipmentSet:ClearIgnoredSlotsForSave()
    for _, button in ipairs(itemSlotButtons) do
        if button and button.ignored then
            button.ignored = nil
            PaperDollItemSlotButton_Update(button)
        end
    end
end

function ExtraStats_PaperDollFrame_IgnoreSlot(slot)
    local button = itemSlotButtons[slot]
    if not button then
        return
    end

    EquipmentSet:IgnoreSlotForSave(slot)
    button.ignored = true
    PaperDollItemSlotButton_Update(button)
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

    PaperDollEquipmentManagerPaneSaveSet:Disable()
    PaperDollEquipmentManagerPaneEquipSet:Disable()
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
    local gearSetButton = dropdownFrame.gearSetButton
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

function GearSetButton_SetSpecInfo(self, specID, specName)
    if specID and specID > 0 and specName and specName ~= "" then
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

    local specGroup = GetEquipmentSetAssignedSpec(self.setID)
    if not specGroup then
        GearSetButton_SetSpecInfo(self, nil)
        return
    end

    local _, _, specID, specName = EquipmentSet:GetSpecGroupInfo(specGroup)
    GearSetButton_SetSpecInfo(self, specID, specName)
end

function tab:init()
    local frame = CreateFrame("ScrollFrame", "PaperDollEquipmentManagerPane", PaperDollFrame, "PaperDollEquipmentManagerPaneTemplate")
    tab.DialogPopup = CreateFrame("Frame", "ExtraStats_GearManagerDialogPopup", frame, "ExtraGearManagerDialogPopupTemplate")
    tab.frame = frame
end

function tab:IsVisible()
end

function tab:show()
end

function tab:hide()
end
