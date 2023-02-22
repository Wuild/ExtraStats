local tab = ExtraStats:CreateModule("character.titles")

local STRIPE_COLOR = { r = 0.9, g = 0.9, b = 1 };

local PLAYER_TITLE_HEIGHT = 32;

tab.frame = nil
function tab:init()
    local mainFrame = CreateFrame("Frame")
    --mainFrame:RegisterEvent("KNOWN_TITLES_UPDATE")
    mainFrame:RegisterEvent("UNIT_NAME_UPDATE")

    local frame = CreateFrame("ScrollFrame", "PaperDollTitlesPane", PaperDollFrame, "PaperDollTitlesPaneTemplate")

    frame:SetScript("OnLoad", function(self)
        frame.scrollBar.doNotHide = 1;
        frame:SetFrameLevel(CharacterFrameInsetRight:GetFrameLevel() + 1);

        HybridScrollFrame_OnLoad(tab.frame);
        frame.update = tab.update;
        HybridScrollFrame_CreateButtons(tab.frame, "PlayerTitleButtonTemplate", 2, -4);
    end)

    frame:SetScript("OnShow", function()
        HybridScrollFrame_CreateButtons(tab.frame, "PlayerTitleButtonTemplate");
        tab:update()
    end)

    mainFrame:SetScript("OnEvent", function(self, event, ...)
        local unit = ...;
        if (event == "KNOWN_TITLES_UPDATE" or (event == "UNIT_NAME_UPDATE" and unit == "player")) then
            if (tab:IsVisible()) then
                HybridScrollFrame_CreateButtons(tab.frame, "PlayerTitleButtonTemplate");
                tab:update()
            end
        end


    end)

    tab.frame = frame
end

function tab:IsVisible()
    return tab.frame and tab.frame:IsVisible()
end

local function TitleSort(a, b)
    return a.name < b.name;
end

local function PaperDollTitlesPane_UpdateScrollFrame()
    local buttons = tab.frame.buttons;
    local playerTitles = tab.frame.titles;
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
            else
                buttons[i].Check:Hide();
                buttons[i].SelectedBar:Hide();
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

function tab:update()
    local playerTitles = { };
    local currentTitle = GetCurrentTitle();
    local titleCount = 1;
    local buttons = tab.frame.buttons;
    local fontstringText = buttons[1].text;
    local playerTitle = false;
    local tempName = 0;
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
                fontstringText:SetText(playerTitles[titleCount].name);
            end
        end
    end

    table.sort(playerTitles, TitleSort);
    playerTitles[1].name = PLAYER_TITLE_NONE;
    tab.frame.titles = playerTitles;

    tab.frame.scrollBar.doNotHide = true
    HybridScrollFrame_Update(tab.frame, titleCount * PLAYER_TITLE_HEIGHT + 32, tab.frame:GetHeight());
    PaperDollTitlesPane_UpdateScrollFrame()
end