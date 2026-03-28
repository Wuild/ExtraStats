local name = "ArkInventory"
local Plugin = {
    name = name
}

ExtraStats:RegisterPlugin(Plugin)

local runtime = {
    setupDone = false,
    eventFrame = nil,
}

local function GetEquipmentModule()
    return ExtraStats:GetModule("EquipmentSet")
end

local function ResolveSetID(equipment, idOrName)
    if type(idOrName) == "number" then
        return idOrName
    end

    if type(idOrName) == "string" then
        if idOrName == "" then
            return nil
        end
        return equipment:GetEquipmentSetID(idOrName)
    end

    return nil
end

local function CopyArray(values)
    local out = {}
    if not values then
        return out
    end
    for i = 1, #values do
        out[i] = values[i]
    end
    return out
end

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

local SLOT_IDS = {
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

local function GetContainerItemLinkCompat(bag, slot)
    if CONTAINER.GetContainerItemLink then
        return CONTAINER.GetContainerItemLink(bag, slot)
    end
    return GetContainerItemLink(bag, slot)
end

local function NormalizeItemLink(link)
    if not link then
        return nil
    end
    return string.match(link, "|H(item:[^|]+)|h") or string.match(link, "(item:[^|]+)") or link
end

local function GetEquippedItemID(slotID)
    local itemID = GetInventoryItemID("player", slotID)
    if itemID == 0 then
        return nil
    end
    return itemID
end

local function GetEquippedItemLink(slotID)
    return NormalizeItemLink(GetInventoryItemLink("player", slotID))
end

local function PackLocation(isPlayer, isBank, isBags, isVoidStorage, slot, bag, voidTab, voidSlot)
    if EquipmentManager_PackLocation then
        return EquipmentManager_PackLocation(isPlayer, isBank, isBags, isVoidStorage, slot or 0, bag or 0, voidTab or 0, voidSlot or 0)
    end
    return nil
end

local function FindBagLocation(itemID, itemLink)
    for bag = 0, NUM_BAG_SLOTS do
        local numSlots = GetContainerNumSlotsCompat(bag) or 0
        for slot = 1, numSlots do
            if itemLink then
                local link = NormalizeItemLink(GetContainerItemLinkCompat(bag, slot))
                if link and link == itemLink then
                    return bag, slot
                end
            end

            if itemID and GetContainerItemIDCompat(bag, slot) == itemID then
                return bag, slot
            end
        end
    end
    return nil, nil
end

local function FindEquippedLocation(itemID, itemLink)
    for _, slotID in ipairs(SLOT_IDS) do
        if itemLink and GetEquippedItemLink(slotID) == itemLink then
            return slotID
        end
        if itemID and GetEquippedItemID(slotID) == itemID then
            return slotID
        end
    end
    return nil
end

local function BuildItemIDTableBySlot(setID, equipment)
    local _, _, _, _, _, items = equipment:GetEquipmentSetInfo(setID)
    local bySlot = {}
    for slotID, slotName in pairs(SLOT_NAME_BY_ID) do
        bySlot[slotID] = items and items[slotName] or nil
    end
    return bySlot
end

local function BuildItemLocationsBySlot(setID, equipment)
    local set = equipment.db and equipment.db.char and equipment.db.char.sets and equipment.db.char.sets[setID]
    if not set then
        return nil
    end

    local items = {}
    local ignored = set.ignoredSlots or {}
    local itemIDs = set.items or {}
    local itemLinks = set.itemLinks or {}

    for slotID, slotName in pairs(SLOT_NAME_BY_ID) do
        if ignored[slotID] ~= true then
            local itemID = itemIDs[slotName]
            local itemLink = itemLinks[slotName]
            local location

            if itemLink and GetEquippedItemLink(slotID) == itemLink then
                location = PackLocation(true, false, false, false, slotID, 0, 0, 0)
            elseif itemID and GetEquippedItemID(slotID) == itemID then
                location = PackLocation(true, false, false, false, slotID, 0, 0, 0)
            else
                local equippedSlotID = FindEquippedLocation(itemID, itemLink)
                if equippedSlotID then
                    location = PackLocation(true, false, false, false, equippedSlotID, 0, 0, 0)
                else
                    local bag, bagSlot = FindBagLocation(itemID, itemLink)
                    if bag and bagSlot then
                        location = PackLocation(false, false, true, false, bagSlot, bag, 0, 0)
                    end
                end
            end

            if location then
                items[slotID] = location
            end
        end
    end

    return items
end

local function IsSetValid(setID, equipment)
    if type(setID) ~= "number" then
        return false
    end
    return equipment:GetEquipmentSetInfo(setID) ~= nil
end

local function SafeCall(tbl, key)
    if not tbl then
        return
    end
    local fn = tbl[key]
    if type(fn) == "function" then
        pcall(fn)
    end
end

local function RefreshArkInventoryOutfits()
    if not _G.ArkInventory then
        return
    end

    local outfit = _G.ArkInventory.Outfit
    SafeCall(outfit, "OnChanged")
    SafeCall(outfit, "Scan")
    SafeCall(outfit, "Rescan")
    SafeCall(outfit, "Build")
    SafeCall(_G.ArkInventory, "ScanLocation")
end

local function Debug(...)
    if ExtraStats and ExtraStats.debug then
        ExtraStats:debug("ArkInventory:", ...)
    end
end

local function InstallArkInventoryRulesHook()
    local ArkInventory = _G.ArkInventory
    if not ArkInventory then
        Debug("Install hook skipped: ArkInventory missing")
        return false
    end

    local ArkInventoryRules = _G.ArkInventoryRules
    if not ArkInventoryRules and LibStub then
        local AceAddon = LibStub("AceAddon-3.0", true)
        if AceAddon and AceAddon.GetAddon then
            ArkInventoryRules = AceAddon:GetAddon("ArkInventoryRules", true)
        end
    end

    if not ArkInventoryRules then
        Debug("Install hook skipped: ArkInventoryRules missing")
        return false
    end

    Debug("Installing HookExtraStats on ArkInventoryRules")
    ArkInventoryRules.HookExtraStats = function()
        if not (ExtraStats and ExtraStats.IsInitialized and ExtraStats:IsInitialized()) then
            Debug("HookExtraStats waiting: ExtraStats not initialized")
            C_Timer.After(3, ArkInventoryRules.HookExtraStats)
            return
        end

        if ArkInventoryRules._ExtraStatsHookInstalled then
            Debug("HookExtraStats already installed")
            return
        end

        local itemCacheClear = ArkInventoryRules.ItemCacheClear
        if type(itemCacheClear) ~= "function" then
            itemCacheClear = function()
                if ArkInventory.ItemCacheClear then
                    ArkInventory.ItemCacheClear()
                end
            end
        end

        ExtraStats:RegisterOutfitEvent("ADD_OUTFIT", itemCacheClear)
        ExtraStats:RegisterOutfitEvent("DELETE_OUTFIT", itemCacheClear)
        ExtraStats:RegisterOutfitEvent("EDIT_OUTFIT", itemCacheClear)
        ArkInventoryRules._ExtraStatsHookInstalled = true
        Debug("HookExtraStats registered outfit callbacks")

        if ArkInventory.db and ArkInventory.db.option and ArkInventory.db.option.message and ArkInventory.db.option.message.rules and ArkInventory.db.option.message.rules.hooked then
            ArkInventory.Output(string.format("%s: ExtraStats %s", ArkInventory.Localise["RULES"], ArkInventory.Localise["ENABLED"]))
        end

        if ArkInventory.ItemCacheClear then
            ArkInventory.ItemCacheClear()
        end
        if ArkInventory.Frame_Main_Generate and ArkInventory.Const and ArkInventory.Const.Window and ArkInventory.Const.Window.Draw then
            ArkInventory.Frame_Main_Generate(nil, ArkInventory.Const.Window.Draw.Recalculate)
        end
        Debug("HookExtraStats refresh triggered")
    end

    ArkInventoryRules.HookExtraStats()
    Debug("HookExtraStats invoked")
    return true
end

local function InstallOutfitterShimForArkInventory()
    local ArkInventory = _G.ArkInventory
    if not ArkInventory then
        Debug("Outfitter shim skipped: ArkInventory missing")
        return false
    end

    -- Do not interfere with real Outfitter.
    if _G.Outfitter and _G.Outfitter ~= ExtraStats and _G.Outfitter ~= true then
        Debug("Outfitter shim skipped: real Outfitter present")
        return false
    end

    if not _G.Outfitter or _G.Outfitter == true then
        _G.Outfitter = {}
    end

    _G.Outfitter.IsInitialized = function()
        return ExtraStats and ExtraStats.IsInitialized and ExtraStats:IsInitialized()
    end
    _G.Outfitter.RegisterOutfitEvent = function(_, eventName, callback)
        if ExtraStats and ExtraStats.RegisterOutfitEvent then
            ExtraStats:RegisterOutfitEvent(eventName, callback)
        end
    end
    _G.Outfitter.GetBagItemInfo = function(_, bag, slot)
        if ExtraStats and ExtraStats.GetBagItemInfo then
            return ExtraStats:GetBagItemInfo(bag, slot)
        end
        return nil
    end
    _G.Outfitter.GetItemInfoFromLink = function(_, link)
        if ExtraStats and ExtraStats.GetItemInfoFromLink then
            return ExtraStats:GetItemInfoFromLink(link)
        end
        return nil
    end
    _G.Outfitter.GetOutfitsUsingItem = function(_, itemInfo)
        if ExtraStats and ExtraStats.GetOutfitsUsingItem then
            local names = ExtraStats:GetOutfitsUsingItem(itemInfo) or {}
            local outfits = {}
            for i = 1, #names do
                outfits[i] = { Name = names[i] }
            end
            return outfits
        end
        return {}
    end

    local cc = ArkInventory.CrossClient
    if cc and type(cc.IsAddOnLoaded) == "function" and not cc._ExtraStatsOutfitterShim then
        local original = cc.IsAddOnLoaded
        cc.IsAddOnLoaded = function(addonName, ...)
            if addonName == "Outfitter" then
                local loaded = original(addonName, ...)
                if loaded then
                    return loaded
                end
                return _G.Outfitter ~= nil
            end
            return original(addonName, ...)
        end
        cc._ExtraStatsOutfitterShim = true
        Debug("Installed CrossClient Outfitter addon-loaded shim")
    end

    Debug("Installed Outfitter compatibility shim")
    return true
end

local outfitListeners = {}

local function RegisterOutfitListener(eventName, callback)
    if type(eventName) ~= "string" or type(callback) ~= "function" then
        return
    end
    outfitListeners[eventName] = outfitListeners[eventName] or {}
    local listeners = outfitListeners[eventName]
    for i = 1, #listeners do
        if listeners[i] == callback then
            return
        end
    end
    table.insert(listeners, callback)
    Debug("Registered outfit listener for", eventName)
end

local function FireOutfitEvent(eventName)
    local listeners = outfitListeners[eventName]
    if not listeners then
        Debug("No listeners for outfit event", eventName)
        return
    end
    Debug("Firing outfit event", eventName, "listeners=", #listeners)
    for i = 1, #listeners do
        pcall(listeners[i])
    end
end

local function BuildItemInfoFromLink(link)
    local itemLink = NormalizeItemLink(link)
    if not itemLink then
        return nil
    end

    local itemID = tonumber(string.match(itemLink, "item:(%d+)"))
    return {
        itemLink = itemLink,
        itemID = itemID,
        Code = itemID,
        Link = itemLink,
    }
end

local function SetContainsItem(set, itemInfo)
    if not set or not itemInfo then
        return false
    end

    local itemID = itemInfo.itemID
    local itemLink = itemInfo.itemLink
    local items = set.items or {}
    local links = set.itemLinks or {}

    for _, slotName in pairs(SLOT_NAME_BY_ID) do
        if itemLink and links[slotName] and links[slotName] == itemLink then
            return true
        end
        if itemID and items[slotName] and items[slotName] == itemID then
            return true
        end
    end

    return false
end

-- Outfitter-style compatibility for ArkInventory custom hook support.
-- These must exist at file load time (not only during Plugin:Setup),
-- because some ArkInventory paths call them during their own initialize step.
ExtraStats.IsInitialized = function()
    return true
end

-- Some downstream copies call the misspelled version; provide an alias.
ExtraStats.IsInitilized = ExtraStats.IsInitialized

ExtraStats.RegisterOutfitEvent = function(_, eventName, callback)
    RegisterOutfitListener(eventName, callback)
end

ExtraStats.GetBagItemInfo = function(_, bag, slot)
    local link = GetContainerItemLinkCompat(bag, slot)
    return BuildItemInfoFromLink(link)
end

ExtraStats.GetItemInfoFromLink = function(_, link)
    return BuildItemInfoFromLink(link)
end

ExtraStats.GetOutfitsUsingItem = function(_, itemInfo)
    local result = {}
    local equipment = GetEquipmentModule()
    if not equipment then
        return result
    end

    local sets = equipment.db and equipment.db.char and equipment.db.char.sets or {}
    for i = 1, #sets do
        local set = sets[i]
        if set and set.name and SetContainsItem(set, itemInfo) then
            table.insert(result, set.name)
        end
    end
    return result
end

function Plugin:Setup()
    if runtime.setupDone then
        Debug("Setup skipped: already initialized")
        return
    end

    if ExtraStats.db.char.disabledPlugins[name] == true then
        Debug("Plugin disabled in settings")
        return
    end

    local equipment = GetEquipmentModule()
    if not equipment then
        Debug("Setup aborted: EquipmentSet module missing")
        return
    end
    Debug("Setup start")
    InstallOutfitterShimForArkInventory()
    InstallArkInventoryRulesHook()

    _G.GetNumEquipmentSets = function()
        return equipment:GetNumEquipmentSets()
    end

    _G.CanUseEquipmentSets = function()
        return true
    end

    _G.GetEquipmentSetIDs = function()
        return CopyArray(equipment:GetEquipmentSetIDs())
    end

    _G.GetEquipmentSetInfo = function(setID)
        return equipment:GetEquipmentSetInfo(setID)
    end

    _G.GetEquipmentSetInfoByName = function(setName)
        return equipment:GetEquipmentSetInfoByName(setName)
    end

    _G.GetEquipmentSetID = function(setName)
        return equipment:GetEquipmentSetID(setName)
    end

    _G.GetEquipmentSetItemIDs = function(setID)
        if not IsSetValid(setID, equipment) then
            return nil
        end
        return BuildItemIDTableBySlot(setID, equipment)
    end

    _G.GetEquipmentSetIgnoreSlots = function(setID)
        if not IsSetValid(setID, equipment) then
            return {}
        end
        return equipment:GetIgnoredSlots(setID)
    end

    _G.GetEquipmentSetLocations = function(setID)
        if not IsSetValid(setID, equipment) then
            return nil
        end
        return BuildItemLocationsBySlot(setID, equipment)
    end

    _G.CreateEquipmentSet = function(setName, icon)
        if type(setName) ~= "string" or setName == "" then
            return nil
        end
        local setID = equipment:CreateEquipmentSet(setName)
        equipment:SaveEquipmentSet(setID, icon)
        return setID
    end

    _G.UseEquipmentSet = function(idOrName)
        local setID = ResolveSetID(equipment, idOrName)
        if not setID then
            return false
        end
        return equipment:UseEquipmentSet(setID)
    end

    _G.SaveEquipmentSet = function(idOrName, icon)
        local setID = ResolveSetID(equipment, idOrName)
        if not setID then
            if type(idOrName) ~= "string" or idOrName == "" then
                return nil
            end
            setID = equipment:CreateEquipmentSet(idOrName)
        end

        equipment:SaveEquipmentSet(setID, icon)
        return setID
    end

    _G.DeleteEquipmentSet = function(idOrName)
        local setID = ResolveSetID(equipment, idOrName)
        if not setID then
            return false
        end

        equipment:DeleteEquipmentSet(setID)
        return true
    end

    _G.ModifyEquipmentSet = function(setID, setName, icon)
        if type(setID) ~= "number" then
            return false
        end
        equipment:ModifyEquipmentSet(setID, setName, icon)
        return true
    end

    _G.C_EquipmentSet = _G.C_EquipmentSet or {}

    _G.C_EquipmentSet.CanUseEquipmentSets = _G.CanUseEquipmentSets
    _G.C_EquipmentSet.GetNumEquipmentSets = _G.GetNumEquipmentSets
    _G.C_EquipmentSet.GetEquipmentSetIDs = _G.GetEquipmentSetIDs
    _G.C_EquipmentSet.GetEquipmentSetInfo = _G.GetEquipmentSetInfo
    _G.C_EquipmentSet.GetEquipmentSetID = _G.GetEquipmentSetID
    _G.C_EquipmentSet.GetItemIDs = _G.GetEquipmentSetItemIDs
    _G.C_EquipmentSet.GetItemLocations = _G.GetEquipmentSetLocations
    _G.C_EquipmentSet.CreateEquipmentSet = _G.CreateEquipmentSet
    _G.C_EquipmentSet.UseEquipmentSet = _G.UseEquipmentSet
    _G.C_EquipmentSet.SaveEquipmentSet = _G.SaveEquipmentSet
    _G.C_EquipmentSet.DeleteEquipmentSet = _G.DeleteEquipmentSet
    _G.C_EquipmentSet.ModifyEquipmentSet = _G.ModifyEquipmentSet
    _G.C_EquipmentSet.GetIgnoredSlots = function(setID)
        return equipment:GetIgnoredSlots(setID)
    end
    _G.C_EquipmentSet.ClearIgnoredSlotsForSave = function()
        equipment:ClearIgnoredSlotsForSave()
    end
    _G.C_EquipmentSet.IgnoreSlotForSave = function(slotID)
        equipment:IgnoreSlotForSave(slotID)
    end

    _G.EquipmentManagerClearIgnoredSlotsForSave = _G.C_EquipmentSet.ClearIgnoredSlotsForSave
    _G.EquipmentManagerIgnoreSlotForSave = _G.C_EquipmentSet.IgnoreSlotForSave
    _G.EquipmentManagerIsSlotIgnoredForSave = function(slotID)
        local ignored = equipment:GetIgnoredSlots()
        return ignored and ignored[slotID] == true
    end
    _G.EquipmentManagerUnignoreSlotForSave = function(slotID)
        local ignored = equipment:GetIgnoredSlots()
        if ignored then
            ignored[slotID] = nil
        end
    end

    runtime.eventFrame = runtime.eventFrame or CreateFrame("Frame")
    local frame = runtime.eventFrame
    frame:UnregisterAllEvents()
    frame:RegisterEvent("ADDON_LOADED")
    frame:RegisterEvent("PLAYER_LOGIN")
    frame:RegisterEvent("EQUIPMENT_SETS_CHANGED")
    frame:SetScript("OnEvent", function(_, event, addonName)
        if event == "ADDON_LOADED" then
            Debug("Event", event, addonName or "")
            if addonName == "ArkInventory" or addonName == "ArkInventoryRules" or addonName == "ExtraStats" then
                InstallOutfitterShimForArkInventory()
                InstallArkInventoryRulesHook()
            end
            return
        end
        Debug("Event", event)
        InstallOutfitterShimForArkInventory()
        InstallArkInventoryRulesHook()
        RefreshArkInventoryOutfits()
    end)

    ExtraStats:On("gear.update", function()
        Debug("Event gear.update")
        FireOutfitEvent("EDIT_OUTFIT")
        FireOutfitEvent("ADD_OUTFIT")
        FireOutfitEvent("DELETE_OUTFIT")
        InstallOutfitterShimForArkInventory()
        InstallArkInventoryRulesHook()
        RefreshArkInventoryOutfits()
    end)

    Debug("Scheduling delayed hook installs")
    C_Timer.After(1, InstallOutfitterShimForArkInventory)
    C_Timer.After(5, InstallOutfitterShimForArkInventory)
    C_Timer.After(1, InstallArkInventoryRulesHook)
    C_Timer.After(5, InstallArkInventoryRulesHook)

    runtime.setupDone = true
end
