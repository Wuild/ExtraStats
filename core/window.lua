local name, stats = ...;

local modules = {}

---@return Module @Module reference
local function _CreateBlankModule()
    ---@class Module
    local module = {}
    return module
end

---@param name string @Module name
---@return Module @Module reference
function ExtraStats:CreateModule(name)
    if not modules[name] then
        modules[name] = _CreateBlankModule()
        return modules[name]
    else
        return modules[name]
    end
end

---@param name string @Module name
---@return Module @Module reference
function ExtraStats:LoadModule(name)
    if not modules[name] then
        modules[name] = _CreateBlankModule()
        return modules[name]
    else
        return modules[name]
    end
end

local name, addon = ...
local Module = {}
ExtraStats.window = Module

local function GetKnownTitles()
    local playerTitles = { };
    local titleCount = 1;
    local playerTitle = false;
    local tempName = 0;
    local selectedTitle = -1;
    playerTitles[1] = { };
    -- reserving space for None so it doesn't get sorted out of the top position
    playerTitles[1].name = "       ";
    playerTitles[1].id = -1;
    for i = 1, GetNumTitles() do
        if (IsTitleKnown(i)) then
            tempName, playerTitle = GetTitleName(i);
            if (tempName and playerTitle) then
                titleCount = titleCount + 1;
                playerTitles[titleCount] = playerTitles[titleCount] or { };
                playerTitles[titleCount].name = strtrim(tempName);
                playerTitles[titleCount].id = i;
            end
        end
    end

    return playerTitles, selectedTitle;
end

ES_PAPERDOLL_SIDEBARS = {
    {
        name = PAPERDOLL_SIDEBAR_STATS;
        frame = "CharacterStatsPane";
        icon = nil; -- Uses the character portrait
        texCoords = { 0.109375, 0.890625, 0.09375, 0.90625 };
        IsActive = function()
            return true;
        end
    },
    {
        name = PAPERDOLL_SIDEBAR_TITLES;
        frame = "ExtraStatsPaperDollTitlesPane";
        icon = "Interface\\PaperDollInfoFrame\\PaperDollSidebarTabs";
        texCoords = { 0.01562500, 0.53125000, 0.32421875, 0.46093750 };
        disabledTooltip = NO_TITLES_TOOLTIP;
        IsActive = function()
            -- You always have the "No Title" title so you need to have more than one to have an option.
            --return #GetKnownTitles() > 1;
            return true
        end
    },
    {
        name = PAPERDOLL_EQUIPMENTMANAGER;
        frame = "ExtraStatsPaperDollEquipmentManagerPane";
        icon = "Interface\\PaperDollInfoFrame\\PaperDollSidebarTabs";
        texCoords = { 0.01562500, 0.53125000, 0.46875000, 0.60546875 };

        IsActive = function()
            return true
        end
    },
};

local defaultWith = 384;
local expandedWidth = 242;

local fullSize = defaultWith + expandedWidth;

local BlizzFrames = {
    CharacterAttributesFrame,
    GearManagerToggleButton,
    PlayerTitleDropDown,

    --GearSetButton1,
    --GearSetButton2,
    --GearSetButton3,
    --GearSetButton4,
    --GearSetButton5,
    --GearSetButton6,
    --GearSetButton7,
    --GearSetButton8,
    --GearSetButton9,
    --GearSetButton10,
    --GearManagerDialogDeleteSet,
    --GearManagerDialogEquipSet,
    --GearManagerDialogSaveSet,
    ----GearManagerDialogClose,
    ----GearManagerDialog.Title,
    --GearManagerDialogTitleBG,
    --GearManagerDialogDialogBG,
    --GearManagerDialogTop,
    --GearManagerDialogTopRight,
    --GearManagerDialogRight,
    --GearManagerDialogBottomRight,
    --GearManagerDialogBottom,
    --GearManagerDialogBottomLeft,
    --GearManagerDialogLeft,
    --GearManagerDialogTopLeft,
};

Module.CharacterFrame = CharacterFrame;
Module.PaperDollFrame = PaperDollFrame;

local SPEC_TABLE = {
    WARRIOR = { "Arms", "Fury", "Protection" },
    PALADIN = { "Holy", "Protection", "Retribution" },
    HUNTER = { "Beast Mastery", "Marksmanship", "Survival" },
    ROGUE = { "Assassination", "Combat", "Subtlety" },
    PRIEST = { "Discipline", "Holy", "Shadow" },
    DEATHKNIGHT = { "Blood", "Frost", "Unholy" },
    SHAMAN = { "Elemental", "Enhancement", "Restoration" },
    MAGE = { "Arcane", "Fire", "Frost" },
    WARLOCK = { "Affliction", "Demonology", "Destruction" },
    DRUID = { "Balance", "Feral Combat", "Restoration" },
}

local ROLE_LABELS = {
    [CLASS_ROLE_DAMAGER] = "Damage",
    [CLASS_ROLE_HEALER] = "Healer",
    [CLASS_ROLE_TANK] = "Tank",
}
local ROLE_ICON_TEXTURES = {
    [CLASS_ROLE_TANK] = "Interface\\Icons\\Ability_Warrior_DefensiveStance",
    [CLASS_ROLE_HEALER] = "Interface\\Icons\\Spell_Holy_Heal",
    [CLASS_ROLE_DAMAGER] = "Interface\\Icons\\Ability_Rogue_Eviscerate",
}
local ROLE_ORDER = { CLASS_ROLE_TANK, CLASS_ROLE_HEALER, CLASS_ROLE_DAMAGER }

local function GetTalentTabName(tabIndex)
    local a, b = GetTalentTabInfo(tabIndex);
    if type(b) == "string" and b ~= "" then
        return b;
    end
    if type(a) == "string" and a ~= "" then
        return a;
    end
    return nil;
end

local function GetTalentTabPoints(tabIndex)
    local points = select(5, GetTalentTabInfo(tabIndex));
    return tonumber(points) or 0;
end

local function HideDefaultTitleDropDown()
    local frame = _G.PlayerTitleDropDown or _G.PlayerTitleDropdown;
    if frame and frame.Hide then
        frame:Hide();
        frame.Show = frame.Hide;
        if not frame.ExtraStatsHooked then
            frame:HookScript("OnShow", function(self)
                self:Hide();
            end);
            frame.ExtraStatsHooked = true;
        end
    end
end

local function EnsureTalentUILoaded()
    local isLoaded = nil;
    if C_AddOns and C_AddOns.IsAddOnLoaded then
        isLoaded = C_AddOns.IsAddOnLoaded("Blizzard_TalentUI");
    elseif IsAddOnLoaded then
        isLoaded = IsAddOnLoaded("Blizzard_TalentUI");
    end
    if TalentFrame_LoadUI and not isLoaded then
        pcall(TalentFrame_LoadUI);
    end
end

function Module:CleanDefaultFrame()
    for _, frame in pairs(BlizzFrames) do
        if frame and frame.Hide then
            frame:Hide();
        end
    end
    HideDefaultTitleDropDown();
end

function Module:DeleteFrameTextures(frame)
    local inversedAttributes = {};
    for k, v in pairs(frame) do
        if ((type(v) == "table") and v:GetObjectType() and (v:GetObjectType() == "Texture")) then
            inversedAttributes[v] = k;
        end
    end

    for _, child in pairs({ frame:GetRegions() }) do
        if (not inversedAttributes[child] and (child:GetObjectType() == "Texture")) then
            child:SetTexture("");
        end
    end
end

function Module:CreateFrameTextures()
    CharacterFramePortrait:SetDrawLayer("BORDER", -1);

    local frame = Module.PaperDollFrame
    frame.bg = frame:CreateTexture("$parentBg", "BACKGROUND", "ExtraPaperDollFrameBgTemplate", -6)
    frame.TitleBg = frame:CreateTexture("$parentTitleBg", "BACKGROUND", "ExtraPaperDollFrameTitleBgTemplate", -6)
    frame.PortraitFrame = frame:CreateTexture("$parentPortraitFrame", "OVERLAY", "ExtraPaperDollPortraitFrameTemplate")
    frame.TopRightCorner = frame:CreateTexture("$parentTopRightCorner", "OVERLAY", "ExtraTopRightCornerTemplate")
    frame.TopLeftCorner = frame:CreateTexture("$parentTopLeftCorner", "OVERLAY", "ExtraTopLeftCornerTemplate")
    frame.TopBorder = frame:CreateTexture("$parentTopBorder", "OVERLAY", "ExtraTopBorderTemplate")
    frame.TopTileStreaks = frame:CreateTexture("$parentTopTileStreaks", "BORDER", "ExtraTopTileStreaksTemplate", -2)
    frame.BotLeftCorner = frame:CreateTexture("$parentBotLeftCorner", "BORDER", "ExtraBotLeftCornerTemplate")
    frame.BotRightCorner = frame:CreateTexture("$parentBotRightCorner", "BORDER", "ExtraBotRightCornerTemplate")
    frame.BottomBorder = frame:CreateTexture("$parentBottomBorder", "BORDER", "ExtraBottomBorderTemplate")
    frame.LeftBorder = frame:CreateTexture("$parentLeftBorder", "BORDER", "ExtraLeftBorderTemplate")
    frame.RightBorder = frame:CreateTexture("$parentRightBorder", "BORDER", "ExtraRightBorderTemplate")

    CharacterHeadSlot:CreateTexture("$parentFrame", "BACKGROUND", "ExtraLeftItemSlotTemplate", -1);
    CharacterNeckSlot:CreateTexture("$parentFrame", "BACKGROUND", "ExtraLeftItemSlotTemplate", -1);
    CharacterShoulderSlot:CreateTexture("$parentFrame", "BACKGROUND", "ExtraLeftItemSlotTemplate", -1);
    CharacterBackSlot:CreateTexture("$parentFrame", "BACKGROUND", "ExtraLeftItemSlotTemplate", -1);
    CharacterChestSlot:CreateTexture("$parentFrame", "BACKGROUND", "ExtraLeftItemSlotTemplate", -1);
    CharacterShirtSlot:CreateTexture("$parentFrame", "BACKGROUND", "ExtraLeftItemSlotTemplate", -1);
    CharacterTabardSlot:CreateTexture("$parentFrame", "BACKGROUND", "ExtraLeftItemSlotTemplate", -1);
    CharacterWristSlot:CreateTexture("$parentFrame", "BACKGROUND", "ExtraLeftItemSlotTemplate", -1);
    -- Creating ItemSlot textures under item icons - Right side
    CharacterHandsSlot:CreateTexture("$parentFrame", "BACKGROUND", "ExtraRightItemSlotTemplate", -1);
    CharacterWaistSlot:CreateTexture("$parentFrame", "BACKGROUND", "ExtraRightItemSlotTemplate", -1);
    CharacterLegsSlot:CreateTexture("$parentFrame", "BACKGROUND", "ExtraRightItemSlotTemplate", -1);
    CharacterFeetSlot:CreateTexture("$parentFrame", "BACKGROUND", "ExtraRightItemSlotTemplate", -1);
    CharacterFinger0Slot:CreateTexture("$parentFrame", "BACKGROUND", "ExtraRightItemSlotTemplate", -1);
    CharacterFinger1Slot:CreateTexture("$parentFrame", "BACKGROUND", "ExtraRightItemSlotTemplate", -1);
    CharacterTrinket0Slot:CreateTexture("$parentFrame", "BACKGROUND", "ExtraRightItemSlotTemplate", -1);
    CharacterTrinket1Slot:CreateTexture("$parentFrame", "BACKGROUND", "ExtraRightItemSlotTemplate", -1);
    -- Creating ItemSlot textures under item icons - Bottom side
    CharacterMainHandSlot:CreateTexture("$parentFrame", "BACKGROUND", "ExtraBottomItemSlotTemplate", -1);
    CharacterSecondaryHandSlot:CreateTexture("$parentFrame", "BACKGROUND", "ExtraBottomItemSlotTemplate", -1);
    CharacterRangedSlot:CreateTexture("$parentFrame", "BACKGROUND", "ExtraBottomItemSlotTemplate", -1);
    -- Creating ItemSlot textures under item icons - Borders for bottom items (left and right vertical lines)
    CharacterMainHandSlot:CreateTexture(nil, "BACKGROUND", "ExtraBottomItemSlotLeftBorderTemplate");
    CharacterRangedSlot:CreateTexture(nil, "BACKGROUND", "ExtraBottomItemSlotRightBorderTemplate");
end

function Module:PaperDollFrame_UpdateSidebarTabs()
    for i = 1, #ES_PAPERDOLL_SIDEBARS do
        local tab = _G["PaperDollSidebarTab" .. i];
        if (tab) then
            if (_G[ES_PAPERDOLL_SIDEBARS[i].frame] and _G[ES_PAPERDOLL_SIDEBARS[i].frame]:IsShown()) then
                tab.Hider:Hide();
                tab.Highlight:Hide();
                tab.TabBg:SetTexCoord(0.01562500, 0.79687500, 0.78906250, 0.95703125);
            else
                tab.Hider:Show();
                tab.Highlight:Show();
                tab.TabBg:SetTexCoord(0.01562500, 0.79687500, 0.61328125, 0.78125000);

                if (ES_PAPERDOLL_SIDEBARS[i].IsActive()) then
                    tab:Enable();
                else
                    tab:Disable();
                end
            end
        end
    end
end

local tabs = {}

function Module:CreateCharacterFrames()
    local frame = Module.CharacterFrame

    tabs[1] = ExtraStats:LoadModule("character.stats")
    tabs[2] = ExtraStats:LoadModule("character.titles")
    tabs[3] = ExtraStats:LoadModule("character.gear")

    frame.Inset = CreateFrame("Frame", "$parentInset", frame, "InsetFrameTemplate");
    frame.Inset:SetPoint("TOPLEFT", 20, -72);
    frame.Inset:SetSize(328, 360);

    if frame.Inset.InsetBorderBottomLeft and CharacterFrame.Inset and CharacterFrame.Inset.Bg then
        frame.Inset.InsetBorderBottomLeft:SetPoint("BOTTOMLEFT", CharacterFrame.Inset.Bg, 0, -3);
    end
    if frame.Inset.InsetBorderBottomRight and CharacterFrame.Inset and CharacterFrame.Inset.Bg then
        frame.Inset.InsetBorderBottomRight:SetPoint("BOTTOMRIGHT", CharacterFrame.Inset.Bg, 0, -3);
    end

    frame.InsetRight = CreateFrame("Frame", "$parentInsetRight", frame, "InsetFrameTemplate");
    frame.InsetRight:SetPoint("TOPLEFT", "CharacterFrameInset", "TOPRIGHT", 0, 0);
    frame.InsetRight:SetPoint("BOTTOMRIGHT", CharacterFrame, "BOTTOMRIGHT", -36, 78);

    frame.Sidebar = CreateFrame("Frame", "PaperDollSidebarTabs", frame, "ExtraPaperDollSidebarTabsTemplate");
    frame.Sidebar.tab1:SetScript("OnClick", function(self)
        Module:HandleTabClick(1)
    end)
    frame.Sidebar.tab2:SetScript("OnClick", function(self)
        Module:HandleTabClick(2)
    end)
    frame.Sidebar.tab3:SetScript("OnClick", function(self)
        Module:HandleTabClick(3)
    end)

    local button = CreateFrame("Button", nil, CharacterModelFrame)
    --button:SetPoint("TOPRIGHT", CharacterFrameCloseButton, "TOPLEFT", -5, -7)
    button:SetPoint("BOTTOMLEFT", 10, 8)
    button:SetWidth(18)
    button:SetHeight(18)
    button:SetNormalFontObject("GameFontNormal")
    button.tooltip = "Settings"

    button:SetScript("OnEnter", function()
        GameTooltip:Show()
    end)

    button:SetScript("OnLeave", function()
        GameTooltip:Hide()
    end)

    button:SetScript("OnClick", function()
        ExtraStats:ShowSettings();
    end)

    local ntex = button:CreateTexture()
    ntex:SetTexture(addon.iconPath .. "resources\\cog")
    ntex:SetAllPoints()
    button:SetNormalTexture(ntex)

    ntex = button:CreateTexture()
    ntex:SetTexture(addon.iconPath .. "resources\\cog-down")
    ntex:SetAllPoints()
    button:SetHighlightTexture(ntex)

    for _, tab in pairs(tabs) do
        if tab.init then
            tab:init()
        end
    end

    Module:CreateRoleIcons()
    Module:PaperDollFrame_UpdateSidebarTabs()
end

function Module:CreateRoleIcons()
    if Module.RoleIcons then
        return
    end

    Module.RoleIcons = {}
    local iconSize = 20
    local spacing = 6
    local totalWidth = (#ROLE_ORDER * iconSize) + ((#ROLE_ORDER - 1) * spacing)
    local offsetX = 15
    local offsetY = 32

    for index, role in ipairs(ROLE_ORDER) do
        local iconFrame = CreateFrame("Frame", nil, CharacterModelFrame, "ExtraStatsRoleIconFrameTemplate")
        iconFrame:SetSize(iconSize, iconSize)
        iconFrame:SetPoint("TOPLEFT", CharacterModelFrame, "TOPLEFT", offsetX + ((index - 1) * (iconSize + spacing)), offsetY)
        iconFrame.Icon:SetTexture(ROLE_ICON_TEXTURES[role])
        iconFrame.Icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
        iconFrame.role = role
        iconFrame:SetScript("OnEnter", function(self)
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            GameTooltip:SetText(ROLE_LABELS[self.role] or tostring(self.role))
            GameTooltip:Show()
        end)
        iconFrame:SetScript("OnLeave", function()
            GameTooltip:Hide()
        end)
        Module.RoleIcons[role] = iconFrame
    end

    Module:UpdateRoleIcons()
end

function Module:UpdateRoleIcons()
    if not Module.RoleIcons then
        return
    end

    local enabled = ExtraStats.db and ExtraStats.db.char and ExtraStats.db.char.dynamic
    local activeRole = ExtraStats:GetActiveRole()

    for role, iconFrame in pairs(Module.RoleIcons) do
        if enabled then
            iconFrame:Show()
            local isActive = role == activeRole
            iconFrame.Icon:SetDesaturated(not isActive)
            iconFrame.Icon:SetAlpha(isActive and 1 or 0.45)
        else
            iconFrame:Hide()
        end
    end
end

function Module:HandleTabClick(index)
    if (not _G[ES_PAPERDOLL_SIDEBARS[index].frame]:IsShown()) then
        for i = 1, #ES_PAPERDOLL_SIDEBARS do
            _G[ES_PAPERDOLL_SIDEBARS[i].frame]:Hide();
        end
        _G[ES_PAPERDOLL_SIDEBARS[index].frame]:Show();
        PaperDollFrame.currentSideBar = _G[ES_PAPERDOLL_SIDEBARS[index].frame];
        PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_OFF);
        Module:PaperDollFrame_UpdateSidebarTabs();
    end
end

function Module:SetUpCharacterModelFrame()
    local frame = CharacterModelFrame
    frame:SetSize(231, 320);
    frame:SetPoint("TOPLEFT", PaperDollFrame, 65, -78);

    -- Creating background textures and overlay
    frame:CreateTexture("$parentBackgroundTopLeft", "BACKGROUND", "ExtraCharacterModelFrameBackgroundTopLeft");
    frame:CreateTexture("$parentBackgroundTopRight", "BACKGROUND", "ExtraCharacterModelFrameBackgroundTopRight");
    frame:CreateTexture("$parentBackgroundBotLeft", "BACKGROUND", "ExtraCharacterModelFrameBackgroundBotLeft");
    frame:CreateTexture("$parentBackgroundBotRight", "BACKGROUND", "ExtraCharacterModelFrameBackgroundBotRight");
    frame:CreateTexture("$parentBackgroundOverlay", "BORDER", "ExtraCharacterModelFrameBackgroundOverlay");
    -- Creating borders
    frame:CreateTexture("PaperDollInnerBorderTopLeft", "OVERLAY", "ExtraPaperDollInnerBorderTopLeftTemplate");
    frame:CreateTexture("PaperDollInnerBorderTopRight", "OVERLAY", "ExtraPaperDollInnerBorderTopRightTemplate");
    frame:CreateTexture("PaperDollInnerBorderBottomLeft", "OVERLAY", "ExtraPaperDollInnerBorderBottomLeftTemplate");
    frame:CreateTexture("PaperDollInnerBorderBottomRight", "OVERLAY", "ExtraPaperDollInnerBorderBottomRightTemplate");
    frame:CreateTexture("PaperDollInnerBorderLeft", "OVERLAY", "ExtraPaperDollInnerBorderLeftTemplate");
    frame:CreateTexture("PaperDollInnerBorderRight", "OVERLAY", "ExtraPaperDollInnerBorderRightTemplate");
    frame:CreateTexture("PaperDollInnerBorderTop", "OVERLAY", "ExtraPaperDollInnerBorderTopTemplate");
    frame:CreateTexture("PaperDollInnerBorderBottom", "OVERLAY", "ExtraPaperDollInnerBorderBottomTemplate");
    frame:CreateTexture("PaperDollInnerBorderBottom2", "OVERLAY", "ExtraPaperDollInnerBorderBottom2Template");
end

function Module:SetPaperDollBackground(model, unit)
    local race, fileName = UnitRace(unit);
    local texture = DressUpTexturePath(fileName);

    model.BackgroundTopLeft:SetTexture(texture .. 1);
    model.BackgroundTopRight:SetTexture(texture .. 2);
    model.BackgroundBotLeft:SetTexture(texture .. 3);
    model.BackgroundBotRight:SetTexture(texture .. 4);

    -- HACK - Adjust background brightness for different races
    model.BackgroundOverlay:SetAlpha(0);
end

function Module:PaperDollBgDesaturate(on)
    CharacterModelFrameBackgroundTopLeft:SetDesaturated(on);
    CharacterModelFrameBackgroundTopRight:SetDesaturated(on);
    CharacterModelFrameBackgroundBotLeft:SetDesaturated(on);
    CharacterModelFrameBackgroundBotRight:SetDesaturated(on);
end

function Module:Expand()
    ExtraStats:debug("expand character frame")
    Module.PaperDollFrame.bg:SetPoint("BOTTOMRIGHT", Module.CharacterFrame, "BOTTOMRIGHT", -36, 78);
    Module.PaperDollFrame.TitleBg:SetPoint("TOPRIGHT", Module.CharacterFrame, "TOPRIGHT", -35, -17);
    Module.PaperDollFrame.TopRightCorner:SetPoint("TOPRIGHT", Module.CharacterFrame, "TOPRIGHT", -32, -13);
    Module.PaperDollFrame.TopTileStreaks:SetPoint("TOPRIGHT", Module.CharacterFrame, "TOPRIGHT", -34, -35);
    Module.PaperDollFrame.BotRightCorner:SetPoint("BOTTOMRIGHT", Module.CharacterFrame, "BOTTOMRIGHT", -32, 70);
    -- Moving CharacterFrameCloseButton
    CharacterFrameCloseButton:SetPoint("TOPRIGHT", Module.CharacterFrame, "TOPRIGHT", -28, -9);
    -- Fixing CharacterNameFrame coordinates
    CharacterNameFrame:ClearAllPoints();
    CharacterNameFrame:SetPoint("TOP", CharacterModelFrame, "TOP", 2 + (expandedWidth / 2), 59);
    CharacterNameText:SetSize(420, 12);
    -- Fixing CharacterLevelText coordinates
    CharacterLevelText:SetPoint("TOP", CharacterNameText, "TOP", 0, -31);
    --UpdateUIPanelPositions(Module.CharacterFrame);

    Module.CharacterFrame.Sidebar:Show()
    Module.CharacterFrame.InsetRight:Show()

    CharacterFrame:SetWidth(fullSize);

    SetUIPanelAttribute(CharacterFrame, "width", fullSize);
    UpdateUIPanelPositions(CharacterFrame);

    Module:HandleTabClick(1)
end

function Module:Collapse()
    ExtraStats:debug("collapse character frame")
    Module.PaperDollFrame.bg:SetPoint("BOTTOMRIGHT", CharacterFrame, "BOTTOMRIGHT", -36, 78);
    Module.PaperDollFrame.TitleBg:SetPoint("TOPRIGHT", CharacterFrame, "TOPRIGHT", -35, -17);
    Module.PaperDollFrame.TopRightCorner:SetPoint("TOPRIGHT", CharacterFrame, "TOPRIGHT", -32, -13);
    Module.PaperDollFrame.TopTileStreaks:SetPoint("TOPRIGHT", CharacterFrame, "TOPRIGHT", -34, -35);
    Module.PaperDollFrame.BotRightCorner:SetPoint("BOTTOMRIGHT", CharacterFrame, "BOTTOMRIGHT", -32, 70);
    -- Moving CharacterFrameCloseButton
    CharacterFrameCloseButton:SetPoint("TOPRIGHT", CharacterFrame, "TOPRIGHT", -28, -9);
    -- Fixing CharacterNameFrame coordinates
    CharacterNameFrame:ClearAllPoints();
    CharacterNameFrame:SetPoint("TOP", CharacterModelFrame, "TOP", 4, 59);
    CharacterNameText:SetSize(218, 12);
    -- Fixing CharacterLevelText coordinates
    CharacterLevelText:SetPoint("TOP", CharacterNameText, "TOP", 0, -31);

    UpdateUIPanelPositions(CharacterFrame);

    Module.CharacterFrame.Sidebar:Hide()
    Module.CharacterFrame.InsetRight:Hide()

    CharacterFrame:SetWidth(defaultWith);

    SetUIPanelAttribute(CharacterFrame, "width", defaultWith);
    UpdateUIPanelPositions(CharacterFrame);

    CharacterFrame.Expanded = false;
end

function Module:GetPrimaryTalentTree(tab)
    local cache = {};
    EnsureTalentUILoaded();
    local numTabs = GetNumTalentTabs and GetNumTalentTabs() or 0;
    if numTabs > 0 then
        local bestTab = nil;
        local bestPoints = -1;
        for i = 1, numTabs do
            local points = GetTalentTabPoints(i);
            if points > bestPoints then
                bestPoints = points;
                bestTab = i;
            end
        end
        return bestTab;
    end
    if not TalentFrame_UpdateSpecInfoCache then
        return cache.primaryTabIndex
    end
    if (tab) then
        TalentFrame_UpdateSpecInfoCache(cache, false, false, tab);
    elseif GetActiveTalentGroup then
        local ok, group = pcall(GetActiveTalentGroup)
        if ok and group then
            TalentFrame_UpdateSpecInfoCache(cache, false, false, group);
        end
    end
    return cache.primaryTabIndex;
end

function Module:GetPrimaryTalentTreeName()
    local bestName = nil;
    local bestPoints = -1;
    EnsureTalentUILoaded();
    local numTabs = GetNumTalentTabs and GetNumTalentTabs() or 0;
    for i = 1, numTabs do
        local points = GetTalentTabPoints(i);
        if points > bestPoints then
            bestPoints = points;
            bestName = GetTalentTabName(i);
            if not bestName then
                local class = select(2, UnitClass("player"));
                if class and SPEC_TABLE[class] then
                    bestName = SPEC_TABLE[class][i];
                end
            end
        end
    end
    if bestName and bestPoints > 0 then
        return bestName;
    end
    return nil;
end

function Module:SetLevel()
    local primaryTalentTree = Module:GetPrimaryTalentTree();
    local classDisplayName, class = UnitClass("player");
    local classColor = RAID_CLASS_COLORS[class];
    local classColorString = RAID_CLASS_COLORS[class].colorStr;
    local specName, _;
    local level = UnitLevel("player");

    if (primaryTalentTree) then
        specName = GetTalentTabInfo(primaryTalentTree);
    end
    if (type(specName) ~= "string" or specName == "") then
        specName = Module:GetPrimaryTalentTreeName();
    end

    if (specName and specName ~= "") then
        CharacterLevelText:SetFormattedText("Level %s |c%s%s %s|r", level, classColorString, specName, classDisplayName);
    else
        CharacterLevelText:SetFormattedText("Level %s |c%s%s|r", level, classColorString, classDisplayName);
    end

    ---- Hack: if the string is very long, move it a bit so that it has more room (although it will no longer be centered)
    --if (CharacterLevelText:GetWidth() > 210) then
    --    if (CharacterFrameInsetRight:IsVisible()) then
    --        --[[ CharacterLevelText:SetPoint("TOP", -10, -36); ]]
    --        CharacterLevelText:AdjustPointsOffset(-10, 0);
    --    else
    --        --[[ CharacterLevelText:SetPoint("TOP", 10, -36); ]]
    --        CharacterLevelText:AdjustPointsOffset(10, 0);
    --    end
    --else
    --    --[[ CharacterLevelText:SetPoint("TOP", 0, -36); ]]
    --    CharacterLevelText:AdjustPointsOffset(0, 0);
    --end
end

function Module:EventHandler(event, ...)
    local arg1, arg2 = ...;

    Module:SetLevel()

    if event == "PLAYER_ENTERING_WORLD" and (arg1 or arg2) then
        Module:CleanDefaultFrame();
        Module:DeleteFrameTextures(Module.PaperDollFrame)
        Module:CreateFrameTextures()

        Module:CreateCharacterFrames()

        Module:SetUpCharacterModelFrame()
        Module:SetPaperDollBackground(CharacterModelFrame, "player");
        CharacterHeadSlot:SetPoint("TOPLEFT", CharacterFrame.Inset, "TOPLEFT", 3, -2);
        CharacterHandsSlot:SetPoint("TOPLEFT", CharacterFrame.Inset, "TOPRIGHT", -43, -2);
        CharacterMainHandSlot:SetPoint("TOPLEFT", PaperDollItemsFrame, "BOTTOMLEFT", 120, 129);

        CharacterFrameInset:SetPoint("BOTTOMRIGHT", CharacterFrame, "BOTTOMLEFT", PANEL_DEFAULT_WIDTH + PANEL_INSET_RIGHT_OFFSET + 16, PANEL_INSET_BOTTOM_OFFSET + 76);

        CharacterFrame:RegisterEvent("PLAYER_PVP_RANK_CHANGED");
        CharacterFrame:RegisterEvent("PREVIEW_TALENT_POINTS_CHANGED");
        CharacterFrame:RegisterEvent("PLAYER_TALENT_UPDATE");
        CharacterFrame:RegisterEvent("ACTIVE_TALENT_GROUP_CHANGED");
        CharacterFrame:UnregisterEvent("UNIT_PORTRAIT_UPDATE");

        Module.PaperDollFrame:SetScript("OnShow", function()
            CharacterFrame.Inset:Show();
            Module:Expand()

            Module:SetPaperDollBackground(CharacterModelFrame, "player");
            Module:PaperDollBgDesaturate(false);
            Module:CleanDefaultFrame();
            HideDefaultTitleDropDown();
            Module.CharacterFrame.Sidebar:Show();

            ExtraStats:Trigger("character.window.show")
        end)

        Module.PaperDollFrame:SetScript("OnHide", function()
            CharacterFrameInset:Hide();
            Module:Collapse()

            Module.CharacterFrame.Sidebar:Hide();
            ExtraStats:Trigger("character.window.hide")
        end)

        Module:Expand()

        ExtraStats:Trigger("character.window")

        ShowUIPanel(CharacterFrame)
        HideUIPanel(CharacterFrame)

    end
end

function Module:PaperDollFrame_OnLoad(self)
    self:RegisterEvent("PLAYER_ENTERING_WORLD");
    self:RegisterEvent("CHARACTER_POINTS_CHANGED");
    self:RegisterEvent("UNIT_MODEL_CHANGED");
    self:RegisterEvent("UNIT_LEVEL");
    self:RegisterEvent("UNIT_RESISTANCES");
    self:RegisterEvent("UNIT_STATS");
    self:RegisterEvent("UNIT_DAMAGE");
    self:RegisterEvent("UNIT_RANGEDDAMAGE");
    self:RegisterEvent("UNIT_ATTACK_SPEED");
    self:RegisterEvent("UNIT_ATTACK_POWER");
    self:RegisterEvent("UNIT_RANGED_ATTACK_POWER");
    self:RegisterEvent("UNIT_ATTACK");
    self:RegisterEvent("UNIT_SPELL_HASTE");
    self:RegisterEvent("PLAYER_GUILD_UPDATE");
    self:RegisterEvent("SKILL_LINES_CHANGED");
    self:RegisterEvent("COMBAT_RATING_UPDATE");
    self:RegisterEvent("UNIT_NAME_UPDATE");
    self:RegisterEvent("VARIABLES_LOADED");
    self:RegisterEvent("PLAYER_TALENT_UPDATE");
    self:RegisterEvent("BAG_UPDATE");
    self:RegisterEvent("PLAYER_EQUIPMENT_CHANGED");
    self:RegisterEvent("PLAYER_DAMAGE_DONE_MODS");
    self:RegisterEvent("ACTIVE_TALENT_GROUP_CHANGED");
    self:RegisterEvent("UNIT_MAXHEALTH");
end

function ExtraStats:CreateWindow()
    Module:PaperDollFrame_OnLoad(PaperDollFrame);
    local mainFrame = CreateFrame("Frame");
    mainFrame:RegisterEvent("PLAYER_ENTERING_WORLD");
    mainFrame:SetScript("OnEvent", Module.EventHandler);
    --mainFrame:SetScript("OnUpdate", function()
    --
    --end);

    ExtraStats:On("character.stats", function()
        if CharacterFrame:IsVisible() then
            Module:SetLevel()
        end
    end)
end
