local tab = ExtraStats:CreateModule("character.gear")

tab.frame = nil

ExtraStats_EQUIPMENTSET_BUTTON_HEIGHT = 44;

local STRIPE_COLOR = { r = 0.9, g = 0.9, b = 1 };
local itemSlotButtons = {
    CharacterHeadSlot, -- 1
    CharacterNeckSlot, -- 2
    CharacterShoulderSlot, -- 3
    CharacterShirtSlot, -- 4
    CharacterChestSlot, -- 5
    CharacterWaistSlot, -- 6
    CharacterLegsSlot, -- 7
    CharacterFeetSlot, -- 8
    CharacterWristSlot, -- 9
    CharacterHandsSlot, -- 10
    CharacterFinger0Slot, -- 11
    CharacterFinger1Slot, -- 12
    CharacterTrinket0Slot, -- 13
    CharacterTrinket1Slot, -- 14
    CharacterBackSlot, -- 15
    CharacterMainHandSlot, -- 16
    CharacterSecondaryHandSlot, -- 17
    CharacterRangedSlot, -- 18
    CharacterTabardSlot         -- 19
};

function ExtraStats_PaperDollEquipmentManagerPane_OnLoad(self)
    HybridScrollFrame_OnLoad(self);
    self.update = ExtraStats_PaperDollEquipmentManagerPane_Update;
    HybridScrollFrame_CreateButtons(self, "ExtraGearSetButtonTemplate", 2, -(self.EquipSet:GetHeight() + 4));

    self:RegisterEvent("EQUIPMENT_SWAP_FINISHED");
    self:RegisterEvent("EQUIPMENT_SETS_CHANGED");
    self:RegisterEvent("PLAYER_EQUIPMENT_CHANGED");
    self:RegisterEvent("BAG_UPDATE");

    --PaperDollFrameItemFlyoutButton_OnClick(self, button, down);
    --hooksecurefunc("PaperDollFrameItemFlyoutButton_OnClick", ExtraStats_EquipmentManager_CheckSetChange);
end

function ExtraStats_PaperDollEquipmentManagerPane_OnShow(self)
    HybridScrollFrame_CreateButtons(tab.frame, "ExtraGearSetButtonTemplate");
    ExtraStats_PaperDollEquipmentManagerPane_Update();

    C_EquipmentSet.ClearIgnoredSlotsForSave(); -- added this line because default one has it

    PaperDollFrameItemPopoutButton_ShowAll();
end

function ExtraStats_PaperDollEquipmentManagerPane_OnHide(self)
    PaperDollFrameItemPopoutButton_HideAll();

    ExtraStats_PaperDollFrame_ClearIgnoredSlots();

    ExtraStats_GearManagerDialogPopup:Hide();
    StaticPopup_Hide("CONFIRM_SAVE_EQUIPMENT_SET");
    StaticPopup_Hide("ExtraStats_CONFIRM_OVERWRITE_EQUIPMENT_SET");
    GearManagerDialog:Hide();
end

function ExtraStats_PaperDollEquipmentManagerPane_OnEvent(self, event, ...)

    if (event == "EQUIPMENT_SWAP_FINISHED") then
        local completed, setID = ...;
        if (completed) then
            PlaySound(SOUNDKIT.PUT_DOWN_SMALL_CHAIN); -- plays the equip sound for plate mail
            if (self:IsShown()) then
                self.selectedSetID = setID;
                ExtraStats_PaperDollEquipmentManagerPane_Update();
            end
        end
    end

    if (self:IsShown()) then
        if (event == "EQUIPMENT_SETS_CHANGED") then
            ExtraStats_PaperDollEquipmentManagerPane_Update();
        elseif (event == "PLAYER_EQUIPMENT_CHANGED" or event == "BAG_UPDATE") then
            ExtraStats_PaperDollEquipmentManagerPane_Update();
            -- This queues the update to only happen once at the end of the frame
            self.queuedUpdate = true;
        end
    end
end

function ExtraStats_PaperDollEquipmentManagerPane_OnUpdate(self)
    for i = 1, #self.buttons do
        local button = self.buttons[i];
        if (button:IsMouseOver()) then
            if (button.name) then
                button.DeleteButton:Show();
                button.EditButton:Show();
            else
                button.DeleteButton:Hide();
                button.EditButton:Hide();
            end
            button.HighlightBar:Show();
        else
            button.DeleteButton:Hide();
            button.EditButton:Hide();
            button.HighlightBar:Hide();
        end
    end
    if (self.queuedUpdate) then
        ExtraStats_PaperDollEquipmentManagerPane_Update();
        self.queuedUpdate = false;
    end
end

function ExtraStats_PaperDollEquipmentManagerPaneEquipSet_OnClick (index)
    local selectedSetID = index;

    if type(selectedSetID) ~= "number" then
        selectedSetID = tab.frame.selectedSetID;
    end

    --[[ if ( selectedSetName and selectedSetName ~= "") then ]]

    PlaySound(SOUNDKIT.IG_CHARACTER_INFO_TAB);
    if (InCombatLockdown()) then
        UIErrorsFrame:AddMessage(ERR_CLIENT_LOCKED_OUT, 1.0, 0.1, 0.1, 1.0);
    elseif (selectedSetID) then
        if GetEquipmentSetAssignedSpec(selectedSetID) then
            if GetEquipmentSetAssignedSpec(selectedSetID) == GetActiveTalentGroup() then
                C_EquipmentSet.UseEquipmentSet(selectedSetID);
            else
                SetActiveTalentGroup(GetEquipmentSetAssignedSpec(selectedSetID))
            end
        else
            C_EquipmentSet.UseEquipmentSet(selectedSetID);
        end
    end
end

function ExtraStats_PaperDollEquipmentManagerPaneSaveSet_OnClick (self)
    local selectedSetName = tab.frame.selectedSetName;
    local selectedSetID = tab.frame.selectedSetID;
    if (selectedSetID) then
        local dialog = StaticPopup_Show("CONFIRM_SAVE_EQUIPMENT_SET", selectedSetName);
        if (dialog) then
            dialog.data = selectedSetID;
        else
            UIErrorsFrame:AddMessage(ERR_CLIENT_LOCKED_OUT, 1.0, 0.1, 0.1, 1.0);
        end
    end
end

function ExtraStats_PaperDollEquipmentManagerPane_Update()
    -- HACK to make ignore slots working "correct"
    if (tab.frame.tempSetID) then
        return ;
    elseif (C_EquipmentSet.GetEquipmentSetID("ExtraStats_TEMP_SET")) then
        C_EquipmentSet.DeleteEquipmentSet(C_EquipmentSet.GetEquipmentSetID("ExtraStats_TEMP_SET"));
    end

    local _, _, setID, isEquipped = ExtraStats_GetEquipmentSetInfoByName(tab.frame.selectedSetName or "");
    if (setID) then
        PaperDollEquipmentManagerPaneSaveSet:Enable();
        if (isEquipped) then
            --PaperDollEquipmentManagerPaneSaveSet:Disable();
            PaperDollEquipmentManagerPaneEquipSet:Disable();
        else
            PaperDollEquipmentManagerPaneEquipSet:Enable();
        end
    else
        PaperDollEquipmentManagerPaneSaveSet:Disable();
        PaperDollEquipmentManagerPaneEquipSet:Disable();

        -- Clear selected equipment set if it doesn't exist
        if (tab.frame.selectedSetID) then
            tab.frame.selectedSetID = nil;
            ExtraStats_PaperDollFrame_ClearIgnoredSlots();
        end
    end

    local numSets = C_EquipmentSet.GetNumEquipmentSets();
    local numRows = numSets;
    if (numSets < MAX_EQUIPMENT_SETS_PER_PLAYER) then
        numRows = numRows + 1;  -- "Add New Set" button
    end

    HybridScrollFrame_Update(tab.frame, numRows * ExtraStats_EQUIPMENTSET_BUTTON_HEIGHT + PaperDollEquipmentManagerPaneEquipSet:GetHeight() + 20, tab.frame:GetHeight());

    local scrollOffset = HybridScrollFrame_GetOffset(tab.frame);
    local buttons = tab.frame.buttons;
    local selectedSetID = tab.frame.selectedSetID;
    local name, icon, button, numLost;
    for i = 1, #buttons do
        if (i + scrollOffset <= numRows) then
            button = buttons[i];
            buttons[i]:Show();
            button:Enable();
            button.setID = nil;

            if (i + scrollOffset <= numSets) then
                -- Normal equipment set button
                local sets = C_EquipmentSet.GetEquipmentSetIDs();
                name, icon, setID, isEquipped, _, _, _, numLost, _ = C_EquipmentSet.GetEquipmentSetInfo(sets[i + scrollOffset]);
                button.name = name;
                button.iconTexture = icon;
                button.setID = setID;
                button.text:SetText(name);
                if (numLost > 0) then
                    button.text:SetTextColor(RED_FONT_COLOR.r, RED_FONT_COLOR.g, RED_FONT_COLOR.b);
                else
                    button.text:SetTextColor(NORMAL_FONT_COLOR.r, NORMAL_FONT_COLOR.g, NORMAL_FONT_COLOR.b);
                end
                if (icon) then
                    button.icon:SetTexture(icon);
                else
                    button.icon:SetTexture("Interface\\Icons\\INV_Misc_QuestionMark");
                end

                if (button.setID == selectedSetID) then
                    button.SelectedBar:Show();
                else
                    button.SelectedBar:Hide();
                end

                if (isEquipped) then
                    button.Check:Show();
                else
                    button.Check:Hide();
                end
                button.icon:SetSize(36, 36);
                button.icon:SetPoint("LEFT", 4, 0);
            else
                -- This is the Add New button
                button.name = nil;
                button.iconTexture = nil;
                button.text:SetText(PAPERDOLL_NEWEQUIPMENTSET);
                button.text:SetTextColor(GREEN_FONT_COLOR.r, GREEN_FONT_COLOR.g, GREEN_FONT_COLOR.b);
                button.icon:SetTexture("Interface\\PaperDollInfoFrame\\Character-Plus");
                button.icon:SetSize(30, 30);
                button.icon:SetPoint("LEFT", 7, 0);
                button.Check:Hide();
                button.SelectedBar:Hide();
            end

            buttons[i].BgTop:Hide();
            buttons[i].BgBottom:Hide();
            buttons[i].BgMiddle:Hide();

            buttons[i].BgMiddle:SetPoint("TOP");
            buttons[i].BgMiddle:SetPoint("BOTTOM");
            if ((i + scrollOffset) % 2 == 0) then
                buttons[i].Stripe:SetColorTexture(STRIPE_COLOR.r, STRIPE_COLOR.g, STRIPE_COLOR.b);
                buttons[i].Stripe:SetAlpha(0.1);
                buttons[i].Stripe:Show();
            else
                buttons[i].Stripe:Hide();
            end
        else
            buttons[i]:Hide();
        end

        GearSetButton_UpdateSpecInfo(buttons[i]);
    end

end

function ExtraStats_GetEquipmentSetInfoByName(arg)
    -- arg could be: "", "name", 1 (number),
    if (type(arg) == "string" and arg ~= "") then
        if (C_EquipmentSet.GetEquipmentSetID(arg) ~= nil) then
            return C_EquipmentSet.GetEquipmentSetInfo(C_EquipmentSet.GetEquipmentSetID(arg));
        else
            return nil;
        end
    elseif (arg == "") then
        return nil;
    else
        return C_EquipmentSet.GetEquipmentSetInfo(arg);
    end
end

function ExtraStats_GearSetButton_OnEnter (self)
    if (self.name and self.name ~= "") then
        GameTooltip_SetDefaultAnchor(GameTooltip, self);
        GameTooltip:SetEquipmentSet(self.name);
    end
end

function ExtraStats_GearSetButton_OnClick (self, button, down)
    GearManagerDialog:Show();

    if (self.setID) then
        ExtraStats_GearManagerDialogPopup:Hide();

        PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON);        -- inappropriately named, but a good sound.
        tab.frame.selectedSetName = self.name;
        tab.frame.selectedSetID = self.setID;
        -- mark the ignored slots
        ExtraStats_PaperDollFrame_ClearIgnoredSlots();
        ExtraStats_PaperDollFrame_IgnoreSlotsForSet(self.setID);
        ExtraStats_PaperDollEquipmentManagerPane_Update();
    else
        -- This is the "New Set" button
        ExtraStats_GearManagerDialogPopup:Show();
        --[[ GearManagerDialog:Hide(); ]]

        tab.frame.setID = nil;
        tab.frame.selectedSetName = nil;
        tab.frame.selectedSetID = nil;
        ExtraStats_PaperDollFrame_ClearIgnoredSlots();
        ExtraStats_PaperDollEquipmentManagerPane_Update();

        -- HACK to make ignore slots working "correct"
        tab.frame.tempSetID = 0;
        C_EquipmentSet.CreateEquipmentSet("ExtraStats_TEMP_SET");
        tab.frame.tempSetID = C_EquipmentSet.GetEquipmentSetID("ExtraStats_TEMP_SET");
        for i = 1, (#tab.frame.buttons) do
            if (tab.frame.buttons[i].name == "ExtraStats_TEMP_SET") then
                tab.frame.buttons[i]:Hide();
                break ;
            end
        end

        -- Ignore shirt and tabard by default
        ExtraStats_PaperDollFrame_IgnoreSlot(4);
        ExtraStats_PaperDollFrame_IgnoreSlot(19);
    end
    StaticPopup_Hide("CONFIRM_SAVE_EQUIPMENT_SET");
    StaticPopup_Hide("ExtraStats_CONFIRM_OVERWRITE_EQUIPMENT_SET");
end

local EM_ICON_FILENAMES = {};

function ExtraStats_GearManagerDialogPopup_OnLoad (self)
    self.buttons = {};

    local rows = 0;

    local button = CreateFrame("CheckButton", "ExtraStats_GearManagerDialogPopupButton1", ExtraStats_GearManagerDialogPopup, "ExtraGearSetPopupButtonTemplate");
    button:SetPoint("TOPLEFT", 24, -85);
    button:SetID(1);
    tinsert(self.buttons, button);

    local lastPos;
    for i = 2, NUM_GEARSET_ICONS_SHOWN do
        button = CreateFrame("CheckButton", "ExtraStats_GearManagerDialogPopupButton" .. i, ExtraStats_GearManagerDialogPopup, "ExtraGearSetPopupButtonTemplate");
        button:SetID(i);

        lastPos = (i - 1) / NUM_GEARSET_ICONS_PER_ROW;
        if (lastPos == math.floor(lastPos)) then
            button:SetPoint("TOPLEFT", self.buttons[i - NUM_GEARSET_ICONS_PER_ROW], "BOTTOMLEFT", 0, -8);
        else
            button:SetPoint("TOPLEFT", self.buttons[i - 1], "TOPRIGHT", 10, 0);
        end
        tinsert(self.buttons, button);
    end

    self.SetSelection = function(self, fTexture, Value)
        if (fTexture) then
            self.selectedTexture = Value;
            self.selectedIcon = nil;
        else
            self.selectedTexture = nil;
            self.selectedIcon = Value;
        end
    end
end

function ExtraStats_GearManagerDialogPopup_OnShow (self)
    GearManagerDialog:Show();
    PlaySound(SOUNDKIT.IG_CHARACTER_INFO_OPEN);
    self.name = nil;
    self.isEdit = false;
    ExtraStats_RecalculateGearManagerDialogPopup();

    PaperDollEquipmentManagerPaneSaveSet:Disable();
    PaperDollEquipmentManagerPaneEquipSet:Disable();
end

function ExtraStats_GearManagerDialogPopup_OnHide (self)
    GearManagerDialog:Hide();
    ExtraStats_GearManagerDialogPopup.name = nil;
    ExtraStats_GearManagerDialogPopup:SetSelection(true, nil);
    ExtraStats_GearManagerDialogPopupEditBox:SetText("");

    if (not tab.frame.selectedSetName) then
        ExtraStats_PaperDollFrame_ClearIgnoredSlots();
    end

    tab.frame.tempSetID = nil;
    tab.frame.selectedSetID = nil;
    tab.frame.selectedSetName = nil;

    ExtraStats_PaperDollEquipmentManagerPane_Update();
    EM_ICON_FILENAMES = nil;
    collectgarbage();
end

--[[
GetEquipmentSetIconInfo(index) determines the texture and real index of a regular index
	Input: 	index = index into a list of equipped items followed by the macro items. Only tricky part is the equipped items list keeps changing.
	Output: the associated texture for the item, and a index relative to the join point between the lists, i.e. negative for the equipped items
			and positive for the macro items//
]]
function ExtraStats_GetEquipmentSetIconInfo(index)
    return EM_ICON_FILENAMES[index];
end

function ExtraStats_GearManagerDialogPopup_Update ()
    ExtraStats_RefreshEquipmentSetIconInfo();

    local popup = ExtraStats_GearManagerDialogPopup;
    local buttons = popup.buttons;
    local offset = FauxScrollFrame_GetOffset(ExtraStats_GearManagerDialogPopupScrollFrame) or 0;
    local button;
    -- Icon list
    local texture, index, button, realIndex, _;
    for i = 1, NUM_GEARSET_ICONS_SHOWN do
        local button = buttons[i];
        index = (offset * NUM_GEARSET_ICONS_PER_ROW) + i;
        if (index <= #EM_ICON_FILENAMES) then
            texture = ExtraStats_GetEquipmentSetIconInfo(index);
            -- button.name:SetText(index); --dcw
            --[[ button.icon:SetTexture("INTERFACE\\ICONS\\"..texture); ]] --MCFFIX replaced with modern version
            button.icon:SetTexture(texture);
            button:Show();
            if (index == popup.selectedIcon) then
                button:SetChecked(true);
            elseif (texture == popup.selectedTexture) then
                button:SetChecked(true);
                popup:SetSelection(false, index);
            else
                button:SetChecked(false);
            end
        else
            button.icon:SetTexture("");
            button:Hide();
        end

    end

    -- Scrollbar stuff
    FauxScrollFrame_Update(ExtraStats_GearManagerDialogPopupScrollFrame, ceil(#EM_ICON_FILENAMES / NUM_GEARSET_ICONS_PER_ROW), NUM_GEARSET_ICON_ROWS, GEARSET_ICON_ROW_HEIGHT);
end

function ExtraStats_RecalculateGearManagerDialogPopup(setName, iconTexture)
    local popup = ExtraStats_GearManagerDialogPopup;
    if (setName and setName ~= "") then
        ExtraStats_GearManagerDialogPopupEditBox:SetText(setName);
        ExtraStats_GearManagerDialogPopupEditBox:HighlightText(0);
    else
        ExtraStats_GearManagerDialogPopupEditBox:SetText("");
    end

    if (iconTexture) then
        popup:SetSelection(true, iconTexture);
    else
        popup:SetSelection(false, 1);
    end

    --[[
    Scroll and ensure that any selected equipment shows up in the list.
    When we first press "save", we want to make sure any selected equipment set shows up in the list, so that
    the user can just make his changes and press Okay to overwrite.
    To do this, we need to find the current set (by icon) and move the offset of the GearManagerDialogPopup
    to display it. Issue ID: 171220
    ]]
    ExtraStats_RefreshEquipmentSetIconInfo();
    local totalItems = #EM_ICON_FILENAMES;
    local texture, _;
    if (popup.selectedTexture) then
        local foundIndex = nil;
        for index = 1, totalItems do
            texture = ExtraStats_GetEquipmentSetIconInfo(index);
            if (texture == popup.selectedTexture) then
                foundIndex = index;
                break ;
            end
        end
        if (foundIndex == nil) then

            foundIndex = 1;

        end
        -- now make it so we always display at least NUM_GEARSET_ICON_ROWS of data
        local offsetnumIcons = floor((totalItems - 1) / NUM_GEARSET_ICONS_PER_ROW);
        local offset = floor((foundIndex - 1) / NUM_GEARSET_ICONS_PER_ROW);
        offset = offset + min((NUM_GEARSET_ICON_ROWS - 1), offsetnumIcons - offset) - (NUM_GEARSET_ICON_ROWS - 1);
        if (foundIndex <= NUM_GEARSET_ICONS_SHOWN) then
            offset = 0;            --Equipment all shows at the same place.
        end
        FauxScrollFrame_OnVerticalScroll(ExtraStats_GearManagerDialogPopupScrollFrame, offset * GEARSET_ICON_ROW_HEIGHT, GEARSET_ICON_ROW_HEIGHT, nil);
    else
        FauxScrollFrame_OnVerticalScroll(ExtraStats_GearManagerDialogPopupScrollFrame, 0, GEARSET_ICON_ROW_HEIGHT, nil);
    end
    ExtraStats_GearManagerDialogPopup_Update();
end

-- RefreshEquipmentSetIconInfo() counts how many uniquely textured inventory items the player has equipped.
function ExtraStats_RefreshEquipmentSetIconInfo()
    EM_ICON_FILENAMES = {};
    --[[ MCFEM_ICON_FILENAMES[1] = "INV_MISC_QUESTIONMARK"; ]] --MCFFIX replaced with modern version
    EM_ICON_FILENAMES[1] = 134400;
    local index = 2;

    for i = INVSLOT_FIRST_EQUIPPED, INVSLOT_LAST_EQUIPPED do
        local itemTexture = GetInventoryItemTexture("player", i); --MCFFIX returns number instead of texture path now
        if (itemTexture) then
            --[[ MCFEM_ICON_FILENAMES[index] = gsub( strupper(itemTexture), "INTERFACE\\ICONS\\", "" ); ]] --MCFFIX replaced with modern version
            EM_ICON_FILENAMES[index] = itemTexture;
            if (EM_ICON_FILENAMES[index]) then
                index = index + 1;
                --[[
                Currently checks all for duplicates, even though only rings, trinkets, and weapons may be duplicated.
                This version is clean and maintainable.
                ]]
                for j = INVSLOT_FIRST_EQUIPPED, (index - 1) do
                    if (EM_ICON_FILENAMES[index] == EM_ICON_FILENAMES[j]) then
                        EM_ICON_FILENAMES[index] = nil;
                        index = index - 1;
                        break ;
                    end
                end
            end
        end
    end
    GetMacroItemIcons(EM_ICON_FILENAMES);
    GetMacroIcons(EM_ICON_FILENAMES);
end

function ExtraStats_GearManagerDialogPopupOkay_Update()
    local popup = ExtraStats_GearManagerDialogPopup;
    local button = ExtraStats_GearManagerDialogPopupOkay;

    if (popup.selectedIcon and popup.name) then
        button:Enable();
    else
        button:Disable();
    end
end
function ExtraStats_GearManagerDialogPopupOkay_OnClick(self, button, pushed)
    local popup = ExtraStats_GearManagerDialogPopup;

    local icon = ExtraStats_GetEquipmentSetIconInfo(popup.selectedIcon);
    --[[ local setID = C_EquipmentSet.GetEquipmentSetID(popup.name); ]]

    if (popup.name == "ExtraStats_TEMP_SET") then
        -- Can't use addon's temp set name to make a set
        UIErrorsFrame:AddMessage(L["ExtraStats_EQUIPMENT_SETS_NAME_RESERVED"], 1.0, 0.1, 0.1, 1.0);
        return ;
    elseif (ExtraStats_GetEquipmentSetInfoByName(popup.name)) then
        if (popup.isEdit and popup.name ~= popup.origName) then
            -- Not allowed to overwrite an existing set by doing a rename
            UIErrorsFrame:AddMessage(EQUIPMENT_SETS_CANT_RENAME, 1.0, 0.1, 0.1, 1.0);
            return ;
        elseif (not popup.isEdit) then
            --[[ if ( setID ) then ]]
            local dialog = StaticPopup_Show("ExtraStats_CONFIRM_OVERWRITE_EQUIPMENT_SET", popup.name);
            if (dialog) then
                local setID = C_EquipmentSet.GetEquipmentSetID(popup.name);
                dialog.data = setID;
                dialog.selectedIcon = icon;
            else
                UIErrorsFrame:AddMessage(ERR_CLIENT_LOCKED_OUT, 1.0, 0.1, 0.1, 1.0);
            end
            tab.frame.tempSetID = nil;
            return ;
        end
    elseif ((not C_EquipmentSet.GetEquipmentSetID("ExtraStats_TEMP_SET")) and (C_EquipmentSet.GetNumEquipmentSets() >= MAX_EQUIPMENT_SETS_PER_PLAYER)) then
        UIErrorsFrame:AddMessage(EQUIPMENT_SETS_TOO_MANY, 1.0, 0.1, 0.1, 1.0);
        return ;
    elseif ((C_EquipmentSet.GetEquipmentSetID("ExtraStats_TEMP_SET")) and (C_EquipmentSet.GetNumEquipmentSets() >= MAX_EQUIPMENT_SETS_PER_PLAYER + 1)) then
        UIErrorsFrame:AddMessage(EQUIPMENT_SETS_TOO_MANY, 1.0, 0.1, 0.1, 1.0);
        return ;
    end

    if (popup.isEdit) then
        --Modifying a set
        tab.frame.selectedSetName = popup.name;
        local setID = C_EquipmentSet.GetEquipmentSetID(ExtraStats_GearManagerDialogPopup.origName);
        --[[ C_EquipmentSet.SaveEquipmentSet(setID, icon); ]]
        C_EquipmentSet.ModifyEquipmentSet(setID, popup.name, icon);
        C_EquipmentSet.AssignSpecToEquipmentSet(setID, GetActiveTalentGroup())
    else
        -- HACK to make ignore slots working "correct"
        C_EquipmentSet.SaveEquipmentSet(tab.frame.tempSetID, icon);
        C_EquipmentSet.ModifyEquipmentSet(tab.frame.tempSetID, popup.name);

        C_EquipmentSet.AssignSpecToEquipmentSet(tab.frame.tempSetID, GetActiveTalentGroup())
        tab.frame.tempSetID = nil;
        ExtraStats_PaperDollEquipmentManagerPane_Update();
    end

    popup:Hide();
end
function ExtraStats_GearManagerDialogPopupCancel_OnClick()
    ExtraStats_GearManagerDialogPopup:Hide();
end
function ExtraStats_GearSetPopupButton_OnClick(self, button)
    local popup = ExtraStats_GearManagerDialogPopup;
    local offset = FauxScrollFrame_GetOffset(ExtraStats_GearManagerDialogPopupScrollFrame) or 0;
    popup.selectedIcon = (offset * NUM_GEARSET_ICONS_PER_ROW) + self:GetID();
    popup.selectedTexture = nil;
    ExtraStats_GearManagerDialogPopup_Update();
    ExtraStats_GearManagerDialogPopupOkay_Update();
end

function ExtraStats_GearSetButton_OnDoubleClick(self)

    ExtraStats_PaperDollEquipmentManagerPaneEquipSet_OnClick(self.setID)

    --local id = self.setID;
    --PlaySound(SOUNDKIT.IG_CHARACTER_INFO_TAB);
    --if (InCombatLockdown()) then
    --    UIErrorsFrame:AddMessage(ERR_CLIENT_LOCKED_OUT, 1.0, 0.1, 0.1, 1.0);
    --elseif (id) then
    --    if C_EquipmentSet.GetEquipmentSetAssignedSpec(id) then
    --        SetActiveTalentGroup(C_EquipmentSet.GetEquipmentSetAssignedSpec(id))
    --    else
    --        C_EquipmentSet.UseEquipmentSet(id);
    --    end
    --end
    --
    --ExtraStats_PaperDollEquipmentManagerPane_Update()
end

function ExtraStats_PaperDollFrame_ClearIgnoredSlots()
    C_EquipmentSet.ClearIgnoredSlotsForSave();
    for k, button in next, itemSlotButtons do
        if (button.ignored) then
            button.ignored = nil;
            PaperDollItemSlotButton_Update(button);
        end
    end
end

function ExtraStats_PaperDollFrame_IgnoreSlotsForSet (setID)
    local set = C_EquipmentSet.GetIgnoredSlots(setID);
    for slot, ignored in ipairs(set) do
        if (ignored == true) then
            C_EquipmentSet.IgnoreSlotForSave(slot);
            itemSlotButtons[slot].ignored = true;
            PaperDollItemSlotButton_Update(itemSlotButtons[slot]);
        end
    end
end

function ExtraStats_PaperDollFrame_IgnoreSlot(slot)
    C_EquipmentSet.IgnoreSlotForSave(slot);
    itemSlotButtons[slot].ignored = true;
    PaperDollItemSlotButton_Update(itemSlotButtons[slot]);
end

function ExtraStats_GearSetDeleteButton_OnClick(self)
    local dialog = StaticPopup_Show("CONFIRM_DELETE_EQUIPMENT_SET", self:GetParent().name);
    if (dialog) then
        dialog.data = self:GetParent().setID;
    else
        UIErrorsFrame:AddMessage(ERR_CLIENT_LOCKED_OUT, 1.0, 0.1, 0.1, 1.0);
    end
end

function GearSetEditButton_OnLoad(self)
    self.Dropdown = GearSetEditButtonDropDown;
    UIDropDownMenu_Initialize(self.Dropdown, nil, "MENU");
    self.Dropdown.gearSetButton = self:GetParent();
    UIDropDownMenu_SetInitializeFunction(self.Dropdown, GearSetEditButtonDropDown_Initialize);
end

function GetPrimaryTalentTree(spec)
    local cache = {};
    TalentFrame_UpdateSpecInfoCache(cache, false, false, spec);
    return cache.primaryTabIndex;
end

function GearSetEditButtonDropDown_Initialize(dropdownFrame, level, menuList)
    local gearSetButton = dropdownFrame.gearSetButton;

    local info = UIDropDownMenu_CreateInfo();
    info.text = EQUIPMENT_SET_EDIT;
    info.notCheckable = true;
    info.func = function()
        ExtraStats_GearManagerDialogPopup:Show();
        ExtraStats_GearManagerDialogPopup.isEdit = true;
        ExtraStats_GearManagerDialogPopup.origName = gearSetButton.name
        ExtraStats_RecalculateGearManagerDialogPopup(gearSetButton.name, gearSetButton.iconTexture)
    end;
    UIDropDownMenu_AddButton(info, UIDROPDOWN_MENU_LEVEL);

    info = UIDropDownMenu_CreateInfo();
    info.text = EQUIPMENT_SET_ASSIGN_TO_SPEC;
    info.isTitle = true;
    info.notCheckable = true;
    UIDropDownMenu_AddButton(info, UIDROPDOWN_MENU_LEVEL);

    local equipmentSetID = gearSetButton.setID;
    for i = 1, 2 do
        info = UIDropDownMenu_CreateInfo();
        info.checked = function()
            return GetEquipmentSetAssignedSpec(equipmentSetID) == i;
        end;

        info.func = function()
            local currentSpecIndex = GetEquipmentSetAssignedSpec(equipmentSetID);
            if (currentSpecIndex ~= i) then
                AssignSpecToEquipmentSet(equipmentSetID, i);
            else
                UnassignEquipmentSetSpec(equipmentSetID);
            end
            ExtraStats_PaperDollEquipmentManagerPane_Update(true);
        end;

        local specID = GetPrimaryTalentTree(i);
        info.text = GetTalentTabInfo(specID);
        UIDropDownMenu_AddButton(info, UIDROPDOWN_MENU_LEVEL);
    end
end

function AssignSpecToEquipmentSet(SetId, SpecId)
    ExtraStats.db.char.sets[SetId] = SpecId
end

function GetEquipmentSetAssignedSpec(SetId)
    return ExtraStats.db.char.sets[SetId]
end

function UnassignEquipmentSetSpec(SetId)
    ExtraStats.db.char.sets[SetId] = nil
end

function GetEquipmentSetForSpec(SpecId)
    for set, spec in pairs(ExtraStats.db.char.sets) do
        if spec == SpecId then
            return set;
        end
    end
    return nil
end

function GearSetButton_SetSpecInfo(self, specID)
    if (specID and specID > 0) then
        self.specID = specID;
        local name, texture, pointsSpent, fileName = GetTalentTabInfo(specID);
        SetPortraitToTexture(self.SpecIcon, texture);
        self.SpecIcon:Show();
        self.SpecRing:Show();
    else
        self.specID = nil;
        self.SpecIcon:Hide();
        self.SpecRing:Hide();
    end
end

function GearSetButton_UpdateSpecInfo(self)
    if (not self.setID) then
        GearSetButton_SetSpecInfo(self, nil);
        return ;
    end

    local specIndex = GetEquipmentSetAssignedSpec(self.setID);
    if (not specIndex) then
        GearSetButton_SetSpecInfo(self, nil);
        return ;
    end

    local specID = GetPrimaryTalentTree(specIndex);
    GearSetButton_SetSpecInfo(self, specID);
end

function tab:init()
    local frame = CreateFrame("ScrollFrame", "PaperDollEquipmentManagerPane", PaperDollFrame, "PaperDollEquipmentManagerPaneTemplate");

    tab.DialogPopup = CreateFrame("Frame", "ExtraStats_GearManagerDialogPopup", frame, "MCF-GearManagerDialogPopupTemplate");

    frame:RegisterEvent("ACTIVE_TALENT_GROUP_CHANGED")
    frame:RegisterEvent("PLAYER_ENTERING_WORLD");
    frame:RegisterEvent("CHARACTER_POINTS_CHANGED");
    frame:RegisterEvent("UNIT_MODEL_CHANGED");
    frame:RegisterEvent("UNIT_LEVEL");
    frame:RegisterEvent("UNIT_RESISTANCES");
    frame:RegisterEvent("UNIT_STATS");
    frame:RegisterEvent("UNIT_DAMAGE");
    frame:RegisterEvent("UNIT_RANGEDDAMAGE");
    frame:RegisterEvent("UNIT_ATTACK_SPEED");
    frame:RegisterEvent("UNIT_ATTACK_POWER");
    frame:RegisterEvent("UNIT_RANGED_ATTACK_POWER");
    frame:RegisterEvent("UNIT_ATTACK");
    frame:RegisterEvent("UNIT_SPELL_HASTE");
    frame:RegisterEvent("PLAYER_GUILD_UPDATE");
    frame:RegisterEvent("SKILL_LINES_CHANGED");
    frame:RegisterEvent("COMBAT_RATING_UPDATE");
    frame:RegisterEvent("UNIT_NAME_UPDATE");
    frame:RegisterEvent("VARIABLES_LOADED");
    frame:RegisterEvent("PLAYER_TALENT_UPDATE");
    frame:RegisterEvent("BAG_UPDATE");
    frame:RegisterEvent("PLAYER_EQUIPMENT_CHANGED");
    frame:RegisterEvent("PLAYER_DAMAGE_DONE_MODS");
    frame:RegisterEvent("ACTIVE_TALENT_GROUP_CHANGED");
    frame:RegisterEvent("UNIT_MAXHEALTH");

    frame:SetScript("OnEvent", function(self, event)
        if event == "ACTIVE_TALENT_GROUP_CHANGED" then
            C_EquipmentSet.UseEquipmentSet(GetEquipmentSetForSpec(GetActiveTalentGroup()));
        end

        ExtraStats_PaperDollEquipmentManagerPane_Update()
    end)

    tab.frame = frame;
end

function tab:IsVisible()
    --return frame and frame:IsVisible()
end

function tab:show()

end

function tab:hide()

end