local tab = ExtraStats:CreateModule("character.titles")

local STRIPE_COLOR = { r = 0.9, g = 0.9, b = 1 };

local PLAYER_TITLE_HEIGHT = 28;
local TITLE_BUTTON_OFFSET_X = 4;
local TITLE_BUTTON_OFFSET_Y = -4;

tab.frame = nil

local EnsureTitleButtons

local function TitleSort(a, b)
    return a.name < b.name;
end

local function PaperDollTitlesPane_UpdateScrollFrame()
    EnsureTitleButtons(tab.frame);

    local buttons = tab.frame.buttons or {};
    local playerTitles = tab.frame.titles or {};
    local numButtons = #buttons;
    local scrollOffset = HybridScrollFrame_GetOffset(tab.frame);
    local playerTitle;
    for i = 1, numButtons do
        playerTitle = playerTitles[i + scrollOffset];
        if (playerTitle) then
            buttons[i]:Show();

            buttons[i]:SetScript("OnClick", function(self)
                PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_OFF);
                SetCurrentTitle(self.titleId);
            end)

            buttons[i].text:SetText(playerTitle.name);
            buttons[i].titleId = playerTitle.id;
            if (tab.frame.selected == playerTitle.id) then
                buttons[i].Check:Show();
                buttons[i].SelectedBar:Show();
                buttons[i].SelectedAccent:Show();
            else
                buttons[i].Check:Hide();
                buttons[i].SelectedBar:Hide();
                buttons[i].SelectedAccent:Hide();
            end

            buttons[i].BgMiddle:Hide();

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
    end
end

EnsureTitleButtons = function(frame)
    if not frame then
        return
    end

    local frameHeight = frame.GetHeight and frame:GetHeight() or 0
    if frameHeight <= math.abs(TITLE_BUTTON_OFFSET_Y) then
        return
    end

    if not frame.extraStatsTitleButtonsInitialized then
        frame.buttons = nil
        HybridScrollFrame_CreateButtons(frame, "ExtraStatsPlayerTitleButtonTemplate", TITLE_BUTTON_OFFSET_X, TITLE_BUTTON_OFFSET_Y)
        frame.extraStatsTitleButtonsInitialized = frame.buttons and #frame.buttons > 0
    elseif not frame.buttons or #frame.buttons == 0 then
        frame.extraStatsTitleButtonsInitialized = nil
        HybridScrollFrame_CreateButtons(frame, "ExtraStatsPlayerTitleButtonTemplate", TITLE_BUTTON_OFFSET_X, TITLE_BUTTON_OFFSET_Y)
        frame.extraStatsTitleButtonsInitialized = frame.buttons and #frame.buttons > 0
    end

    local activeScrollChild = frame.GetScrollChild and frame:GetScrollChild()
    if activeScrollChild then
        frame.scrollChild = activeScrollChild
        frame.ScrollChild = activeScrollChild
    end
end

function tab:init()
    local mainFrame = CreateFrame("Frame")
    --mainFrame:RegisterEvent("KNOWN_TITLES_UPDATE")
    mainFrame:RegisterEvent("UNIT_NAME_UPDATE")

    local frame = CreateFrame("ScrollFrame", "ExtraStatsPaperDollTitlesPane", PaperDollFrame, "ExtraStatsPaperDollTitlesPaneTemplate")
    frame.update = PaperDollTitlesPane_UpdateScrollFrame;
    frame.scrollBar.doNotHide = 1;
    frame:SetFrameLevel(CharacterFrameInsetRight:GetFrameLevel() + 1);
    HybridScrollFrame_OnLoad(frame);
    tab.frame = frame

    frame:SetScript("OnShow", function(self)
        EnsureTitleButtons(self)
        ExtraStats:Trigger("titles.tab.show", tab.frame)
        tab:update()
        C_Timer.After(0, function()
            if self and self:IsShown() then
                EnsureTitleButtons(self)
                tab:update()
            end
        end)
    end)
    frame:SetScript("OnHide", function()
        ExtraStats:Trigger("titles.tab.hide", tab.frame)
    end)

    mainFrame:SetScript("OnEvent", function(self, event, ...)
        local unit = ...;
        if (event == "KNOWN_TITLES_UPDATE" or (event == "UNIT_NAME_UPDATE" and unit == "player")) then
            if (tab:IsVisible()) then
                EnsureTitleButtons(tab.frame)
                tab:update()
            end
        end
    end)
end

function tab:IsVisible()
    return tab.frame and tab.frame:IsVisible()
end

function tab:update()
    local playerTitles = { };
    local currentTitle = GetCurrentTitle();
    local titleCount = 1;
    local playerTitle = false;
    local tempName = 0;
    EnsureTitleButtons(tab.frame)

    if not tab.frame.buttons or #tab.frame.buttons == 0 then
        return
    end

    tab.frame.selected = -1;
    playerTitles[1] = { };

    playerTitles[1].name = "       ";
    playerTitles[1].id = -1;

    for i = 1, GetNumTitles() do
        if (IsTitleKnown(i) ~= false) then
            tempName, playerTitle = GetTitleName(i);
            if (tempName and playerTitle) then
                titleCount = titleCount + 1;
                playerTitles[titleCount] = playerTitles[titleCount] or { };
                playerTitles[titleCount].name = strtrim(tempName);
                playerTitles[titleCount].id = i;
                if (i == currentTitle) then
                    tab.frame.selected = i;
                end
            end
        end
    end

    table.sort(playerTitles, TitleSort);
    playerTitles[1].name = PLAYER_TITLE_NONE;
    tab.frame.titles = playerTitles;

    tab.frame.scrollBar.doNotHide = true
    HybridScrollFrame_Update(tab.frame, titleCount * PLAYER_TITLE_HEIGHT, tab.frame:GetHeight());
    PaperDollTitlesPane_UpdateScrollFrame()
end
