local name, stats = ...;

button = nil;

function ExtraStats:CreateWindow()
    ExtraStats.window = CreateFrame("Frame", nil, PaperDollFrame)
    ExtraStats.window:SetWidth(stats.window.width)
    ExtraStats.window:SetHeight(stats.window.height)
    ExtraStats.window:EnableMouse(true)
    ExtraStats.window:SetFrameStrata("BACKGROUND")

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
    ExtraStats.window.Inset:SetPoint("TOPLEFT", 0, -4)
    ExtraStats.window.Inset:SetPoint("BOTTOMRIGHT", 0, 4)

    ExtraStats.window.TopLeftCorner = ExtraStats.window:CreateTexture(nil, "OVERLAY", "UI-Frame-TopCornerLeft")
    ExtraStats.window.TopLeftCorner:SetTexture("")
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
    ExtraStats.window.BotLeftCorner:SetTexture("")
    ExtraStats.window.BotLeftCorner:SetPoint("BOTTOMLEFT", ExtraStats.window, -8, -6)

    ExtraStats.window.BottomBorder = ExtraStats.window:CreateTexture(nil, "OVERLAY", "_UI-Frame-Bot")
    ExtraStats.window.BottomBorder:ClearAllPoints()
    ExtraStats.window.BottomBorder:SetPoint("BOTTOMLEFT", ExtraStats.window.BotLeftCorner, "BOTTOMRIGHT", -6, 0)
    ExtraStats.window.BottomBorder:SetPoint("BOTTOMRIGHT", ExtraStats.window.BotRightCorner, "BOTTOMLEFT")

    ExtraStats.window.RightBorder = ExtraStats.window:CreateTexture(nil, "OVERLAY", "!UI-Frame-RightTile")
    ExtraStats.window.RightBorder:ClearAllPoints()
    --ExtraStats.window.RightBorder:SetPoint("TOPRIGHT", ExtraStats.window.TopRightCorner, "BOTTOMRIGHT", -10)
    --ExtraStats.window.RightBorder:SetPoint("BOTTOMRIGHT", ExtraStats.window.BotRightCorner, "TOPRIGHT", -10)
    ExtraStats.window.RightBorder:SetPoint("TOPRIGHT", ExtraStats.window.TopRightCorner, "BOTTOMRIGHT", 0, 0)
    ExtraStats.window.RightBorder:SetPoint("BOTTOMRIGHT", ExtraStats.window.BotRightCorner, "TOPRIGHT")

    ExtraStats.window.LeftBorder = ExtraStats.window:CreateTexture(nil, "OVERLAY", "!UI-Frame-LeftTile")
    ExtraStats.window.LeftBorder:ClearAllPoints()
    ExtraStats.window.LeftBorder:SetTexture("")
    ExtraStats.window.LeftBorder:SetPoint("TOPLEFT", ExtraStats.window.TopLeftCorner, "BOTTOMLEFT", 0, 0)
    ExtraStats.window.LeftBorder:SetPoint("BOTTOMLEFT", ExtraStats.window.BotLeftCorner, "TOPLEFT")

    ExtraStats.window.TopBorder = ExtraStats.window:CreateTexture(nil, "OVERLAY", "_UI-Frame-TitleTile")
    ExtraStats.window.TopBorder:ClearAllPoints()
    ExtraStats.window.TopBorder:SetPoint("TOPLEFT", ExtraStats.window.TopLeftCorner, "TOPRIGHT", -6, -4)
    ExtraStats.window.TopBorder:SetPoint("TOPRIGHT", ExtraStats.window.TopRightCorner, "TOPLEFT")

    ExtraStats.window.ScrollFrame = CreateFrame("ScrollFrame", "ExtraStatsScrollFrame", ExtraStats.window, "ExtraStatsScrollFrame")
    ExtraStats.window.ScrollFrame:SetPoint("TOPLEFT", ExtraStats.window, "TOPLEFT", 0, -10)
    ExtraStats.window.ScrollFrame:SetPoint("BOTTOMRIGHT", ExtraStats.window, "BOTTOMRIGHT", -28, 10)

    ExtraStats.window.ScrollChild = CreateFrame("Frame", ExtraStats.window, ExtraStats.window.ScrollFrame)
    ExtraStats.window.ScrollChild:SetSize(stats.window.width, stats.window.height - 20)

    ExtraStats.window.ScrollFrame:SetScrollChild(ExtraStats.window.ScrollChild)

    self.categoryFramePool = CreateFramePool("FRAME", ExtraStats.window.ScrollChild, "ExtraStatsFrameCategoryTemplate");
    self.statsFramePool = CreateFramePool("FRAME", ExtraStats.window.ScrollChild, "CharacterStatFrameTemplate");

    ExtraStats.window:SetPoint("LEFT", PaperDollFrame, "RIGHT", -35, 30)

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
        ExtraStats:UpdateStats()
    end)

    ExtraStats.window.ExpandButton = CreateFrame("Button", "$parentExpandButton", PaperDollFrame, "CharacterFrameExpandButtonTemplate");

    ExtraStats.window.ExpandButton:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT");
        if (ExtraStats.db.char.enabled) then
            GameTooltip:SetText(HIGHLIGHT_FONT_COLOR_CODE .. "Hide ExtraStats" .. FONT_COLOR_CODE_CLOSE);
        else
            GameTooltip:SetText(HIGHLIGHT_FONT_COLOR_CODE .. "Show ExtraStats" .. FONT_COLOR_CODE_CLOSE);
        end
    end);

    ExtraStats.window.ExpandButton:SetScript("OnClick", function()
        ExtraStats.db.char.enabled = not ExtraStats.db.char.enabled;

        if ExtraStats.db.char.enabled then
            ExtraStats.window:Show()
            PlaySound(SOUNDKIT.IG_CHARACTER_INFO_OPEN);
        else
            ExtraStats.window:Hide()
            PlaySound(SOUNDKIT.IG_CHARACTER_INFO_CLOSE);
        end

        ExtraStats:FixToggleButton()
    end)

    if ExtraStats.db.char.enabled then
        ExtraStats.window:Show()
    else
        ExtraStats.window:Hide()
    end

    ExtraStats:FixToggleButton()
end

function ExtraStats:FixToggleButton()
    if not ExtraStats.db.char.enabled then
        ExtraStats.window.ExpandButton:SetNormalTexture("Interface\\Buttons\\UI-SpellbookIcon-NextPage-Up");
        ExtraStats.window.ExpandButton:SetPushedTexture("Interface\\Buttons\\UI-SpellbookIcon-NextPage-Down");
        ExtraStats.window.ExpandButton:SetDisabledTexture("Interface\\Buttons\\UI-SpellbookIcon-NextPage-Disabled");
    else
        ExtraStats.window.ExpandButton:SetNormalTexture("Interface\\Buttons\\UI-SpellbookIcon-PrevPage-Up");
        ExtraStats.window.ExpandButton:SetPushedTexture("Interface\\Buttons\\UI-SpellbookIcon-PrevPage-Down");
        ExtraStats.window.ExpandButton:SetDisabledTexture("Interface\\Buttons\\UI-SpellbookIcon-PrevPage-Disabled");
    end

    ExtraStats:UpdateStats()
end