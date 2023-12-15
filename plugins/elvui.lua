local name = "ElvUI"
local Plugin = {
    name = name
}

table.insert(ExtraStats.plugins, Plugin)

function Plugin:Setup()

    if not ElvUI then
        return
    end

    if ExtraStats.db.char.disabledPlugins[name] == true then
        return
    end

    local E, L, V, P, G = unpack(ElvUI)

    if not (E.private.skins.blizzard.enable and E.private.skins.blizzard.character) then
        return
    end

    ExtraStats.categoryYOffset = -5;
    ExtraStats.statYOffset = -5;

    ExtraStats:debug("ELVUI Detected")

    S = E:GetModule('Skins')
    S:CharacterFrame()

    ExtraStats:On("category:build", function(frame)
        frame:StripTextures()
        frame:CreateBackdrop("transparent")
        frame:SetHeight(30)
    end);
    --
    --ExtraStats:On("stat:build", function(frame)
    --    frame:StripTextures()
    --    frame:CreateBackdrop()
    --end);


    ExtraStats:On("character.window.hide", function()
        CharacterFrame.backdrop:Show()
    end);

    ExtraStats:On("character.window.show", function()

        CharacterFrameInset:StripTextures()
        CharacterFrameInsetRight:StripTextures()

        CharacterModelFrame:StripTextures()
        CharacterModelFrameBackgroundTopLeft:Kill()
        CharacterModelFrameBackgroundTopRight:Kill()
        CharacterModelFrameBackgroundBotLeft:Kill()
        CharacterModelFrameBackgroundBotRight:Kill()

        PaperDollFrame.TitleBg:StripTextures()
        PaperDollFrame.TopBorder:StripTextures()

        CharacterFrameInsetRight:StripTextures()
        CharacterFramePortrait:StripTextures()

        PaperDollFrame.bg:StripTextures()
        PaperDollFrame.TitleBg:StripTextures()
        PaperDollFrame.PortraitFrame:StripTextures()
        PaperDollFrame.TopRightCorner:StripTextures()
        PaperDollFrame.TopLeftCorner:StripTextures()
        PaperDollFrame.TopBorder:StripTextures()
        PaperDollFrame.TopTileStreaks:StripTextures()
        PaperDollFrame.BotLeftCorner:StripTextures()
        PaperDollFrame.BotRightCorner:StripTextures()
        PaperDollFrame.BottomBorder:StripTextures()
        PaperDollFrame.LeftBorder:StripTextures()
        PaperDollFrame.RightBorder:StripTextures()

        CharacterHeadSlotFrame:StripTextures()
        CharacterNeckSlotFrame:StripTextures()
        CharacterShoulderSlotFrame:StripTextures()
        CharacterBackSlotFrame:StripTextures()
        CharacterChestSlotFrame:StripTextures()
        CharacterShirtSlotFrame:StripTextures()
        CharacterTabardSlotFrame:StripTextures()
        CharacterWristSlotFrame:StripTextures()
        -- Creating ItemSlot textures under item icons - Right side
        CharacterHandsSlotFrame:StripTextures()
        CharacterWaistSlotFrame:StripTextures()
        CharacterLegsSlotFrame:StripTextures()
        CharacterFeetSlotFrame:StripTextures()
        CharacterFinger0SlotFrame:StripTextures()
        CharacterFinger1SlotFrame:StripTextures()
        CharacterTrinket0SlotFrame:StripTextures()
        CharacterTrinket1SlotFrame:StripTextures()
        -- Creating ItemSlot textures under item icons - Bottom side
        CharacterMainHandSlotFrame:StripTextures()
        CharacterSecondaryHandSlotFrame:StripTextures()
        CharacterRangedSlotFrame:StripTextures()
        -- Creating ItemSlot textures under item icons - Borders for bottom items (left and right vertical lines)
        CharacterMainHandSlotFrame:StripTextures()
        CharacterMainHandSlot.BorderLeft:StripTextures()
        CharacterRangedSlotFrame:StripTextures()
        CharacterRangedSlot.BorderRight:StripTextures()

        --PaperDollFrame.TitleBg:CreateBackdrop()
        --
        ----PaperDollFrame.bg:StripTextures()
        ----PaperDollFrame.bg:CreateBackdrop()
        --
        CharacterStatsPane.scrollBar:StripTextures()
        S:HandleScrollBar(CharacterStatsPane.scrollBar)

        PaperDollTitlesPane.scrollBar:StripTextures()
        S:HandleScrollBar(PaperDollTitlesPane.scrollBar)

        PaperDollEquipmentManagerPane.scrollBar:StripTextures()
        S:HandleScrollBar(PaperDollEquipmentManagerPane.scrollBar)
    end)

    --ExtraStats.window.Inset:Hide()
    --S:HandleFrame(ExtraStats.window, true, nil)
    --ExtraStats.window.ScrollFrame:StripTextures()
    --S:HandleScrollBar(ExtraStats.window.ScrollFrame.ScrollBar)
    --S:HandleScrollBar(ExtraStats.window.ScrollFrame.ScrollBar)
    --
    --ExtraStats.window:SetPoint("LEFT", PaperDollFrame, "RIGHT", -33, 30)

end