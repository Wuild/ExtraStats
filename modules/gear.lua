local name, stats = ...

local Module = {  }

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

local ALT_BAR_BUTTON_SIZE = 37
local ALT_BAR_BUTTON_GAP = 4
local ALT_BAR_MAX_BUTTONS = 14
local DRAWER_MARGIN = 0
local DRAWER_ANIM_DURATION = 0.12
local DRAWER_ANIM_SLIDE = 8
local DRAWER_BORDER = 3
local DRAWER_THICKNESS = ALT_BAR_BUTTON_SIZE + (DRAWER_BORDER * 2)

local FLYOUT_TEX = "Interface\\PaperDollInfoFrame\\UI-GearManager-Flyout"
local ONESLOT_LEFT_COORDS = { 0, 0.09765625, 0.5546875, 0.77734375 }
local ONESLOT_RIGHT_COORDS = { 0.41796875, 0.51171875, 0.5546875, 0.77734375 }
local ONESLOT_LEFT_WIDTH = 25
local ONESLOT_RIGHT_WIDTH = 24
local ONEROW_LEFT_COORDS = { 0, 0.16796875, 0.5546875, 0.77734375 }
local ONEROW_CENTER_COORDS = { 0.16796875, 0.328125, 0.5546875, 0.77734375 }
local ONEROW_RIGHT_COORDS = { 0.328125, 0.51171875, 0.5546875, 0.77734375 }
local ONEROW_LEFT_WIDTH = 43
local ONEROW_CENTER_WIDTH = 41
local ONEROW_RIGHT_WIDTH = 47

local AltBarFrame
local hideAltBarRequestId = 0
local activeSlotID
local RefreshActiveDrawer
local UpdateFlyoutButtonsVisualState
local drawerHoverWatchId = 0
local flyoutRefreshRequestId = 0
local gearFrameRefreshRequestId = 0
local alternativesCacheBySlot = {}
local alternativesCacheDirty = true
local characterFrameRefreshHooked = false

local SLOT_EQUIP_LOCS = {
    [INVSLOT_HEAD] = { INVTYPE_HEAD = true },
    [INVSLOT_NECK] = { INVTYPE_NECK = true },
    [INVSLOT_SHOULDER] = { INVTYPE_SHOULDER = true },
    [INVSLOT_BACK] = { INVTYPE_CLOAK = true },
    [INVSLOT_CHEST] = { INVTYPE_CHEST = true, INVTYPE_ROBE = true },
    [INVSLOT_WRIST] = { INVTYPE_WRIST = true },
    [INVSLOT_HAND] = { INVTYPE_HAND = true },
    [INVSLOT_WAIST] = { INVTYPE_WAIST = true },
    [INVSLOT_LEGS] = { INVTYPE_LEGS = true },
    [INVSLOT_FEET] = { INVTYPE_FEET = true },
    [INVSLOT_FINGER1] = { INVTYPE_FINGER = true },
    [INVSLOT_FINGER2] = { INVTYPE_FINGER = true },
    [INVSLOT_TRINKET1] = { INVTYPE_TRINKET = true },
    [INVSLOT_TRINKET2] = { INVTYPE_TRINKET = true },
    [INVSLOT_MAINHAND] = { INVTYPE_WEAPON = true, INVTYPE_WEAPONMAINHAND = true, INVTYPE_2HWEAPON = true },
    [INVSLOT_OFFHAND] = { INVTYPE_WEAPON = true, INVTYPE_WEAPONOFFHAND = true, INVTYPE_SHIELD = true, INVTYPE_HOLDABLE = true },
    [INVSLOT_RANGED] = { INVTYPE_RANGED = true, INVTYPE_THROWN = true, INVTYPE_RANGEDRIGHT = true, INVTYPE_RELIC = true },
}

local SLOT_ANCHOR_SIDE = {
    [INVSLOT_HEAD] = "RIGHT",
    [INVSLOT_NECK] = "RIGHT",
    [INVSLOT_SHOULDER] = "RIGHT",
    [INVSLOT_BACK] = "RIGHT",
    [INVSLOT_CHEST] = "RIGHT",
    [INVSLOT_WRIST] = "RIGHT",
    [INVSLOT_HAND] = "LEFT",
    [INVSLOT_WAIST] = "LEFT",
    [INVSLOT_LEGS] = "LEFT",
    [INVSLOT_FEET] = "LEFT",
    [INVSLOT_FINGER1] = "LEFT",
    [INVSLOT_FINGER2] = "LEFT",
    [INVSLOT_TRINKET1] = "LEFT",
    [INVSLOT_TRINKET2] = "LEFT",
    [INVSLOT_MAINHAND] = "UP",
    [INVSLOT_OFFHAND] = "UP",
    [INVSLOT_RANGED] = "UP",
}

local CONTAINER = C_Container or {}

local function GetContainerNumSlotsCompat(bag)
    if CONTAINER.GetContainerNumSlots then
        return CONTAINER.GetContainerNumSlots(bag)
    end
    return GetContainerNumSlots(bag)
end

local function GetContainerItemLinkCompat(bag, slot)
    if CONTAINER.GetContainerItemLink then
        return CONTAINER.GetContainerItemLink(bag, slot)
    end
    return GetContainerItemLink(bag, slot)
end

local function GetContainerItemCountCompat(bag, slot)
    if CONTAINER.GetContainerItemInfo then
        local info = CONTAINER.GetContainerItemInfo(bag, slot)
        return (info and info.stackCount) or 0
    end
    local _, count = GetContainerItemInfo(bag, slot)
    return count or 0
end

local function PickupContainerItemCompat(bag, slot)
    if CONTAINER.PickupContainerItem then
        return CONTAINER.PickupContainerItem(bag, slot)
    end
    return PickupContainerItem(bag, slot)
end

local function UnequipInventorySlot(slotID)
    if not slotID or not GetInventoryItemLink("player", slotID) then
        return false
    end

    PickupInventoryItem(slotID)
    if not CursorHasItem() then
        return false
    end

    for bag = 0, NUM_BAG_SLOTS do
        local slots = GetContainerNumSlotsCompat(bag) or 0
        for slot = 1, slots do
            if not GetContainerItemLinkCompat(bag, slot) then
                PickupContainerItemCompat(bag, slot)
                if not CursorHasItem() then
                    return true
                end
            end
        end
    end

    -- No compatible bag space was available; put the item back where it came from.
    PickupInventoryItem(slotID)
    UIErrorsFrame:AddMessage(ERR_INV_FULL or "Inventory is full.", 1.0, 0.1, 0.1, 1.0)
    return false
end

local function NormalizeItemLink(link)
    if not link then
        return nil
    end
    return string.match(link, "|H(item:[^|]+)|h") or string.match(link, "(item:[^|]+)") or link
end

local function MarkAlternativesCacheDirty()
    alternativesCacheDirty = true
end

local function RebuildAlternativesCache()
    alternativesCacheBySlot = {}
    local seenBySlot = {}
    local equippedBySlot = {}

    for slotID in pairs(SLOT_EQUIP_LOCS) do
        alternativesCacheBySlot[slotID] = {}
        seenBySlot[slotID] = {}
        equippedBySlot[slotID] = NormalizeItemLink(GetInventoryItemLink("player", slotID))
    end

    for bag = 0, NUM_BAG_SLOTS do
        local slots = GetContainerNumSlotsCompat(bag) or 0
        for slot = 1, slots do
            local link = GetContainerItemLinkCompat(bag, slot)
            if link then
                local normalized = NormalizeItemLink(link)
                if normalized then
                    local _, itemLink, itemQuality, _, _, _, _, _, equipLoc, icon = GetItemInfo(link)
                    if GetItemInfoInstant and ((not equipLoc or equipLoc == "") or (not icon or icon == 0)) then
                        local _, _, _, instantEquipLoc, instantIcon = GetItemInfoInstant(link)
                        if not equipLoc or equipLoc == "" then
                            equipLoc = instantEquipLoc
                        end
                        if not icon or icon == 0 then
                            icon = instantIcon
                        end
                    end

                    if equipLoc and equipLoc ~= "" then
                        local stackCount = GetContainerItemCountCompat(bag, slot) or 1
                        for slotID, equipLocMap in pairs(SLOT_EQUIP_LOCS) do
                            if equipLocMap[equipLoc] and normalized ~= equippedBySlot[slotID] then
                                local existing = seenBySlot[slotID][normalized]
                                if not existing then
                                    existing = {
                                        link = itemLink or link,
                                        count = 0,
                                        icon = icon,
                                        quality = itemQuality,
                                        bag = bag,
                                        slot = slot,
                                    }
                                    seenBySlot[slotID][normalized] = existing
                                    table.insert(alternativesCacheBySlot[slotID], existing)
                                end
                                existing.count = existing.count + stackCount
                            end
                        end
                    end
                end
            end
        end
    end

    for slotID in pairs(SLOT_EQUIP_LOCS) do
        table.sort(alternativesCacheBySlot[slotID], function(a, b)
            return tostring(a.link) < tostring(b.link)
        end)
    end

    alternativesCacheDirty = false
end

local function GetAlternativesForSlot(slotID)
    if not slotID or not SLOT_EQUIP_LOCS[slotID] then
        return {}
    end
    if alternativesCacheDirty then
        RebuildAlternativesCache()
    end
    return alternativesCacheBySlot[slotID] or {}
end

local function HideAltBar()
    if AltBarFrame then
        AltBarFrame:Hide()
    end
    drawerHoverWatchId = drawerHoverWatchId + 1
    activeSlotID = nil
    if UpdateFlyoutButtonsVisualState then
        UpdateFlyoutButtonsVisualState()
    end
end

local function IsMouseOverActiveSlot()
    if not activeSlotID then
        return false
    end
    for _, frame in ipairs(GEAR_SLOT_FRAMES) do
        if frame and frame.GetID and frame:GetID() == activeSlotID and frame.IsMouseOver and frame:IsMouseOver() then
            return true
        end
    end
    return false
end

local function IsMouseOverActiveSlotFlyoutButton()
    if not activeSlotID then
        return false
    end
    for _, frame in ipairs(GEAR_SLOT_FRAMES) do
        if frame and frame.GetID and frame:GetID() == activeSlotID then
            local btn = frame.ExtraStatsFlyoutButton
            return btn and btn:IsShown() and btn.IsMouseOver and btn:IsMouseOver()
        end
    end
    return false
end

local function ScheduleHideAltBar(delay)
    hideAltBarRequestId = hideAltBarRequestId + 1
    local requestId = hideAltBarRequestId
    C_Timer.After(delay or 0.15, function()
        if requestId ~= hideAltBarRequestId then
            return
        end
        if AltBarFrame and AltBarFrame:IsMouseOver() then
            return
        end
        if IsMouseOverActiveSlot() then
            return
        end
        if IsMouseOverActiveSlotFlyoutButton() then
            return
        end
        HideAltBar()
    end)
end

local function StartDrawerHoverWatch()
    drawerHoverWatchId = drawerHoverWatchId + 1
    local watchId = drawerHoverWatchId

    local function tick()
        if watchId ~= drawerHoverWatchId then
            return
        end
        if not AltBarFrame or not AltBarFrame:IsShown() then
            return
        end
        if AltBarFrame:IsMouseOver() or IsMouseOverActiveSlot() or IsMouseOverActiveSlotFlyoutButton() then
            C_Timer.After(0.10, tick)
            return
        end
        HideAltBar()
    end

    C_Timer.After(0.20, tick)
end

local function RefreshEquipmentSlotTooltipForModifiers()
    if not GameTooltip or not GameTooltip:IsShown() then
        return
    end

    local owner = GameTooltip:GetOwner()
    if not owner then
        return
    end

    if owner.ExtraStatsDrawerItem and owner.itemLink then
        GameTooltip:SetOwner(owner, "ANCHOR_RIGHT")
        GameTooltip:SetHyperlink(owner.itemLink)
        return
    end

    local slotID
    for _, gearSlotFrame in ipairs(GEAR_SLOT_FRAMES) do
        if owner == gearSlotFrame and gearSlotFrame.GetID then
            slotID = gearSlotFrame:GetID()
            break
        end
    end
    if not slotID or slotID <= 0 then
        return
    end

    -- Rebuild tooltip content so compare tooltips react to current modifier keys.
    GameTooltip:SetInventoryItem("player", slotID)
end

local function EnsureAltBarFrame()
    if AltBarFrame then
        return AltBarFrame
    end

    AltBarFrame = CreateFrame("Frame", "ExtraStatsGearAltBar", UIParent, "BackdropTemplate")
    AltBarFrame:SetFrameStrata("HIGH")
    AltBarFrame:SetFrameLevel(200)
    AltBarFrame:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Buttons\\WHITE8X8",
        tile = true,
        tileSize = 8,
        edgeSize = 1,
        insets = { left = 1, right = 1, top = 1, bottom = 1 },
    })
    AltBarFrame:SetBackdropColor(0.07, 0.08, 0.1, 0.97)
    AltBarFrame:SetBackdropBorderColor(0.28, 0.34, 0.4, 0.95)
    AltBarFrame:SetMovable(false)
    AltBarFrame:EnableMouse(true)
    AltBarFrame:Hide()
    AltBarFrame:SetClampedToScreen(true)
    AltBarFrame:SetAlpha(0)

    AltBarFrame.verticalBG = AltBarFrame:CreateTexture(nil, "BACKGROUND")
    AltBarFrame.verticalBG:SetTexture(FLYOUT_TEX)
    AltBarFrame.verticalBG:SetTexCoord(unpack(ONEROW_CENTER_COORDS))
    AltBarFrame.verticalBG:SetVertexColor(1, 1, 1, 1)
    AltBarFrame.verticalBG:SetAllPoints()

    AltBarFrame.verticalBorder = AltBarFrame:CreateTexture(nil, "BORDER")
    AltBarFrame.verticalBorder:SetTexture("Interface\\Buttons\\WHITE8X8")
    AltBarFrame.verticalBorder:SetVertexColor(0.24, 0.31, 0.38, 0.95)
    AltBarFrame.verticalBorder:SetAllPoints()

    AltBarFrame.bgLeft = AltBarFrame:CreateTexture(nil, "BACKGROUND")
    AltBarFrame.bgLeft:SetTexture(FLYOUT_TEX)
    AltBarFrame.bgCenter = AltBarFrame:CreateTexture(nil, "BACKGROUND")
    AltBarFrame.bgCenter:SetTexture(FLYOUT_TEX)
    AltBarFrame.bgRight = AltBarFrame:CreateTexture(nil, "BACKGROUND")
    AltBarFrame.bgRight:SetTexture(FLYOUT_TEX)
    AltBarFrame.bgCenters = {}
    for i = 1, ALT_BAR_MAX_BUTTONS do
        local tex = AltBarFrame:CreateTexture(nil, "BACKGROUND")
        tex:SetTexture(FLYOUT_TEX)
        tex:Hide()
        AltBarFrame.bgCenters[i] = tex
    end

    AltBarFrame.buttons = {}
    for i = 1, ALT_BAR_MAX_BUTTONS do
        local btn = CreateFrame("Button", nil, AltBarFrame)
        btn:SetSize(ALT_BAR_BUTTON_SIZE, ALT_BAR_BUTTON_SIZE)
        btn:EnableMouse(true)
        btn:RegisterForClicks("LeftButtonUp", "RightButtonUp")
        btn.ExtraStatsDrawerItem = true

        btn.icon = btn:CreateTexture(nil, "ARTWORK")
        btn.icon:SetPoint("TOPLEFT", 0, 0)
        btn.icon:SetPoint("BOTTOMRIGHT", 0, 0)
        btn.icon:SetTexCoord(0.07, 0.93, 0.07, 0.93)

        btn.border = btn:CreateTexture(nil, "OVERLAY")
        btn.border:SetAllPoints()
        btn.border:SetTexture(stats.iconPath .. "resources\\WhiteIconFrame.blp")
        btn.border:SetVertexColor(0.2, 0.2, 0.2, 0.85)

        btn.hover = btn:CreateTexture(nil, "HIGHLIGHT")
        btn.hover:SetAllPoints(btn.icon)
        btn.hover:SetTexture("Interface\\Buttons\\ButtonHilight-Square")
        btn.hover:SetBlendMode("ADD")
        btn.hover:SetAlpha(0.45)

        btn.count = btn:CreateFontString(nil, "OVERLAY", "NumberFontNormalSmall")
        btn.count:SetPoint("BOTTOMRIGHT", -2, 2)

        btn:SetScript("OnEnter", function(self)
            hideAltBarRequestId = hideAltBarRequestId + 1
            if self.isUnequip then
                GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
                GameTooltip:SetText("Unequip")
                GameTooltip:AddLine("Move the equipped item to your bags.", 1, 1, 1, true)
                GameTooltip:Show()
            elseif self.itemLink then
                GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
                GameTooltip:SetHyperlink(self.itemLink)
                GameTooltip:Show()
            end
        end)
        btn:SetScript("OnLeave", function()
            GameTooltip:Hide()
            ScheduleHideAltBar(0.2)
        end)
        btn:SetScript("OnClick", function(self, mouseButton)
            if mouseButton ~= "LeftButton" and mouseButton ~= "RightButton" then
                return
            end
            if not self.targetSlotID then
                return
            end
            if self.isUnequip then
                UnequipInventorySlot(self.targetSlotID)
                HideAltBar()
                return
            end
            if self.bag == nil or not self.slot then
                return
            end
            PickupContainerItemCompat(self.bag, self.slot)
            if CursorHasItem() then
                EquipCursorItem(self.targetSlotID)
            end
            C_Timer.After(0.05, RefreshActiveDrawer)
        end)

        AltBarFrame.buttons[i] = btn
    end

    AltBarFrame:SetScript("OnEnter", function()
        hideAltBarRequestId = hideAltBarRequestId + 1
    end)
    AltBarFrame:SetScript("OnLeave", function()
        ScheduleHideAltBar(0.15)
    end)

    return AltBarFrame
end

local function PositionDrawer(bar, slotFrame, anchorSide, progress)
    local p = progress or 1
    local slide = (1 - p) * DRAWER_ANIM_SLIDE

    bar:ClearAllPoints()

    if anchorSide == "RIGHT" then
        bar:SetPoint("LEFT", slotFrame, "RIGHT", DRAWER_MARGIN - slide, 0)
    elseif anchorSide == "LEFT" then
        bar:SetPoint("RIGHT", slotFrame, "LEFT", -DRAWER_MARGIN + slide, 0)
    else
        bar:SetPoint("BOTTOM", slotFrame, "TOP", 0, DRAWER_MARGIN - slide)
    end
end

local function LayoutDrawerBackground(bar, shown, isVertical)
    for i = 1, ALT_BAR_MAX_BUTTONS do
        bar.bgCenters[i]:Hide()
    end
    bar.bgLeft:Hide()
    bar.bgCenter:Hide()
    bar.bgRight:Hide()
    bar.verticalBG:Hide()
    bar.verticalBorder:Hide()
end

local function AnimateDrawerOpen(bar, slotFrame, anchorSide)
    bar.animAnchor = anchorSide
    bar.animSlot = slotFrame
    bar.animStart = GetTime()
    bar:SetAlpha(0)
    PositionDrawer(bar, slotFrame, anchorSide, 0)

    bar:SetScript("OnUpdate", function(self)
        local elapsed = GetTime() - (self.animStart or 0)
        local p = elapsed / DRAWER_ANIM_DURATION
        if p >= 1 then
            self:SetAlpha(1)
            PositionDrawer(self, self.animSlot, self.animAnchor, 1)
            self:SetScript("OnUpdate", nil)
            return
        end
        self:SetAlpha(p)
        PositionDrawer(self, self.animSlot, self.animAnchor, p)
    end)
end

local function ShowAlternativesBar(slotFrame, animate)
    if not slotFrame or not slotFrame.GetID then
        return
    end

    local slotID = slotFrame:GetID()
    if not slotID or slotID <= 0 then
        return
    end

    local alternatives = GetAlternativesForSlot(slotID)
    local bar = EnsureAltBarFrame()

    local canUnequip = GetInventoryItemLink("player", slotID) ~= nil
    if #alternatives == 0 and not canUnequip then
        if not bar:IsShown() then
            HideAltBar()
        end
        return
    end

    hideAltBarRequestId = hideAltBarRequestId + 1
    activeSlotID = slotID

    local shown = math.min(#alternatives + (canUnequip and 1 or 0), ALT_BAR_MAX_BUTTONS)
    for i = 1, ALT_BAR_MAX_BUTTONS do
        local btn = bar.buttons[i]
        if i <= shown then
            btn.targetSlotID = slotID
            btn.isUnequip = canUnequip and i == 1
            if btn.isUnequip then
                btn.itemLink = nil
                btn.bag = nil
                btn.slot = nil
                btn.icon:SetTexture("Interface\\PaperDollInfoFrame\\UI-GearManager-LeaveItem-Transparent")
                btn.icon:SetTexCoord(0, 1, 0, 1)
                btn.count:SetText("")
                btn.border:SetVertexColor(0.8, 0.15, 0.15, 0.95)
            else
                local itemIndex = i - (canUnequip and 1 or 0)
                local item = alternatives[itemIndex]
                btn.itemLink = item.link
                btn.bag = item.bag
                btn.slot = item.slot
                btn.icon:SetTexture(item.icon or "Interface\\Icons\\INV_Misc_QuestionMark")
                btn.icon:SetTexCoord(0.07, 0.93, 0.07, 0.93)
                btn.count:SetText(item.count and item.count > 1 and tostring(item.count) or "")
                if item.quality then
                    local r, g, b = GetItemQualityColor(item.quality)
                    btn.border:SetVertexColor(r or 0.2, g or 0.2, b or 0.2, 0.95)
                else
                    btn.border:SetVertexColor(0.2, 0.2, 0.2, 0.85)
                end
            end
            btn:Show()
        else
            btn.isUnequip = nil
            btn.itemLink = nil
            btn.targetSlotID = nil
            btn.bag = nil
            btn.slot = nil
            btn:Hide()
        end
    end

    local anchorSide = SLOT_ANCHOR_SIDE[slotID] or "UP"
    local isVertical = anchorSide == "UP"
    if isVertical then
        local height = (shown * ALT_BAR_BUTTON_SIZE) + (math.max(0, shown - 1) * ALT_BAR_BUTTON_GAP) + (DRAWER_BORDER * 2)
        bar:SetSize(DRAWER_THICKNESS, height)
        LayoutDrawerBackground(bar, shown, true)

        local startY = DRAWER_BORDER
        local x = DRAWER_BORDER
        for i = 1, shown do
            local btn = bar.buttons[i]
            btn:ClearAllPoints()
            btn:SetPoint("BOTTOMLEFT", bar, "BOTTOMLEFT", x, startY + (i - 1) * (ALT_BAR_BUTTON_SIZE + ALT_BAR_BUTTON_GAP))
        end
    else
        local width = (shown * ALT_BAR_BUTTON_SIZE) + (math.max(0, shown - 1) * ALT_BAR_BUTTON_GAP) + (DRAWER_BORDER * 2)
        bar:SetSize(width, DRAWER_THICKNESS)
        LayoutDrawerBackground(bar, shown, false)

        local startX = DRAWER_BORDER
        local y = -DRAWER_BORDER
        for i = 1, shown do
            local btn = bar.buttons[i]
            btn:ClearAllPoints()
            btn:SetPoint("TOPLEFT", bar, "TOPLEFT", startX + (i - 1) * (ALT_BAR_BUTTON_SIZE + ALT_BAR_BUTTON_GAP), y)
        end
    end

    bar.currentAnchorSide = anchorSide
    bar:Show()
    if animate == false then
        bar:SetScript("OnUpdate", nil)
        bar:SetAlpha(1)
        PositionDrawer(bar, slotFrame, anchorSide, 1)
    else
        AnimateDrawerOpen(bar, slotFrame, anchorSide)
    end

    StartDrawerHoverWatch()

    if UpdateFlyoutButtonsVisualState then
        UpdateFlyoutButtonsVisualState()
    end

end

local function GetGearFrameBySlotID(slotID)
    for _, frame in ipairs(GEAR_SLOT_FRAMES) do
        if frame and frame.GetID and frame:GetID() == slotID then
            return frame
        end
    end
    return nil
end

local function ShowFlyoutButtonForFrame(frame)
    if frame and frame.ExtraStatsFlyoutButton and not frame.ExtraStatsFlyoutButton:IsShown() then
        frame.ExtraStatsFlyoutButton:Show()
    end
end

local function ToggleAlternativesBar(slotFrame)
    if not slotFrame or not slotFrame.GetID then
        return
    end
    local slotID = slotFrame:GetID()
    if slotID and activeSlotID == slotID and AltBarFrame and AltBarFrame:IsShown() then
        HideAltBar()
        return
    end
    ShowAlternativesBar(slotFrame)
end

local function SetupFlyoutButton(frame)
    if not frame or frame.ExtraStatsFlyoutButton then
        return
    end

    local btn
    local templates = {
        "EquipmentFlyoutPopoutButtonTemplate",    -- retail/client-provided template (live FrameXML)
        "PaperDollFrameItemPopoutButtonTemplate", -- compatibility alias on older branches
        "PaperDollItemPopoutButtonTemplate",      -- compatibility alias on some branches
        "ExtraStatsPopoutButtonTemplate",         -- local fallback template
    }
    for _, templateName in ipairs(templates) do
        local ok, created = pcall(CreateFrame, "Button", nil, frame, templateName)
        if ok and created then
            btn = created
            break
        end
    end
    if not btn then
        return
    end

    btn:SetFrameLevel(frame:GetFrameLevel() + 4)
    btn:Hide()

    local side = SLOT_ANCHOR_SIDE[frame:GetID()] or "RIGHT"
    if side == "UP" then
        btn:SetSize(32, 16)
    end
    if side == "RIGHT" then
        btn:SetPoint("LEFT", frame, "RIGHT", 2, 0)
    elseif side == "LEFT" then
        btn:SetPoint("RIGHT", frame, "LEFT", -2, 0)
    else
        btn:SetPoint("BOTTOM", frame, "TOP", 0, 1)
    end
    frame.verticalFlyout = (side == "UP")

    btn:SetScript("OnClick", function()
        ToggleAlternativesBar(frame)
    end)
    btn:SetScript("OnEnter", function() end)
    btn:SetScript("OnLeave", function() ScheduleHideAltBar(0.22) end)

    frame.ExtraStatsFlyoutButton = btn
end

local function AnchorFlyoutButton(frame, isOpen)
    if not frame or not frame.ExtraStatsFlyoutButton then
        return
    end

    local btn = frame.ExtraStatsFlyoutButton
    local side = SLOT_ANCHOR_SIDE[frame:GetID()] or "RIGHT"
    if btn.ExtraStatsAnchorSide == side and btn.ExtraStatsAnchorOpen == isOpen then
        return
    end

    btn.ExtraStatsAnchorSide = side
    btn.ExtraStatsAnchorOpen = isOpen
    btn:ClearAllPoints()

    if side == "RIGHT" then
        btn:SetPoint("LEFT", frame, "RIGHT", 2, 0)
    elseif side == "LEFT" then
        btn:SetPoint("RIGHT", frame, "LEFT", -2, 0)
    else
        btn:SetPoint("BOTTOM", frame, "TOP", 0, 1)
    end
end

local function SetFlyoutButtonVisual(frame, isOpen)
    if not frame or not frame.ExtraStatsFlyoutButton then
        return
    end

    local btn = frame.ExtraStatsFlyoutButton
    local side = SLOT_ANCHOR_SIDE[frame:GetID()] or "RIGHT"
    if btn.ExtraStatsVisualSide == side and btn.ExtraStatsVisualOpen == isOpen then
        return
    end

    btn.ExtraStatsVisualSide = side
    btn.ExtraStatsVisualOpen = isOpen
    local reversedWhenClosed = (side == "LEFT" or side == "UP")
    local reversed = reversedWhenClosed
    if isOpen then
        reversed = not reversedWhenClosed
    end

    if EquipmentFlyoutPopoutButton_SetReversed then
        if side ~= "UP" then
            frame.verticalFlyout = false
            EquipmentFlyoutPopoutButton_SetReversed(btn, reversed)
            return
        end
    end

    local normal = btn:GetNormalTexture()
    local highlight = btn:GetHighlightTexture()
    if not normal or not highlight then
        return
    end

    if side == "UP" then
        if reversed then
            normal:SetTexCoord(0.15625, 0.84375, 0, 0.5)
            highlight:SetTexCoord(0.15625, 0.84375, 0.5, 1)
        else
            normal:SetTexCoord(0.15625, 0.84375, 0.5, 0)
            highlight:SetTexCoord(0.15625, 0.84375, 1, 0.5)
        end
    else
        if reversed then
            normal:SetTexCoord(0.15625, 0, 0.84375, 0, 0.15625, 0.5, 0.84375, 0.5)
            highlight:SetTexCoord(0.15625, 0.5, 0.84375, 0.5, 0.15625, 1, 0.84375, 1)
        else
            normal:SetTexCoord(0.15625, 0.5, 0.84375, 0.5, 0.15625, 0, 0.84375, 0)
            highlight:SetTexCoord(0.15625, 1, 0.84375, 1, 0.15625, 0.5, 0.84375, 0.5)
        end
    end
end

UpdateFlyoutButtonsVisualState = function()
    for _, frame in ipairs(GEAR_SLOT_FRAMES) do
        if frame and frame.ExtraStatsFlyoutButton and frame.ExtraStatsFlyoutButton:IsShown() then
            local isOpen = activeSlotID and frame.GetID and frame:GetID() == activeSlotID and AltBarFrame and AltBarFrame:IsShown()
            AnchorFlyoutButton(frame, isOpen and true or false)
            SetFlyoutButtonVisual(frame, isOpen and true or false)
        end
    end
end

local function UpdateFlyoutButtonsVisibility()
    for _, frame in ipairs(GEAR_SLOT_FRAMES) do
        if frame then
            SetupFlyoutButton(frame)
            local slotID = frame.GetID and frame:GetID()
            local hasDrawerActions = slotID and slotID > 0 and (#GetAlternativesForSlot(slotID) > 0 or GetInventoryItemLink("player", slotID) ~= nil)
            if hasDrawerActions then
                ShowFlyoutButtonForFrame(frame)
            elseif frame.ExtraStatsFlyoutButton then
                if frame.ExtraStatsFlyoutButton:IsShown() then
                    frame.ExtraStatsFlyoutButton:Hide()
                end
            end
        end
    end
    UpdateFlyoutButtonsVisualState()
end

local function ScheduleFlyoutButtonsRefresh(delay)
    flyoutRefreshRequestId = flyoutRefreshRequestId + 1
    local requestId = flyoutRefreshRequestId
    C_Timer.After(delay or 0.05, function()
        if requestId ~= flyoutRefreshRequestId then
            return
        end
        if not CharacterFrame or not CharacterFrame:IsShown() then
            return
        end
        if alternativesCacheDirty then
            RebuildAlternativesCache()
        end
        UpdateFlyoutButtonsVisibility()
        RefreshActiveDrawer()
    end)
end

RefreshActiveDrawer = function()
    if not activeSlotID then
        return
    end
    if not AltBarFrame or not AltBarFrame:IsShown() then
        return
    end

    local frame = GetGearFrameBySlotID(activeSlotID)
    if not frame then
        HideAltBar()
        return
    end

    ShowAlternativesBar(frame, false)
end

local function HookGearSlotAlternativesBar()
    for _, frame in ipairs(GEAR_SLOT_FRAMES) do
        if frame and not frame.ExtraStatsAltBarHooked then
            SetupFlyoutButton(frame)
            frame:HookScript("OnEnter", function() end)
            frame:HookScript("OnLeave", function() ScheduleHideAltBar(0.22) end)
            frame.ExtraStatsAltBarHooked = true
        end
    end
end

local function SetGearFrameQualityColor(gearFrame, r, g, b, a)
    if gearFrame.ExtraStatsQualityR == r and gearFrame.ExtraStatsQualityG == g and gearFrame.ExtraStatsQualityB == b and gearFrame.ExtraStatsQualityA == a then
        return
    end

    gearFrame.ExtraStatsQualityR = r
    gearFrame.ExtraStatsQualityG = g
    gearFrame.ExtraStatsQualityB = b
    gearFrame.ExtraStatsQualityA = a
    gearFrame.qualityTexture:SetVertexColor(r, g, b, a)
end

local function UpdateGearFrame(gearFrame)
    if not gearFrame or not gearFrame.qualityTexture then
        return
    end

    local itemLink = GetInventoryItemLink("player", gearFrame:GetID())
    if itemLink ~= nil then
        local _, itemInfo = GetItemInfo(itemLink)
        if itemInfo ~= nil then
            gearFrame.ExtraStatsPendingItemInfoRetry = nil
            local itemQuality = C_Item.GetItemQualityByID(itemInfo)
            local r, g, b, _ = GetItemQualityColor(itemQuality)
            SetGearFrameQualityColor(gearFrame, r, g, b, 0.75)
        elseif not gearFrame.ExtraStatsPendingItemInfoRetry then
            gearFrame.ExtraStatsPendingItemInfoRetry = true
            C_Timer.After(0.2, function()
                gearFrame.ExtraStatsPendingItemInfoRetry = nil
                UpdateGearFrame(gearFrame)
            end)
        end
    else
        gearFrame.ExtraStatsPendingItemInfoRetry = nil
        SetGearFrameQualityColor(gearFrame, 0, 0, 0, 0)
    end
end

local function UpdateGearFrames()
    for _, gearFrame in ipairs(GEAR_SLOT_FRAMES) do
        UpdateGearFrame(gearFrame, "player")
    end
end

local function ScheduleGearFramesRefresh(delay)
    gearFrameRefreshRequestId = gearFrameRefreshRequestId + 1
    local requestId = gearFrameRefreshRequestId
    C_Timer.After(delay or 0.05, function()
        if requestId ~= gearFrameRefreshRequestId then
            return
        end
        UpdateGearFrames()
    end)
end

local function SetupGearFrames()
    for _, frame in ipairs(GEAR_SLOT_FRAMES) do
        if not frame.qualityTexture then
            frame.qualityTexture = frame:CreateTexture(nil, "OVERLAY", nil)
            frame.qualityTexture:SetPoint("TOPLEFT", frame, "TOPLEFT", -2, 2)
            frame.qualityTexture:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", 2, -2)
            frame.qualityTexture:SetTexture(stats.iconPath .. "resources\\WhiteIconFrame.blp")
        end
    end

    UpdateGearFrames()
    HookGearSlotAlternativesBar()
    if CharacterFrame and CharacterFrame:IsShown() then
        UpdateFlyoutButtonsVisibility()
    end

    if CharacterFrame and not characterFrameRefreshHooked then
        CharacterFrame:HookScript("OnShow", function()
            ScheduleFlyoutButtonsRefresh(0)
        end)
        characterFrameRefreshHooked = true
    end
end

local Module = ExtraStats:NewModule("Gear")

function Module:EventHandler(event, ...)
    if event == "PLAYER_LOGIN" or event == "PLAYER_EQUIPMENT_CHANGED" then
        MarkAlternativesCacheDirty()
        local equipmentSet = ExtraStats:GetModule("EquipmentSet")
        if event == "PLAYER_EQUIPMENT_CHANGED" and equipmentSet and equipmentSet.IsEquipmentSwapActive and equipmentSet:IsEquipmentSwapActive() then
            ScheduleGearFramesRefresh(0.2)
            ScheduleFlyoutButtonsRefresh(0.2)
        else
            UpdateGearFrames()
            ScheduleFlyoutButtonsRefresh(0)
        end
    elseif event == "BAG_UPDATE_DELAYED" then
        MarkAlternativesCacheDirty()
        ScheduleFlyoutButtonsRefresh(0.25)
    elseif event ~= "MODIFIER_STATE_CHANGED" then
        UpdateFlyoutButtonsVisibility()
        RefreshActiveDrawer()
    end
    if event == "MODIFIER_STATE_CHANGED" then
        C_Timer.After(0, RefreshEquipmentSlotTooltipForModifiers)
    end
end

function Module:OnEnable()
    SetupGearFrames()
    self:RegisterEvent("PLAYER_LOGIN", "EventHandler")
    self:RegisterEvent("PLAYER_EQUIPMENT_CHANGED", "EventHandler")
    self:RegisterEvent("BAG_UPDATE_DELAYED", "EventHandler")
    self:RegisterEvent("MODIFIER_STATE_CHANGED", "EventHandler")
end

function Module:OnDisable()
    self:UnregisterEvent("PLAYER_LOGIN")
    self:UnregisterEvent("PLAYER_EQUIPMENT_CHANGED")
    self:UnregisterEvent("BAG_UPDATE_DELAYED")
    self:UnregisterEvent("MODIFIER_STATE_CHANGED")
    HideAltBar()
    for _, frame in ipairs(GEAR_SLOT_FRAMES) do
        if frame and frame.ExtraStatsFlyoutButton then
            frame.ExtraStatsFlyoutButton:Hide()
        end
    end
end
