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

local function UpdateGearFrame (gearFrame)
    gearFrame.qualityTexture:SetVertexColor(0, 0, 0, 0)

    local itemLink = GetInventoryItemLink("player", gearFrame:GetID())
    if itemLink ~= nil then
        local _, itemInfo = GetItemInfo(itemLink)
        if itemInfo ~= nil then
            local itemQuality = C_Item.GetItemQualityByID(itemInfo)
            local r, g, b, _ = GetItemQualityColor(itemQuality)
            gearFrame.qualityTexture:SetVertexColor(r, g, b, 0.75)
        end
    else
        C_Timer.After(0.2, function()
            UpdateGearFrame(gearFrame)
        end)
    end
end

local function UpdateGearFrames()
    for _, gearFrame in ipairs(GEAR_SLOT_FRAMES) do
        UpdateGearFrame(gearFrame, "player")
    end
end

local function SetupGearFrames()
    for _, frame in ipairs(GEAR_SLOT_FRAMES) do
        frame.qualityTexture = frame:CreateTexture(nil, "OVERLAY", nil)
        frame.qualityTexture:SetPoint("TOPLEFT", frame, "TOPLEFT", -2, 2)
        frame.qualityTexture:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", 2, -2)
        frame.qualityTexture:SetTexture(stats.iconPath .. "resources\\WhiteIconFrame.blp")
    end

    UpdateGearFrames()
end

local Module = ExtraStats:NewModule("Gear")

function Module:EventHandler(event)
    UpdateGearFrames()
end

function Module:OnEnable()
    SetupGearFrames()
    self:RegisterEvent("PLAYER_LOGIN", "EventHandler")
    self:RegisterEvent("PLAYER_EQUIPMENT_CHANGED", "EventHandler")
    self:RegisterEvent("MODIFIER_STATE_CHANGED", "EventHandler")
end

function Module:OnDisable()
    self:UnregisterEvent("PLAYER_LOGIN")
    self:UnregisterEvent("PLAYER_EQUIPMENT_CHANGED")
    self:UnregisterEvent("MODIFIER_STATE_CHANGED")
end