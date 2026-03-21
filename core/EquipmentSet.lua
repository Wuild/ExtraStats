local equipment = ExtraStats:NewModule("EquipmentSet")

local SLOT_NAME_BY_ID = {
    [INVSLOT_HEAD] = "HeadSlot",
    [INVSLOT_NECK] = "NeckSlot",
    [INVSLOT_SHOULDER] = "ShoulderSlot",
    [INVSLOT_BACK] = "BackSlot",
    [INVSLOT_CHEST] = "ChestSlot",
    [INVSLOT_BODY] = "ShirtSlot",
    [INVSLOT_TABARD] = "TabardSlot",
    [INVSLOT_WRIST] = "WristSlot",
    [INVSLOT_HAND] = "HandsSlot",
    [INVSLOT_WAIST] = "WaistSlot",
    [INVSLOT_LEGS] = "LegsSlot",
    [INVSLOT_FEET] = "FeetSlot",
    [INVSLOT_FINGER1] = "Finger0Slot",
    [INVSLOT_FINGER2] = "Finger1Slot",
    [INVSLOT_TRINKET1] = "Trinket0Slot",
    [INVSLOT_TRINKET2] = "Trinket1Slot",
    [INVSLOT_MAINHAND] = "MainHandSlot",
    [INVSLOT_OFFHAND] = "SecondaryHandSlot",
    [INVSLOT_RANGED] = "RangedSlot",
    [INVSLOT_AMMO] = "AmmoSlot",
}

local SLOT_ORDER = {
    INVSLOT_HEAD,
    INVSLOT_NECK,
    INVSLOT_SHOULDER,
    INVSLOT_BACK,
    INVSLOT_CHEST,
    INVSLOT_BODY,
    INVSLOT_TABARD,
    INVSLOT_WRIST,
    INVSLOT_HAND,
    INVSLOT_WAIST,
    INVSLOT_LEGS,
    INVSLOT_FEET,
    INVSLOT_FINGER1,
    INVSLOT_FINGER2,
    INVSLOT_TRINKET1,
    INVSLOT_TRINKET2,
    INVSLOT_MAINHAND,
    INVSLOT_OFFHAND,
    INVSLOT_RANGED,
    INVSLOT_AMMO,
}

local CONTAINER = C_Container or {}

local function GetContainerNumSlotsCompat(bag)
    if CONTAINER.GetContainerNumSlots then
        return CONTAINER.GetContainerNumSlots(bag)
    end
    return GetContainerNumSlots(bag)
end

local function GetContainerItemIDCompat(bag, slot)
    if CONTAINER.GetContainerItemID then
        return CONTAINER.GetContainerItemID(bag, slot)
    end
    return GetContainerItemID(bag, slot)
end

local function GetContainerItemInfoCompat(bag, slot)
    if CONTAINER.GetContainerItemInfo then
        return CONTAINER.GetContainerItemInfo(bag, slot)
    end

    local _, _, locked = GetContainerItemInfo(bag, slot)
    return { isLocked = locked }
end

local function PickupContainerItemCompat(bag, slot)
    if CONTAINER.PickupContainerItem then
        return CONTAINER.PickupContainerItem(bag, slot)
    end
    return PickupContainerItem(bag, slot)
end

local function ContainerIDToInventoryIDCompat(bag)
    if CONTAINER.ContainerIDToInventoryID then
        return CONTAINER.ContainerIDToInventoryID(bag)
    end
    return ContainerIDToInventoryID(bag)
end

local function GetEquippedItemID(slotID)
    local itemID = GetInventoryItemID("player", slotID)
    if itemID == 0 then
        return nil
    end
    return itemID
end

local function NormalizeItemLink(link)
    if not link then
        return nil
    end
    return string.match(link, "|H(item:[^|]+)|h") or string.match(link, "(item:[^|]+)") or link
end

local function GetEquippedItemLink(slotID)
    return NormalizeItemLink(GetInventoryItemLink("player", slotID))
end

local function GetContainerItemLinkCompat(bag, slot)
    if CONTAINER.GetContainerItemLink then
        return CONTAINER.GetContainerItemLink(bag, slot)
    end
    return GetContainerItemLink(bag, slot)
end

local function BuildSlotInfo()
    local info = {}
    for _, slotID in ipairs(SLOT_ORDER) do
        table.insert(info, {
            id = slotID,
            name = SLOT_NAME_BY_ID[slotID],
        })
    end
    return info
end

local function IsSlotIgnored(set, slotID)
    if not set or not set.ignoredSlots then
        return false
    end
    return set.ignoredSlots[slotID] == true
end

local function FindItemInBags(itemID)
    if not itemID then
        return nil, nil
    end

    for bag = 0, NUM_BAG_SLOTS do
        local numSlots = GetContainerNumSlotsCompat(bag) or 0
        for slot = 1, numSlots do
            if GetContainerItemIDCompat(bag, slot) == itemID then
                return bag, slot
            end
        end
    end

    return nil, nil
end

local function FindItemInBagsByLink(itemLink)
    if not itemLink then
        return nil, nil
    end

    for bag = 0, NUM_BAG_SLOTS do
        local numSlots = GetContainerNumSlotsCompat(bag) or 0
        for slot = 1, numSlots do
            local link = NormalizeItemLink(GetContainerItemLinkCompat(bag, slot))
            if link and link == itemLink then
                return bag, slot
            end
        end
    end

    return nil, nil
end

local function IsSlotSetMatched(set, slotID)
    if IsSlotIgnored(set, slotID) then
        return true
    end
    local slotName = SLOT_NAME_BY_ID[slotID]
    local desiredLink = set.itemLinks and set.itemLinks[slotName]
    if desiredLink then
        return GetEquippedItemLink(slotID) == desiredLink
    end
    return GetEquippedItemID(slotID) == set.items[slotName]
end

local function IsSetFullyEquipped(set)
    for _, slotID in ipairs(SLOT_ORDER) do
        if not IsSlotSetMatched(set, slotID) then
            return false
        end
    end
    return true
end

local function FindEquippedSlotWithItem(set, itemID, itemLink, excludedSlotID)
    if not itemID and not itemLink then
        return nil
    end

    for _, slotID in ipairs(SLOT_ORDER) do
        if slotID ~= excludedSlotID and not IsSlotSetMatched(set, slotID) then
            if itemLink and GetEquippedItemLink(slotID) == itemLink then
                return slotID
            end
            if itemID and GetEquippedItemID(slotID) == itemID then
                return slotID
            end
        end
    end

    return nil
end

local function PutCursorItemIntoBags()
    if not CursorHasItem() then
        return true
    end

    PutItemInBackpack()
    if not CursorHasItem() then
        return true
    end

    for bag = 1, NUM_BAG_SLOTS do
        local invBagSlot = ContainerIDToInventoryIDCompat(bag)
        if invBagSlot then
            PutItemInBag(invBagSlot)
            if not CursorHasItem() then
                return true
            end
        end
    end

    return false
end

local function CountAvailableItemIDs()
    local counts = {}

    for _, slotID in ipairs(SLOT_ORDER) do
        local id = GetEquippedItemID(slotID)
        if id then
            counts[id] = (counts[id] or 0) + 1
        end
    end

    for bag = 0, NUM_BAG_SLOTS do
        local numSlots = GetContainerNumSlotsCompat(bag) or 0
        for slot = 1, numSlots do
            local id = GetContainerItemIDCompat(bag, slot)
            if id then
                counts[id] = (counts[id] or 0) + 1
            end
        end
    end

    return counts
end

local function CountRequiredItemIDs(set)
    local counts = {}

    for _, slotID in ipairs(SLOT_ORDER) do
        if not IsSlotIgnored(set, slotID) then
            local key = SLOT_NAME_BY_ID[slotID]
            local itemID = set.items[key]
            if itemID then
                counts[itemID] = (counts[itemID] or 0) + 1
            end
        end
    end

    return counts
end

local function GetMissingItemCountForSet(set)
    local required = CountRequiredItemIDs(set)
    local available = CountAvailableItemIDs()
    local missing = 0

    for itemID, needed in pairs(required) do
        local have = available[itemID] or 0
        if have < needed then
            missing = missing + (needed - have)
        end
    end

    return missing
end

local pendingEquip

local function FinishEquip(success, errorMessage)
    if errorMessage then
        UIErrorsFrame:AddMessage(errorMessage, 1.0, 0.1, 0.1, 1.0)
    end

    local setID = pendingEquip and pendingEquip.setID
    pendingEquip = nil

    ExtraStats:SendMessage("EQUIPMENT_SWAP_FINISHED", success == true, setID)
    ExtraStats:Trigger("gear.swap.finished", success == true, setID)
    ExtraStats:Trigger("gear.update")
end

local function TryEquipSingleSlot(set, slotID)
    local slotName = SLOT_NAME_BY_ID[slotID]
    local desiredItemID = set.items[slotName]
    local desiredItemLink = set.itemLinks and set.itemLinks[slotName]
    local equippedItemID = GetEquippedItemID(slotID)
    local equippedItemLink = GetEquippedItemLink(slotID)

    if desiredItemLink then
        if desiredItemLink == equippedItemLink then
            return false, false
        end
    elseif desiredItemID == equippedItemID then
        return false, false
    end

    if desiredItemID == nil and desiredItemLink == nil then
        if equippedItemID == nil then
            return false, false
        end

        PickupInventoryItem(slotID)
        if not CursorHasItem() then
            return false, true
        end

        if not PutCursorItemIntoBags() then
            return false, false, ERR_EQUIPMENT_MANAGER_BAGS_FULL
        end

        return true, false
    end

    local bag, bagSlot = FindItemInBagsByLink(desiredItemLink)
    if (not bag or not bagSlot) and desiredItemID then
        bag, bagSlot = FindItemInBags(desiredItemID)
    end
    if bag and bagSlot then
        local info = GetContainerItemInfoCompat(bag, bagSlot)
        if info and info.isLocked then
            return false, true
        end

        PickupContainerItemCompat(bag, bagSlot)
        EquipCursorItem(slotID)
        if CursorHasItem() then
            ClearCursor()
        end
        return true, false
    end

    local equippedSourceSlot = FindEquippedSlotWithItem(set, desiredItemID, desiredItemLink, slotID)
    if equippedSourceSlot then
        PickupInventoryItem(equippedSourceSlot)
        EquipCursorItem(slotID)
        if CursorHasItem() then
            ClearCursor()
        end
        return true, false
    end

    return false, false
end

local function ProcessEquip()
    if not pendingEquip then
        return
    end

    local set = equipment.db.char.sets[pendingEquip.setID]
    if not set then
        FinishEquip(false)
        return
    end

    if InCombatLockdown() then
        FinishEquip(false, ERR_CLIENT_LOCKED_OUT)
        return
    end

    pendingEquip.attempt = pendingEquip.attempt + 1

    local didAction = false
    local blockedByLock = false

    for _, slotID in ipairs(SLOT_ORDER) do
        if not IsSlotIgnored(set, slotID) then
            local changed, blocked, err = TryEquipSingleSlot(set, slotID)
            if err then
                FinishEquip(false, err)
                return
            end

            if blocked then
                blockedByLock = true
            end

            if changed then
                didAction = true
                break
            end
        end
    end

    if not didAction and not blockedByLock then
        if IsSetFullyEquipped(set) then
            FinishEquip(true)
        else
            FinishEquip(false, ERR_EQUIPMENT_MANAGER_MISSING_ITEMS or ERR_EQUIPMENT_MANAGER_BAGS_FULL)
        end
        return
    end

    if pendingEquip.attempt >= pendingEquip.maxAttempts then
        FinishEquip(false)
        return
    end

    C_Timer.After(0.05, ProcessEquip)
end

function equipment:OnInitialize()
    equipment.db = ExtraStats.db:RegisterNamespace("equipments", {
        char = {
            sets = {},
        },
    })

    self:ClearIgnoredSlotsForSave()
end

function equipment:CreateEquipmentSet(name)
    local set = {
        name = name,
        icon = nil,
        items = {},
        ignoredSlots = {},
    }
    table.insert(self.db.char.sets, set)
    return #self.db.char.sets
end

function equipment:GetEquipmentSetID(name)
    if not name then
        return nil
    end

    for index, set in ipairs(self.db.char.sets) do
        if set.name == name then
            return index
        end
    end

    return nil
end

function equipment:GetEquipmentSetInfo(id)
    local set = self.db.char.sets[id]
    if not set then
        return nil
    end

    local isEquipped = IsSetFullyEquipped(set)

    local missing = GetMissingItemCountForSet(set)

    return set.name, set.icon, id, isEquipped, missing, set.items
end

function equipment:DeleteEquipmentSet(setId)
    table.remove(self.db.char.sets, setId)
    ExtraStats:Trigger("gear.update")
end

function equipment:SaveEquipmentSet(setId, icon)
    local set = self.db.char.sets[setId]
    if not set then
        return
    end

    set.items = set.items or {}
    set.itemLinks = set.itemLinks or {}
    set.ignoredSlots = set.ignoredSlots or {}

    if icon then
        set.icon = icon
    end

    for _, slotID in ipairs(SLOT_ORDER) do
        local key = SLOT_NAME_BY_ID[slotID]
        if self.ignoredSlotsForSave[slotID] then
            set.ignoredSlots[slotID] = true
            set.items[key] = nil
            set.itemLinks[key] = nil
        else
            set.ignoredSlots[slotID] = nil
            set.items[key] = GetEquippedItemID(slotID)
            set.itemLinks[key] = GetEquippedItemLink(slotID)
        end
    end

    ExtraStats:Trigger("gear.update")
end

function equipment:SlotInfo()
    return BuildSlotInfo()
end

function equipment:ModifyEquipmentSet(setId, name, icon)
    local set = self.db.char.sets[setId]
    if not set then
        return
    end

    if name and name ~= "" then
        set.name = name
    end

    if icon then
        set.icon = icon
    end

    ExtraStats:Trigger("gear.update")
end

function equipment:GetEquipmentSetIDs()
    local ids = {}
    for i = 1, #self.db.char.sets do
        ids[#ids + 1] = i
    end
    return ids
end

function equipment:ClearIgnoredSlotsForSave()
    self.ignoredSlotsForSave = {}
end

function equipment:GetIgnoredSlots(setID)
    if not setID then
        return self.ignoredSlotsForSave or {}
    end

    local set = self.db.char.sets[setID]
    if not set then
        return {}
    end

    set.ignoredSlots = set.ignoredSlots or {}
    return set.ignoredSlots
end

function equipment:IgnoreSlotForSave(slot)
    self.ignoredSlotsForSave = self.ignoredSlotsForSave or {}
    self.ignoredSlotsForSave[slot] = true
end

function equipment:FindItemInBags(itemID)
    local bag, slot = FindItemInBags(itemID)
    return itemID, bag, slot
end

function equipment:UseEquipmentSet(id)
    local set = self.db.char.sets[id]
    if not set then
        return false
    end

    if InCombatLockdown() then
        UIErrorsFrame:AddMessage(ERR_CLIENT_LOCKED_OUT, 1.0, 0.1, 0.1, 1.0)
        return false
    end

    local missing = GetMissingItemCountForSet(set)
    if missing > 0 then
        UIErrorsFrame:AddMessage(ERR_EQUIPMENT_MANAGER_MISSING_ITEMS or "Missing items for equipment set.", 1.0, 0.1, 0.1, 1.0)
        ExtraStats:SendMessage("EQUIPMENT_SWAP_FINISHED", false, id)
        ExtraStats:Trigger("gear.swap.finished", false, id)
        return false
    end

    pendingEquip = {
        setID = id,
        attempt = 0,
        maxAttempts = 120,
    }

    ProcessEquip()
    return true
end

function equipment:GetNumEquipmentSets()
    return #self.db.char.sets
end

function equipment:GetEquipmentSetInfoByName(arg)
    if type(arg) == "string" then
        if arg == "" then
            return nil
        end
        local setID = self:GetEquipmentSetID(arg)
        if not setID then
            return nil
        end
        return self:GetEquipmentSetInfo(setID)
    end

    return self:GetEquipmentSetInfo(arg)
end
