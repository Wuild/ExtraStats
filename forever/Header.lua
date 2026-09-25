-- Original ExtraStats sidebar artwork on Forever's native navigation buttons.
local addonName = ...
local _, _, _, interface = GetBuildInfo()
if interface < 16000 or interface >= 17000 then return end
local texture = "Interface\\PaperDollInfoFrame\\PaperDollSidebarTabs"
local styled = {}
local decoration

local function Piece(owner, layer, width, height, point, relativePoint, x, y, coords)
    local region = owner:CreateTexture(nil, layer)
    region:SetTexture(texture)
    region:SetSize(width, height)
    region:SetPoint(point, owner, relativePoint, x, y)
    region:SetTexCoord(unpack(coords))
    return region
end

local function UpdateHeader()
    -- The native sidebar setter restores this atlas's original size on each tab.
    CharacterFrameRightPaneHostStoneBg:SetAlpha(1)
    CharacterFrameRightPaneHostStoneBg:SetHeight(40)
    local visible = {}
    -- Display order is independent of Forever's native IDs (stats/gear/pet).
    for _, button in ipairs({ PaperDollSidebarTab1, PaperDollSidebarTab2, PaperDollSidebarTab3 }) do
        if button:IsShown() then table.insert(visible, button) end
    end
    decoration:SetWidth(#visible * 35 + 56)
    for index, button in ipairs(visible) do
        button:ClearAllPoints()
        button:SetPoint("BOTTOM", CharacterFrameRightPaneHostStoneBg, "BOTTOM", (index - (#visible + 1) / 2) * 35, 1)
        local art = styled[button]
        local selected = button:GetChecked()
        art.background:SetTexCoord(0.015625, 0.796875, selected and 0.7890625 or 0.61328125, selected and 0.95703125 or 0.78125)
        art.hider:SetShown(not selected)
    end
end

local events = CreateFrame("Frame")
events:RegisterEvent("ADDON_LOADED")
events:SetScript("OnEvent", function(self, _, name)
    if name ~= addonName then return end
    self:UnregisterEvent("ADDON_LOADED")
    PaperDollSidebarTabs:SetHeight(40)
    -- Keep Forever's stone header visible behind the Classic tab artwork.
    -- The former opaque rock overlay concealed the native panel texture.
    decoration = CreateFrame("Frame", nil, PaperDollSidebarTabs)
    decoration:SetSize(161, 35)
    decoration:SetPoint("BOTTOM", CharacterFrameRightPaneHostStoneBg, "BOTTOM", 0, 1)
    Piece(decoration, "ARTWORK", 28, 11, "BOTTOMLEFT", "BOTTOMLEFT", 0, 0,
        {0.015625, 0.453125, 0.00390625, 0.046875})
    Piece(decoration, "ARTWORK", 28, 13, "BOTTOMRIGHT", "BOTTOMRIGHT", 0, 0,
        {0.015625, 0.453125, 0.0546875, 0.10546875})
    for index, button in ipairs({ PaperDollSidebarTab1, PaperDollSidebarTab2, PaperDollSidebarTab3 }) do
        button:SetSize(33, 35)
        for _, region in ipairs({ button:GetRegions() }) do
            if region:IsObjectType("Texture") and region:GetAtlas() == "UI-Character-Info-StatTab" then region:Hide() end
        end
        local checked = button:GetCheckedTexture()
        if checked then checked:SetAlpha(0) end
        button.Icon:SetDrawLayer("ARTWORK")
        button.Icon:ClearAllPoints()
        button.Icon:SetPoint("BOTTOM", button, "BOTTOM", 1, index == 1 and 0 or -2)
        button.Icon:SetSize(index == 1 and 29 or 33, index == 1 and 31 or 35)
        if index == 1 then
            button.Icon:SetTexCoord(0.109375, 0.890625, 0.09375, 0.90625)
        elseif index == 2 then
            button.Icon:SetTexture(texture)
            button.Icon:SetTexCoord(0.015625, 0.53125, 0.46875, 0.60546875)
        end -- Pet keeps its native icon; it is not the Classic gear-set tab.
        local background = Piece(button, "BACKGROUND", 50, 43, "BOTTOMLEFT", "BOTTOMLEFT", -9, -2,
            {0.015625, 0.796875, 0.61328125, 0.78125})
        local hider = Piece(button, "OVERLAY", 34, 19, "BOTTOM", "BOTTOM", 0, 0,
            {0.015625, 0.546875, 0.11328125, 0.1875})
        Piece(button, "HIGHLIGHT", 31, 31, "TOPLEFT", "TOPLEFT", 2, -3,
            {0.015625, 0.5, 0.1953125, 0.31640625})
        styled[button] = { background = background, hider = hider }
    end
    -- Match Classic's level/class subtitle beneath the character-window title.
    PaperDollLevelInfo:ClearAllPoints()
    PaperDollLevelInfo:SetPoint("TOP", CharacterFrame, "TOP", 0, -34)
    CharacterLevelText:SetFontObject("GameFontNormal")
    CharacterLevelTextBackground:Hide()
    -- Native stats-tab click focuses its hidden ScrollBox. Focus our visible
    -- rows instead; leave gear and pet tabs on their native controller paths.
    PaperDollSidebarTab1:SetScript("OnClick", function(button)
        PaperDollFrame_SetSidebar(button, 1)
        if InputUtil.IsGamepadUIEnabled() and SmartNavigation:GetActiveFrame() == CharacterFrame then
            local ui = ExtraStatsForeverStats
            ui:Refresh()
            for _, row in ipairs(ui.rows) do
                if row:IsShown() then SmartNavigation:SelectButton(row); break end
            end
        end
    end)
    hooksecurefunc("PaperDollFrame_UpdateSidebarTabs", UpdateHeader)
    UpdateHeader()
end)
