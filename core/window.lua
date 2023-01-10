local name, stats = ...;

button = nil;

function ExtraStats:CreateCategories()


    --ExtraStats.window.AttributesCategory = CreateFrame("Frame", nil, ExtraStats.window.ScrollChild, "CharacterStatFrameCategoryTemplate2")
    --ExtraStats.window.AttributesCategory.Title:SetText(STAT_CATEGORY_ATTRIBUTES)
    --
    --ExtraStats.window.MeleeCategory = CreateFrame("Frame", nil, ExtraStats.window.ScrollChild, "CharacterStatFrameCategoryTemplate2")
    --ExtraStats.window.MeleeCategory.Title:SetText("Melee")
    --
    --ExtraStats.window.RangedCategory = CreateFrame("Frame", nil, ExtraStats.window.ScrollChild, "CharacterStatFrameCategoryTemplate2")
    --ExtraStats.window.RangedCategory.Title:SetText("Ranged")
    --
    --ExtraStats.window.SpellCategory = CreateFrame("Frame", nil, ExtraStats.window.ScrollChild, "CharacterStatFrameCategoryTemplate2")
    --ExtraStats.window.SpellCategory.Title:SetText("Spell")
    --
    --ExtraStats.window.DefensesCategory = CreateFrame("Frame", nil, ExtraStats.window.ScrollChild, "CharacterStatFrameCategoryTemplate2")
    --ExtraStats.window.DefensesCategory.Title:SetText("Defenses")
    --
    --ExtraStats.window.EnhancementsCategory = CreateFrame("Frame", nil, ExtraStats.window.ScrollChild, "CharacterStatFrameCategoryTemplate2")
    --ExtraStats.window.EnhancementsCategory.Title:SetText(STAT_CATEGORY_ENHANCEMENTS)
end

function ExtraStats:CreateWindow()
    ExtraStats.window = CreateFrame("Frame", nil, UIParent)
    ExtraStats.window:SetWidth(stats.window.width)
    ExtraStats.window:SetHeight(stats.window.height)
    ExtraStats.window:EnableMouse(true)
    ExtraStats.window:SetFrameStrata("MEDIUM")

    ExtraStats.window:RegisterEvent("PLAYER_ENTERING_WORLD")
    ExtraStats.window:RegisterEvent("ACTIVE_TALENT_GROUP_CHANGED")
    ExtraStats.window:RegisterEvent("PLAYER_TALENT_UPDATE")
    ExtraStats.window:RegisterEvent("CHARACTER_POINTS_CHANGED")
    ExtraStats.window:RegisterEvent("PLAYER_LEVEL_UP")

    ExtraStats.window.Background = ExtraStats.window:CreateTexture("CharacterStatsFrameBackground", "BACKGROUND")
    ExtraStats.window.Background:SetTexture("Interface\\FrameGeneral\\UI-Background-Rock")
    ExtraStats.window.Background:SetAllPoints(ExtraStats.window)

    ExtraStats.window.Inset = CreateFrame("Frame", nil, ExtraStats.window, "InsetFrameTemplate")
    ExtraStats.window.Inset:ClearAllPoints()
    ExtraStats.window.Inset:SetPoint("TOPLEFT", 4, -4)
    ExtraStats.window.Inset:SetPoint("BOTTOMRIGHT", 0, 4)

    ExtraStats.window.TopLeftCorner = ExtraStats.window:CreateTexture(nil, "OVERLAY", "UI-Frame-TopCornerLeft")
    ExtraStats.window.TopLeftCorner:ClearAllPoints()
    ExtraStats.window.TopLeftCorner:SetPoint("TOPLEFT", ExtraStats.window, -8, 6)

    ExtraStats.window.TopRightCorner = ExtraStats.window:CreateTexture(nil, "OVERLAY", "UI-Frame-TopCornerRightSimple")
    ExtraStats.window.TopRightCorner:ClearAllPoints()
    ExtraStats.window.TopRightCorner:SetPoint("TOPRIGHT", ExtraStats.window, 4, 6)

    ExtraStats.window.BotRightCorner = ExtraStats.window:CreateTexture(nil, "OVERLAY", "UI-Frame-BotCornerRight")
    ExtraStats.window.BotRightCorner:ClearAllPoints()
    ExtraStats.window.BotRightCorner:SetPoint("BOTTOMRIGHT", ExtraStats.window, 4, -6)

    ExtraStats.window.BotLeftCorner = ExtraStats.window:CreateTexture(nil, "OVERLAY", "UI-Frame-BotCornerLeft")
    ExtraStats.window.BotLeftCorner:ClearAllPoints()
    ExtraStats.window.BotLeftCorner:SetPoint("BOTTOMLEFT", ExtraStats.window, -8, -6)

    ExtraStats.window.BottomBorder = ExtraStats.window:CreateTexture(nil, "OVERLAY", "_UI-Frame-Bot")
    ExtraStats.window.BottomBorder:ClearAllPoints()
    ExtraStats.window.BottomBorder:SetPoint("BOTTOMLEFT", ExtraStats.window.BotLeftCorner, "BOTTOMRIGHT")
    ExtraStats.window.BottomBorder:SetPoint("BOTTOMRIGHT", ExtraStats.window.BotRightCorner, "BOTTOMLEFT")

    ExtraStats.window.RightBorder = ExtraStats.window:CreateTexture(nil, "OVERLAY", "!UI-Frame-RightTile")
    ExtraStats.window.RightBorder:ClearAllPoints()
    --ExtraStats.window.RightBorder:SetPoint("TOPRIGHT", ExtraStats.window.TopRightCorner, "BOTTOMRIGHT", -10)
    --ExtraStats.window.RightBorder:SetPoint("BOTTOMRIGHT", ExtraStats.window.BotRightCorner, "TOPRIGHT", -10)
    ExtraStats.window.RightBorder:SetPoint("TOPRIGHT", ExtraStats.window.TopRightCorner, "BOTTOMRIGHT", 0, 0)
    ExtraStats.window.RightBorder:SetPoint("BOTTOMRIGHT", ExtraStats.window.BotRightCorner, "TOPRIGHT")

    ExtraStats.window.LeftBorder = ExtraStats.window:CreateTexture(nil, "OVERLAY", "!UI-Frame-LeftTile")
    ExtraStats.window.LeftBorder:ClearAllPoints()
    ExtraStats.window.LeftBorder:SetPoint("TOPLEFT", ExtraStats.window.TopLeftCorner, "BOTTOMLEFT", 0, 0)
    ExtraStats.window.LeftBorder:SetPoint("BOTTOMLEFT", ExtraStats.window.BotLeftCorner, "TOPLEFT")

    ExtraStats.window.TopBorder = ExtraStats.window:CreateTexture(nil, "OVERLAY", "_UI-Frame-TitleTile")
    ExtraStats.window.TopBorder:ClearAllPoints()
    ExtraStats.window.TopBorder:SetPoint("TOPLEFT", ExtraStats.window.TopLeftCorner, "TOPRIGHT", 0, -4)
    ExtraStats.window.TopBorder:SetPoint("TOPRIGHT", ExtraStats.window.TopRightCorner, "TOPLEFT")

    ExtraStats.window.ScrollFrame = CreateFrame("ScrollFrame", "ExtraStatsScrollFrame", ExtraStats.window, "ExtraStatsScrollFrame")
    ExtraStats.window.ScrollFrame:SetPoint("TOPLEFT", ExtraStats.window, "TOPLEFT", 0, -10)
    ExtraStats.window.ScrollFrame:SetPoint("BOTTOMRIGHT", ExtraStats.window, "BOTTOMRIGHT", -28, 10)

    ExtraStats.window.ScrollChild = CreateFrame("Frame", ExtraStats.window, ExtraStats.window.ScrollFrame)
    ExtraStats.window.ScrollChild:SetSize(stats.window.width, stats.window.height - 20)

    ExtraStats.window.ScrollFrame:SetScrollChild(ExtraStats.window.ScrollChild)

    self.categoryFramePool = CreateFramePool("FRAME", ExtraStats.window.ScrollChild, "ExtraStatsFrameCategoryTemplate");
    self.statsFramePool = CreateFramePool("FRAME", ExtraStats.window.ScrollChild, "CharacterStatFrameTemplate");

    ExtraStats.window:SetPoint("CENTER", 0, 0)
    ExtraStats.window:Hide()

    --GearManagerToggleButton:ClearAllPoints()
    --GearManagerToggleButton:SetPoint("TOPLEFT", PaperDollFrame, "TOPLEFT", 0, 0)
    --GearManagerToggleButton:SetPoint("BOTTOMRIGHT", PaperDollFrame, "BOTTOMRIGHT", 0, 0)
    ----GearManagerToggleButton:SetPoint("RIGHT", 0, 60)

    local button = CreateFrame("Button", nil, ExtraStats.window.ScrollFrame)
    --button:SetPoint("TOPRIGHT", CharacterFrameCloseButton, "TOPLEFT", -5, -7)
    button:SetPoint("TOPLEFT", 10, 0)
    button:SetWidth(14)
    button:SetHeight(14)
    button:SetNormalFontObject("GameFontNormal")

    button:SetScript("OnClick", function()
        ExtraStats:ShowSettings();
    end)

    local ntex = button:CreateTexture()
    ntex:SetTexture(stats.iconPath .. "resources\\cog")
    ntex:SetAllPoints()
    button:SetNormalTexture(ntex)

    ntex = button:CreateTexture()
    ntex:SetTexture(stats.iconPath .. "resources\\cog-down")
    ntex:SetAllPoints()
    button:SetHighlightTexture(ntex)

    PaperDollFrame:HookScript('OnShow', function()
        ExtraStats.window:Show()
        ExtraStats.window:SetPoint("LEFT", PaperDollFrame, "RIGHT", -40, 30)
        ExtraStats:UpdateStats()
    end)

    PaperDollFrame:HookScript('OnHide', function()
        ExtraStats.window:Hide()
    end)
end