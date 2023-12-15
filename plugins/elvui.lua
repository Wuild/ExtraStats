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

    --ExtraStats:On("category:build", function(frame)
    --    frame:StripTextures()
    --    frame:CreateBackdrop()
    --    frame:SetHeight(30)
    --end);
    --
    --ExtraStats:On("stat:build", function(frame)
    --
    --end);


    ExtraStats:On("character.window.hide", function()
        CharacterFrame.backdrop:Show()
    end);

    ExtraStats:On("character.window.show", function()
        CharacterFrame.backdrop:Hide()
        
        CharacterModelFrame:StripTextures()
        CharacterModelFrameBackgroundTopLeft:Kill()
        CharacterModelFrameBackgroundTopRight:Kill()
        CharacterModelFrameBackgroundBotLeft:Kill()
        CharacterModelFrameBackgroundBotRight:Kill()

        PaperDollFrame.TitleBg:StripTextures()
        PaperDollFrame.TopBorder:StripTextures()

        CharacterStatsPaneScrollBar:StripTextures()
        S:HandleScrollBar(CharacterStatsPaneScrollBar)

        CharacterFrameInsetRight:StripTextures()
        --CharacterFrameInsetRight:CreateBackdrop()

        PaperDollFrame.TitleBg:CreateBackdrop('Transparent')
        PaperDollFrame.bg:CreateBackdrop('Transparent')

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