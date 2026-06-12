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

local SLOT_LABEL_BY_ID = {
    [INVSLOT_HEAD] = HEADSLOT or "Head",
    [INVSLOT_NECK] = NECKSLOT or "Neck",
    [INVSLOT_SHOULDER] = SHOULDERSLOT or "Shoulder",
    [INVSLOT_BACK] = BACKSLOT or "Back",
    [INVSLOT_CHEST] = CHESTSLOT or "Chest",
    [INVSLOT_BODY] = SHIRTSLOT or "Shirt",
    [INVSLOT_TABARD] = TABARDSLOT or "Tabard",
    [INVSLOT_WRIST] = WRISTSLOT or "Wrist",
    [INVSLOT_HAND] = HANDSSLOT or "Hands",
    [INVSLOT_WAIST] = WAISTSLOT or "Waist",
    [INVSLOT_LEGS] = LEGSSLOT or "Legs",
    [INVSLOT_FEET] = FEETSLOT or "Feet",
    [INVSLOT_FINGER1] = FINGER0SLOT or "Finger 1",
    [INVSLOT_FINGER2] = FINGER1SLOT or "Finger 2",
    [INVSLOT_TRINKET1] = TRINKET0SLOT or "Trinket 1",
    [INVSLOT_TRINKET2] = TRINKET1SLOT or "Trinket 2",
    [INVSLOT_MAINHAND] = MAINHANDSLOT or "Main Hand",
    [INVSLOT_OFFHAND] = SECONDARYHANDSLOT or "Off Hand",
    [INVSLOT_RANGED] = RANGEDSLOT or "Ranged",
    [INVSLOT_AMMO] = AMMOSLOT or "Ammo",
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

local function IsNormalBag(bag)
    if bag == 0 then
        return true
    end

    local invBagSlot = ContainerIDToInventoryIDCompat(bag)
    if not invBagSlot then
        return false
    end

    local bagLink = GetInventoryItemLink("player", invBagSlot)
    if not bagLink then
        return false
    end

    local itemFamily = GetItemFamily and GetItemFamily(bagLink)
    return itemFamily == 0
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

local function FindDesiredItemInBags(set, slotID)
    local slotName = SLOT_NAME_BY_ID[slotID]
    local desiredItemID = set.items[slotName]
    local desiredItemLink = set.itemLinks and set.itemLinks[slotName]

    local bag, bagSlot = FindItemInBagsByLink(desiredItemLink)
    if (not bag or not bagSlot) and desiredItemID then
        bag, bagSlot = FindItemInBags(desiredItemID)
    end

    return bag, bagSlot
end

local function GetNextEquipSlot(set)
    local fallbackSlotID = nil
    local bagSlotID = nil
    local emptySlotID = nil

    for _, slotID in ipairs(SLOT_ORDER) do
        if not IsSlotIgnored(set, slotID) and not IsSlotSetMatched(set, slotID) then
            local slotName = SLOT_NAME_BY_ID[slotID]
            local desiredItemID = set.items[slotName]
            local desiredItemLink = set.itemLinks and set.itemLinks[slotName]

            fallbackSlotID = fallbackSlotID or slotID

            if desiredItemID == nil and desiredItemLink == nil then
                emptySlotID = emptySlotID or slotID
            elseif FindEquippedSlotWithItem(set, desiredItemID, desiredItemLink, slotID) then
                return slotID
            elseif not bagSlotID and FindDesiredItemInBags(set, slotID) then
                bagSlotID = slotID
            end
        end
    end

    return bagSlotID or emptySlotID or fallbackSlotID
end

local function PutCursorItemIntoBags()
    if not CursorHasItem() then
        return true
    end

    for bag = NUM_BAG_SLOTS, 0, -1 do
        if IsNormalBag(bag) then
            local numSlots = GetContainerNumSlotsCompat(bag) or 0
            for slot = 1, numSlots do
                local info = GetContainerItemInfoCompat(bag, slot)
                if not GetContainerItemIDCompat(bag, slot) and not (info and info.isLocked) then
                    PickupContainerItemCompat(bag, slot)
                    if not CursorHasItem() then
                        return true
                    end
                end
            end
        end
    end

    return false
end

local function FindFreeBagSlot()
    for bag = NUM_BAG_SLOTS, 0, -1 do
        if IsNormalBag(bag) then
            local numSlots = GetContainerNumSlotsCompat(bag) or 0
            for slot = 1, numSlots do
                local info = GetContainerItemInfoCompat(bag, slot)
                if not GetContainerItemIDCompat(bag, slot) and not (info and info.isLocked) then
                    return bag, slot
                end
            end
        end
    end
end

local function IsTwoHandedWeapon(itemID, itemLink)
    local item = itemLink or itemID
    if GetItemInfoInstant then
        local _, _, _, equipLoc = GetItemInfoInstant(item)
        if equipLoc then
            return equipLoc == "INVTYPE_2HWEAPON"
        end
    end
    local _, _, _, _, _, _, _, _, equipLoc = GetItemInfo(item)
    return equipLoc == "INVTYPE_2HWEAPON"
end

local function ClearOffhandForTwoHander(set)
    local offhandSlotName = SLOT_NAME_BY_ID[INVSLOT_OFFHAND]
    if set.items[offhandSlotName] or (set.itemLinks and set.itemLinks[offhandSlotName]) then
        return true, false, nil, false
    end

    if not GetEquippedItemID(INVSLOT_OFFHAND) then
        return true, false, nil, false
    end

    local bag, slot = FindFreeBagSlot()
    if not bag then
        return false, false, ERR_EQUIPMENT_MANAGER_BAGS_FULL
    end

    PickupInventoryItem(INVSLOT_OFFHAND)
    if not CursorHasItem() then
        return false, true
    end

    PickupContainerItemCompat(bag, slot)
    if CursorHasItem() then
        return false, true
    end

    return true, false, nil, true
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

local function GetItemDisplayName(itemID, itemLink)
    local name = GetItemInfo(itemLink or itemID)
    if name then
        return name
    end
    if itemID then
        return tostring(itemID)
    end
    return UNKNOWN or "Unknown"
end

local function GetMissingItemsForSet(set)
    local available = CountAvailableItemIDs()
    local missing = {}

    for _, slotID in ipairs(SLOT_ORDER) do
        if not IsSlotIgnored(set, slotID) then
            local key = SLOT_NAME_BY_ID[slotID]
            local itemID = set.items[key]
            if itemID then
                local have = available[itemID] or 0
                if have > 0 then
                    available[itemID] = have - 1
                else
                    table.insert(missing, {
                        slotID = slotID,
                        slotName = key,
                        slotLabel = SLOT_LABEL_BY_ID[slotID] or key,
                        itemID = itemID,
                        itemLink = set.itemLinks and set.itemLinks[key],
                        itemName = GetItemDisplayName(itemID, set.itemLinks and set.itemLinks[key]),
                    })
                end
            end
        end
    end

    return missing
end

local pendingEquip
local equipToken = 0
local EQUIP_ACTION_DELAY = 0.15
local EQUIP_LOCK_RETRY_DELAY = 0.07
local ProcessEquip
local pendingSpecEquipToken = 0
local lastAutoEquippedSpecGroup

local SPEC_ICON_TEXTURES_BY_CLASS = {
    [INDEX_CLASS_WARRIOR] = {
        [1] = "Interface\\Icons\\Ability_Warrior_SavageBlow",
        [2] = "Interface\\Icons\\Ability_Warrior_InnerRage",
        [3] = "Interface\\Icons\\Ability_Warrior_DefensiveStance",
    },
    [INDEX_CLASS_PALADIN] = {
        [1] = "Interface\\Icons\\Spell_Holy_HolyBolt",
        [2] = "Interface\\Icons\\ability_paladin_shieldofthetemplar",
        [3] = "Interface\\Icons\\Spell_Holy_AuraOfLight",
    },
    [INDEX_CLASS_HUNTER] = {
        [1] = "Interface\\Icons\\Ability_Hunter_BestialDiscipline",
        [2] = "Interface\\Icons\\Ability_Marksmanship",
        [3] = "Interface\\Icons\\Ability_Hunter_ExplosiveShot",
    },
    [INDEX_CLASS_ROGUE] = {
        [1] = "Interface\\Icons\\Ability_Rogue_Deadliness",
        [2] = "Interface\\Icons\\Ability_Rogue_MurderSpree",
        [3] = "Interface\\Icons\\Ability_Rogue_ShadowDance",
    },
    [INDEX_CLASS_PRIEST] = {
        [1] = "Interface\\Icons\\Spell_Holy_Penance",
        [2] = "Interface\\Icons\\Spell_Holy_GuardianSpirit",
        [3] = "Interface\\Icons\\Spell_Shadow_Dispersion",
    },
    [INDEX_CLASS_DEATH_KNIGHT] = {
        [1] = "Interface\\Icons\\Spell_Deathknight_BloodPresence",
        [2] = "Interface\\Icons\\Spell_Deathknight_FrostPresence",
        [3] = "Interface\\Icons\\Spell_Deathknight_UnholyPresence",
    },
    [INDEX_CLASS_SHAMAN] = {
        [1] = "Interface\\Icons\\Spell_Shaman_ThunderStorm",
        [2] = "Interface\\Icons\\Spell_Shaman_FeralSpirit",
        [3] = "Interface\\Icons\\Spell_Nature_Riptide",
    },
    [INDEX_CLASS_MAGE] = {
        [1] = "Interface\\Icons\\Spell_Arcane_ArcanePotency",
        [2] = "Interface\\Icons\\Ability_Mage_LivingBomb",
        [3] = "Interface\\Icons\\Spell_Frost_ChillingArmor",
    },
    [INDEX_CLASS_WARLOCK] = {
        [1] = "Interface\\Icons\\Ability_Warlock_Haunt",
        [2] = "Interface\\Icons\\Spell_Shadow_DemonForm",
        [3] = "Interface\\Icons\\Ability_Warlock_ChaosBolt",
    },
    [INDEX_CLASS_DRUID] = {
        [1] = "Interface\\Icons\\Spell_Nature_StarFall",
        [2] = "Interface\\Icons\\Ability_Druid_CatForm",
        [3] = "Interface\\Icons\\Spell_Nature_HealingTouch",
    },
}

local SPEC_ICON_TEXTURES_BY_NAME = {
    Arms = "Interface\\Icons\\Ability_Warrior_SavageBlow",
    Fury = "Interface\\Icons\\Ability_Warrior_InnerRage",
    Protection = "Interface\\Icons\\Ability_Warrior_DefensiveStance",
    Holy = "Interface\\Icons\\Spell_Holy_HolyBolt",
    Retribution = "Interface\\Icons\\Spell_Holy_AuraOfLight",
    ["Beast Mastery"] = "Interface\\Icons\\Ability_Hunter_BestialDiscipline",
    Marksmanship = "Interface\\Icons\\Ability_Marksmanship",
    Survival = "Interface\\Icons\\Ability_Hunter_ExplosiveShot",
    Assassination = "Interface\\Icons\\Ability_Rogue_Deadliness",
    Combat = "Interface\\Icons\\Ability_Rogue_MurderSpree",
    Subtlety = "Interface\\Icons\\Ability_Rogue_ShadowDance",
    Discipline = "Interface\\Icons\\Spell_Holy_Penance",
    Shadow = "Interface\\Icons\\Spell_Shadow_Dispersion",
    Blood = "Interface\\Icons\\Spell_Deathknight_BloodPresence",
    Frost = "Interface\\Icons\\Spell_Deathknight_FrostPresence",
    Unholy = "Interface\\Icons\\Spell_Deathknight_UnholyPresence",
    Elemental = "Interface\\Icons\\Spell_Shaman_ThunderStorm",
    Enhancement = "Interface\\Icons\\Spell_Shaman_FeralSpirit",
    Restoration = "Interface\\Icons\\Spell_Nature_HealingTouch",
    Arcane = "Interface\\Icons\\Spell_Arcane_ArcanePotency",
    Fire = "Interface\\Icons\\Ability_Mage_LivingBomb",
    Affliction = "Interface\\Icons\\Ability_Warlock_Haunt",
    Demonology = "Interface\\Icons\\Spell_Shadow_DemonForm",
    Destruction = "Interface\\Icons\\Ability_Warlock_ChaosBolt",
    Balance = "Interface\\Icons\\Spell_Nature_StarFall",
    Feral = "Interface\\Icons\\Ability_Druid_CatForm",
    ["Feral Combat"] = "Interface\\Icons\\Ability_Druid_CatForm",
}

local function IsInventorySlotLocked(slotID)
    if IsInventoryItemLocked then
        return IsInventoryItemLocked(slotID) == true
    end
    return false
end

local function HasPendingItemLocks()
    for _, slotID in ipairs(SLOT_ORDER) do
        if IsInventorySlotLocked(slotID) then
            return true
        end
    end

    for bag = 0, NUM_BAG_SLOTS do
        local numSlots = GetContainerNumSlotsCompat(bag) or 0
        for slot = 1, numSlots do
            local info = GetContainerItemInfoCompat(bag, slot)
            if info and info.isLocked then
                return true
            end
        end
    end

    return false
end

local function PutCursorItemIntoPreferredSlot(bag, slot)
    if not CursorHasItem() or bag == nil or slot == nil then
        return not CursorHasItem()
    end

    local info = GetContainerItemInfoCompat(bag, slot)
    if info and info.isLocked then
        return false
    end

    if GetContainerItemIDCompat(bag, slot) then
        return false
    end

    PickupContainerItemCompat(bag, slot)
    return not CursorHasItem()
end

local function PutCursorItemAway(preferredBag, preferredSlot)
    if not CursorHasItem() then
        return true, false
    end

    local hasPreferredSlot = preferredBag ~= nil and preferredSlot ~= nil
    if PutCursorItemIntoPreferredSlot(preferredBag, preferredSlot) then
        return true, false
    end

    if PutCursorItemIntoBags() then
        return true, false
    end

    if hasPreferredSlot then
        return false, true
    end

    return false, HasPendingItemLocks()
end

local function GetActiveSpecGroup()
    if GetActiveTalentGroup then
        local ok, group = pcall(GetActiveTalentGroup)
        if ok and type(group) == "number" and group > 0 then
            return group
        end
    end

    return 1
end

local function GetNumSpecGroups()
    if GetNumTalentGroups then
        local ok, numGroups = pcall(GetNumTalentGroups)
        if ok and type(numGroups) == "number" and numGroups > 0 then
            return numGroups
        end
    end

    if MAX_TALENT_GROUPS and MAX_TALENT_GROUPS > 0 then
        return MAX_TALENT_GROUPS
    end

    return GetActiveTalentGroup and 2 or 1
end

local function GetTalentTabInfoForGroup(tabIndex, group)
    local ok, a, b, c, d, e

    if group and GetActiveTalentGroup then
        ok, a, b, c, d, e = pcall(GetTalentTabInfo, tabIndex, false, false, group)
    end

    if not ok then
        ok, a, b, c, d, e = pcall(GetTalentTabInfo, tabIndex)
    end

    if not ok then
        return nil, nil, nil
    end

    local name
    if type(b) == "string" and b ~= "" then
        name = b
    elseif type(a) == "string" and a ~= "" then
        name = a
    end

    local icon
    if type(b) == "string" and (type(a) == "number" or type(a) == "string") then
        icon = a
    elseif type(d) == "number" or type(d) == "string" then
        icon = d
    elseif type(c) == "number" or type(c) == "string" then
        icon = c
    end

    local points = tonumber(e) or tonumber(c)
    if type(b) ~= "string" then
        points = tonumber(c) or points
    end

    return name, icon, points
end

local function GetFallbackSpecIcon(specName, primaryTab)
    local classIndex = CURRENT_CLASS or (ExtraStats and ExtraStats.GetCurrentClass and ExtraStats:GetCurrentClass())
    local classIcons = classIndex and SPEC_ICON_TEXTURES_BY_CLASS[classIndex]

    if classIcons and primaryTab and classIcons[primaryTab] then
        return classIcons[primaryTab]
    end

    if specName and SPEC_ICON_TEXTURES_BY_NAME[specName] then
        return SPEC_ICON_TEXTURES_BY_NAME[specName]
    end

    local role = classIndex and CLASS_TALENTS_ROLE[classIndex] and CLASS_TALENTS_ROLE[classIndex][primaryTab]

    if role == CLASS_ROLE_TANK then
        return "Interface\\Icons\\Ability_Warrior_DefensiveStance"
    elseif role == CLASS_ROLE_HEALER then
        return "Interface\\Icons\\Spell_Holy_Heal"
    end

    return "Interface\\Icons\\Ability_Rogue_Eviscerate"
end

local function GetPrimaryTalentTreeForGroup(group)
    if TalentFrame_UpdateSpecInfoCache then
        local cache = {}
        local ok = pcall(TalentFrame_UpdateSpecInfoCache, cache, false, false, group)
        if ok and cache.primaryTabIndex then
            return cache.primaryTabIndex
        end
    end

    local numTabs = GetNumTalentTabs and GetNumTalentTabs() or 0
    local bestTab = nil
    local bestPoints = -1

    for tabIndex = 1, numTabs do
        local _, _, points = GetTalentTabInfoForGroup(tabIndex, group)
        points = tonumber(points) or 0
        if points > bestPoints then
            bestPoints = points
            bestTab = tabIndex
        end
    end

    if bestPoints <= 0 then
        return nil
    end

    return bestTab
end

local function ScheduleProcessEquip(token, delay)
    if not pendingEquip or pendingEquip.token ~= token then
        return
    end

    if pendingEquip.scheduled then
        return
    end

    pendingEquip.scheduled = true
    C_Timer.After(delay or EQUIP_ACTION_DELAY, function()
        if not pendingEquip or pendingEquip.token ~= token then
            return
        end

        pendingEquip.scheduled = false
        ProcessEquip(token)
    end)
end

local function FinishEquip(success, errorMessage, token)
    if token and (not pendingEquip or pendingEquip.token ~= token) then
        return
    end

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
    if SpellIsTargeting and SpellIsTargeting() then
        return false, true
    end

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

        local stored, blocked = PutCursorItemAway()
        if not stored then
            if blocked then
                return false, true
            end
            return false, false, ERR_EQUIPMENT_MANAGER_BAGS_FULL
        end

        return true, false
    end

    if slotID == INVSLOT_MAINHAND and IsTwoHandedWeapon(desiredItemID, desiredItemLink) then
        local cleared, blocked, err, changed = ClearOffhandForTwoHander(set)
        if err then
            return false, false, err
        end
        if not cleared then
            return false, blocked == true
        end
        if changed then
            return true, false
        end
    end

    local bag, bagSlot = FindDesiredItemInBags(set, slotID)
    if bag and bagSlot then
        local info = GetContainerItemInfoCompat(bag, bagSlot)
        if info and info.isLocked then
            return false, true
        end

        PickupContainerItemCompat(bag, bagSlot)
        PickupInventoryItem(slotID)
        if CursorHasItem() then
            local stored, blocked = PutCursorItemAway(bag, bagSlot)
            if not stored then
                if blocked then
                    pendingEquip.cursorPreferredBag = bag
                    pendingEquip.cursorPreferredSlot = bagSlot
                    return true, true
                end
                return false, false, ERR_EQUIPMENT_MANAGER_BAGS_FULL
            end
        end
        if pendingEquip then
            pendingEquip.cursorPreferredBag = nil
            pendingEquip.cursorPreferredSlot = nil
        end
        return true, false
    end

    local equippedSourceSlot = FindEquippedSlotWithItem(set, desiredItemID, desiredItemLink, slotID)
    if equippedSourceSlot then
        PickupInventoryItem(equippedSourceSlot)
        PickupInventoryItem(slotID)
        if CursorHasItem() then
            PickupInventoryItem(equippedSourceSlot)
        end
        if CursorHasItem() then
            local stored, blocked = PutCursorItemAway()
            if not stored then
                if blocked then
                    return true, true
                end
                return false, false, ERR_EQUIPMENT_MANAGER_BAGS_FULL
            end
        end
        return true, false
    end

    return false, false
end

function ProcessEquip(token)
    if not pendingEquip or pendingEquip.token ~= token then
        return
    end

    local set = equipment.db.char.sets[pendingEquip.setID]
    if not set then
        FinishEquip(false, nil, token)
        return
    end

    if InCombatLockdown() then
        FinishEquip(false, ERR_CLIENT_LOCKED_OUT, token)
        return
    end

    if SpellIsTargeting and SpellIsTargeting() then
        ScheduleProcessEquip(token, EQUIP_LOCK_RETRY_DELAY)
        return
    end

    if CursorHasItem() then
        if HasPendingItemLocks() then
            ScheduleProcessEquip(token, EQUIP_LOCK_RETRY_DELAY)
            return
        end

        local stored, blocked = PutCursorItemAway(pendingEquip.cursorPreferredBag, pendingEquip.cursorPreferredSlot)
        if not stored then
            if blocked then
                ScheduleProcessEquip(token, EQUIP_LOCK_RETRY_DELAY)
                return
            end
            FinishEquip(false, ERR_EQUIPMENT_MANAGER_BAGS_FULL, token)
            return
        end
        pendingEquip.cursorPreferredBag = nil
        pendingEquip.cursorPreferredSlot = nil

        ScheduleProcessEquip(token, EQUIP_ACTION_DELAY)
        return
    end

    if HasPendingItemLocks() then
        pendingEquip.attempt = pendingEquip.attempt + 1
        if pendingEquip.attempt >= pendingEquip.maxAttempts then
            FinishEquip(false, nil, token)
            return
        end

        ScheduleProcessEquip(token, EQUIP_LOCK_RETRY_DELAY)
        return
    end

    pendingEquip.attempt = pendingEquip.attempt + 1

    local blockedByLock = false
    local slotID = GetNextEquipSlot(set)

    if slotID then
        local changed, blocked, err = TryEquipSingleSlot(set, slotID)
        if err then
            FinishEquip(false, err, token)
            return
        end

        if blocked then
            blockedByLock = true
        end

        if changed then
            ScheduleProcessEquip(token, EQUIP_ACTION_DELAY)
            return
        end
    end

    if not blockedByLock then
        if IsSetFullyEquipped(set) then
            FinishEquip(true, nil, token)
        else
            FinishEquip(false, ERR_EQUIPMENT_MANAGER_MISSING_ITEMS or ERR_EQUIPMENT_MANAGER_BAGS_FULL, token)
        end
        return
    end

    if pendingEquip.attempt >= pendingEquip.maxAttempts then
        FinishEquip(false, nil, token)
        return
    end

    ScheduleProcessEquip(token, EQUIP_LOCK_RETRY_DELAY)
end

function equipment:OnInitialize()
    equipment.db = ExtraStats.db:RegisterNamespace("equipments", {
        char = {
            sets = {},
        },
    })

    self:ClearIgnoredSlotsForSave()
end

function equipment:OnEnable()
    self:RegisterEvent("BAG_UPDATE_DELAYED", "EventHandler")
    self:RegisterEvent("ITEM_LOCK_CHANGED", "EventHandler")
    self:RegisterEvent("PLAYER_EQUIPMENT_CHANGED", "EventHandler")
    self:RegisterEvent("ACTIVE_TALENT_GROUP_CHANGED", "EventHandler")
end

function equipment:OnDisable()
    self:UnregisterEvent("BAG_UPDATE_DELAYED")
    self:UnregisterEvent("ITEM_LOCK_CHANGED")
    self:UnregisterEvent("PLAYER_EQUIPMENT_CHANGED")
    self:UnregisterEvent("ACTIVE_TALENT_GROUP_CHANGED")
end

function equipment:EventHandler(event)
    if pendingEquip then
        ScheduleProcessEquip(pendingEquip.token, EQUIP_LOCK_RETRY_DELAY)
    end

    if event == "ACTIVE_TALENT_GROUP_CHANGED" then
        self:EquipSetForActiveSpec()
    end
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

function equipment:GetMissingEquipmentSetItems(id)
    local set = self.db.char.sets[id]
    if not set then
        return {}
    end

    return GetMissingItemsForSet(set)
end

function equipment:DeleteEquipmentSet(setId)
    table.remove(self.db.char.sets, setId)

    if ExtraStats.db and ExtraStats.db.char and ExtraStats.db.char.sets then
        local assignedSpecs = ExtraStats.db.char.sets
        local shiftedSpecs = {}

        for assignedSetID, specGroup in pairs(assignedSpecs) do
            local numericSetID = tonumber(assignedSetID)
            if numericSetID and numericSetID < setId then
                shiftedSpecs[numericSetID] = specGroup
            elseif numericSetID and numericSetID > setId then
                shiftedSpecs[numericSetID - 1] = specGroup
            end
        end

        ExtraStats.db.char.sets = shiftedSpecs
    end

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

    if pendingEquip then
        return false
    end

    if InCombatLockdown() then
        UIErrorsFrame:AddMessage(ERR_CLIENT_LOCKED_OUT, 1.0, 0.1, 0.1, 1.0)
        return false
    end

    if SpellIsTargeting and SpellIsTargeting() then
        return false
    end

    if CursorHasItem() then
        local stored = PutCursorItemAway()
        if not stored then
            UIErrorsFrame:AddMessage(ERR_EQUIPMENT_MANAGER_BAGS_FULL or "Inventory is full.", 1.0, 0.1, 0.1, 1.0)
            return false
        end
    end

    equipToken = equipToken + 1
    pendingEquip = {
        setID = id,
        token = equipToken,
        attempt = 0,
        maxAttempts = 120,
        scheduled = false,
    }

    ExtraStats:Trigger("gear.update")
    ProcessEquip(equipToken)
    return true
end

function equipment:IsEquipmentSwapActive()
    return pendingEquip ~= nil
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

function equipment:GetSpecGroupCount()
    return GetNumSpecGroups()
end

function equipment:GetSpecGroupInfo(group)
    local primaryTab = GetPrimaryTalentTreeForGroup(group)
    local name, icon

    if primaryTab then
        name, icon = GetTalentTabInfoForGroup(primaryTab, group)
    end

    local specName = name
    icon = GetFallbackSpecIcon(specName, primaryTab) or icon

    if name and name ~= "" then
        name = string.format("Spec %d: %s", group, name)
    else
        name = string.format("Spec %d", group)
    end

    return name, icon, primaryTab, specName
end

function equipment:AssignSpecToEquipmentSet(setID, specGroup)
    if not self.db.char.sets[setID] then
        return
    end

    ExtraStats.db.char.sets = ExtraStats.db.char.sets or {}

    for assignedSetID, assignedSpecGroup in pairs(ExtraStats.db.char.sets) do
        if assignedSetID ~= setID and assignedSpecGroup == specGroup then
            ExtraStats.db.char.sets[assignedSetID] = nil
        end
    end

    ExtraStats.db.char.sets[setID] = specGroup
    ExtraStats:Trigger("gear.update")
end

function equipment:GetEquipmentSetAssignedSpec(setID)
    ExtraStats.db.char.sets = ExtraStats.db.char.sets or {}
    return ExtraStats.db.char.sets[setID]
end

function equipment:UnassignSpecFromEquipmentSet(setID)
    ExtraStats.db.char.sets = ExtraStats.db.char.sets or {}
    ExtraStats.db.char.sets[setID] = nil
    ExtraStats:Trigger("gear.update")
end

function equipment:GetEquipmentSetForSpec(specGroup)
    ExtraStats.db.char.sets = ExtraStats.db.char.sets or {}

    for setID, assignedSpecGroup in pairs(ExtraStats.db.char.sets) do
        if assignedSpecGroup == specGroup and self.db.char.sets[setID] then
            return setID
        end
    end

    return nil
end

function equipment:EquipSetForActiveSpec()
    pendingSpecEquipToken = pendingSpecEquipToken + 1
    local token = pendingSpecEquipToken

    C_Timer.After(0.5, function()
        if token ~= pendingSpecEquipToken then
            return
        end

        if InCombatLockdown() then
            return
        end

        local specGroup = GetActiveSpecGroup()
        if specGroup == lastAutoEquippedSpecGroup then
            return
        end

        local setID = self:GetEquipmentSetForSpec(specGroup)
        if not setID then
            lastAutoEquippedSpecGroup = specGroup
            return
        end

        local _, _, _, isEquipped = self:GetEquipmentSetInfo(setID)
        if isEquipped then
            lastAutoEquippedSpecGroup = specGroup
            return
        end

        lastAutoEquippedSpecGroup = specGroup
        self:UseEquipmentSet(setID)
    end)
end
