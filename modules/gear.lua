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

function Module:Update()
    UpdateGearFrames()
end

function Module:Setup()
    SetupGearFrames()
end

do
    table.insert(ExtraStats.modules, Module)
end