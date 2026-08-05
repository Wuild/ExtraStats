local name = "ElvUI"
local Plugin = {
    name = name
}

ExtraStats:RegisterPlugin(Plugin)

local SLOT_FRAMES = {
    CharacterHeadSlot,
    CharacterNeckSlot,
    CharacterShoulderSlot,
    CharacterBackSlot,
    CharacterChestSlot,
    CharacterShirtSlot,
    CharacterTabardSlot,
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

local function KillTexture(tex)
    if not tex then
        return
    end

    if tex.Kill then
        tex:Kill()
        return
    end

    tex:Hide()
    tex:SetAlpha(0)
end

local function StripSlotBackgrounds(slot)
    if not slot or not slot.GetName then
        return
    end

    local name = slot:GetName()
    if name then
        KillTexture(_G[name .. "Frame"])
    end

    for _, region in pairs({ slot:GetRegions() }) do
        if region and region.GetObjectType and region:GetObjectType() == "Texture" then
            if region:GetDrawLayer() == "BACKGROUND" then
                KillTexture(region)
            end
        end
    end
end

local function StripExtraPaperDollTextures()
    if not PaperDollFrame then
        return
    end

    local textures = {
        PaperDollFrame.bg,
        PaperDollFrame.TitleBg,
        PaperDollFrame.PortraitFrame,
        PaperDollFrame.TopRightCorner,
        PaperDollFrame.TopLeftCorner,
        PaperDollFrame.TopBorder,
        PaperDollFrame.TopTileStreaks,
        PaperDollFrame.BotLeftCorner,
        PaperDollFrame.BotRightCorner,
        PaperDollFrame.BottomBorder,
        PaperDollFrame.LeftBorder,
        PaperDollFrame.RightBorder
    }

    for _, texture in pairs(textures) do
        KillTexture(texture)
    end

    local extraNames = {
        "PaperDollInnerBorderTopLeft",
        "PaperDollInnerBorderTopRight",
        "PaperDollInnerBorderBottomLeft",
        "PaperDollInnerBorderBottomRight",
        "PaperDollInnerBorderLeft",
        "PaperDollInnerBorderRight",
        "PaperDollInnerBorderTop",
        "PaperDollInnerBorderBottom",
        "PaperDollInnerBorderBottom2"
    }

    for _, name in pairs(extraNames) do
        KillTexture(_G[name])
    end
end

local function StripSidebarTextures()
    local sidebar = CharacterFrame and CharacterFrame.Sidebar
    if not sidebar then
        return
    end

    KillTexture(sidebar.DecorLeft)
    KillTexture(sidebar.DecorRight)

    for i = 1, 3 do
        local tab = _G["PaperDollSidebarTab" .. i]
        if tab then
            KillTexture(tab.TabBg)
            KillTexture(tab.Hider)
            KillTexture(tab.Highlight)
        end
    end
end

local function SkinFrame(frame, template)
    if not frame or not frame.CreateBackdrop then
        return
    end

    if not frame.backdrop then
        frame:CreateBackdrop(template or "Transparent")
    end
end

local function EnsureCharacterBackdrop()
    if not CharacterFrame then
        return
    end

    --if CharacterFrame.backdrop then
    --    CharacterFrame.backdrop:ClearAllPoints()
    --    CharacterFrame.backdrop:SetAllPoints(CharacterFrame)
    --    --CharacterFrame.backdrop:Show()
    --    return
    --end
    --
    --if not CharacterFrame.ExtraStatsBackdrop then
    --    local bg = CreateFrame("Frame", nil, CharacterFrame)
    --    bg:SetAllPoints(CharacterFrame)
    --    bg:SetFrameLevel(CharacterFrame:GetFrameLevel() - 1)
    --    bg:CreateBackdrop("Transparent")
    --    CharacterFrame.ExtraStatsBackdrop = bg
    --end
end

local function SkinTabs(S)
    if not S or not S.HandleTab then
        return
    end

    local numTabs = CharacterFrame and CharacterFrame.numTabs
    if not numTabs or numTabs == 0 then
        return
    end

    for i = 1, numTabs do
        local tab = _G["CharacterFrameTab" .. i]
        if tab then
            S:HandleTab(tab)
        end
    end
end

local function SkinSidebarTabs(S)
    if not S then
        return
    end

    for i = 1, 3 do
        local tab = _G["PaperDollSidebarTab" .. i]
        if tab then
            StripSlotBackgrounds(tab)
            if S.HandleButton then
                S:HandleButton(tab)
            end
        end
    end
end

local function SkinSlotButtons(S)
    if not S then
        return
    end

    for _, slot in pairs(SLOT_FRAMES) do
        StripSlotBackgrounds(slot)
        if S.HandleItemButton then
            S:HandleItemButton(slot)
        elseif S.HandleButton then
            S:HandleButton(slot)
        end
    end
end

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
    ExtraStats.statYOffset = 0;

    ExtraStats:debug("ELVUI Detected")

    S = E:GetModule('Skins')
    --S:CharacterFrame()

    --ExtraStats:On("category:build", function(frame)
    --    frame:StripTextures()
    --    frame:CreateBackdrop()
    --    frame:SetHeight(30)
    --end);
    --
    --ExtraStats:On("stat:build", function(frame)
    --
    --end);


    ExtraStats:On("character.window.show", function()
        EnsureCharacterBackdrop()
    --
        PaperDollItemsFrame:StripTextures()
        CharacterFrameInset:StripTextures()
        --CharacterModelFrame:StripTextures()w
        CharacterModelFrameBackgroundTopLeft:Kill()
        CharacterModelFrameBackgroundTopRight:Kill()
        CharacterModelFrameBackgroundBotLeft:Kill()
        CharacterModelFrameBackgroundBotRight:Kill()
    --
        PaperDollFrame.TitleBg:StripTextures()
        PaperDollFrame.TopBorder:StripTextures()
    --
        CharacterStatsPaneScrollBar:StripTextures()
        S:HandleScrollBar(CharacterStatsPaneScrollBar)

        CharacterFrameInsetRight:StripTextures()

        CharacterStatsPane.scrollBar:StripTextures()
        S:HandleScrollBar(CharacterStatsPane.scrollBar)

        local titlesPane = ExtraStatsPaperDollTitlesPane or PaperDollTitlesPane
        if titlesPane and titlesPane.scrollBar then
            titlesPane.scrollBar:StripTextures()
            S:HandleScrollBar(titlesPane.scrollBar)
        end

        local equipmentPane = ExtraStatsPaperDollEquipmentManagerPane or PaperDollEquipmentManagerPane
        if equipmentPane and equipmentPane.scrollBar then
            equipmentPane.scrollBar:StripTextures()
            S:HandleScrollBar(equipmentPane.scrollBar)
        end

        StripExtraPaperDollTextures()
        StripSidebarTextures()
        --
        --SkinFrame(CharacterFrameInset)
        --SkinFrame(CharacterFrame.InsetRight)
        --SkinFrame(PaperDollItemsFrame)
        --SkinFrame(CharacterStatsPane)
        SkinFrame(ExtraStatsPaperDollTitlesPane or PaperDollTitlesPane)
        SkinFrame(ExtraStatsPaperDollEquipmentManagerPane or PaperDollEquipmentManagerPane)
        SkinTabs(S)
        SkinSidebarTabs(S)
        SkinSlotButtons(S)
    end)

    --ExtraStats.window.Inset:Hide()
    --S:HandleFrame(ExtraStats.window, true, nil)
    --ExtraStats.window.ScrollFrame:StripTextures()
    --S:HandleScrollBar(ExtraStats.window.ScrollFrame.ScrollBar)
    --S:HandleScrollBar(ExtraStats.window.ScrollFrame.ScrollBar)
    --
    --ExtraStats.window:SetPoint("LEFT", PaperDollFrame, "RIGHT", -33, 30)

end
