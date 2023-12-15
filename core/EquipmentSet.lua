local equipment = ExtraStats:NewModule("EquipmentSet")

EQUIPMENTMANAGER_INVENTORYSLOTS = {};
EQUIPMENTMANAGER_BAGSLOTS = {};

local _isAtBank = false;
local SLOT_LOCKED = -1;
local SLOT_EMPTY = -2;

local EQUIP_ITEM = 1;
local UNEQUIP_ITEM = 2;
local SWAP_ITEM = 3;

local NUM_TOTAL_EQUIPPED_BAG_SLOTS = NUM_TOTAL_EQUIPPED_BAG_SLOTS or NUM_BAG_SLOTS

for i = BANK_CONTAINER, NUM_TOTAL_EQUIPPED_BAG_SLOTS do
    EQUIPMENTMANAGER_BAGSLOTS[i] = {};
end

local slotInfo = {
    [1] = { name = "HeadSlot", tooltip = HEADSLOT, id = INVSLOT_HEAD },
    [2] = { name = "NeckSlot", tooltip = NECKSLOT, id = INVSLOT_NECK },
    [3] = { name = "ShoulderSlot", tooltip = SHOULDERSLOT, id = INVSLOT_SHOULDER },
    [4] = { name = "BackSlot", tooltip = BACKSLOT, id = INVSLOT_BACK },
    [5] = { name = "ChestSlot", tooltip = CHESTSLOT, id = INVSLOT_CHEST },
    [6] = { name = "ShirtSlot", tooltip = SHIRTSLOT, id = INVSLOT_BODY },
    [7] = { name = "TabardSlot", tooltip = TABARDSLOT, id = INVSLOT_TABARD },
    [8] = { name = "WristSlot", tooltip = WRISTSLOT, id = INVSLOT_WRIST },
    [9] = { name = "HandsSlot", tooltip = HANDSSLOT, id = INVSLOT_HAND },
    [10] = { name = "WaistSlot", tooltip = WAISTSLOT, id = INVSLOT_WAIST },
    [11] = { name = "LegsSlot", tooltip = LEGSSLOT, id = INVSLOT_LEGS },
    [12] = { name = "FeetSlot", tooltip = FEETSLOT, id = INVSLOT_FEET },
    [13] = { name = "Finger0Slot", tooltip = FINGER0SLOT, id = INVSLOT_FINGER1 },
    [14] = { name = "Finger1Slot", tooltip = FINGER1SLOT, id = INVSLOT_FINGER2 },
    [15] = { name = "Trinket0Slot", tooltip = TRINKET0SLOT, id = INVSLOT_TRINKET1 },
    [16] = { name = "Trinket1Slot", tooltip = TRINKET1SLOT, id = INVSLOT_TRINKET2 },
    [17] = { name = "MainHandSlot", tooltip = MAINHANDSLOT, id = INVSLOT_MAINHAND },
    [18] = { name = "SecondaryHandSlot", tooltip = SECONDARYHANDSLOT, id = INVSLOT_OFFHAND },
    [19] = { name = "RangedSlot", tooltip = RANGEDSLOT, id = INVSLOT_RANGED },
    [20] = { name = "AmmoSlot", tooltip = AMMOSLOT, id = INVSLOT_AMMO },
}

function equipment:OnInitialize()
    equipment.db = ExtraStats.db:RegisterNamespace("equipments", {
        char = {
            sets = {}
        }
    })

    for index, set in pairs(equipment.db.char.sets) do
        if set.name == "TEMP_SET" then
            table.remove(equipment.db.char.sets, index)
        end
    end
end

function equipment:CreateEquipmentSet(name)
    local set = {
        name = name,
        icon = nil,
        items = {}
    }

    table.insert(equipment.db.char.sets, set)
end

function equipment:GetEquipmentSetID(name)
    for index, set in pairs(equipment.db.char.sets) do
        if set.name == name then
            return index
        end
    end
    return nil;
end


--- name, icon, id, isEquipped, numlost, items

function equipment:GetEquipmentSetInfo(id)
    local set = equipment.db.char.sets[id];

    local isSetEquipped = true;

    local missingItems = 0;

    for key, slot in pairs(slotInfo) do
        local item = GetInventoryItemID("player", slot.id);

        local isEquipped = item == set.items[slot.name];

        if item == 0 then
            item = nil
        end

        if item ~= set.items[slot.name] then
            isSetEquipped = false
        end

        if set.items[slot.name] then
            if not isEquipped then
                local itemID, x, y = equipment:FindItemInBags(set.items[slot.name]);
                if x == nil and y == nil then
                    missingItems = missingItems + 1;
                end
            end
        end
    end

    return set.name, set.icon, id, isSetEquipped, missingItems, {}
end

function equipment:DeleteEquipmentSet(setId)
    table.remove(equipment.db.char.sets, setId);
end

function equipment:SaveEquipmentSet(setId, icon)
    local set = equipment.db.char.sets[setId]
    if set then
        if icon then
            set.icon = icon;
        end
        for key, slot in pairs(slotInfo) do
            set.items[slot.name] = nil
            local item = GetInventoryItemID("player", slot.id);

            if item == 0 then
                set.items[slot.name] = nil
            elseif item then
                set.items[slot.name] = item
            end
        end
    end
end

function equipment:SlotInfo()
    local slots = slotInfo;
    table.sort(slots, function(a, b)
        return a.id > b.id
    end);
    return slots;
end

function equipment:ModifyEquipmentSet(setId, name, icon)
    local set = equipment.db.char.sets[setId]
    if set then
        if name then
            set.name = name;
        end
        if icon then
            set.icon = icon;
        end
    end
end

function equipment:GetEquipmentSetIDs()
    local ids = {};

    for index, set in pairs(equipment.db.char.sets) do
        table.insert(ids, index)
    end

    return ids
end

function equipment:ClearIgnoredSlotsForSave()

end

function equipment:GetIgnoredSlots()

end

function equipment:IgnoreSlotForSave()

end

function equipment:FindEmptySlotIntBags()
    for i = 0, NUM_BAG_SLOTS do
        for z = 1, C_Container.GetContainerNumSlots(i) do
            if not C_Container.GetContainerItemID(i, z) then
                return i, z
            end
        end
    end
end

function equipment:FindItemInBags(itemID)
    for i = 0, NUM_BAG_SLOTS do
        for z = 1, C_Container.GetContainerNumSlots(i) do
            if C_Container.GetContainerItemID(i, z) == itemID then
                return itemID, i, z
            end
        end
    end
    return nil, nil
end

function equipment:UpdateFreeBagSpace ()
    local bagSlots = EQUIPMENTMANAGER_BAGSLOTS;

    for i = BANK_CONTAINER, NUM_TOTAL_EQUIPPED_BAG_SLOTS + GetNumBankSlots() do
        local _, bagType = C_Container.GetContainerNumFreeSlots(i);
        local freeSlots = C_Container.GetContainerFreeSlots(i);
        if (freeSlots) then
            if (not bagSlots[i]) then
                bagSlots[i] = {};
            end

            -- Reset all EMPTY bag slots
            for index, flag in next, bagSlots[i] do
                if (flag == SLOT_EMPTY) then
                    bagSlots[i][index] = nil;
                end
            end

            for index, slot in ipairs(freeSlots) do
                if (bagSlots[i] and not bagSlots[i][slot] and bagType == 0) then
                    -- Don't overwrite locked slots, don't reset empty slots to empty, only use normal bags
                    bagSlots[i][slot] = SLOT_EMPTY;
                end
            end
        else
            bagSlots[i] = nil;
        end
    end
end

local selectedSet, gearThread;

local frame = CreateFrame("Frame", nil)
frame:SetScript("OnUpdate", function()
    if gearThread then
        coroutine.resume(gearThread)
    end
end)

local InventorySlots = {--    Comment or remove whichever slots you don't want to process, these enums exist in all clients
    INVSLOT_AMMO;
    INVSLOT_HEAD;
    INVSLOT_NECK;
    INVSLOT_SHOULDER;
    INVSLOT_BODY;
    INVSLOT_CHEST;
    INVSLOT_WAIST;
    INVSLOT_LEGS;
    INVSLOT_FEET;
    INVSLOT_WRIST;
    INVSLOT_HAND;
    INVSLOT_FINGER1;
    INVSLOT_FINGER2;
    INVSLOT_TRINKET1;
    INVSLOT_TRINKET2;
    INVSLOT_BACK;
    INVSLOT_MAINHAND;
    INVSLOT_OFFHAND;
    INVSLOT_RANGED;
    INVSLOT_TABARD;
};

local function UnequipAll()
    if #InventorySlots <= 0 then
        return ;
    end--    Sanity check
    local slotindex = 1;

    ClearCursor();--    Make sure the cursor isn't holding anything, otherwise we might accidentally issue an item swap instead of an unequip
    for bag = NUM_BAG_SLOTS or NUM_TOTAL_EQUIPPED_BAG_SLOTS, 0, -1 do
        -- CE and Wrath use NUM_BAG_SLOTS, DF uses NUM_TOTAL_EQUIPPED_BAG_SLOTS
        local free, type = (C_Container or _G).GetContainerNumFreeSlots(bag);--    C_Container is used in Wrath and DF, CE still has this in _G
        free = (type == 0 and free or 0);-- Uses a quirk with this style of condition, only process bags with no item type restriction with fallback to zero if no bag is there (if free is nil, it'll fallback to zero even if the condition is true)

        for _ = 1, free do
            --   Variable is unused, we just need to loop for every free slot we see
            local invslot = InventorySlots[slotindex];--  Cache slot mapped to current index
            while not GetInventoryItemID("player", invslot) do
                -- Loop if no item in slot and until we find one
                if slotindex < #InventorySlots then
                    slotindex = slotindex + 1;
                else
                    return ;
                end-- Increment to next index or stop when we have no more inventory slots to process
                invslot = InventorySlots[slotindex];--    Update to new slot
            end

            --          This pair is a complete operation, cursor is expected to be clear by the time both of these lines have run
            PickupInventoryItem(invslot);
            (bag == 0 and PutItemInBackpack or PutItemInBag)((C_Container or _G).ContainerIDToInventoryID(bag));--    First set of parenthesis chooses function to run before calling it, PutItemInBackpack() doesn't accept any args, so ContainerIDToInventoryID() is safe to run regardless

            if slotindex < #InventorySlots then
                slotindex = slotindex + 1;
            else
                return ;
            end-- Increment to next index or stop when we have no more inventory slots to process
        end
    end
end

function equipment:PutItemInInventory()
    if (not CursorHasItem()) then
        return ;
    end

    for bag = NUM_BAG_SLOTS or NUM_TOTAL_EQUIPPED_BAG_SLOTS, 0, -1 do
        local free, type = (C_Container or _G).GetContainerNumFreeSlots(bag);
        free = (type == 0 and free or 0);
        for _ = 1, free do
            (bag == 0 and PutItemInBackpack or PutItemInBag)((C_Container or _G).ContainerIDToInventoryID(bag));
        end
    end

    return true;
end

local function equipItems()
    for key, slot in pairs(slotInfo) do
        ClearCursor();
        if selectedSet.items[slot.name] == nil and GetInventoryItemID("player", slot.id) then
            PickupInventoryItem(slot.id);
            if (CursorHasItem()) then
                if not equipment:PutItemInInventory() then
                    UIErrorsFrame:AddMessage(ERR_EQUIPMENT_MANAGER_BAGS_FULL, 1.0, 0.1, 0.1, 1.0);
                end
            end
        else
            if GetInventoryItemID("player", slot.id) ~= selectedSet.items[slot.name] then
                local itemID, bagId, slotId;
                while true do
                    itemID, bagId, slotId = equipment:FindItemInBags(selectedSet.items[slot.name]);
                    local info = C_Container.GetContainerItemInfo(bagId, slotId)

                    if info.isLocked then
                        coroutine.yield()
                    else
                        break
                    end
                end

                C_Container.PickupContainerItem(bagId, slotId)
                EquipCursorItem(slot.id)
            end
        end
    end

    selectedSet = nil;
end

function equipment:UseEquipmentSet(id)
    local set = equipment.db.char.sets[id];

    selectedSet = set;

    ExtraStats:print("Equipping items from set:", set.name)

    gearThread = coroutine.create(equipItems)

end

function equipment:GetNumEquipmentSets()
    return ExtraStats:tablelength(equipment.db.char.sets)
end

function equipment:GetEquipmentSetInfoByName(arg)
    -- arg could be: "", "name", 1 (number),
    if (type(arg) == "string" and arg ~= "") then
        if (equipment:GetEquipmentSetID(arg) ~= nil) then
            return equipment:GetEquipmentSetInfo(equipment:GetEquipmentSetID(arg));
        else
            return nil;
        end
    elseif (arg == "") then
        return nil;
    else
        return equipment:GetEquipmentSetInfo(arg);
    end
end