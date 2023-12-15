local name = "Engraving"
local Plugin = {
    name = name
}

table.insert(ExtraStats.plugins, Plugin)

local GEAR_SLOT_FRAMES = {
    CharacterHeadSlot,
    CharacterNeckSlot,
    CharacterShoulderSlot,
    CharacterBackSlot,
    CharacterChestSlot,
    CharacterWristSlot,
    CharacterHandsSlot,
    CharacterWaistSlot,
    CharacterLegsSlot,
    CharacterFeetSlot,
    CharacterFinger0Slot,
    CharacterFinger1Slot,
    CharacterTrinket0Slot,
    CharacterTrinket1Slot,
    CharacterMainHandSlot,
    CharacterSecondaryHandSlot,
    CharacterRangedSlot
}

function Plugin:Setup()
    if not C_Engraving.IsEngravingEnabled() then
        return ;
    end

    if (not EngravingFrame) then
        if (not C_AddOns.IsAddOnLoaded("Blizzard_EngravingUI")) then
            UIParentLoadAddOn("Blizzard_EngravingUI");
        end
    end

    function ToggleEngravingFrame()
        if (EngravingFrame and EngravingFrame:IsVisible()) then
            EngravingFrame:Hide();
            C_Engraving.SetEngravingModeEnabled(false);
        else
            EngravingFrame:Show();
            C_Engraving.SetEngravingModeEnabled(true);
        end

        RefreshRuneFrameControlButton();
    end

    ExtraStats:On("character.window.show", function()
        RuneFrameControlButton:ClearAllPoints();
        RuneFrameControlButton:SetPoint("BOTTOMRIGHT", CharacterFrame.Sidebar, 35, 0)

        SetUIPanelAttribute(CharacterFrame, "width", 580);
        UpdateUIPanelPositions(CharacterFrame);
    end);

    EngravingFrame:SetScript("OnShow", function(self)
        --OpenAllBags(self);
        C_Engraving.RefreshRunesList();
        C_Engraving.SetSearchFilter("");

        EngravingFrame_UpdateRuneList(self);

        self:RegisterEvent("PLAYER_EQUIPMENT_CHANGED");
        self:RegisterEvent("NEW_RECIPE_LEARNED");

        RefreshRuneFrameControlButton();

        SetUIPanelAttribute(CharacterFrame, "width", 790);
        UpdateUIPanelPositions(CharacterFrame);

        for _, slot in pairs(GEAR_SLOT_FRAMES) do
            PaperDollItemSlotButton_RefreshRuneIcon(slot, true);
        end

        OpenAllBags(self)

    end);

    EngravingFrame:SetScript("OnHide", function(self)
        self:UnregisterEvent("PLAYER_EQUIPMENT_CHANGED");
        self:UnregisterEvent("NEW_RECIPE_LEARNED");

        RefreshRuneFrameControlButton();

        SetUIPanelAttribute(CharacterFrame, "width", 580);
        UpdateUIPanelPositions(CharacterFrame);

        CloseAllBags(self);
    end);

    ExtraStats:On("character.window.show", function()
        if C_Engraving.GetEngravingModeEnabled() then
            EngravingFrame:Show()
        end
    end);

    ExtraStats:On("character.window.hide", function()
        if C_Engraving.GetEngravingModeEnabled() then
            EngravingFrame:Hide()
        end
    end);

end